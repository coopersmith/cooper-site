# frozen_string_literal: true

require "set"
require_relative "places_geocode"

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
# Data left on each venue for the templates to read:
#
#   place_kind    'venue' | 'destination'
#   place_type    the venue's category, wikilink noise removed
#                 ("Bars + Cocktails", "Restaurants")
#   place_country the country tier ("United States", "Austria")
#   place_city    the destination you'd say you're going to ("New York City",
#                 "Vienna", "Providence")
#   place_area    the neighborhood within it ("Cobble Hill"), when there is one
#   place_path    those three as tree slugs, coarsest first — ["united-states",
#                 "new-york-city", "cobble-hill"]. The /places/ filter matches
#                 a selected node against this, so selecting a country and
#                 selecting a neighborhood are the same operation — and so is
#                 selecting several at once, since matching any one is enough.
#   place_city_slug / place_area_slug
#                 the city and neighborhood tiers of that path, for templates
#                 that link to one tier ("Where" jumps, a destination note's
#                 "filter all my places here"). Read out of the tree rather
#                 than re-slugified, so a disambiguated slug still matches.
#   place_lat / place_lng
#                 coordinates as floats, nil when the note has no (parsable)
#                 `location` — such venues list but don't pin, by design.
#   place_gmaps   the Google Maps URL from `source`, when present.
#
# == Resolving the hierarchy
#
# The `loc` chain can't be trusted for order or completeness. Real chains
# arrive as [Cobble Hill, NYC], [NYC, Brooklyn Heights] (outside-in), [Brooklyn,
# Cobble Hill] (no city at all), [Providence, Rhode Island] (running past the
# city to a state), [Kyoto] (city only, no country), and occasionally empty. So
# ancestry is resolved by *identity* rather than position — after dropping
# region-level entries (US states and countries, which are never "the place
# you're going to"):
#
#   1. Neighborhood — an entry that is a known neighborhood, either because its
#      own destination note names a city parent (Cobble Hill → New York City)
#      or because _data/places_geo.yml says so. Its parent is the city, found
#      even when the chain never mentions the city itself.
#   2. City — an entry that is a known city (named in places_geo.yml, or a
#      destination note whose parents are all regions, like Vienna → Austria).
#   3. Fallback — the inside-out convention: city = last entry, area = first.
#
# Because step 2 matches on identity, [NYC, Brooklyn Heights] and
# [Brooklyn Heights, NYC] now resolve identically; under the old positional
# rule they produced two different cities for the same corner of Brooklyn.
#
# The country comes from the city's destination note (Vienna's `loc` names
# Austria) when there is one, else places_geo.yml, else — for a venue filed
# straight under a country, like Cuixmala → [[Mexico]] — the city *is* the
# country and there's no city tier. A city with no country anywhere groups
# under "Elsewhere" and logs a warning naming it.
#
# So the destination notes remain the ontology, and publishing one still
# upgrades every venue that references it; places_geo.yml only fills in the
# destinations that don't have a note yet.
#
# Destinations get place_kind + place_city (their own title) plus place_venues:
# the venue docs whose city or area is this destination, for the place layout's
# mini-map and index table. Matching is done here, case-insensitively, because
# it can't safely happen in Liquid: title_case.rb sentence-cases note titles
# ("Cobble hill") while a venue's city/area keeps the canonical casing ("Cobble
# Hill"), so a template string compare silently misses multi-word destinations.
# For the same reason note titles are never used as the canonical spelling of a
# destination — places_geo.yml is the spelling authority.
#
# == The tree
#
# site.data["places_tree"] is the nested country → city → neighborhood
# structure the /places/ filter renders, each node:
#
#   { "name", "slug", "tier" (1|2|3), "parent" (slug or nil), "count", "children" }
#
# `count` is the number of venues at or below the node. Slugs are unique across
# the whole tree (a collision is disambiguated with the parent slug and logged),
# because the filter addresses nodes by slug alone — in the DOM, in ?dest=, and
# in place_path.
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

  # Sub-national regions — never "the place you're going to", and never a tier
  # of the filter. Dropped from `loc` chains wherever they appear.
  SUBREGIONS = [
    "Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado",
    "Connecticut", "Delaware", "Florida", "Georgia", "Hawaii", "Idaho",
    "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky", "Louisiana", "Maine",
    "Maryland", "Massachusetts", "Michigan", "Minnesota", "Mississippi",
    "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire",
    "New Jersey", "New Mexico", "New York", "North Carolina", "North Dakota",
    "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island",
    "South Carolina", "South Dakota", "Tennessee", "Texas", "Utah", "Vermont",
    "Virginia", "Washington", "West Virginia", "Wisconsin", "Wyoming",
  ].freeze

  # Countries. Dropped from `loc` chains like the subregions above, but unlike
  # them they *are* a tier — an entry matching one of these is the venue's
  # country. _data/places_geo.yml extends this list (its `continents` keys and
  # `countries` values), so a new country is a data change, not a code change.
  COUNTRIES = [
    "Argentina", "Australia", "Austria", "Belgium", "Brazil", "Canada",
    "Chile", "China", "Colombia", "Costa Rica", "Croatia", "Cuba",
    "Czech Republic", "Denmark", "England", "France", "Germany", "Greece",
    "Hungary", "Iceland", "India", "Indonesia", "Ireland", "Israel", "Italy",
    "Jamaica", "Japan", "Kenya", "Mexico", "Morocco", "Netherlands",
    "New Zealand", "Norway", "Peru", "Poland", "Portugal", "Scotland",
    "Singapore", "South Africa", "South Korea", "Spain", "Sweden",
    "Switzerland", "Thailand", "Turkey", "United Kingdom", "UK", "USA",
    "United States", "Vietnam",
  ].freeze

  ELSEWHERE = "Elsewhere"

  def generate(site)
    places = site.collections["notes"].docs.select { |d| d.relative_path.include?(PLACES_PATH) }
    return if places.empty?

    load_geo(site)

    places.each { |doc| strip_base_embeds(doc) }
    destinations, venues = places.partition { |doc| destination?(doc) }

    # The destination notes double as the place ontology: a note whose own
    # `loc` names a city-level (non-region) parent is a neighborhood of that
    # city; one whose parents are all regions is a city, and the region that
    # is a country is its country.
    destinations.each do |dest|
      title = dest.data["title"].to_s
      key = canonical(title).downcase
      dest.data["place_kind"] = "destination"
      dest.data["place_city"] = title

      parent = non_region_locs(dest).first
      @hood_city[key] ||= canonical(parent) if parent
      country = Array(dest.data["loc"]).map { |l| canonical(normalize_link(l)) }
                                       .find { |l| !blank?(l) && country?(l) }
      @city_country[key] ||= canonical(country) if country
    end

    learn_countries(venues)
    venues.each { |doc| resolve_venue(doc) }

    # Names first, then the tree (which is where slugs are minted and any
    # collision is resolved), then the per-venue paths — read back out of the
    # tree so a row's slugs are always the ones its chips carry.
    site.data["places_tree"] = build_tree(venues)
    venues.each { |doc| assign_path(doc) }

    destinations.each do |dest|
      key = dest.data["title"].to_s.downcase
      dest.data["place_venues"] = venues.select do |v|
        v.data["place_city"].to_s.downcase == key || v.data["place_area"].to_s.downcase == key
      end.sort_by { |v| v.data["title"].to_s.downcase }
    end

    @geocoder.flush!
    warn_unplaced(venues)
  end

  private

  # ---- Geography data (_data/places_geo.yml) -------------------------------
  #
  # Every lookup is case-insensitive, and the spelling used in the data file is
  # the canonical one — that's what collapses the vault's "FiDi"/"Fidi" into a
  # single node instead of two chips for one neighborhood.
  def load_geo(site)
    geo = site.data["places_geo"] || {}
    # Previously geocoded cities sit underneath the curated file, so a hand
    # -written line always wins over a generated one.
    @geocoder = PlacesGeocoder.new(site)
    @city_country = @geocoder.cached.merge(downcase_keys(geo["countries"]))
    @hood_city = downcase_keys(geo["neighborhoods"])
    @aliases = downcase_keys(geo["aliases"])
    continents = geo["continents"] || {}

    @spelling = {}
    [geo["countries"], geo["neighborhoods"], continents].each do |h|
      (h || {}).each_key { |k| @spelling[k.to_s.downcase] ||= k.to_s }
    end
    (COUNTRIES + continents.keys.map(&:to_s) + @city_country.values.map(&:to_s)).each do |c|
      @spelling[c.downcase] ||= c
    end

    @countries = (COUNTRIES + continents.keys.map(&:to_s) + @city_country.values.map(&:to_s))
                 .map(&:downcase).to_set.freeze
    @regions = (@countries + SUBREGIONS.map(&:downcase)).to_set.freeze
    @unplaced = {}
  end

  def downcase_keys(hash)
    (hash || {}).each_with_object({}) { |(k, v), out| out[k.to_s.downcase] = v.to_s }
  end

  # Resolve a name to the one spelling the whole site uses for it: an alias
  # first ("RI Farm Coast" → "Farm Coast"), then the data file's casing.
  def canonical(name)
    return nil if blank?(name)
    n = name.to_s.strip
    n = @aliases[n.downcase] if @aliases.key?(n.downcase)
    @spelling[n.downcase] || n
  end

  def country?(name)
    !blank?(name) && @countries.include?(name.to_s.downcase)
  end

  def region?(name)
    !blank?(name) && @regions.include?(name.to_s.downcase)
  end

  def hood_parent(name)
    return nil if blank?(name)
    canonical(@hood_city[name.to_s.downcase])
  end

  def known_city?(name)
    !blank?(name) && @city_country.key?(name.to_s.downcase)
  end

  # ---- Venues --------------------------------------------------------------

  def resolve_venue(doc)
    doc.data["place_kind"] = "venue"
    doc.data["place_type"] = normalize_link(Array(doc.data["type"]).first)

    # Coordinates first: they're the geocoder's input when nothing else can
    # place the city.
    lat, lng = coords(doc)
    city, area = resolve_city_area(doc)
    country = resolve_country(doc, city, lat, lng)

    # A venue filed straight under a country ([[Mexico]]) resolves its country
    # as its "city"; collapse that rather than emit a Mexico → Mexico tier.
    city = nil if city && country && city.casecmp?(country)

    doc.data["place_country"] = country
    doc.data["place_city"] = city
    doc.data["place_area"] = area

    doc.data["place_lat"] = lat
    doc.data["place_lng"] = lng

    source = doc.data["source"].to_s
    doc.data["place_gmaps"] = source if source.start_with?("http")
  end

  # See the resolution rules in the class comment. Identity beats position:
  # the chain is searched for something recognisably a neighborhood, then for
  # something recognisably a city, and only then read inside-out.
  def resolve_city_area(doc)
    entries = non_region_locs(doc)
    if entries.empty?
      # A chain of nothing but regions (or nothing at all): better a country-
      # level destination than none. resolve_venue collapses it to the country.
      fallback = Array(doc.data["loc"]).map { |l| canonical(normalize_link(l)) }.reject { |l| blank?(l) }
      return [fallback.last, nil]
    end

    area = entries.find { |e| hood_parent(e) }
    city = hood_parent(area) if area
    city ||= entries.find { |e| known_city?(e) }
    city ||= entries.last
    area ||= entries.find { |e| e != city }
    [city, area]
  end

  # A venue whose own `loc` names its country teaches that country to its whole
  # city, before anything is resolved: file one Florence venue as
  # [[Florence]], [[Italy]] and every other Florence venue lands under Italy
  # too, with nothing added to places_geo.yml.
  #
  # This has to be its own pass. non_region_locs drops countries from the chain
  # — correct, since a country is never the city — but that left resolve_country
  # with only the places_geo.yml lookup, so a chain that said [[Italy]] in as
  # many words still fell through to "Elsewhere".
  def learn_countries(venues)
    venues.each do |doc|
      country = chain_country(doc)
      next if blank?(country)
      city, = resolve_city_area(doc)
      next if blank?(city) || city.casecmp?(country)
      @city_country[city.downcase] ||= country
    end
  end

  def chain_country(doc)
    Array(doc.data["loc"]).map { |l| canonical(normalize_link(l)) }.find { |l| country?(l) }
  end

  # City → country, cheapest and most trustworthy source first:
  #
  #   1. _data/places_geo.yml, the destination notes, and the geocode cache —
  #      by now also taught anything the venues' own chains knew.
  #   2. This venue's own chain.
  #   3. The "city" that is itself a country (a venue filed straight under
  #      [[Mexico]]).
  #   4. The coordinates, via PlacesGeocoder — one network call per unknown
  #      city, cached in _data/places_geo_cache.yml so it happens once ever.
  #
  # Whatever answers gets taught to the city, so the other venues in it resolve
  # for free and never trigger a second lookup. Nil only when even the
  # coordinates can't say (or there are none) — those group under "Elsewhere"
  # and get named in a build warning.
  def resolve_country(doc, city, lat, lng)
    known = @city_country[city.to_s.downcase] unless blank?(city)
    return canonical(known) unless blank?(known)

    from_chain = chain_country(doc)
    return teach(city, from_chain) unless blank?(from_chain)

    return canonical(city) if country?(city)

    found = @geocoder.country_for(city, lat, lng) unless blank?(city)
    return teach(city, found) unless blank?(found)

    @unplaced[city] = true unless blank?(city)
    nil
  end

  def teach(city, country)
    c = canonical(country)
    @city_country[city.to_s.downcase] = c unless blank?(city)
    c
  end

  def non_region_locs(doc)
    Array(doc.data["loc"])
      .map { |l| canonical(normalize_link(l)) }
      .reject { |l| blank?(l) || region?(l) }
  end

  # ---- Tree ----------------------------------------------------------------

  # A venue's ancestry as names, coarsest first. Always opens with a country,
  # falling back to the Elsewhere bucket, so every venue hangs somewhere and
  # every node the tree renders has rows that match it.
  def name_path(doc)
    [doc.data["place_country"] || ELSEWHERE, doc.data["place_city"], doc.data["place_area"]]
      .reject { |n| blank?(n) }
  end

  # Country → city → neighborhood, counted and sorted by weight (the branches
  # worth opening lead), then alphabetically.
  def build_tree(venues)
    roots = {}
    venues.each do |doc|
      level = roots
      parent = nil
      name_path(doc).each_with_index do |name, i|
        node = (level[name] ||= { "name" => name, "tier" => i + 1, "parent" => parent, "count" => 0, "kids" => {} })
        node["count"] += 1
        parent = name
        level = node["kids"]
      end
    end
    @node_slug = {}
    finish(roots, nil, [], {})
  end

  # place_path is the venue's ancestry as *tree* slugs — looked up rather than
  # re-slugified, so a node whose slug had to be disambiguated still matches
  # the rows beneath it. place_city_slug / place_area_slug name the two tiers
  # the templates link to directly (the "Where" jump, a destination note's
  # "filter all my places here" link).
  def assign_path(doc)
    names = name_path(doc)
    path = names.each_index.map { |i| @node_slug[names[0..i]] }.compact
    doc.data["place_path"] = path
    doc.data["place_city_slug"] = @node_slug[names[0..1]] unless blank?(doc.data["place_city"])
    doc.data["place_area_slug"] = @node_slug[names] unless blank?(doc.data["place_area"])
  end

  # Depth-first: sort, assign slugs (disambiguating collisions with the parent
  # slug), and swap the by-name hashes for the arrays the templates iterate.
  #
  # Any repeat is disambiguated, including two nodes with the same name in
  # different branches (a Newport in the US and a Newport in Wales) — they are
  # different destinations, and the filter addresses nodes by slug alone.
  def finish(level, parent_slug, ancestry, seen)
    level.values.sort_by { |n| [-n["count"], n["name"].to_s.downcase] }.map do |node|
      names = ancestry + [node["name"]]
      slug = unique_slug(slugify(node["name"]), parent_slug, node, seen)
      @node_slug[names] = slug
      {
        "name" => node["name"],
        "slug" => slug,
        "tier" => node["tier"],
        "parent" => parent_slug,
        "count" => node["count"],
        "children" => finish(node["kids"], slug, names, seen),
      }
    end
  end

  def unique_slug(slug, parent_slug, node, seen)
    unless seen.key?(slug)
      seen[slug] = node["name"]
      return slug
    end

    base = parent_slug ? "#{parent_slug}-#{slug}" : "#{slug}-#{node['tier']}"
    candidate = base
    n = 1
    candidate = "#{base}-#{n += 1}" while seen.key?(candidate)
    Jekyll.logger.warn "Places:", "destination slug collision on '#{slug}' " \
      "(#{seen[slug]} vs #{node['name']}) — using '#{candidate}' for the latter"
    seen[candidate] = node["name"]
    candidate
  end

  def warn_unplaced(venues)
    return if @unplaced.empty?
    Jekyll.logger.warn "Places:", "no country for #{@unplaced.keys.sort.join(', ')} — " \
      "grouped under \"#{ELSEWHERE}\"; add them to _data/places_geo.yml (or publish their destination notes)"
    orphans = venues.count { |d| blank?(d.data["place_country"]) }
    Jekyll.logger.warn "Places:", "#{orphans} venue(s) affected" if orphans.positive?
  end

  # ---- Notes ---------------------------------------------------------------

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

  # Jekyll's own slugify, so a slug built here is identical to one the
  # templates build with the `| slugify` filter.
  def slugify(name)
    Jekyll::Utils.slugify(name.to_s)
  end

  def strip_base_embeds(doc)
    return unless doc.content.include?(".base")
    doc.content = doc.content.gsub(BASE_EMBED, "")
  end

  def blank?(v)
    v.nil? || (v.respond_to?(:empty?) && v.to_s.strip.empty?)
  end
end
