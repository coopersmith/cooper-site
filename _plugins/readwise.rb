# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

# Shared Readwise client.
#
# Both build-time features — the transclusion baker (readwise_transclusion.rb)
# and the /highlights page generator (readwise_highlights_page.rb) — need the
# same thing: the whole Readwise library, books with their highlights nested.
# The export endpoint returns exactly that in a handful of paginated calls
# regardless of library size, so we pull it once and memoize it on `site.data`
# for the life of the build. That way two features cost one library pull, and a
# `jekyll serve` regeneration re-fetches (site.data is rebuilt each pass) so the
# content stays fresh in dev.
module Readwise
  API_BASE = "https://readwise.io/api/v2"

  # The array of book hashes (each with a nested "highlights" array), or [] on
  # any failure. Memoized per build; callers may call it freely.
  def self.export(site, token)
    return [] unless token

    site.data["__readwise_export"] ||= fetch_export(token)
  end

  # Walk the paginated Readwise export (every book with its highlights nested).
  def self.fetch_export(token)
    books = []
    cursor = nil

    loop do
      url = +"#{API_BASE}/export/?"
      url << "pageCursor=#{URI.encode_www_form_component(cursor)}" if cursor

      data = api_get(url, token)
      break unless data

      books.concat(Array(data["results"]))
      cursor = data["nextPageCursor"]
      break if cursor.nil? || cursor.to_s.empty?
    end

    Jekyll.logger.info "Readwise:", "loaded #{books.size} books from Readwise export"
    books
  end

  def self.api_get(url, token, attempt: 1)
    uri = URI(url)
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Token #{token}"

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true,
                               open_timeout: 10, read_timeout: 60) do |http|
      http.request(request)
    end

    case response
    when Net::HTTPSuccess
      JSON.parse(response.body)
    when Net::HTTPTooManyRequests
      retry_after = response["Retry-After"].to_i
      if attempt <= 5 && retry_after.between?(1, 60)
        Jekyll.logger.info "Readwise:", "rate limited, retrying in #{retry_after}s"
        sleep(retry_after)
        api_get(url, token, attempt: attempt + 1)
      end
    end
  rescue StandardError => e
    Jekyll.logger.warn "Readwise:", "API error (#{url}): #{e.message}"
    nil
  end
end
