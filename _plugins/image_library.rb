# frozen_string_literal: true

# Image library generator — the successor to photo_exif_generator.rb.
#
# Guarantees every image under the configured library roots (see
# `image_library.roots` in _config.yml) has a metadata record in _images/.
# The record is the CMS: machine facts (EXIF date, dimensions, camera, lens,
# geocoded location) are extracted from the original at build time, editorial
# facts (surfaces, caption, alt, trip) are yours. The site renders from the
# records, so served images never need to carry EXIF themselves.
#
# The one rule that makes hand-editing safe: MACHINE FILLS, HUMAN OVERRIDES.
# Apart from `image` (the file path, which the generator owns so a moved file
# can't strand its record), a field that already exists in a record is never
# overwritten — correct a date or camera by editing the record and the fix
# sticks. Geocoding runs only for records with no `location` yet, keeping
# API calls one-time.
#
# `surfaces` is the routing: a list of the site surfaces an image appears on
# (diary, best, …). Pages query it (`where_exp: img.surfaces contains 'x'`).
# A new record starts with its root's default surfaces from _config.yml.
#
# Records created or upgraded mid-build are synced into the in-memory
# collection too, so a fresh image renders on the same build that mints its
# record instead of the one after.

require 'exifr/jpeg'
require 'exifr/tiff'
require 'fileutils'
require 'pathname'
require 'net/http'
require 'json'
require 'uri'
require 'yaml'
require 'date'

