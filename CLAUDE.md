# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Install dependencies
bundle install

# Build the site
bundle exec jekyll build

# Run development server (http://127.0.0.1:4000/)
bundle exec jekyll serve
```

## Deployment

The site deploys to Netlify automatically. Production URL: https://coopersmith.nyc

## Architecture

This is a Jekyll-based digital garden/personal website with Obsidian-style wikilink support.

### Collections

- **`_notes/`** - Main content collection (digital garden notes). Supports `[[wikilinks]]` syntax for internal linking. **⚠️ Do not edit files in `_notes/` directly in this repo — they are a build-time mirror.** Notes are authored in Obsidian and live in the private `coopersmith/coops-site-publish` repo; that repo's `sync-to-site` GitHub Action copies them into `_notes/` on every publish, so any direct edit here is overwritten on the next sync. To change a note, edit it in `coops-site-publish`.
- **`_photos/`** - Photo entries auto-generated from `assets/photos/` images via EXIF extraction.
- **`_pages/`** - Static pages (about, travels, concerts, etc.)

### Key Content Types

**Notes** use the `note` layout and support:
- Roam/Obsidian-style `[[double bracket]]` links
- `[[Note Title|custom display text]]` syntax
- Automatic backlink generation

**Concerts** (`_notes/Concerts/`) use the `concert` layout with frontmatter:
```yaml
layout: concert
title: Artist at Venue
Artists: ["[[Artist Name]]"]
Dates: YYYY-MM-DD
Venue: "[[Venue Name]]"
tags: [concerts]
```

**Photos** are auto-generated - drop images in `assets/photos/` and the `photo_exif_generator.rb` plugin creates markdown files with EXIF date and geocoded location.

**Cocktails & Cabinet** — a cross-linked drinks database. Two note types live under `_notes/FoodDrink/`, get frontmatter-driven layouts, and pivot to each other (built by `cocktail_cabinet.rb`). Index pages: `/cocktails/` (sortable table) and `/cabinet/` (bottles grouped by category).

**Cocktails** (`_notes/FoodDrink/Cocktails/`) use the `cocktail` layout:
```yaml
categories: ["[[Cocktails]]"]
type: ["[[Negroni]]"]          # the family — cocktails sharing a `type` are variants of each other
ingredients:                    # wikilinks to Cabinet bottles; each resolves to a bottle link (+stock dot)
  - "[[Gin]]"
  - "[[Campari]]"
  - "[[Sweet Vermouth]]"
url: https://…                  # source, shown as a fact
rating: 6                       # optional, 1–7 (◆◇ marks, same scale as media)
last: YYYY-MM-DD                # optional, drives the "Recent" sort
tags: [cocktails]               # REQUIRED — this is how the plugin/pages find cocktails
```
Body carries the recipe (`## Ingredients` with measurements, `## Directions`, `## Notes`). A `## Variants` section with `![[Cocktails.base#Variants]]` is baked into the same-family cocktails.

**Cabinet bottles** (`_notes/FoodDrink/Cabinet/`) use the `cabinet` layout:
```yaml
categories: ["[[Cabinet]]"]
type: Spirit                    # the category (Spirit / Vermouth / Liqueur / Bitters / …) — groups the /cabinet page
nyc: Full                       # stock status in Brooklyn (any non-blank = stocked → filled dot)
ri:                             # stock status in Rhode Island
abv:                            # optional fact
similar: ["[[Bourbon]]"]        # related bottles (wikilinks)
tags: [cabinet]                 # REQUIRED — this is how the plugin/pages find bottles
```
Body carries tasting notes / `## Recommended Brands`. A `## Cocktails Using This` section with `![[Cocktails.base#By Ingredient]]` is baked into the reverse pivot (every cocktail whose `ingredients` link this bottle). The `nyc`/`ri` stock fields are the seed for the future "what can I make from what's on my shelf" recommender.

