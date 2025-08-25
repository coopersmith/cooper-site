# frozen_string_literal: true

require 'shellwords'
require 'time'

module CreatedAt
  class Generator < Jekyll::Generator
    def generate(site)
      notes = site.collections['notes'].docs
      notes.each do |page|
        timestamp = created_timestamp(page.path)
        page.data['created_at'] = Time.parse(timestamp)
        page.data['created_at_timestamp'] = timestamp
      end
    end

    private

    def created_timestamp(path)
      escaped = Shellwords.escape(path)
      ts = `git log --diff-filter=A --follow --format=%aI -1 -- #{escaped}`.strip
      ts = File.ctime(path).utc.iso8601 if ts.empty?
      ts
    end
  end
end
