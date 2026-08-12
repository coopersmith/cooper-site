# frozen_string_literal: true

require "date"

# Trips model.
#
# A trip is a note tagged `#travel` — the writeups listed on /travels/. In the
# vault a trip carries a `loc` chain of destination wikilinks and a `start`/
# `end` date range, which is enough to answer the two questions this generator
# exists for:
#
#   1. Where was it? — so the trip can be a pin on the /places/ map, filtered
#      by the same destination chips as the venues around it.
#   2. Which of my places did I go to *on that trip*? — so the writeup can end
#      with the recommendations it actually produced.
#
# Runs at :low, after PlacesGenerator (:high) has resolved every venue and
# minted the destination tree's slugs; a trip's `loc` chain is resolved through
# that same model (PlacesGenerator.model) rather than a second copy of the
# geography, which is what keeps a trip's `data-path` matching the chips.
#
# Data left on each trip note:
#
#   trip_kind      'trip' — the flag layouts gate on
#   trip_dests     the destination names, canonically spelled ("New Orleans")
#   trip_where     those names as prose ("Vienna & Salzburg")
#   trip_path      the union of the destinations' tree slugs, coarsest first —
#                  the /places/ destination filter matches against this exactly
#                  as it does a venue's place_path, so selecting United States,
#                  New York City or Cobble Hill all work on trips too
#   trip_dest      ?dest= value linking to the trip's slice of /places/
#   trip_lat/lng   the pin, or nil (see below) — such trips still list and
#                  still get their places table; they just don't pin
#   trip_venues    my places at those destinations, best-rated first
#   trip_venues_dated
#                  true when that list is scoped to the trip's dates, false
#                  when it fell back to everything at the destination
#   trip_venues_total
#                  how many places I have there in total, so a date-scoped
#                  list can say what it left out
#
# == Multi-destination trips
#
# Each `loc` entry is resolved *separately*, unlike a venue's chain. A venue's
# chain describes one point from the inside out ([[Cobble Hill]], [[NYC]]);
# a trip's lists the places it went ([[Vienna]], [[Salzburg]]), and running
# those through the venue rules would file Salzburg as a neighborhood of
# Vienna. Sub-national regions are dropped first, so a chain written like a
# venue's ([[Providence]], [[Rhode Island]]) still resolves to one destination.
#
# == The pin
#
# In precedence order:
#
#   1. `location` on the trip note — an explicit coordinate is a decision, and
#      it wins. Same tolerant parse as a venue's.
#   2. The centroid of my places at that destination. Needs no maintenance and
#      lands the pin on the part of the city the trip was actually about.
#   3. `coords:` in _data/places_geo.yml — the stopgap for destinations I have
#      no places in (so nothing to take a centroid of), same role that file's
#      other sections play for destinations with no note.
#   4. Nothing, plus a build warning naming the destination — the same "lists
#      but doesn't pin" degradation a venue with no `location` gets.
class TripsGenerator < Jekyll::Generator
  # After PlacesGenerator (:high) — we read the tree it builds and the
  # place_* fields it distils onto every venue.
  priority :low

  # Matched with any leading '#' stripped, so the vault's `#travel` and a
  # plain `trips` both count.
  TRIP_TAGS = %w[travel trips].freeze

  def generate(site)
    docs = site.collections["notes"]&.docs || []
    trips = docs.select { |d| trip?(d) }
    return if trips.empty?

    @model = PlacesGenerator.model
    @coords = coord_table(site)
    @unpinned = {}

    venues = docs.select { |d| d.data["place_kind"] == "venue" }
    trips.each { |doc| resolve(doc, venues) }

    warn_unpinned
  end

  private

  def trip?(doc)
    Array(doc.data["tags"]).any? { |t| TRIP_TAGS.include?(t.to_s.delete("#").strip.downcase) }
  end

  # _data/places_geo.yml `coords:` — destination name → [lat, lng], keyed
  # case-insensitively like the rest of that file. An unparsable pair is
  # dropped (and warned about) rather than pinning a trip into the ocean.
  def coord_table(site)
    raw = (site.data["places_geo"] || {})["coords"] || {}
    raw.each_with_object({}) do |(name, pair), out|
      lat, lng = PlacesGenerator.coords(pair)
      if lat.nil?
        Jekyll.logger.warn "Trips:", "ignoring unparsable coords for '#{name}' in _data/places_geo.yml"
        next
      end
      out[name.to_s.downcase] = [lat, lng]
    end
  end

  def resolve(doc, venues)
    doc.data["trip_kind"] = "trip"

    dests = destinations(doc)
    doc.data["trip_dests"] = dests.map { |d| d["names"].last }
    doc.data["trip_where"] = to_prose(doc.data["trip_dests"])
    doc.data["trip_path"] = dests.flat_map { |d| d["path"] }.uniq
    # Every destination, so a two-city trip links to a two-city view (?dest=
    # takes a comma-separated list) — but only the destinations /places/ can
    # actually express, i.e. the ones that *are* a node of the tree. A
    # destination I have no places in has no chip, and linking to its country
    # instead would promise a view of somewhere else. trip_dest_where names
    # exactly what the link covers, so the label can't overclaim either.
    linkable = dests.select { |d| d["node"] && d["node"] == d["slug"] }
    doc.data["trip_dest"] = linkable.map { |d| d["node"] }.uniq.join(",")
    doc.data["trip_dest_where"] = to_prose(linkable.map { |d| d["names"].last })

    here = venues_at(venues, dests)
    on_trip = during(here, doc)
    doc.data["trip_venues"] = by_rating(on_trip.empty? ? here : on_trip)
    doc.data["trip_venues_dated"] = !on_trip.empty?
    doc.data["trip_venues_total"] = here.size

    lat, lng = pin(doc, here, dests)
    doc.data["trip_lat"] = lat
    doc.data["trip_lng"] = lng
  end

  # One resolved destination per `loc` entry — see "Multi-destination trips".
  # Dropping the regions can empty the chain ([[Rhode Island]] on its own), in
  # which case we fall back to resolving it whole rather than losing the trip's
  # location entirely.
  def destinations(doc)
    return [] unless @model
    raw = Array(doc.data["loc"])
    entries = raw.reject { |l| @model.subregion?(l) }
    entries = raw if entries.empty?
    entries.map { |e| @model.locate([e]) }
           .reject { |d| d["names"].empty? }
           .uniq { |d| d["path"] }
  end

  # A venue is "at" a destination when the destination's node is anywhere in
  # its ancestry — the same containment test the /places/ filter runs, so a
  # trip to Japan collects the Kyoto venues and a trip to Cobble Hill collects
  # only that neighborhood's.
  def venues_at(venues, dests)
    slugs = dests.map { |d| d["slug"] }.compact
    return [] if slugs.empty?
    venues.select { |v| (Array(v.data["place_path"]) & slugs).any? }
  end

  # Narrow to the places whose visit history overlaps the trip's dates. The
  # vault records a venue's first and last visit, not every one, so this is an
  # overlap test rather than an exact match: a place visited across several
  # trips shows up on each of them, which is the right answer for a "where did
  # I go" list. A venue with no visit dates can't be placed in time and drops
  # out — resolve() falls back to the whole destination when *nothing* is
  # datable, which is the case for older trips.
  def during(venues, doc)
    from = to_date(doc.data["start"])
    to = to_date(doc.data["end"]) || from
    return [] unless from && to
    venues.select do |v|
      last = to_date(v.data["last_visit"])
      first = to_date(v.data["first_visit"]) || last
      first && last && first <= to && last >= from
    end
  end

  def by_rating(venues)
    venues.sort_by { |v| [-v.data["rating"].to_f, v.data["title"].to_s.downcase] }
  end

  def pin(doc, here, dests)
    lat, lng = PlacesGenerator.coords(doc.data["location"])
    return [lat, lng] if lat

    pts = here.map { |v| [v.data["place_lat"], v.data["place_lng"]] }.reject { |p| p.first.nil? }
    unless pts.empty?
      return [pts.sum { |p| p[0] } / pts.size, pts.sum { |p| p[1] } / pts.size]
    end

    # Deepest name first: a neighborhood-level coordinate beats its city's.
    dests.each do |d|
      d["names"].reverse_each do |name|
        found = @coords[name.to_s.downcase]
        return found if found
      end
    end

    label = doc.data["trip_where"]
    @unpinned[label] = true unless label.to_s.strip.empty?
    [nil, nil]
  end

  def warn_unpinned
    return if @unpinned.empty?
    Jekyll.logger.warn "Trips:", "no coordinates for #{@unpinned.keys.sort.join(', ')} — " \
      "those trips list but don't pin; add them under `coords:` in _data/places_geo.yml " \
      "(or give the note its own `location`)"
  end

  # "Vienna", "Vienna & Salzburg", "Tokyo, Kyoto & Naoshima"
  def to_prose(names)
    names = Array(names).compact
    return nil if names.empty?
    return names.first if names.size == 1
    "#{names[0..-2].join(', ')} & #{names.last}"
  end

  # Frontmatter dates arrive as Date (YAML parsed them) or as a string when
  # quoted; anything else isn't a date.
  def to_date(value)
    case value
    when Date then value
    when Time then value.to_date
    when String
      begin
        Date.parse(value)
      rescue ArgumentError
        nil
      end
    end
  end
end
