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

### Custom Plugins (`_plugins/`)

- **`bidirectional_links_generator.rb`** - Converts `[[wikilinks]]` to HTML, generates backlinks, creates `notes_graph.json` for visualization
- **`photo_exif_generator.rb`** - Auto-creates `_photos/*.md` from images, extracts EXIF dates, reverse geocodes GPS coordinates via OpenStreetMap
- **`photo_feed_generator.rb`** - Bakes the OpenFeed photo feed ([openfeed.photo/setup](https://openfeed.photo/setup/)) as JSON Feed 1.1 at `/photo/feed.json` on every build, so publishing a photo stays "drop image → build → deploy" with no hand-editing. One item per `_photos` doc, newest first: `id`/`url` are the photo's permalink page, `image` is the full-size file (path percent-encoded). EXIF is re-read from the **original** image files here at build time — `DateTimeOriginal` becomes `date_published` (RFC 3339, falling back to file mtime), and camera/lens/shutter/aperture/iso/focal become display-formatted strings under `_photoring.exif`, including only the fields a file carries and omitting the whole object when it has none (exported/stripped copies just get a date). Author (`name`/`url`/`avatar`) and `_photoring` (`ring` must stay `openfeed-demo`; `creator` is a permanent handle) come from `_config.yml`. Discovery `<link rel="alternate" type="application/feed+json">` is injected site-wide via `_includes/head.html`, and `netlify.toml` serves the file as `application/feed+json`. **Requires an avatar image at the configured `author.avatar` path** (`assets/avatar.jpg`) since OpenFeed requires the field.
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
- `photo.html` / `photos_stream.html` - Photo gallery
- `two-column.html` - Year/content grid (used for travels)

### Styling

All CSS lives in `_sass/` and compiles through `styles.scss` — pages don't carry inline `<style>` blocks. `_style.scss` holds the global tokens and base styles; page- or feature-specific styles go in their own partial (`_home.scss`, `_media.scss`, `_changelog.scss`, `_listening.scss`, `_scrapbook.scss`, `_photos.scss`, `_cv.scss`), imported after the globals in `styles.scss` so overrides don't need `!important`. Supports light/dark mode via CSS custom properties (`--color-*`). Note: `body` caps content width at 720px, so `.wrapper` max-width overrides above that are no-ops.

## Wikilink Syntax

When adding internal links in notes, use double brackets. The plugin handles both filename and title matching:
- `[[Guide to New Orleans]]` - links by title
- `[[guide-to-new-orleans]]` - links by filename
- `[[Guide to New Orleans|NOLA Guide]]` - custom link text