Authoring note: these are synced from Obsidian like all `_notes/` (edit in `coops-site-publish`, not here). The `![[Cocktails.base#…]]` embeds are Obsidian *Bases* views that are dead on the web — `cocktail_cabinet.rb` reconstructs them from frontmatter so the site cross-links the way the vault does.

**Places** (`_notes/Places/`) are venue recommendations plus the destinations that contain them, one note apiece, all synced from Obsidian. A venue's frontmatter carries `type` (`[[Restaurants]]`, `[[Bars + Cocktails]]`…), a `loc` chain of destination wikilinks ordered inside-out (neighborhood first, city last), `location` ([lat, lng] as strings), `rating` (7-point), visit stats (`visit_count`/`first_visit`/`last_visit`), `scoreGoogle`, and a Google Maps `source` URL; a destination note has `type: [[Cities]]`. The `/places/` page (`_pages/places.md`) renders every venue as a destination/type/rating/recency-filterable list with a toggleable Leaflet map view (vendored `assets/vendor/leaflet/`, CARTO Positron/Dark Matter raster tiles following `prefers-color-scheme` and keyed off `carto_api_key` in `_config.yml` — CARTO's raster endpoint stopped serving anonymous requests in 2026 and stamps unkeyed tiles "API KEY REQUIRED"; the key is public by design, so it lives in config rather than the build environment, and `places-map.js` carries front matter (with `layout: null`, or the `**/*` default would wrap the script in a page) so Jekyll interpolates it. A blank key still renders, just watermarked. Their raster service is deprecated in favour of vector basemaps, so this is a stopgap, Leaflet.markercluster rolling overlapping pins into count badges that spiderfy at max zoom); the table rows are the single source of truth — markers, popups, and the map's fit are driven off their data attributes (emitted by `_includes/place-row-attrs.html`). The Leaflet runtime is shared with the destination mini-maps via `assets/js/places-map.js`, which also provides the big map's geolocating "places near me" control. Venues without `location` coords list but don't pin, by design. The "Visited" dropdown scopes the list by `last_visit` recency (any time / past 1, 2, 5, 10 years) so stale recommendations can be filtered out; the cutoff is computed in the browser (never baked), and a venue with no recorded visit drops out of any scoped view. The "Rating" dropdown is a floor on the 7-point scale and is **the one filter that doesn't start wide open** — the page is a list of recommendations, so it opens at 5+ rather than at everything ever filed. All seven rungs are selectable plus "Any"; an unrated venue can't be shown to clear a bar, so (like the visit scope) it only appears under "Any". Because the default isn't `all`, the script carries a `DEFAULT_RATING` and `?rating=` is written whenever the floor differs from it — `?rating=all` is a real, shareable state. Two places lean on that: a destination note's "Filter & map **all** my places in X" CTA links with `&rating=all` so it can't hand back a shorter list than the table above it, and a `?focus=` link (a venue note's "See it on my map") drops the floor to `all` when the focused venue sits below it — otherwise a 4-rated venue would deep-link to a map with no pin. An explicit `?rating=` in the link still wins. Deep links: `?dest=<slug>[,<slug>…]`, `?type=`, `?rating=<1–7|all>`, `?visited=<years|all>`, `?view=map`, `?sort=`, and `?focus=<venue-slug>` (opens that venue's popup). Place names are jump controls — clicking one in the "Where" column or in a map popup replaces the destination filter with that place and swings the map to it. Below the list/map, an Export button turns the current filter into a takeaway named after it ("Coop's Guide to Bars + Cocktails in Cobble Hill"): a copyable LLM trip-planning prompt and a .kml download (imports at Google My Maps), both carrying each venue's last-visit month so the freshness of a rec travels with it. The prompt also states the active rating floor and visit window, since a pre-screened list reads differently to whatever's planning the trip. Places notes are excluded from the home "Recent notes" list and `/notes/`, like MediaDiet. Individual notes use the `place` layout (facts header + "See it on my map").

