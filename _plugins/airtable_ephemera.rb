# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'
require 'time'

# Airtable Ephemera Plugin for Jekyll
# Fetches ephemera data from Airtable with optimized API usage to prevent quota issues

module Jekyll
  class AirtableEphemeraGenerator < Generator
    safe true
    priority :high

    def generate(site)
      # Skip if environment variables are not set
      api_key = ENV['AIRTABLE_API_KEY']
      base_id = ENV['AIRTABLE_BASE_ID']
      table_name = ENV['AIRTABLE_TABLE_NAME'] || 'Ephemera'

      unless api_key && base_id
        Jekyll.logger.warn "Airtable Ephemera:", "Missing API credentials. Skipping ephemera data fetch."
        return
      end

      # Check if we have cached data that's less than 1 hour old to avoid unnecessary API calls
      data_file = File.join(site.source, '_data', 'ephemera.yml')
      if File.exist?(data_file)
        file_age = Time.now - File.mtime(data_file)
        if file_age < 3600 # 1 hour cache
          Jekyll.logger.info "Airtable Ephemera:", "Using cached data (#{(file_age/60).round} minutes old)"
          return
        end
      end

      begin
        Jekyll.logger.info "Airtable Ephemera:", "Fetching data from Airtable..."
        
        # Fetch data with optimized parameters
        records = fetch_airtable_records(api_key, base_id, table_name)
        
        if records.empty?
          Jekyll.logger.warn "Airtable Ephemera:", "No records found in Airtable"
          return
        end

        # Process and sort records
        ephemera_items = process_records(records)
        
        # Generate YAML data file
        generate_data_file(site, ephemera_items)
        
        Jekyll.logger.info "Airtable Ephemera:", "Successfully processed #{ephemera_items.length} ephemera items"
        
      rescue => e
        Jekyll.logger.error "Airtable Ephemera:", "Error fetching data: #{e.message}"
        # Create empty data file on error to prevent build failures
        generate_data_file(site, [])
      end
    end

    private

    def fetch_airtable_records(api_key, base_id, table_name)
      records = []
      offset = nil
      max_requests = 3 # Conservative limit to prevent quota exhaustion
      request_count = 0

      loop do
        break if request_count >= max_requests

        # Try different table name formats
        table_names_to_try = [table_name]
        
        # Add the actual table ID from the Airtable URL
        table_names_to_try << 'tblzLdJRyUzTYUMzq' # The actual table ID

        success = false
        
        table_names_to_try.each do |current_table_name|
          begin
            uri = URI("https://api.airtable.com/v0/#{base_id}/#{current_table_name}")
            params = {
              'pageSize' => 100, # Use maximum page size to minimize requests
              'sort[0][field]' => 'date',
              'sort[0][direction]' => 'desc'
            }
            params['offset'] = offset if offset
            uri.query = URI.encode_www_form(params)

            request = Net::HTTP::Get.new(uri)
            request['Authorization'] = "Bearer #{api_key}"

            response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
              http.request(request)
            end

            if response.code == '200'
              data = JSON.parse(response.body)
              records.concat(data['records'] || [])
              
              offset = data['offset']
              request_count += 1
              success = true
              
              Jekyll.logger.info "Airtable Ephemera:", "Successfully fetched page #{request_count} using table '#{current_table_name}'"
              
              # Add delay to respect rate limits (5 requests/second)
              sleep(0.25)
              
              break # Exit the table name loop on success
            elsif response.code == '403'
              Jekyll.logger.warn "Airtable Ephemera:", "403 error with table '#{current_table_name}' - trying next option"
              next # Try next table name
            else
              raise "Airtable API error: #{response.code} - #{response.body}"
            end
          rescue => e
            Jekyll.logger.warn "Airtable Ephemera:", "Error with table '#{current_table_name}': #{e.message}"
            next # Try next table name
          end
        end

        unless success
          raise "Failed to fetch data from any table name variant"
        end
        
        break unless offset
      end

      records
    end

    def process_records(records)
      ephemera_items = records.map do |record|
        fields = record['fields'] || {}
        
        # Extract date - try multiple field names
        date = extract_date(record, fields)
        
        {
          'id' => record['id'],
          'title' => fields['name'] || fields['Title'] || fields['Name'] || 'Untitled',
          'description' => fields['Description'] || fields['Notes'] || '',
          'date' => date,
          'location' => fields['location'] || fields['venue'] || fields['Location'] || '',
          'tags' => extract_tags(fields),
          'attachments' => extract_attachments(fields),
          'created_time' => record['createdTime'],
          'venue' => fields['venue'] || '',
          'country' => fields['country'] || ''
        }
      end

      # Sort by date (most recent first)
      ephemera_items.sort_by! do |item|
        begin
          item['date'] ? Date.parse(item['date'].to_s) : Date.parse(item['created_time'])
        rescue
          Time.now.to_date
        end
      end.reverse!

      ephemera_items
    end

    def extract_date(record, fields)
      # Try various common date field names
      date_fields = ['Date', 'Created', 'Date Created', 'Timestamp']
      
      date_fields.each do |field_name|
        if fields[field_name]
          return fields[field_name]
        end
      end
      
      # Fallback to record creation time
      record['createdTime']
    end

    def extract_tags(fields)
      tags = fields['Tags'] || fields['Category'] || fields['Type'] || []
      return [] unless tags
      
      # Handle both string and array formats
      case tags
      when String
        tags.split(',').map(&:strip)
      when Array
        tags
      else
        []
      end
    end

    def extract_attachments(fields)
      attachments = fields['images'] || fields['Attachments'] || fields['Images'] || fields['Photos'] || []
      return [] unless attachments.is_a?(Array)
      
      attachments.map do |attachment|
        {
          'id' => attachment['id'],
          'url' => attachment['url'],
          'filename' => attachment['filename'],
          'type' => attachment['type'],
          'thumbnails' => attachment['thumbnails']
        }
      end
    end

    def generate_data_file(site, ephemera_items)
      data_dir = File.join(site.source, '_data')
      FileUtils.mkdir_p(data_dir) unless Dir.exist?(data_dir)
      
      data_file = File.join(data_dir, 'ephemera.yml')
      
      yaml_content = {
        'last_updated' => Time.now.utc.strftime('%Y-%m-%d %H:%M:%S +0000'),
        'count' => ephemera_items.length,
        'items' => ephemera_items
      }.to_yaml
      
      File.write(data_file, yaml_content)
      Jekyll.logger.info "Airtable Ephemera:", "Generated #{data_file}"
    end
  end
end