module Jekyll
  class ImageLibraryGenerator < Generator
    safe true
    priority :low

    COLLECTION = 'images'
    RECORDS_DIR = '_images'
    IMAGE_EXTENSIONS = %w[.jpg .jpeg .png .gif .webp .tiff .tif].freeze

    # Frontmatter key order for records the generator writes. User-added keys
    # it doesn't know about are preserved after these.
    KEY_ORDER = %w[title date image width height camera lens location surfaces].freeze

    def generate(site)
      @site = site
      roots = library_roots(site)
      return if roots.empty?

      records_dir = File.join(site.source, RECORDS_DIR)
      FileUtils.mkdir_p(records_dir)

      known_images = []

      roots.each do |root|
        dir = File.join(site.source, root['path'])
        next unless File.directory?(dir)

        Dir.glob(File.join(dir, '**', '*')).sort.each do |image_path|
          next unless IMAGE_EXTENSIONS.include?(File.extname(image_path).downcase)

          known_images << image_path
          process_image(site, image_path, records_dir, root)
        end
      end

      cleanup_orphaned_records(site, records_dir, known_images)
    end

    private

    def library_roots(site)
      config = site.config['image_library'] || {}
      roots = config['roots'] || []
      roots.select { |r| r.is_a?(Hash) && r['path'] }
    end

    # ── Per-image record maintenance ──────────────────────────────────

    def process_image(site, image_path, records_dir, root)
      relative_path = Pathname.new(image_path).relative_path_from(Pathname.new(site.source))
      image_url = "/#{relative_path}"

      slug = generate_slug(image_path)
      md_path = File.join(records_dir, "#{slug}.md")

      existing_data, body = read_record(md_path)
      return if existing_data.nil? # unparseable frontmatter — leave the record alone

      machine = machine_facts(image_path, image_url, geocode: !existing_data.key?('location'))

      # Fill-don't-clobber merge: `image` is machine-owned, everything else
      # only lands where the record has nothing.
      merged = existing_data.dup
      merged['image'] = machine['image']
      machine.each do |key, value|
        next if key == 'image'
        merged[key] = value unless merged.key?(key)
      end
      merged['surfaces'] = Array(root['surfaces']).map(&:to_s) unless merged.key?('surfaces') || Array(root['surfaces']).empty?

      if merged != existing_data || !File.exist?(md_path)
        action = File.exist?(md_path) ? 'Updated' : 'Created'
        write_record(md_path, merged, body)
        Jekyll.logger.info 'ImageLibrary:', "#{action} record #{slug}"
      end

      sync_in_memory(site, md_path, merged)
    end

    # Machine-extracted facts for an image. Geocoding is skipped unless asked
    # for (i.e. the record has no location yet) to avoid re-hitting the API.
    def machine_facts(image_path, image_url, geocode:)
      facts = { 'image' => image_url }
      facts['title'] = default_title(image_path)

      exif = read_exif(image_path)

      date = exif && extract_date(exif)
      date ||= File.mtime(image_path)
      facts['date'] = date.to_date

      width, height = extract_dimensions(image_path, exif)
      if width && height
        facts['width'] = width
        facts['height'] = height
      end

      camera = extract_camera(exif)
      facts['camera'] = camera if camera
      lens = extract_lens(exif)
      facts['lens'] = lens if lens

      if exif && geocode
        location = extract_location(exif, image_path)
        facts['location'] = location if location
      end

      facts
    end

    def default_title(image_path)
      File.basename(image_path, File.extname(image_path))
          .gsub(/[-_]/, ' ').split.map(&:capitalize).join(' ')
    end

    def generate_slug(image_path)
      # Filename (sans extension) is the permanent ID — same algorithm the old
      # generator used, so existing records keep matching their images.
      File.basename(image_path, File.extname(image_path))
          .downcase.gsub(/[^a-z0-9]+/, '-').gsub(/^-|-$/, '')
    end

    # ── Record file I/O ───────────────────────────────────────────────

    def read_record(md_path)
      return [{}, ''] unless File.exist?(md_path)

      content = File.read(md_path)
      if content =~ /\A---\s*\n(.*?)\n?---\s*\n?/m
        data = YAML.safe_load(Regexp.last_match(1), permitted_classes: [Date, Time], aliases: true) || {}
        [data, Regexp.last_match.post_match]
      else
        [{}, content]
      end
    rescue Psych::Exception => e
      Jekyll.logger.warn 'ImageLibrary:', "Unparseable frontmatter in #{md_path} (#{e.message}) — leaving it alone"
      [nil, nil]
    end

    def write_record(md_path, data, body)
      return if data.nil? # unparseable file, don't touch it

      ordered = {}
      KEY_ORDER.each { |k| ordered[k] = data[k] if data.key?(k) }
      data.each { |k, v| ordered[k] = v unless ordered.key?(k) }

      yaml = ordered.to_yaml.sub(/\A---\s*\n/, '')
      File.write(md_path, "---\n#{yaml}---\n#{body.to_s.empty? ? '' : "\n#{body.to_s.lstrip}"}")
    end

    # Keep the live collection consistent with what was just written, so a
    # record minted or upgraded this build renders this build.
    def sync_in_memory(site, md_path, data)
      return if data.nil?

      collection = site.collections[COLLECTION]
      return unless collection

      doc = collection.docs.find { |d| d.path == md_path }
      if doc
        data.each { |k, v| doc.data[k] = liquid_value(v) }
      else
        doc = Jekyll::Document.new(md_path, site: site, collection: collection)
        doc.read
        collection.docs << doc
        collection.docs.sort!
      end
    end

    def liquid_value(value)
      value.is_a?(Date) ? value.to_time : value
    end

    # ── EXIF extraction ───────────────────────────────────────────────

    def read_exif(image_path)
      case File.extname(image_path).downcase
      when '.jpg', '.jpeg' then EXIFR::JPEG.new(image_path)
      when '.tiff', '.tif' then EXIFR::TIFF.new(image_path)
      end
    rescue StandardError => e
      Jekyll.logger.warn 'ImageLibrary:', "Could not read EXIF from #{image_path}: #{e.message}"
      nil
    end

    def extract_date(exif)
      exif.date_time_original || exif.date_time
    rescue StandardError
      nil
    end

    # Pixel dimensions, corrected for EXIF orientation (a portrait shot from a
    # rotated camera stores landscape dimensions plus a rotation flag).
    def extract_dimensions(image_path, exif)
      width = height = nil

      if exif.respond_to?(:width) && exif.width && exif.height
        width = exif.width
        height = exif.height
        orientation = (exif.orientation.to_i rescue 0)
        width, height = height, width if [5, 6, 7, 8].include?(orientation)
      elsif File.extname(image_path).downcase == '.png'
        width, height = png_dimensions(image_path)
      elsif File.extname(image_path).downcase == '.gif'
        width, height = gif_dimensions(image_path)
      end

      [width, height]
    rescue StandardError => e
      Jekyll.logger.warn 'ImageLibrary:', "Could not read dimensions of #{image_path}: #{e.message}"
      [nil, nil]
    end

    def png_dimensions(image_path)
      header = File.binread(image_path, 24)
      return [nil, nil] unless header && header[0, 8] == "\x89PNG\r\n\x1a\n".b

      header[16, 8].unpack('N2')
    end

    def gif_dimensions(image_path)
      header = File.binread(image_path, 10)
      return [nil, nil] unless header && header[0, 3] == 'GIF'

      header[6, 4].unpack('v2')
    end

    def extract_camera(exif)
      return nil unless exif

      make = (exif.make rescue nil).to_s.strip
      model = (exif.model rescue nil).to_s.strip
      return nil if make.empty? && model.empty?

      # "LEICA CAMERA AG" + "LEICA Q3" → the model already names the make.
      camera = if model.empty?
                 make
               elsif make.empty? || model.downcase.include?(make.split.first.to_s.downcase)
                 model
               else
                 "#{make} #{model}"
               end
      humanize_caps(camera)
    end

    def extract_lens(exif)
      return nil unless exif

      lens = (exif.lens_model rescue nil).to_s.strip
      lens.empty? ? nil : lens
    end

    # "LEICA Q3" → "Leica Q3": soften SHOUTING vendor strings but leave short
    # alphanumeric designations (Q3, M11, ASPH.) alone.
    def humanize_caps(str)
      str.split.map do |word|
        word.match?(/\A[A-Z]{4,}\z/) ? word.capitalize : word
      end.join(' ')
    end

    # ── Location (geocoding) ──────────────────────────────────────────

    def extract_location(exif, image_path)
      gps = (exif.gps rescue nil)
      return nil unless gps && gps.latitude && gps.longitude

      Jekyll.logger.info 'ImageLibrary:', "Geocoding #{File.basename(image_path)} (#{gps.latitude}, #{gps.longitude})..."
      reverse_geocode(gps.latitude, gps.longitude)
    end

    def reverse_geocode(lat, lng)
      # OpenStreetMap Nominatim (free, no key); the sleep respects their rate limit.
      sleep(1)

      uri = URI("https://nominatim.openstreetmap.org/reverse?lat=#{lat}&lon=#{lng}&format=json&addressdetails=1")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 10
      http.open_timeout = 10

      request = Net::HTTP::Get.new(uri)
      request['User-Agent'] = 'Jekyll Photo Blog/1.0' # Required by Nominatim

      response = http.request(request)
      unless response.code == '200'
        Jekyll.logger.warn 'ImageLibrary:', "Geocoding API returned #{response.code} for #{lat}, #{lng}"
        return nil
      end

      address = JSON.parse(response.body)['address']
      return nil unless address

      city = address['city'] || address['town'] || address['village'] || address['municipality'] || address['suburb']
      country = address['country']
      return nil unless city || country

      [city, country].compact.join(', ')
    rescue StandardError => e
      Jekyll.logger.warn 'ImageLibrary:', "Geocoding failed for #{lat}, #{lng}: #{e.message}"
      nil
    end

    # ── Orphan cleanup ────────────────────────────────────────────────

    # A record whose image file is gone renders a broken page; drop it. (The
    # record is hand-curated, so this logs loudly — a rename is a delete plus
    # a fresh record, and the curation should be moved over by hand.)
    def cleanup_orphaned_records(site, records_dir, _known_images)
      Dir.glob(File.join(records_dir, '*.md')).each do |md_path|
        data, = read_record(md_path)
        next if data.nil? # unparseable — leave it alone

        image_url = data['image']
        next unless image_url.is_a?(String)

        image_path = File.join(site.source, image_url.sub(%r{^/}, ''))
        next if File.exist?(image_path)

        Jekyll.logger.warn 'ImageLibrary:', "Removing orphaned record #{File.basename(md_path)} (image not found: #{image_url}). If the image was renamed, re-add any hand-edited fields to the new record."
        File.delete(md_path)
        collection = site.collections[COLLECTION]
        collection&.docs&.reject! { |d| d.path == md_path }
      end
    end
  end
end