**The Places destination filter** is a multi-select drill-down over a Country → City → Neighborhood tree, one chip row per tier (`_includes/place-chip.html`). It replaced a flat chip-per-city row that didn't scale: the chip count grew with the content (47 venues had produced 26 city chips, 17 of them filtering to a single venue) and neighborhoods had no chip at all, so they borrowed an ad-hoc one. A country row is bounded by how much of the world you've been to; the rows below it appear only for branches you've opened.

Chips are tri-state — on (the whole branch), mixed (you narrowed into its children), off. Picking a node *inside* one you'd already selected narrows (Italy → Florence) instead of un-checking it; picking one that contains selected nodes subsumes them. Otherwise everything is a plain toggle, so Florence + Milan + Tokyo compose, and `?dest=` takes a comma-separated list (single-value links from before the tree still resolve). Counts on each chip are live against the Type and Visited filters, so an empty branch dims rather than promising places that aren't there. Matching is one `indexOf` against the row's `data-path` (`"united-states new-york-city cobble-hill"`), which is why selecting a country, a city or a neighborhood is the same operation. On narrow screens each tier becomes a horizontal scroll rail rather than collapsing to a `<select>` like /media/ does — a dropdown would cost both the multi-select and the drill-down.

**Trips** (`_notes/Travel/`, tagged `#travel`) are the writeups listed on `/travels/`. Frontmatter carries `year`, a `start`/`end` date range, and a `loc` chain of destination wikilinks; `_plugins/trips.rb` resolves that chain through the *same* geography and tree slugs `places.rb` gives venues, so a trip is a first-class citizen of the Places model without duplicating any of it. Two things come of that:

