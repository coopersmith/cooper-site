# frozen_string_literal: true

require "json"
require "fileutils"
require "time"

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

  # Tags always shown as filter chips, even when they're used fewer than
  # MIN_TAG_COUNT times (or ranked below the MAX_TAGS cutoff). Use this to
  # surface a tag that matters more than its raw count suggests — e.g. one
  # mostly applied at the document level in Readwise, so few *highlights* carry
  # it directly, or a parent tag whose highlights are spread across its children.
  #
  # Nested tags aggregate at the parent automatically (see `tag_with_ancestors`),
  # so "mywork" is already a real tag covering every "mywork/*" highlight — pinning
  # it just guarantees the chip when that aggregate is still under MIN_TAG_COUNT.
  # Matching ignores case and separators, so "songlyrics", "song-lyrics", and
  # "songLyrics" all pin the same tag.
  #
  # A pin still needs at least one highlight beneath it to have a baked stream;
  # if none do, it's silently skipped. Pinned chips join the featured list in the
  # same count order as everything else, so a low-use pin lands at the bottom.
  PINNED_TAGS = %w[
    songlyrics
    mywork
  ].freeze

  OUTPUT_SUBDIR = File.join("assets", "highlights")

  def self.emit(site)
    token = ENV["READWISE_TOKEN"]
    unless token
      Jekyll.logger.warn "Readwise:", "READWISE_TOKEN not set — /highlights will be empty"
    end

    rows = token ? flatten(Readwise.export(site, token)) : []
    all_tags = ranked_tags(rows)                                        # every linkable tag
    # The most-used tags become chips (capped at MAX_TAGS), then any pinned tag
    # is force-included even if it fell below the cut. Both slices come from the
    # count-sorted all_tags, so appending the pins keeps the whole bar in count
    # order — a low-use pin naturally lands at the end. uniq drops a pin that
    # already ranked into the head on its own.
    featured = all_tags.select { |t| t[:count] >= MIN_TAG_COUNT }.first(MAX_TAGS)
    featured += all_tags.select { |t| pinned?(t[:name]) }
    featured.uniq! { |t| t[:slug] }

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
    rows = dedupe(rows)
    rows.each { |r| r.delete("_sort") }
    rows
  end

  # Collapse highlights that would read as the same passage twice.
  #
  # The Readwise library carries real duplicates. They're invisible in
  # Readwise's own UI but obvious on a single flat page, and they come in two
  # shapes, each needing its own pass:
  #
  #   1. The same document saved twice — two book records, so two copies of
  #      every highlight. Usually an old save plus a later re-save under a
  #      slightly different title, or a Kindle import alongside a Reader copy.
  #      The copies are textually identical but carry different timestamps, so
  #      they sort to unrelated places and the repeat surfaces pages away from
  #      its twin. `exact_dedupe` handles these.
  #
  #   2. One highlight gesture recorded twice — the copies land milliseconds
  #      apart, and the second often captures a slightly *longer* selection
  #      (the shorter text is a substring of the longer). These render as two
  #      near-identical blockquotes back to back. `near_dedupe` handles these.
  #
  # Both passes keep one row and merge the tags of the copies they drop: a tag
  # applied to only one copy would otherwise take the passage out of that tag's
  # stream entirely.
  def self.dedupe(rows)
    kept = near_dedupe(exact_dedupe(rows))

    dropped = rows.size - kept.size
    Jekyll.logger.info "Readwise:", "dropped #{dropped} duplicate highlight(s)" if dropped.positive?

    kept
  end

  # Pass 1: collapse textually identical highlights, wherever they sit. Rows
  # arrive newest-first, so the first copy seen wins.
  def self.exact_dedupe(rows)
    kept = {}

    rows.each do |row|
      key = exact_key(row["text"])
      if (winner = kept[key])
        winner["_tags"] = (winner["_tags"] + row["_tags"]).uniq
      else
        kept[key] = row
      end
    end

    kept.values # Hash preserves insertion order, so this is still newest-first
  end

  # Normalized comparison key: whitespace, case and enclosing punctuation are
  # noise here. The punctuation strip is what makes `"It's not a failure."` and
  # `It's not a failure."` — the same sentence re-highlighted with the opening
  # quote included — collapse into one. Falls back to the unstripped key for
  # text that is *all* punctuation, so those don't all collide on "".
  def self.exact_key(text)
    key = text.gsub(/\s+/, " ").strip.downcase
    stripped = key.gsub(/\A[^a-z0-9]+|[^a-z0-9]+\z/, "")
    stripped.empty? ? key : stripped
  end

  # A highlight shorter than this is too small to safely call a duplicate of a
  # longer one just because it appears inside it.
  MIN_CONTAINMENT_LENGTH = 20

  # How far apart two overlapping highlights can be and still count as one
  # gesture. The observed gap in the library is unambiguous: overlapping pairs
  # land either within ~96 seconds of each other (the double-fire artifact) or
  # 30+ days apart (a genuine re-read, sometimes years later — those are two
  # real highlights and must both survive). 15 minutes sits inside that gap
  # with room on both sides.
  NEAR_DUPLICATE_WINDOW = 900 # seconds

  # Pass 2: within one source, collapse a highlight that is wholly contained in
  # another made moments later — the same gesture, recorded twice with a
  # slightly different selection. The longer text wins (it's the fuller
  # passage) and keeps its own position in the stream.
  #
  # Deliberately narrow: same source, inside NEAR_DUPLICATE_WINDOW, and long
  # enough that containment means something. A short quote legitimately
  # re-highlighted on a later read is a different highlight and stays.
  def self.near_dedupe(rows)
    dropped = {}

    rows.group_by { |r| r["attribution"] }.each_value do |group|
      next if group.size < 2

      # Derive each row's comparison key and timestamp once. This pass is
      # pairwise within a source, so recomputing them per comparison turns a
      # few milliseconds into ten seconds of build time on a full library.
      entries = group.map do |row|
        key = exact_key(row["text"])
        { row: row, key: key, length: key.length, time: parse_time(row["_sort"]), dropped: false }
      end

      entries.each_with_index do |entry, i|
        entries[(i + 1)..].each do |other|
          break if entry[:dropped] # absorbed by an earlier row; nothing left to compare
          next if other[:dropped] || !near_duplicate?(entry, other)

          shorter, longer = [entry, other].sort_by { |e| e[:length] }
          longer[:row]["_tags"] = (longer[:row]["_tags"] + shorter[:row]["_tags"]).uniq
          shorter[:dropped] = true
          dropped[shorter[:row].object_id] = true
        end
      end
    end

    rows.reject { |r| dropped[r.object_id] } # reject over the original keeps newest-first order
  end

  # True when one entry's text sits inside the other's and the two were
  # captured close enough together to be one gesture. Checks run cheapest
  # first; the substring test is the expensive one. Undated rows never match,
  # so they're always left alone.
  def self.near_duplicate?(a, b)
    return false if [a[:length], b[:length]].min < MIN_CONTAINMENT_LENGTH
    return false unless a[:time] && b[:time]
    return false if (a[:time] - b[:time]).abs > NEAR_DUPLICATE_WINDOW

    a[:key].include?(b[:key]) || b[:key].include?(a[:key])
  end

  def self.parse_time(value)
    Time.iso8601(value.to_s)
  rescue ArgumentError
    nil
  end

  # Downcased, de-duplicated tag names for one highlight. Nested tags are
  # expanded to every ancestor level (see `tag_with_ancestors`), so a highlight
  # tagged "mywork/lyft" counts toward both "mywork/lyft" and "mywork" — the
  # parent aggregates its children while each child stays independently linkable.
  def self.tag_names(highlight)
    Array(highlight["tags"])
      .map { |t| t["name"].to_s.strip.downcase }
      .reject(&:empty?)
      .flat_map { |name| tag_with_ancestors(name) }
      .uniq
  end

  # A nested tag plus every ancestor level: "a/b/c" -> ["a/b/c", "a/b", "a"].
  # This is what exposes any tag hierarchy at the parent level — the parent tag
  # accumulates all highlights filed beneath it. Flat tags return just
  # themselves. Blank path segments (e.g. a stray "a//b") are dropped.
  def self.tag_with_ancestors(name)
    segments = name.split("/").map(&:strip).reject(&:empty?)
    return [name] if segments.size <= 1

    (1..segments.size).map { |i| segments.first(i).join("/") }
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

  # True when a tag is pinned as an always-on chip, compared with case and
  # separators stripped so "songLyrics"/"song-lyrics"/"songlyrics" all match.
  # Ancestor expansion means a nested pin like "mywork" already exists as a real
  # aggregated tag by the time this runs, so an exact (normalized) match is enough.
  def self.pinned?(name)
    key = normalize(name)
    PINNED_TAGS.any? { |pin| normalize(pin) == key }
  end

  def self.normalize(str)
    str.to_s.downcase.gsub(/[^a-z0-9]+/, "")
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
