# frozen_string_literal: true

require 'exifr/jpeg'
require 'exifr/tiff'
require 'fileutils'
require 'pathname'
require 'net/http'
require 'json'
require 'uri'

module Jekyll
  class PhotoExifGenerator < Generator
    safe true
    priority :low

    def generate(site)
      photos_dir = File.join(site.source, 'assets', 'photos')
      return unless File.directory?(photos_dir)

      photos_collection_dir = File.join(site.source, '_photos')
      FileUtils.mkdir_p(photos_collection_dir) unless File.directory?(photos_collection_dir)

      # Find all image files
      image_extensions = %w[.jpg .jpeg .png .gif .webp .tiff .tif]
      image_files = Dir.glob(File.join(photos_dir, '**', '*')).select do |file|
        image_extensions.include?(File.extname(file).downcase)
      end

      # Track which images exist
      existing_image_paths = image_files.map { |f| File.join(site.source, f) }

      # Process all existing images
      image_files.each do |image_path|
        process_image(site, image_path, photos_collection_dir)
      end

      # Clean up markdown files for deleted images
      cleanup_orphaned_photos(site, photos_collection_dir, existing_image_paths)
    end

    private

    def cleanup_orphaned_photos(site, photos_collection_dir, existing_image_paths)
      # Get all markdown files in _photos directory
      md_files = Dir.glob(File.join(photos_collection_dir, '*.md'))
      
      md_files.each do |md_path|
        # Read the markdown file to get the image path
        content = File.read(md_path)
        image_match = content.match(/image:\s*(.+)/)
        
        if image_match
          image_url = image_match.captures.first.strip
          # Convert URL path to file path
          image_path = File.join(site.source, image_url.gsub(/^\//, ''))
          
          # If image file doesn't exist, delete the markdown file
          unless File.exist?(image_path)
            Jekyll.logger.info "PhotoExifGenerator:", "Removing orphaned photo: #{md_path} (image not found: #{image_path})"
            File.delete(md_path)
          end
        end
      end
    end

    def process_image(site, image_path, photos_collection_dir)
      relative_path = Pathname.new(image_path).relative_path_from(Pathname.new(site.source))
      image_url = "/#{relative_path}"

      # Skip if markdown file already exists
      slug = generate_slug(image_path)
      md_path = File.join(photos_collection_dir, "#{slug}.md")
      
      # Check if file exists and has location already
      existing_has_location = false
      existing_location = nil
      if File.exist?(md_path)
        content = File.read(md_path)
        existing_has_location = content.include?('location:')
        if existing_has_location
          location_match = content.match(/location:\s*(.+)/)
          existing_location = location_match.captures.first.strip if location_match
        end
      end
      
      # Extract EXIF data
      date_taken = nil
      location_data = nil
      
      begin
        # Try JPEG first, then TIFF
        exif_data = nil
        if File.extname(image_path).downcase.match?(/\.(jpg|jpeg)$/)
          exif_data = EXIFR::JPEG.new(image_path)
        elsif File.extname(image_path).downcase.match?(/\.(tiff|tif)$/)
          exif_data = EXIFR::TIFF.new(image_path)
        end
        
        if exif_data
          date_taken = extract_date(exif_data)
          # Only geocode if location doesn't exist yet (to avoid unnecessary API calls)
          unless existing_has_location
            Jekyll.logger.info "PhotoExifGenerator:", "Geocoding #{File.basename(image_path)}..."
            location_data = extract_location(exif_data)
            if location_data
              Jekyll.logger.info "PhotoExifGenerator:", "Found location: #{location_data}"
            else
              Jekyll.logger.warn "PhotoExifGenerator:", "No location found for #{File.basename(image_path)} (no GPS data or geocoding failed)"
            end
          end
        else
          Jekyll.logger.warn "PhotoExifGenerator:", "No EXIF data found for #{File.basename(image_path)}"
        end
      rescue => e
        # Fallback if EXIF extraction fails
        Jekyll.logger.warn "PhotoExifGenerator:", "Could not extract EXIF from #{image_path}: #{e.message}"
      end
      
      # Use file modification time as fallback if no date found
      date_taken ||= File.mtime(image_path)

      # Generate front matter
      front_matter = {
        'title' => File.basename(image_path, File.extname(image_path)).gsub(/[-_]/, ' ').split.map(&:capitalize).join(' '),
        'date' => date_taken.strftime('%Y-%m-%d'),
        'image' => image_url
      }
      
      # Preserve existing location or add new one
      if existing_has_location && File.exist?(md_path)
        content = File.read(md_path)
        existing_location = content.match(/location:\s*(.+)/)&.captures&.first
        front_matter['location'] = existing_location.strip if existing_location
      elsif location_data
        front_matter['location'] = location_data
      end
      
      front_matter.compact

      # Only create/update if file doesn't exist or needs updating
      if !File.exist?(md_path) || should_update?(md_path, front_matter)
        write_markdown_file(md_path, front_matter)
      end
    end

    def extract_date(exif_data)
      if exif_data.date_time_original
        exif_data.date_time_original
      elsif exif_data.date_time
        exif_data.date_time
      else
        nil
      end
    end

    def extract_location(exif_data)
      unless exif_data.gps
        Jekyll.logger.info "PhotoExifGenerator:", "No GPS data in EXIF"
        return nil
      end

      begin
        lat = exif_data.gps.latitude
        lng = exif_data.gps.longitude
        
        unless lat && lng
          Jekyll.logger.info "PhotoExifGenerator:", "GPS coordinates are nil"
          return nil
        end
        
        Jekyll.logger.info "PhotoExifGenerator:", "Found GPS: #{lat}, #{lng}"
        
        # Reverse geocode using OpenStreetMap Nominatim API
        location_name = reverse_geocode(lat, lng)
        return location_name if location_name
        
        Jekyll.logger.warn "PhotoExifGenerator:", "Geocoding returned nil for coordinates #{lat}, #{lng}"
        nil
      rescue => e
        Jekyll.logger.warn "PhotoExifGenerator:", "Could not extract location: #{e.message}"
        nil
      end
    end

    def reverse_geocode(lat, lng)
      # Use OpenStreetMap Nominatim API (free, no API key required)
      # Add a small delay to respect rate limits
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
        Jekyll.logger.warn "PhotoExifGenerator:", "Geocoding API returned #{response.code} for #{lat}, #{lng}"
        return nil
      end
      
      data = JSON.parse(response.body)
      address = data['address']
      unless address
        Jekyll.logger.warn "PhotoExifGenerator:", "No address data in geocoding response for #{lat}, #{lng}"
        return nil
      end
      
      # Extract city and country
      city = address['city'] || address['town'] || address['village'] || address['municipality'] || address['suburb']
      country = address['country']
      
      unless city || country
        Jekyll.logger.warn "PhotoExifGenerator:", "No city or country found in address: #{address.inspect}"
        return nil
      end
      
      # Format as "City, Country" or just "City" if no country
      if city && country
        result = "#{city}, #{country}"
      elsif city
        result = city
      elsif country
        result = country
      else
        result = nil
      end
      
      Jekyll.logger.info "PhotoExifGenerator:", "Geocoded #{lat}, #{lng} to: #{result}"
      result
    rescue => e
      Jekyll.logger.warn "PhotoExifGenerator:", "Geocoding failed for #{lat}, #{lng}: #{e.message}"
      nil
    end


    def generate_slug(image_path)
      # Use filename without extension as slug
      base_name = File.basename(image_path, File.extname(image_path))
      # Clean up the slug
      base_name.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/^-|-$/, '')
    end

    def should_update?(md_path, front_matter)
      return true unless File.exist?(md_path)

      # Read existing file and check if key fields match or if location is missing
      content = File.read(md_path)
      existing_date = content.match(/date:\s*(.+)/)&.captures&.first
      existing_image = content.match(/image:\s*(.+)/)&.captures&.first
      existing_location = content.match(/location:\s*(.+)/)&.captures&.first

      # Update if date/image changed OR if location is missing but we have location data
      date_changed = existing_date != front_matter['date']
      image_changed = existing_image != front_matter['image']
      location_missing = front_matter['location'] && !existing_location

      date_changed || image_changed || location_missing
    end

    def write_markdown_file(md_path, front_matter)
      content = "---\n"
      front_matter.each do |key, value|
        if value.is_a?(String) && value.include?(':')
          content += "#{key}: \"#{value}\"\n"
        else
          content += "#{key}: #{value}\n"
        end
      end
      content += "---\n\n"

      File.write(md_path, content)
    end
  end
end