- **Trips pin on the `/places/` map.** `_pages/places.md` emits a hidden `.places-trips` table (`_includes/trip-row-attrs.html`) that the map runtime reads exactly as it reads venue rows — one source of truth per pin, no parallel JSON. Trips obey the destination filter (their `data-path` comes out of the same tree) and the Visited recency scope (a trip's `data-date` is when it *ended*, compared against the same cutoff — a 2017 trip left pinned beside the 2017 venues that scope just hid would be the map contradicting itself), but they drop out under a Type selection, since a trip isn't a kind of place, and they never enter the list, the counts, or the export — the list is places. A trip pin is a hollow diamond on a needle against the places' filled dots, with a legend under the map.
- **Trips break out of the cluster sooner.** A trip is coarser than a place, so both share one cluster group — a zoomed-out city is a single badge covering trips and places alike — but below `TRIP_BREAKOUT_ZOOM` (5, in `assets/js/places-map.js`) trip markers cluster and at or above it they move onto the map in their own right, while the places underneath stay rolled up until their own clustering distance breaks them apart. Panning out to a country shows you the trips; zooming past them dissolves into the individual recommendations. The needle shape exists for the same reason: a trip usually sits at the centroid of its own places, i.e. exactly where their cluster badge is, so the marker has to cross that badge — a hairline leaves the count readable where a pin body would swallow it.

**A trip's pin** comes from, in order: `location` on the note (an explicit coordinate wins), the centroid of my places at that destination (self-maintaining, and it lands on the part of the city the trip was about), `coords:` in `_data/places_geo.yml` (the stopgap for destinations I have no places in), else nothing plus a build warning naming it — the same "lists but doesn't pin" degradation a venue with no `location` gets. Each `loc` entry is resolved *separately*, unlike a venue's chain: a venue's chain describes one point inside-out, a trip's lists the places it went, and running `[[Vienna]], [[Salzburg]]` through the venue rules would file Salzburg as a neighborhood of Vienna.

**Every trip entry ends with the places it produced** (`_includes/trip-places.html`, rendered from `note.html` on the `trip_kind` flag, so it follows the tag rather than the folder), best-rated first, with a mini-map and a link to that destination's `/places/` view.

That list is **strictly** the places the check-in history puts inside the trip's `start`/`end`, and the test is that a venue's `first_visit` or `last_visit` falls *within* the window — not that its `first..last` span merely overlaps it. The looser overlap test was wrong in a way that got worse with every entry: 21 venues have multi-year visit windows (Henry Public spans 2012–2026 across 58 visits), so every NYC writeup would have claimed every one of them. An endpoint inside the window is evidence; a span straddling it is not. The cost — a venue whose only visit on this trip was a middle one — is data the vault doesn't record and so can't be claimed either way.

There is deliberately **no fallback** to "my whole list for the city": a 2019 New Orleans entry listing places first visited in 2024 is a false claim about the trip, and being a useful list doesn't redeem it. When the dates turn up nothing (an older trip, or one whose venues predate the check-ins) the section degrades to a one-line pointer at the destination's `/places/` view. A trip with no `start` can never list anything, so `trips.rb` warns at build time naming it.

`_data/places_geo.yml` supplies the ancestry the vault doesn't: most venues are filed under a bare city (`[[Kyoto]]`) with no country, so it maps city → country, neighborhood → city (only for neighborhoods with no destination note), country → continent (unrendered; the tree is generic, so adding that tier later is a template change), destination → [lat, lng] (`coords:`, trip pins only — see Trips above), and variant → canonical spellings. A destination note whose `loc` names a country still wins, so publishing one from Obsidian upgrades every venue in that city with no change here. A city missing from the file still lists and pins — it groups under "Elsewhere" and the build logs a warning naming it. Deliberately no borough entries (Brooklyn): a `[[Brooklyn]], [[Cobble Hill]]` chain names both, and the first known neighborhood wins.

### Custom Plugins (`_plugins/`)

- **`bidirectional_links_generator.rb`** - Converts `[[wikilinks]]` to HTML, generates backlinks, creates `notes_graph.json` for visualization
- **`photo_exif_generator.rb`** - Auto-creates `_photos/*.md` from images, extracts EXIF dates, reverse geocodes GPS coordinates via OpenStreetMap
- **`cocktail_cabinet.rb`** - Wires the cocktail↔cabinet database at build time. Indexes notes tagged `cocktails` and `cabinet`, resolves each cocktail's `ingredients` wikilinks to bottle notes (handling Obsidian's aliased-path form `[[vault/path/Rye whiskey|Rye whiskey]]`), and records the reverse ("which cocktails use this bottle") on each bottle. Groups cocktails into families by `type` for the variants pivot. Decorates every note with display-ready data (clean name, category, stock status, resolved ingredient/similar links) for the layouts, and replaces the Obsidian *Bases* embeds (`![[Cocktails.base#By Ingredient]]`, `![[Cocktails.base#Variants]]`) — dead text on the web — with generated HTML link lists (dropping the introducing heading when a pivot is empty, like `readwise_transclusion`). Runs at `:high` priority so its output is final HTML before `bidirectional_links_generator` processes the note's other wikilinks. An ingredient with no matching bottle renders as plain text, so unstocked/unwritten ingredients degrade gracefully.
- **`places.rb`** - Distils each `_notes/Places` note's vault frontmatter into flat `place_*` fields (kind, type, country/city/area, `place_path` as tree slugs, float coords, Google Maps URL) for the `/places/` page and `place` layout, builds `site.data.places_tree` (the Country → City → Neighborhood filter tree, counted and sorted by weight, slugs unique across tiers), and strips the Obsidian `![[….base#…]]` embeds plus their introducing headings (same treatment `tv_shows.rb` gives Shows). Ancestry is resolved by *identity*, not position — a `loc` chain arrives inside-out, outside-in, missing its city, or running past it to a state, so the chain is searched for a known neighborhood, then a known city, and only then read inside-out. (The old positional rule filed `[[NYC]], [[Brooklyn Heights]]` and `[[Brooklyn Heights]], [[NYC]]` as two different cities.) Slugs are minted while building the tree and read back onto each venue, so a disambiguated slug still matches its rows. `_data/places_geo.yml` is the spelling authority — note titles can't be, since `title_case.rb` sentence-cases them. Publishes the resolved model as `PlacesGenerator.model` for `trips.rb` (`locate` a `loc` chain, `subregion?`, `coords`), so trips resolve through this geography rather than a second copy of it
- **`trips.rb`** - Distils each `#travel` note into `trip_*` fields: `trip_path` (tree slugs, so the /places/ destination filter matches a trip exactly as it matches a venue), `trip_lat`/`trip_lng` (the pin, resolved by the precedence in Trips above), `trip_venues` + `trip_venues_total` (the places whose check-ins fall inside the trip's dates, best-rated first; the total is every place at the destination, used only to size the "and the rest" pointer), and `trip_dest`/`trip_dest_where` for the ?dest= link — which names only destinations the filter has a chip for, so the link never promises a view it can't show. Runs at `:low`, after `places.rb` (`:high`) has resolved every venue and minted the tree's slugs. Identifies trips by tag, not folder, matching how `/travels/` finds them
- **`readwise.rb`** - Shared Readwise client. Pulls the whole library (books + nested highlights) once per build via the Readwise **export** endpoint (a few paginated calls, not one request per book) and memoizes it on `site.data`, so both Readwise features below share a single fetch. Requires `READWISE_TOKEN` in the build environment (ensure it's exposed to builds, not just Netlify functions).
- **`readwise_transclusion.rb`** - Bakes Readwise book highlights into notes at build time. In a note, the native Obsidian embed `![[<Book Title> - Notes]]` is replaced with that book's highlights. Keeps the Obsidian vault pure markdown (no ids/frontmatter) and keeps Readwise notes out of the repo entirely.
  - Matching: exact title (ignoring case/emoji/punctuation), then the main title before a `": "`/`" - "` subtitle and any trailing `(Series, #1)` parenthetical (so `Filterworld: How Algorithms…` resolves to Readwise's `Filterworld`). Ambiguous main titles are skipped, not guessed. Add `"Title": book_id` overrides in `_data/readwise_books.yml` for stragglers.
  - One book per URL: notes slug on filename (`/:slug`), so two files for the same book (e.g. `Foo - Bar.md` and `Foo Bar.md`) collide — keep a single note per book.
  - Fails gracefully: a missing token, no match, or an API error drops the embed *and* its introducing `## Notes` heading (so books with no highlights leave no empty section) and logs a warning to the build output — the build never breaks.
- **`readwise_highlights_page.rb`** - Bakes the `/highlights` ("Commonplace") page at build time. Flattens every highlight from the shared library pull (newest first), joins quote + attribution + optional source link, and emits static paginated JSON under `_site/assets/highlights/`: a default `all/page-N.json` stream, one `tag/<slug>/page-N.json` stream per linkable tag, and an `index.json` manifest. The page fetches those static files, pages in more as you scroll (IntersectionObserver, no Load More button), and filters by tag with zero extra per-request work (each filter is just a different set of static files). Zero runtime API calls — it previously fanned out to one Readwise call per book on every visit (~10s to first paint). The filter bar shows only the most-used tags as chips (`MAX_TAGS`/`MIN_TAG_COUNT`), but every tag down to `MIN_LINK_COUNT` gets a baked stream, so any tag URL (e.g. `/highlights#watches`) deep-links — `index.json`'s `allTags` (slug→name) lets the page validate/label a non-featured tag. Suppressed/workflow tags (`TAG_STOPLIST` — `discard`/`shortlist`/`hinge`/`datingapps`…) are excluded from both. Nested tags aggregate at every ancestor level (a `mywork/lyft` highlight also counts toward `mywork`), so a parent tag is a real, deep-linkable stream covering all its children while each child stays linkable on its own. `PINNED_TAGS` force-includes specific tags as chips even below `MIN_TAG_COUNT` (matched case/separator-insensitive) — used for tags that matter more than their raw highlight count (e.g. ones mostly applied at the document level, or a parent whose highlights are spread thin across children); pinned chips still sort in by count, so a low-use pin lands at the bottom. `all/page-1.json` is always written, so a missing token or API error degrades to an empty state instead of a failed fetch. Duplicates in the Readwise library are collapsed by `dedupe`, in two passes (both merge the tags of the copies they drop, so a tag applied to only one copy keeps its passage). `exact_dedupe` collapses textually identical highlights anywhere in the library, keyed on text normalized for whitespace, case and enclosing punctuation, newest copy winning — these come from the same document saved twice (two book records, so two copies of every highlight), and since the copies carry different timestamps they'd otherwise surface pages apart in the stream. `near_dedupe` then collapses a highlight wholly contained in another from the same source captured within `NEAR_DUPLICATE_WINDOW` (15 min), keeping the longer text — one highlight gesture recorded twice, the second often grabbing a slightly longer selection, which renders as two near-identical blockquotes back to back. That pass is deliberately narrow (same source, inside the window, both texts ≥ `MIN_CONTAINMENT_LENGTH`) because an overlapping passage highlighted on a genuine re-read months or years later is a real second highlight and must survive; the window sits in a wide observed gap (artifacts land ≤ ~96s apart, re-reads 30+ days). It precomputes each row's key and timestamp — recomputing them per comparison made the pass ~10s on a full library. Both passes are edit-aware via the highlight's `updated`/`updated_at` (the only trace the API gives of a hand-corrected highlight; Readwise's UI doesn't surface it): the exact pass adopts the wording of whichever copy was edited last, and the near pass keeps the *shorter* text when it was edited more than `EDIT_GRACE` (1 day) after the longer, reading that as a deliberate trim. The grace period matters because bulk syncs rewrite hundreds of highlights in one second, so `updated` is a hint rather than proof. Caveat worth knowing: correcting a highlight in a document that exists twice makes the copies stop matching, which *reintroduces* the duplicate rather than losing the fix — dedupe can't help there, merging the documents in Readwise is the fix.

### Layouts

- `default.html` - Base layout with nav/footer
- `note.html` - Digital garden notes with backlinks; appends `trip-places.html` to trip writeups
- `concert.html` - Concert entries with artist/venue/date display
- `cocktail.html` / `cabinet.html` - Cocktail recipes and cabinet bottles, with the cross-pivot (see Cocktails & Cabinet above)
- `place.html` - Places notes: venues get a facts header (where/rating/visits/Google/map link); destinations get a mini-map plus an index table of their venues (`place_venues`, matched case-insensitively by the plugin) and a link to their filtered `/places/` view
- `photo.html` / `photos_stream.html` - Photo gallery
- `two-column.html` - Year/content grid (used for travels)

### Styling

All CSS lives in `_sass/` and compiles through `styles.scss` — pages don't carry inline `<style>` blocks. `_style.scss` holds the global tokens and base styles; page- or feature-specific styles go in their own partial (`_home.scss`, `_media.scss`, `_places.scss`, `_changelog.scss`, `_listening.scss`, `_scrapbook.scss`, `_photos.scss`, `_cv.scss`), imported after the globals in `styles.scss` so overrides don't need `!important`. Supports light/dark mode via CSS custom properties (`--color-*`). Note: `body` caps content width at 720px, so `.wrapper` max-width overrides above that are no-ops.

## Wikilink Syntax

When adding internal links in notes, use double brackets. The plugin handles both filename and title matching:
- `[[Guide to New Orleans]]` - links by title
- `[[guide-to-new-orleans]]` - links by filename
- `[[Guide to New Orleans|NOLA Guide]]` - custom link text
