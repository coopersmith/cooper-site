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
# attribution + an optional source link), and emit static paginated JSON. The
# page then loads instantly from the CDN with no runtime API calls, and pages
# in more as you scroll.
#
# Tag filtering is baked the same way: we count how often each highlight tag is
# used, feature the most-used ones, and write a separate paginated view per
# featured tag. A small index.json manifest lists those tags (with counts) so
# the filter bar can render itself. Filtering therefore costs no more per-request
# work than the default view — it's just a different set of static files.
#
# Output (all under _site/assets/highlights/):
#   index.json                     -> { total, allUrl, tags: [{name, slug, count, url}] }
#   all/page-N.json                -> the default newest-first stream
#   tag/<slug>/page-N.json         -> one stream per featured tag
# Each page-N.json is shaped { highlights, nextPageUrl, hasMore } so the client
# keeps one simple "load the next page" loop. all/page-1.json is always written,
# so a missing token or API error degrades to an empty state, not a failed fetch.
#
# Runs on the :post_write hook because that's the only point at which the
# destination directory exists and is stable (Jekyll's own cleanup/write pass
# has finished and won't clobber what we add).
module ReadwiseHighlightsPage
  PAGE_SIZE = 50

  # Feature at most this many tags as filter chips, and only tags used at least
  # this often — enough to be a real theme, not a one-off.
  MAX_TAGS = 16
  MIN_TAG_COUNT = 5

  # Every tag used at least this often gets its own baked stream, so any tag URL
  # (e.g. /highlights#watches) resolves — not just the featured chips. Set to 1
  # to make literally every tag deep-linkable.
  MIN_LINK_COUNT = 1

  # Tags never offered as filters: Reader/workflow tags that describe triage
  # state rather than subject matter, plus a few topical tags deliberately kept
  # off the page. Compared with separators/case stripped (see `stopword?`), so
  # "datingapps", "dating-apps", and "datingApps" all match one entry.
  TAG_STOPLIST = %w[
    discard shortlist later archive new feed inbox untagged
    hinge datingapps
  ].freeze

  OUTPUT_SUBDIR = File.join("assets", "highlights")

  def self.emit(site)
    token = ENV["READWISE_TOKEN"]
    unless token
      Jekyll.logger.warn "Readwise:", "READWISE_TOKEN not set — /highlights will be empty"
    end

    rows = token ? flatten(Readwise.export(site, token)) : []
    all_tags = ranked_tags(rows)                                        # every linkable tag
    featured = all_tags.select { |t| t[:count] >= MIN_TAG_COUNT }.first(MAX_TAGS)

    root = File.join(site.dest, OUTPUT_SUBDIR)
    FileUtils.rm_rf(root)
    FileUtils.mkdir_p(root)

    # Default stream + one stream per linkable tag, so any tag URL resolves —
    # even the tags that aren't featured as chips.
    write_view(File.join(root, "all"), "/assets/highlights/all", rows)
    all_tags.each do |tag|
      tagged = rows.select { |r| r["_tags"].include?(tag[:name]) }
      write_view(File.join(root, "tag", tag[:slug]), "/assets/highlights/tag/#{tag[:slug]}", tagged)
    end

    write_index(root, rows, featured, all_tags)

    Jekyll.logger.info "Readwise:",
                       "baked #{rows.size} highlight(s), #{all_tags.size} linkable tag(s) " \
                       "(#{featured.size} featured) into /highlights"
  end

  # One flat, newest-first list of render-ready highlights. Each book in the
  # export carries its highlights nested; we keep what the page shows plus the
  # highlight's tag names (kept under an internal "_tags" key for grouping) and
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
          "_tags" => tag_names(h),
          "_sort" => h["highlighted_at"].to_s,
        }
      end
    end

    rows = rows.sort_by { |r| r["_sort"] }.reverse
    rows.each { |r| r.delete("_sort") }
    rows
  end

  # Downcased, de-duplicated tag names for one highlight.
  def self.tag_names(highlight)
    Array(highlight["tags"])
      .map { |t| t["name"].to_s.strip.downcase }
      .reject(&:empty?)
      .uniq
  end

  # Every linkable tag, ranked by count (ties broken alphabetically), each with
  # a globally-unique URL-safe slug. Suppressed (stoplist) tags and tags below
  # MIN_LINK_COUNT are dropped. The featured chips are just the high-count head
  # of this list, so their slugs are assigned consistently here.
  def self.ranked_tags(rows)
    counts = Hash.new(0)
    rows.each { |r| r["_tags"].each { |name| counts[name] += 1 } }

    ranked = counts
             .reject { |name, count| stopword?(name) || count < MIN_LINK_COUNT }
             .sort_by { |name, count| [-count, name] }

    used = {}
    ranked.map do |name, count|
      { name: name, slug: unique_slug(slugify(name), used), count: count }
    end
  end

  # True when a tag is on the stoplist, comparing with case and separators
  # stripped so "datingApps"/"dating-apps"/"datingapps" all match.
  def self.stopword?(name)
    key = name.gsub(/[^a-z0-9]+/, "")
    TAG_STOPLIST.include?(key)
  end

  def self.slugify(name)
    slug = name.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
    slug.empty? ? "tag" : slug
  end

  # Guard against two different tag names slugging to the same path.
  def self.unique_slug(slug, used)
    candidate = slug
    n = 2
    while used.key?(candidate)
      candidate = "#{slug}-#{n}"
      n += 1
    end
    used[candidate] = true
    candidate
  end

  # Prefer the original source (articles/newsletters link back to the web).
  # Readwise's own bookreview URLs aren't public-facing, and Kindle books have
  # no source URL, so those highlights simply render unlinked.
  def self.source_link(book)
    url = book["source_url"].to_s
    return url if url.start_with?("http") && !url.include?("readwise.io")

    nil
  end

  # Write one paginated view (a directory of page-N.json files) for `rows`.
  # `url_prefix` is the site-absolute path the files will be served from, used
  # to build each page's nextPageUrl.
  def self.write_view(dir, url_prefix, rows)
    FileUtils.mkdir_p(dir)

    pages = rows.each_slice(PAGE_SIZE).to_a
    pages = [[]] if pages.empty? # always emit page-1 so there's something to fetch

    pages.each_with_index do |slice, i|
      n = i + 1
      has_more = n < pages.size
      payload = {
        "highlights" => slice.map { |r| render_row(r) },
        "nextPageUrl" => has_more ? "#{url_prefix}/page-#{n + 1}.json" : nil,
        "hasMore" => has_more,
      }
      File.write(File.join(dir, "page-#{n}.json"), JSON.generate(payload))
    end
  end

  # Strip internal ("_"-prefixed) bookkeeping keys before serializing.
  def self.render_row(row)
    { "text" => row["text"], "attribution" => row["attribution"], "url" => row["url"] }
  end

  def self.write_index(root, rows, featured, all_tags)
    index = {
      "total" => rows.size,
      "allUrl" => "/assets/highlights/all/page-1.json",
      # Featured tags become the filter chips.
      "tags" => featured.map do |tag|
        {
          "name" => tag[:name],
          "slug" => tag[:slug],
          "count" => tag[:count],
          "url" => "/assets/highlights/tag/#{tag[:slug]}/page-1.json",
        }
      end,
      # slug => name for every linkable tag, so the page can validate an
      # arbitrary tag URL and label it even when it isn't a featured chip.
      "allTags" => all_tags.each_with_object({}) { |tag, h| h[tag[:slug]] = tag[:name] },
    }
    File.write(File.join(root, "index.json"), JSON.generate(index))
  end
end

Jekyll::Hooks.register :site, :post_write do |site|
  ReadwiseHighlightsPage.emit(site)
end
