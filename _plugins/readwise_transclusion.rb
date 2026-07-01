# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

# Bakes Readwise book highlights into notes at BUILD time.
#
# Your Obsidian vault stays pure markdown: you write the native transclusion
#
#     ## Notes
#
#     ![[Fight Club - Notes]]
#
# which renders your local Readwise note inside Obsidian. Nothing Readwise-
# specific (ids, plugins, frontmatter) is added to the vault, and the Readwise
# notes themselves never need to live in this repo.
#
# On publish, this generator finds every `![[<Title> - Notes]]` embed, looks up
# `<Title>` in your Readwise library via the API, fetches that book's
# highlights, and replaces the embed with the highlights as markdown — so the
# published page is self-contained, static HTML.
#
# Requirements:
#   * ENV["READWISE_TOKEN"] available at build time (already set on Netlify for
#     the readwise-highlights function; make sure it's exposed to builds too).
#
# Matching:
#   * `<Title>` (the part before " - Notes") is matched to a Readwise book's
#     title, normalized to ignore case, emoji, and punctuation.
#   * For titles that won't match cleanly, add an override in
#     _data/readwise_books.yml  ("Obsidian Title": readwise_book_id).
#
# Failure is always graceful: a missing token, no match, or an API error leaves
# an HTML comment in place of the highlights and logs a warning — the build
# never breaks.
#
# Runs at :high priority so it executes before BidirectionalLinksGenerator,
# letting any wikilinks inside the fetched highlights resolve normally.
module ReadwiseTransclusion
  API_BASE = "https://readwise.io/api/v2"

  # ![[Some Book - Notes]]  (whole-note embeds only; #headings / ^blocks and
  # aliased embeds are intentionally left alone)
  EMBED_PATTERN = /!\[\[([^\]|#\^]+?)\s*-\s*Notes\]\]/

  class Generator < Jekyll::Generator
    priority :high
    safe false # needs network access at build time

    def generate(site)
      @token = ENV["READWISE_TOKEN"]
      @overrides = build_overrides(site.data["readwise_books"])
      @books_by_title = nil # lazily fetched on first lookup
      @warned_no_token = false

      collection = site.collections["notes"]
      return unless collection

      collection.docs.each { |doc| bake(doc) }
    end

    private

    def bake(doc)
      return unless doc.content =~ EMBED_PATTERN

      doc.content = doc.content.gsub(EMBED_PATTERN) do
        title = Regexp.last_match(1).strip
        render(title, doc)
      end
    end

    def render(title, doc)
      unless @token
        unless @warned_no_token
          Jekyll.logger.warn "Readwise:", "READWISE_TOKEN not set — leaving embeds unresolved"
          @warned_no_token = true
        end
        return placeholder("no READWISE_TOKEN at build time", title)
      end

      book_id = resolve_book_id(title)
      unless book_id
        Jekyll.logger.warn "Readwise:", "no book match for #{title.inspect} (#{doc.relative_path})"
        return placeholder("no Readwise book matched", title)
      end

      highlights = fetch_highlights(book_id)
      if highlights.nil?
        Jekyll.logger.warn "Readwise:", "highlight fetch failed for #{title.inspect}"
        return placeholder("Readwise fetch failed", title)
      end
      if highlights.empty?
        Jekyll.logger.info "Readwise:", "no highlights for #{title.inspect}"
        return placeholder("no highlights found", title)
      end

      Jekyll.logger.info "Readwise:", "baked #{highlights.size} highlight(s) for #{title.inspect}"
      format_highlights(highlights)
    end

    # --- lookup -------------------------------------------------------------

    def resolve_book_id(title)
      key = normalize(title)
      return @overrides[key] if @overrides.key?(key)

      books_by_title[key]
    end

    def books_by_title
      @books_by_title ||= begin
        map = {}
        each_book do |book|
          next unless book["title"]

          # First title wins on collision; overrides exist for disambiguation.
          map[normalize(book["title"])] ||= book["id"]
        end
        map
      end
    end

    # Walk the (paginated) list of all Readwise sources.
    def each_book
      url = "#{API_BASE}/books/?page_size=1000"
      while url
        data = api_get(url)
        break unless data

        Array(data["results"]).each { |book| yield book }
        url = data["next"]
      end
    end

    def fetch_highlights(book_id)
      highlights = []
      url = "#{API_BASE}/highlights/?book_id=#{book_id}&page_size=1000"
      while url
        data = api_get(url)
        return nil unless data

        highlights.concat(Array(data["results"]))
        url = data["next"]
      end
      # Preserve reading order; highlights without a location sort last.
      highlights.sort_by { |h| h["location"] || Float::INFINITY }
    end

    # --- formatting ---------------------------------------------------------

    def format_highlights(highlights)
      blocks = highlights.map do |h|
        parts = [blockquote(h["text"])]
        note = h["note"].to_s.strip
        parts << "*#{note}*" unless note.empty?
        parts.join("\n\n")
      end
      # Blank lines around the block keep markdown parsing clean.
      "\n#{blocks.join("\n\n")}\n"
    end

    def blockquote(text)
      text.to_s.strip.split("\n").map { |line| "> #{line}".rstrip }.join("\n")
    end

    def placeholder(reason, title)
      "<!-- readwise: #{reason} for \"#{title}\" -->"
    end

    # --- helpers ------------------------------------------------------------

    # Lowercase, strip anything that isn't a letter/number, collapse spaces.
    # "🦖 Jurassic Park" and "Jurassic Park!" both normalize to "jurassic park".
    def normalize(str)
      str.to_s.downcase.gsub(/[^a-z0-9]+/, " ").strip
    end

    def build_overrides(data)
      overrides = {}
      return overrides unless data.is_a?(Hash)

      data.each { |title, id| overrides[normalize(title)] = id }
      overrides
    end

    def api_get(url, attempt: 1)
      uri = URI(url)
      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Token #{@token}"

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true,
                                 open_timeout: 10, read_timeout: 30) do |http|
        http.request(request)
      end

      case response
      when Net::HTTPSuccess
        JSON.parse(response.body)
      when Net::HTTPTooManyRequests
        retry_after = response["Retry-After"].to_i
        if attempt <= 3 && retry_after.between?(1, 60)
          sleep(retry_after)
          api_get(url, attempt: attempt + 1)
        end
      end
    rescue StandardError => e
      Jekyll.logger.warn "Readwise:", "API error (#{url}): #{e.message}"
      nil
    end
  end
end
