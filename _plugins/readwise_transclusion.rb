# frozen_string_literal: true

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
# On publish, this generator finds every `![[<Title> - Notes]]` embed, matches
# `<Title>` to a book in your Readwise library, and replaces the embed with
# that book's highlights as markdown — so the published page is self-contained.
#
# The whole library (books + highlights) is pulled once per build via the
# Readwise export endpoint, so a large media diet costs a handful of API calls
# rather than one per book.
#
# Requirements:
#   * ENV["READWISE_TOKEN"] available at build time (already set on Netlify for
#     the readwise-highlights function; make sure it's exposed to builds too).
#
# Matching (in order):
#   1. an explicit override in _data/readwise_books.yml ("Title": book_id)
#   2. exact title match, ignoring case / emoji / punctuation
#   3. the main title before a ": "/" - " subtitle (so
#      "Filterworld: How Algorithms Flattened Culture" resolves to Readwise's
#      "Filterworld"). Skipped when a main title is shared by >1 book — add an
#      override to disambiguate.
#
# Failure is always graceful: a missing token, no match, or an API error leaves
# an HTML comment in place of the highlights and logs a warning — the build
# never breaks.
#
# Runs at :high priority so it executes before BidirectionalLinksGenerator,
# letting any wikilinks inside the fetched highlights resolve normally.
module ReadwiseTransclusion
  # An optional introducing heading (e.g. "## Notes") followed by the embed.
  #
  #   group 1 (lead)    : start-of-string or the newline before the block
  #   group 2 (heading) : optional "## Heading\n\n" that exists only to intro
  #                       the embed — captured so it can be dropped alongside
  #                       the embed when there's nothing to bake (no empty
  #                       section left behind). Only matches when the embed
  #                       immediately follows the heading's blank line.
  #   group 3 (title)   : the embedded note title
  #
  # Whole-note embeds only. The `- Notes]]` anchor keeps section/block embeds
  # (`![[Book - Notes#Section]]`, `![[Book - Notes^ref]]`) out. The title may
  # contain `#` — real ones do, e.g. `![[Jurassic Park (Jurassic Park, #1) - Notes]]`.
  EMBED_BLOCK = /(\A|\n)?([ \t]*[#]{1,6}[ \t]*[^\n]*\n\s*\n)?[ \t]*!\[\[([^\]]+?)\s*-\s*Notes\]\][ \t]*/

  # Subtitle separators: ": ", " - ", " — ", " – " (spaced hyphen/dash only, so
  # hyphenated words like "Chain-Gang All-Stars" are left intact).
  SUBTITLE_SPLIT = /:\s|\s[-—–]\s/

  AMBIGUOUS = :ambiguous

  class Generator < Jekyll::Generator
    priority :high
    safe false # needs network access at build time

    def generate(site)
      @site = site
      @token = ENV["READWISE_TOKEN"]
      @overrides = build_overrides(site.data["readwise_books"])
      @library = nil # lazily indexed on first lookup
      @warned_no_token = false

      collection = site.collections["notes"]
      return unless collection

      collection.docs.each { |doc| bake(doc) }
    end

    private

    def bake(doc)
      return unless doc.content.include?("- Notes]]")

      doc.content = doc.content.gsub(EMBED_BLOCK) do
        lead = Regexp.last_match(1).to_s
        heading = Regexp.last_match(2).to_s
        title = Regexp.last_match(3).strip

        highlights = render(title, doc)
        if highlights
          "#{lead}#{heading}#{highlights}"
        else
          # Nothing to bake — drop the introducing heading too, so a book with
          # no Readwise highlights doesn't leave an empty "## Notes" section.
          lead
        end
      end
    end

    # Returns the highlights as markdown, or nil when there's nothing to show
    # (no token, no matching book, or no highlights). Diagnostics go to the
    # build log rather than an on-page comment.
    def render(title, doc)
      unless @token
        unless @warned_no_token
          Jekyll.logger.warn "Readwise:", "READWISE_TOKEN not set — leaving embeds unresolved"
          @warned_no_token = true
        end
        return nil
      end

      book = resolve_book(title, doc)
      unless book
        Jekyll.logger.warn "Readwise:", "no book match for #{title.inspect} (#{doc.relative_path})"
        return nil
      end

      highlights = Array(book["highlights"]).sort_by { |h| h["location"] || Float::INFINITY }
      if highlights.empty?
        Jekyll.logger.info "Readwise:", "no highlights for #{title.inspect}"
        return nil
      end

      Jekyll.logger.info "Readwise:", "baked #{highlights.size} highlight(s) for #{title.inspect}"
      format_highlights(highlights)
    end

    # --- matching -----------------------------------------------------------

    def resolve_book(title, doc)
      if (id = @overrides[normalize(title)])
        book = library[:by_id][id]
        return book if book

        Jekyll.logger.warn "Readwise:", "override book_id #{id} for #{title.inspect} not found in library"
      end

      return library[:by_full][normalize(title)] if library[:by_full].key?(normalize(title))

      main = normalize(main_title(title))
      match = library[:by_main][main]
      return match if match && match != AMBIGUOUS

      if match == AMBIGUOUS
        Jekyll.logger.warn "Readwise:", "#{title.inspect} (#{doc.relative_path}) matches multiple books on " \
                                        "#{main.inspect} — add an override in _data/readwise_books.yml"
      end
      nil
    end

    # Build the title -> book lookup indexes from the shared library pull
    # (Readwise.export memoizes the fetch, so this is free after the first
    # feature touches it).
    def library
      @library ||= begin
        by_full = {}
        by_main = {}
        by_id = {}

        Readwise.export(@site, @token).each do |book|
          id = book["user_book_id"]
          title = book["title"]
          next unless id && title && !title.to_s.strip.empty?

          by_id[id] = book
          by_full[normalize(title)] ||= book

          main = normalize(main_title(title))
          by_main[main] = by_main.key?(main) ? AMBIGUOUS : book
        end

        { by_full: by_full, by_main: by_main, by_id: by_id }
      end
    end

    # --- formatting ---------------------------------------------------------

    def format_highlights(highlights)
      blocks = highlights.map do |h|
        parts = [blockquote(h["text"])]
        note = h["note"].to_s.strip
        parts << "*#{note}*" unless note.empty?
        parts.join("\n\n")
      end
      "\n#{blocks.join("\n\n")}\n"
    end

    def blockquote(text)
      text.to_s.strip.split("\n").map { |line| "> #{line}".rstrip }.join("\n")
    end

    # --- helpers ------------------------------------------------------------

    # Lowercase, drop anything that isn't a letter/number, collapse spaces.
    # "🦖 Jurassic Park" and "Jurassic Park!" both normalize to "jurassic park".
    def normalize(str)
      str.to_s.downcase.gsub(/[^a-z0-9]+/, " ").strip
    end

    # The core title: drop a trailing "(Series, #1)" parenthetical (Goodreads-
    # style, absent from Readwise), then the part before a ": "/" - " subtitle.
    # "Jurassic Park (Jurassic Park, #1)" -> "Jurassic Park"
    # "Filterworld: How Algorithms Flattened Culture" -> "Filterworld"
    def main_title(title)
      core = title.to_s.sub(/\s*\([^)]*\)\s*\z/, "")
      core.split(SUBTITLE_SPLIT, 2).first.to_s.strip
    end

    def build_overrides(data)
      overrides = {}
      return overrides unless data.is_a?(Hash)

      data.each { |title, id| overrides[normalize(title)] = id }
      overrides
    end
  end
end
