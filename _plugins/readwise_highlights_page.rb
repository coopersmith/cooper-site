# frozen_string_literal: true

require "json"
require "fileutils"

# Bakes the /highlights ("Commonplace") page's data at BUILD time.
#
# The page used to fetch a Netlify function on every visit, and that function
# fanned out to one Readwise API call *per book* to attach titles/authors — so
# first paint took ~10s. Instead we reuse the single library pull the
# transclusion baker already makes (Readwise.export, memoized per build),
# flatten every highlight newest-first, join the bits the page renders (quote +
# attribution + an optional source link), and emit static paginated JSON into
# the built site. The page then loads instantly from the CDN with no runtime
# API calls at all.
#
# Output: _site/assets/highlights/page-1.json, page-2.json, … each shaped like
# the old function response ({ highlights, nextPageUrl, hasMore }) so the client
# keeps its simple "load the next page" loop. page-1.json is always written —
# even with no token or an API error — so the page degrades to an empty state
# rather than a failed fetch.
#
# Runs on the :post_write hook because that's the only point at which the
# destination directory exists and is stable (Jekyll's own cleanup/write pass
# has finished and won't clobber what we add).
module ReadwiseHighlightsPage
  PAGE_SIZE = 50
  OUTPUT_SUBDIR = File.join("assets", "highlights")

  def self.emit(site)
    token = ENV["READWISE_TOKEN"]
    unless token
      Jekyll.logger.warn "Readwise:", "READWISE_TOKEN not set — /highlights will be empty"
    end

    highlights = token ? flatten(Readwise.export(site, token)) : []
    write_pages(File.join(site.dest, OUTPUT_SUBDIR), highlights)

    Jekyll.logger.info "Readwise:", "baked #{highlights.size} highlight(s) into /highlights"
  end

  # One flat, newest-first list of render-ready highlights. Each book in the
  # export carries its highlights nested; we keep only what the page shows and
  # sort by the highlight date (ISO-8601 strings sort lexically, undated last).
  def self.flatten(books)
    rows = []

    books.each do |book|
      title = book["title"].to_s.strip
      author = book["author"].to_s.strip
      link = source_link(book)
      attribution =
        if title.empty?
          nil
        elsif author.empty?
          title
        else
          "#{title} by #{author}"
        end

      Array(book["highlights"]).each do |h|
        text = h["text"].to_s.strip
        next if text.empty?

        rows << {
          "text" => text,
          "attribution" => attribution,
          "url" => link,
          "_sort" => h["highlighted_at"].to_s,
        }
      end
    end

    rows.sort_by { |r| r["_sort"] }.reverse.each { |r| r.delete("_sort") }
  end

  # Prefer the original source (articles/newsletters link back to the web).
  # Readwise's own bookreview URLs aren't public-facing, and Kindle books have
  # no source URL, so those highlights simply render unlinked.
  def self.source_link(book)
    url = book["source_url"].to_s
    return url if url.start_with?("http") && !url.include?("readwise.io")

    nil
  end

  def self.write_pages(dir, highlights)
    FileUtils.rm_rf(dir)
    FileUtils.mkdir_p(dir)

    pages = highlights.each_slice(PAGE_SIZE).to_a
    pages = [[]] if pages.empty? # always emit page-1 so the page has something to fetch

    pages.each_with_index do |slice, i|
      n = i + 1
      has_more = n < pages.size
      payload = {
        "highlights" => slice,
        "nextPageUrl" => has_more ? "/assets/highlights/page-#{n + 1}.json" : nil,
        "hasMore" => has_more,
      }
      File.write(File.join(dir, "page-#{n}.json"), JSON.generate(payload))
    end
  end
end

Jekyll::Hooks.register :site, :post_write do |site|
  ReadwiseHighlightsPage.emit(site)
end
