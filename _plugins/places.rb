# frozen_string_literal: true

require "set"

# Places model.
#
# The Obsidian vault keeps every place — venues and the destinations that
# contain them — as one note apiece under _notes/Places:
#
#   * Destination — a note whose `type` is Cities (a city or a neighborhood:
#     Vienna, Cobble Hill). Context and prose only; never a pin of its own.
#   * Venue — everything else (Restaurants, Bars + Cocktails, …): the unit of
#     recommendation. Carries `type`, a `loc` chain of destination wikilinks,
#     `location` ([lat, lng] as strings), `rating`, visit stats, and a Google
#     Maps `source` URL.
#
# This generator runs before BidirectionalLinksGenerator and, for each Places
# note, distils the vault's frontmatter into flat fields the /places/ page and
# the place layout can read without re-parsing wikilinks. It also strips the
# Obsidian `![[….base#…]]` embeds — database views that mean nothing on the
# built site — along with the heading that introduces them (same treatment as
# tv_shows.rb gives Shows).
#
# Data left on each doc for the templates to read:
#
#   place_kind   'venue' | 'destination'
#   place_type   the venue's category, wikilink noise removed
#                ("Bars + Cocktails", "Restaurants")
#   place_city   the destination you'd say you're going to — the *last* entry
#                of the `loc` chain ("New York City", "Vienna") after
#                skipping region-level entries (REGIONS below): some chains
#                run past the city to a state or country ([Providence,
#                Rhode Island]), and "pick where you're going" means
#                Providence, not Rhode Island. The vault orders `loc`
#                inside-out (neighborhood first), so the last non-region
#                entry is the city.
#   place_area   the neighborhood — the *first* `loc` entry, when it differs
#                from the city ("Cobble Hill"). Nil for venues located
#                directly in their city.
#   place_lat / place_lng
#                coordinates as floats, nil when the note has no (parsable)
#                `location` — such venues list but don't pin, by design.
#   place_gmaps  the Google Maps URL from `source`, when present.
#
# Destinations get place_kind + place_city (their own title), nothing else.
class PlacesGenerator < Jekyll::Generator
  # Ahead of BidirectionalLinksGenerator (:normal), which would otherwise
  # rewrite the `![[…]]` embeds into stray `!text` before we can remove them.
  priority :high

  PLACES_PATH = "_notes/Places"

  # A heading (optional) immediately followed by a `![[ … .base# … ]]` embed
  # (`## Check-ins` + `![[Checkins.base#Venue]]`, `## Map` + `![[Places.base…]]`).
  # Both are Obsidian-only; drop the pair together so no empty heading is left
  # behind. Also matches a bare embed with no heading.
  BASE_EMBED = %r{
    (?:^[ \t]*\#{1,6}[ \t]*[^\n]*\r?\n\s*\r?\n)?  # optional introducing heading
    [ \t]*!\[\[[^\]]*\.base[^\]]*\]\][ \t]*\r?\n?
  }x

  # Region-level `loc` entries — never "the place you're going to". US states
  # plus the countries the vault's destination notes roll up to. A chain that
  # is *only* regions (a venue filed straight under a state) falls back to its
  # last entry rather than nothing.
  REGIONS = [
    "Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado",
    "Connecticut", "Delaware", "Florida", "Georgia", "Hawaii", "Idaho",
    "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky", "Louisiana", "Maine",
    "Maryland", "Massachusetts", "Michigan", "Minnesota", "Mississippi",
    "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire",
    "New Jersey", "New Mexico", "New York", "North Carolina", "North Dakota",
    "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island",
    "South Carolina", "South Dakota", "Tennessee", "Texas", "Utah", "Vermont",
    "Virginia", "Washington", "West Virginia", "Wisconsin", "Wyoming",
    "United States", "USA",
    "Argentina", "Australia", "Austria", "Belgium", "Brazil", "Canada",
    "Chile", "China", "Colombia", "Costa Rica", "Croatia", "Cuba",
    "Czech Republic", "Denmark", "England", "France", "Germany", "Greece",
    "Hungary", "Iceland", "India", "Indonesia", "Ireland", "Israel", "Italy",
    "Jamaica", "Japan", "Kenya", "Mexico", "Morocco", "Netherlands",
    "New Zealand", "Norway", "Peru", "Poland", "Portugal", "Scotland",
    "Singapore", "South Africa", "South Korea", "Spain", "Sweden",
    "Switzerland", "Thailand", "Turkey", "United Kingdom", "UK", "Vietnam",
  ].map(&:downcase).to_set.freeze

  def generate(site)
    places = site.collections["notes"].docs.select { |d| d.relative_path.include?(PLACES_PATH) }
    return if places.empty?

    places.each do |doc|
      strip_base_embeds(doc)

      if destination?(doc)
        doc.data["place_kind"] = "destination"
        doc.data["place_city"] = doc.data["title"].to_s
        next
      end

      doc.data["place_kind"] = "venue"
      doc.data["place_type"] = normalize_link(Array(doc.data["type"]).first)

      locs = Array(doc.data["loc"]).map { |l| normalize_link(l) }.reject { |l| blank?(l) }
      cities = locs.reject { |l| REGIONS.include?(l.downcase) }
      city = cities.last || locs.last
      doc.data["place_city"] = city
      doc.data["place_area"] = locs.first if locs.size > 1 && locs.first != city && !REGIONS.include?(locs.first.downcase)

      lat, lng = coords(doc)
      doc.data["place_lat"] = lat
      doc.data["place_lng"] = lng

      source = doc.data["source"].to_s
      doc.data["place_gmaps"] = source if source.start_with?("http")
    end
  end

  private

  def destination?(doc)
    Array(doc.data["type"]).any? { |t| normalize_link(t).casecmp?("Cities") }
  end

  # `location` is a YAML list of strings — ["40.68…", "-73.99…"]. Anything
  # that doesn't parse as a plausible lat/lng pair yields nils, so a venue
  # missing coordinates degrades to list-only instead of a pin at (0, 0).
  def coords(doc)
    raw = Array(doc.data["location"])
    return [nil, nil] unless raw.size == 2
    lat, lng = raw.map { |v| Float(v.to_s.strip, exception: false) }
    return [nil, nil] if lat.nil? || lng.nil?
    return [nil, nil] unless lat.between?(-90, 90) && lng.between?(-180, 180)
    [lat, lng]
  end

  # Obsidian links can carry a folder path and/or a display alias —
  # `[[coops-site-publish/Places/Cobble Hill]]` or `[[Vienna|Wien]]` — so
  # prefer the alias, else the target's basename, so a vault-relative path
  # never leaks into the rendered page.
  def normalize_link(raw)
    return nil if blank?(raw)
    inner = raw.to_s.gsub(/\[\[|\]\]/, "").strip
    target, display = inner.split("|", 2)
    (blank?(display) ? target.to_s.split("/").last : display).to_s.strip
  end

  def strip_base_embeds(doc)
    return unless doc.content.include?(".base")
    doc.content = doc.content.gsub(BASE_EMBED, "")
  end

  def blank?(v)
    v.nil? || (v.respond_to?(:empty?) && v.to_s.strip.empty?)
  end
end
