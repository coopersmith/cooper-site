# frozen_string_literal: true

require 'fileutils'
require 'pathname'
require 'time'
require 'jekyll-last-modified-at'

module Recents
  # Generate change information for all markdown pages
  class Generator < Jekyll::Generator
    def generate(site)
      items = site.collections['notes'].docs
      items.each do |page|
        timestamp = Jekyll::LastModifiedAt::Determinator.new(site.source, page.path, '%FT%T%:z').to_s
        page.data['last_modified_at_timestamp'] = timestamp

        created = created_at_for(site, page)
        next unless created

        page.data['created_at'] = created
        page.data['created_at_timestamp'] = created.strftime('%FT%T%:z')
      end
    end

    private

    # Determine when a note was created. Prefer an explicit `created` (or
    # `date`) value in the front matter, otherwise fall back to the date of
    # the file's first git commit.
    def created_at_for(site, page)
      explicit = page.data['created'] || page.data['date']
      return to_time(explicit) if explicit

      git_created_at(site, page.path)
    end

    def git_created_at(source, path)
      Dir.chdir(source) do
        output = `git log --diff-filter=A --follow --format=%aI -1 -- "#{path}" 2>/dev/null`.strip
        return nil if output.empty?

        Time.parse(output)
      end
    rescue StandardError
      nil
    end

    def to_time(value)
      return value if value.is_a?(Time)

      Time.parse(value.to_s)
    rescue StandardError
      nil
    end
  end
end
