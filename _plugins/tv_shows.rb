# frozen_string_literal: true

require "set"

# Season-level TV model.
#
# The Obsidian vault models TV in three layers:
#
#   * Series     — context only: creator / cast / genre / poster / run-years.
#                  Never a diet entry, because it has no data to be one with —
#                  no rating, no watch date, no shelf.
#   * Season     — the unit of record, and a real diet entry. Carries rating,
#                  shelf, watch date (`last`), release `year`, and a `show`
#                  link back to its series.
#   * Standalone — a season with no parent (a miniseries, or a show tracked as
#                  a single unit). Same shape as a season, minus the `show`.
#
# You didn't watch "Hacks", you watched "Hacks — Season 3" and gave it a 6, so
# the season/standalone is what shows up in the library; the series is only
# ever a container.
#
# This generator runs before BidirectionalLinksGenerator so it can classify
# every note under _notes/MediaDiet/Shows and, for each series, compute the
# two things the vault deliberately never stores: the average of its seasons'
# ratings and the ordered list of seasons its page tables. It also:
#
#   * gives a season a display title ("Hacks — Season 3") in place of its raw
#     filename title ("Hacks s03"),
#   * falls a season's missing poster back to its series' poster,
#   * lends the series' creator/cast to its seasons for the library's "By"
#     column (seasons carry none of their own), and
#   * strips the Obsidian `![[…Shows.base#…]]` embeds — database views that
#     mean nothing on the built site — along with the heading that introduces
#     them, so no `!references/…` noise reaches the page.
#
# Data left on each doc for the templates to read:
#
#   tv_kind        'series' | 'season' | 'standalone'
#   hide_from_diet true for series (context) and `dnf` (abandoned) — both are
#                  kept out of the media library's entry list.
#   display_title  what to render in place of the raw title.
#   series_url     season → its series page (nil if the series note is absent)
#   series_title   season → its series' name
#   seasons        series → its watched seasons, ordered by season number
#   avg_rating     series → mean of its seasons' ratings, rounded to an integer
#   avg_rating_exact  series → the same mean to one decimal (for the tooltip)
class TvShowsGenerator < Jekyll::Generator
  # Ahead of BidirectionalLinksGenerator (:normal), which would otherwise
  # rewrite the `![[…]]` embeds into stray `!text` before we can remove them.
  priority :high

  SHOWS_PATH = "MediaDiet/Shows"

  # A `## Seasons` / `## Episodes` heading (optional) immediately followed by a
  # `![[ … .base# … ]]` embed. Both are Obsidian-only; drop the pair together so
  # no empty heading is left behind. Also matches a bare embed with no heading.
  BASE_EMBED = %r{
    (?:^[ \t]*\#{1,6}[ \t]*[^\n]*\r?\n\s*\r?\n)?  # optional introducing heading
    [ \t]*!\[\[[^\]]*\.base[^\]]*\]\][ \t]*\r?\n?
  }x

  def generate(site)
    shows = site.collections["notes"].docs.select { |d| d.path.include?(SHOWS_PATH) }
    return if shows.empty?

    # Classify first (it reads the `.base` embed), then strip the embeds — the
    # database views mean nothing off Obsidian.
    shows.each { |doc| doc.data["tv_kind"] = classify(doc) }
    shows.each { |doc| strip_base_embeds(doc) }

    # A note that some season points to with `show:` is a series, full stop —
    # even if its own frontmatter is a mid-migration leftover still carrying an
    # old rating. This promotion runs before we build the series index.
    parent_keys = shows
      .select { |d| d.data["tv_kind"] == "season" }
      .flat_map { |d| parent_key(d) }
      .compact
      .to_set
    shows.each do |doc|
      doc.data["tv_kind"] = "series" if keys_for(doc).any? { |k| parent_keys.include?(k) }
    end

    series_by_key = {}
    shows.each do |doc|
      next unless doc.data["tv_kind"] == "series"
      keys_for(doc).each { |k| series_by_key[k] = doc }
    end

    seasons = shows.select { |d| d.data["tv_kind"] == "season" }
    kids_of = Hash.new { |h, k| h[k] = [] }
    seasons.each do |s|
      key = parent_key(s)
      kids_of[key] << s if key
    end

    # Build each series: its ordered seasons and their averaged rating, and the
    # links/fallbacks that flow from series down to season.
    shows.each do |series|
      next unless series.data["tv_kind"] == "series"
      series.data["hide_from_diet"] = true
      series.data["display_title"] = clean_title(series)

      kids = keys_for(series).flat_map { |k| kids_of[k] }.uniq
      kids = kids.sort_by { |s| s.data["season"].to_i }
      series.data["seasons"] = kids

      ratings = kids.map { |s| s.data["rating"] }.compact.map(&:to_f)
      if ratings.any?
        avg = ratings.sum / ratings.size
        series.data["avg_rating"] = avg.round
        series.data["avg_rating_exact"] = (avg * 10).round / 10.0
      end

      kids.each do |s|
        s.data["series_url"] = series.url
        s.data["series_title"] ||= clean_title(series)
        if blank?(s.data["cover"]) && !blank?(series.data["cover"])
          s.data["cover"] = series.data["cover"]
        end
        if Array(s.data["creator"]).empty? && !Array(series.data["creator"]).empty?
          s.data["creator"] = series.data["creator"]
        end
        if Array(s.data["cast"]).empty? && !Array(series.data["cast"]).empty?
          s.data["cast"] = series.data["cast"]
        end
      end
    end

    # Every season gets a display title, whether or not its series note exists
    # (an orphan season still knows its series' name and its number).
    seasons.each do |s|
      s.data["series_title"] ||= parent_title(s)
      s.data["display_title"] = season_title(s)
    end

    # Standalones read straight through; give them a display title too so the
    # templates can use one field for every kind.
    shows.each do |d|
      d.data["display_title"] ||= clean_title(d)
      shelf = Array(d.data["shelf"]).join(" ").downcase
      d.data["hide_from_diet"] = true if shelf.include?("dnf")
    end
  end

  private

  def classify(doc)
    return "season" if has_parent?(doc)
    tags = Array(doc.data["tags"]).map(&:to_s)
    return "series" if tags.include?("series")
    return "series" if blank?(doc.data["shelf"]) && doc.content =~ /!\[\[[^\]]*\.base#Seasons/i
    "standalone"
  end

  def strip_base_embeds(doc)
    return unless doc.content.include?(".base")
    doc.content = doc.content.gsub(BASE_EMBED, "")
  end

  def has_parent?(doc)
    !blank?(Array(doc.data["show"]).first)
  end

  # The parent series' name from a season's `show: [[Title]]` link.
  def parent_title(doc)
    raw = Array(doc.data["show"]).first
    return nil if blank?(raw)
    raw.to_s.gsub(/\[\[|\]\]/, "").split("|").first.strip
  end

  def parent_key(doc)
    t = parent_title(doc)
    blank?(t) ? nil : t.downcase
  end

  # Keys a series can be addressed by: its (Jekyll-derived) title and its
  # filename, both downcased, so a `show:` link resolves against either.
  def keys_for(doc)
    base = File.basename(doc.basename, File.extname(doc.basename))
    [doc.data["title"].to_s, base].reject(&:empty?).map(&:downcase).uniq
  end

  def season_title(doc)
    series = doc.data["series_title"] || parent_title(doc)
    num = doc.data["season"]
    return clean_title(doc) if blank?(series)
    return series.to_s if blank?(num)
    "#{series} — Season #{num}"
  end

  def clean_title(doc)
    doc.data["title"].to_s.gsub(/[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}]/, "").strip
  end

  def blank?(v)
    v.nil? || (v.respond_to?(:empty?) && v.to_s.strip.empty?)
  end
end
