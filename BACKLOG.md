# Backlog

Things worth doing, captured so they don't get lost. Not a commitment or a
priority order — just a place to park ideas with enough context to pick up cold.

## Image library

The library itself (one `_images/` record per image, `surfaces` routing,
build-time EXIF — see CLAUDE.md) shipped as phase 1. The remaining phases:

### Phase 2: adopt the strays

Move the per-trip folders (`assets/CDMX`, `assets/SanDiego2024`, `lisbon`,
`paris2022`, …) under a library root so trip images get records too, and
resolve an embed syntax (`![[img:<slug>]]`, wikilink-style, at `:high`
priority like `cocktail_cabinet.rb`) so notes reference images by slug
instead of hardcoded paths. Slugs mint from filenames, so rename before
migrating, not after. Then the "best of" gallery is just a page querying a
`best` surface. Concert notes also carry `_notes/**/attachments/*.jpeg`
images (currently the source of a harmless `_site/:slug.jpeg` build-conflict
warning) — candidates for the same treatment, but they live in the vault
repo, so the sync has to be thought through first.

### Phase 3: derived sizes via Netlify Image CDN

Serve `/photos/` (and later embeds) through `/.netlify/images?url=…&w=1600`
instead of the full-res originals — **~91 MB across 69 photos** today, files
up to 3.5 MB. On-the-fly resize/format negotiation, no build cost, no derived
files in git; transformed variants also drop EXIF (GPS stays out of public
files while the records keep the data). The single-photo page can keep the
original as the click-through source of truth.

### Phase 4 (maybe): Sveltia CMS admin

A static `/admin/` (Sveltia, the maintained Decap successor) editing
`_images/` records + uploads through git, for phone-friendly tagging. Pure
veneer over the records — only worth it if hand-editing ever chafes.

### Someday: originals out of git

The library lives in git and only grows; ~100 MB is fine, several GB will
slow clones and Netlify builds. Escape hatch: originals in object storage,
records stay in git. Not worth solving until it hurts. (Related someday:
the scrapbook/ephemera idea — an Airtable-ish database of scanned stuff —
could just be another library root with a `scrapbook` surface.)

### ~~Reserve correct image space to kill the layout shift~~

Done with library phase 1: records carry orientation-corrected `width`/
`height` and `photos_stream.html` sets `aspect-ratio` on each
`.photo-placeholder`, so boxes reserve their true height before the image
loads.

### Paginate or windowize the `/photos/` stream

The page mounts all 69 photo items at once. As the library grows this only gets
worse. Options: build-time pagination (page-N pages), or a windowing approach
that keeps only the on-screen items in the DOM. The `/highlights` page already
does static build-time pagination with an IntersectionObserver-driven "load
more as you scroll" pattern (`readwise_highlights_page.rb`) — worth mirroring
that approach here rather than inventing a new one.
