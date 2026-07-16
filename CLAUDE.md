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

### Custom Plugins (`_plugins/`)

- **`bidirectional_links_generator.rb`** - Converts `[[wikilinks]]` to HTML, generates backlinks, creates `notes_graph.json` for visualization
- **`photo_exif_generator.rb`** - Auto-creates `_photos/*.md` from images, extracts EXIF dates, reverse geocodes GPS coordinates via OpenStreetMap
- **`cocktail_cabinet.rb`** - Wires the cocktail↔cabinet database at build time. Indexes notes tagged `cocktails` and `cabinet`, resolves each cocktail's `ingredients` wikilinks to bottle notes (handling Obsidian's aliased-path form `[[vault/path/Rye whiskey|Rye whiskey]]`), and records the reverse ("which cocktails use this bottle") on each bottle. Groups cocktails into families by `type` for the variants pivot. Decorates every note with display-ready data (clean name, category, stock status, resolved ingredient/similar links) for the layouts, and replaces the Obsidian *Bases* embeds (`![[Cocktails.base#By Ingredient]]`, `![[Cocktails.base#Variants]]`) — dead text on the web — with generated HTML link lists (dropping the introducing heading when a pivot is empty, like `readwise_transclusion`). Runs at `:high` priority so its output is final HTML before `bidirectional_links_generator` processes the note's other wikilinks. An ingredient with no matching bottle renders as plain text, so unstocked/unwritten ingredients degrade gracefully.
- **`readwise.rb`** - Shared Readwise client. Pulls the whole library (books + nested highlights) once per build via the Readwise **export** endpoint (a few paginated calls, not one request per book) and memoizes it on `site.data`, so both Readwise features below share a single fetch. Requires `READWISE_TOKEN` in the build environment (ensure it's exposed to builds, not just Netlify functions).
- **`readwise_transclusion.rb`** - Bakes Readwise book highlights into notes at build time. In a note, the native Obsidian embed `![[<Book Title> - Notes]]` is replaced with that book's highlights. Keeps the Obsidian vault pure markdown (no ids/frontmatter) and keeps Readwise notes out of the repo entirely.
  - Matching: exact title (ignoring case/emoji/punctuation), then the main title before a `": "`/`" - "` subtitle and any trailing `(Series, #1)` parenthetical (so `Filterworld: How Algorithms…` resolves to Readwise's `Filterworld`). Ambiguous main titles are skipped, not guessed. Add `"Title": book_id` overrides in `_data/readwise_books.yml` for stragglers.
  - One book per URL: notes slug on filename (`/:slug`), so two files for the same book (e.g. `Foo - Bar.md` and `Foo Bar.md`) collide — keep a single note per book.
  - Fails gracefully: a missing token, no match, or an API error drops the embed *and* its introducing `## Notes` heading (so books with no highlights leave no empty section) and logs a warning to the build output — the build never breaks.
- **`readwise_highlights_page.rb`** - Bakes the `/highlights` ("Commonplace") page at build time. Flattens every highlight from the shared library pull (newest first), joins quote + attribution + optional source link, and emits static paginated JSON under `_site/assets/highlights/`: a default `all/page-N.json` stream, one `tag/<slug>/page-N.json` stream per linkable tag, and an `index.json` manifest. The page fetches those static files, pages in more as you scroll (IntersectionObserver, no Load More button), and filters by tag with zero extra per-request work (each filter is just a different set of static files). Zero runtime API calls — it previously fanned out to one Readwise call per book on every visit (~10s to first paint). The filter bar shows only the most-used tags as chips (`MAX_TAGS`/`MIN_TAG_COUNT`), but every tag down to `MIN_LINK_COUNT` gets a baked stream, so any tag URL (e.g. `/highlights#watches`) deep-links — `index.json`'s `allTags` (slug→name) lets the page validate/label a non-featured tag. Suppressed/workflow tags (`TAG_STOPLIST` — `discard`/`shortlist`/`hinge`/`datingapps`…) are excluded from both. `all/page-1.json` is always written, so a missing token or API error degrades to an empty state instead of a failed fetch.

### Layouts

- `default.html` - Base layout with nav/footer
- `note.html` - Digital garden notes with backlinks
- `concert.html` - Concert entries with artist/venue/date display
- `cocktail.html` / `cabinet.html` - Cocktail recipes and cabinet bottles, with the cross-pivot (see Cocktails & Cabinet above)
- `photo.html` / `photos_stream.html` - Photo gallery
- `two-column.html` - Year/content grid (used for travels)

### Styling

All CSS lives in `_sass/` and compiles through `styles.scss` — pages don't carry inline `<style>` blocks. `_style.scss` holds the global tokens and base styles; page- or feature-specific styles go in their own partial (`_home.scss`, `_media.scss`, `_changelog.scss`, `_listening.scss`, `_scrapbook.scss`, `_photos.scss`, `_cv.scss`), imported after the globals in `styles.scss` so overrides don't need `!important`. Supports light/dark mode via CSS custom properties (`--color-*`). Note: `body` caps content width at 720px, so `.wrapper` max-width overrides above that are no-ops.

## Wikilink Syntax

When adding internal links in notes, use double brackets. The plugin handles both filename and title matching:
- `[[Guide to New Orleans]]` - links by title
- `[[guide-to-new-orleans]]` - links by filename
- `[[Guide to New Orleans|NOLA Guide]]` - custom link text
