# frozen_string_literal: true

require "json"
require "fileutils"
require "exifr/jpeg"
require "exifr/tiff"

# Bakes the OpenFeed photo feed (JSON Feed 1.1) at BUILD time.
#
# OpenFeed (https://openfeed.photo/setup/) reads a JSON Feed of your photos
# straight off your domain — nothing is uploaded anywhere. This plugin emits
# that feed to /photo/feed.json so publishing a photo stays "drop the image
# file, run one build, deploy": the feed is regenerated from the `photos`
# collection every build and is never hand-edited.
#
# Per the spec:
#   - one item per photo, newest first
#   - id + url are the photo's permalink page; image is the FULL-SIZE file
#   - EXIF is read from the ORIGINAL image files here at build time (exported
#     or resized copies usually have it stripped). DateTimeOriginal becomes
#     date_published (RFC 3339), falling back to the file's mtime only when a
#     file carries no EXIF date. Camera/lens/shutter/aperture/iso/focal become
#     _photoring.exif as display-formatted strings — whatever the file has,
#     omitting the rest, omitting the whole object when a file has none.
#   - no captions, no thumbnails: OpenFeed generates its own sizes.
#
# Runs on :post_write for the same reason as the Readwise pager — that's the
# point at which site.dest exists and Jekyll's own write pass is done.
module PhotoFeedGenerator
  # ƒ (U+0192) matches how cameras/apps render aperture, e.g. "ƒ/1.4".
  APERTURE_PREFIX = "ƒ/"

  def self.emit(site)
    photos = site.collections["photos"]&.docs || []

    items = photos.map { |doc| item_for(site, doc) }.compact
    # Newest first. `_ts` is the parsed timestamp we sort on, then drop.
    items.sort_by! { |i| i.delete("_ts") }
    items.reverse!

    feed = {
      "version" => "https://jsonfeed.org/version/1.1",
      "title" => "#{author_name(site)} — Photos",
      "home_page_url" => absolute(site, "/photos/"),
      "feed_url" => absolute(site, "/photo/feed.json"),
      "authors" => [author(site)],
      "_photoring" => photoring(site),
      "items" => items,
    }

    dir = File.join(site.dest, "photo")
    FileUtils.mkdir_p(dir)
    File.write(File.join(dir, "feed.json"), JSON.pretty_generate(feed))

    Jekyll.logger.info "PhotoFeed:", "baked #{items.size} photo(s) into /photo/feed.json"
  end

  # One JSON Feed item, or nil if the photo has no image to point at.
  def self.item_for(site, doc)
    image_path = doc.data["image"].to_s
    return nil if image_path.empty?

    page_url = absolute(site, doc.url)
    file = File.join(site.source, image_path.sub(%r{\A/}, ""))
    exif = read_exif(file)

    item = {
      "id" => page_url,
      "url" => page_url,
      "image" => absolute(site, encode_path(image_path)),
      "date_published" => published_at(exif, file, doc),
    }
    photo_exif = exif ? exif_card(exif) : {}
    item["_photoring"] = { "exif" => photo_exif } unless photo_exif.empty?

    # Carry a sortable timestamp alongside the RFC 3339 string.
    item["_ts"] = item["date_published"]
    item
  end

  # EXIFR object for the original file, or nil if it can't be read as EXIF.
  def self.read_exif(file)
    return nil unless File.file?(file)

    case File.extname(file).downcase
    when ".jpg", ".jpeg" then EXIFR::JPEG.new(file)
    when ".tif", ".tiff" then EXIFR::TIFF.new(file)
    end
  rescue StandardError => e
    Jekyll.logger.warn "PhotoFeed:", "EXIF read failed for #{File.basename(file)}: #{e.message}"
    nil
  end

  # RFC 3339 timestamp. DateTimeOriginal (then DateTime) wins; fall back to the
  # file's mtime, and only then to the collection doc's date, so the feed always
  # has a valid published date even for EXIF-less files.
  def self.published_at(exif, file, doc)
    time =
      (exif && (exif.date_time_original || exif.date_time)) ||
      (File.file?(file) ? File.mtime(file) : nil) ||
      doc.date

    time.strftime("%Y-%m-%dT%H:%M:%S%:z")
  end

  # Display-formatted EXIF card. Includes only the fields the file actually
  # carries; returns {} when none are present (caller omits the object then).
  def self.exif_card(exif)
    {
      "camera" => camera(exif),
      "lens" => lens(exif),
      "shutter" => shutter(exif.exposure_time),
      "aperture" => aperture(exif.f_number),
      "iso" => iso(exif.iso_speed_ratings),
      "focal" => focal(exif.focal_length),
    }.reject { |_, v| v.nil? || v.to_s.strip.empty? }
  end

  def self.camera(exif)
    make = exif.make.to_s.strip
    model = exif.model.to_s.strip
    return nil if model.empty? && make.empty?
    return model if make.empty?

    make_disp = make.split.map { |w| w == w.upcase ? w.capitalize : w }.join(" ")
    # Avoid "Canon Canon EOS R6" when the model already repeats the make.
    return model if model.downcase.start_with?(make.split.first.to_s.downcase)

    "#{make_disp} #{model}".strip
  end

  def self.lens(exif)
    value = exif.respond_to?(:lens_model) ? exif.lens_model : nil
    value ||= (exif.exif[:lens_model] rescue nil)
    value = value.to_s.strip
    value.empty? ? nil : value
  end

  # e.g. (1/6400) -> "1/6400", 2.0 -> "2", 1.3 -> "1.3"
  def self.shutter(time)
    return nil unless time

    t = time.to_f
    return nil if t <= 0
    return "1/#{(1.0 / t).round}" if t < 1

    trim_number(t)
  end

  # e.g. 1.4 -> "ƒ/1.4", 8.0 -> "ƒ/8"
  def self.aperture(f_number)
    return nil unless f_number

    f = f_number.to_f
    return nil if f <= 0

    "#{APERTURE_PREFIX}#{trim_number(f)}"
  end

  # iso_speed_ratings can be an Integer or an Array of them.
  def self.iso(iso)
    value = iso.is_a?(Array) ? iso.first : iso
    value.nil? ? nil : value.to_i.to_s
  end

  # e.g. 35 -> "35mm", 16.5 -> "16.5mm"
  def self.focal(focal_length)
    return nil unless focal_length

    f = focal_length.to_f
    return nil if f <= 0

    "#{trim_number(f)}mm"
  end

  # Whole numbers lose their ".0"; everything else keeps one decimal.
  def self.trim_number(value)
    (value % 1).zero? ? value.to_i.to_s : format("%.1f", value)
  end

  def self.author(site)
    {
      "name" => author_name(site),
      "url" => author_url(site),
      "avatar" => absolute(site, site.config.dig("author", "avatar") || "/assets/avatar.jpg"),
    }
  end

  def self.photoring(site)
    ring = site.config.dig("photoring", "ring") || "openfeed-demo"
    creator = site.config.dig("photoring", "creator").to_s
    Jekyll.logger.warn "PhotoFeed:", "photoring.creator is unset in _config.yml" if creator.empty?
    { "ring" => ring, "creator" => creator }
  end

  def self.author_name(site)
    site.config.dig("author", "name") || site.config["title"]
  end

  def self.author_url(site)
    site.config.dig("author", "url") || site.config["url"]
  end

  # Site-absolute URL -> fully-qualified URL on the production domain.
  def self.absolute(site, path)
    base = site.config["url"].to_s.chomp("/")
    "#{base}#{path}"
  end

  # Percent-encode each path segment (filenames carry spaces) while leaving the
  # separators intact, so "/assets/photos/All Film - 1 of 13.jpeg" becomes a
  # valid URL. Operates byte-wise for correct multibyte encoding.
  def self.encode_path(path)
    path.split("/", -1).map do |segment|
      segment.b.gsub(/[^A-Za-z0-9\-._~]/) { |b| format("%%%02X", b.ord) }
    end.join("/")
  end
end

Jekyll::Hooks.register :site, :post_write do |site|
  PhotoFeedGenerator.emit(site)
end
