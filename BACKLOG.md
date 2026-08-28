# Backlog

Things worth doing, captured so they don't get lost. Not a commitment or a
priority order — just a place to park ideas with enough context to pick up cold.

## Image library

The library itself (one `_images/` record per image, `surfaces` routing,
build-time EXIF — see CLAUDE.md) shipped as phase 1. The remaining phases:

### ~~Phase 2: adopt the strays~~ (mostly done)

Done: the per-trip folders are library roots (adopted in place — files never
moved, old hardcoded paths still work — so trip images have records now),
`image_embeds.rb` resolves `![[img:<slug>]]` in notes/pages, and `/best-of/`
renders the `best` surface (empty until records are tagged). Remaining:

- **Geocode the trip records.** 85 of the 98 trip images have GPS but their
  records lack `location` — the sandbox this shipped from couldn't reach
  Nominatim. Any `jekyll build` on a machine with network fills them
  (fill-don't-clobber, one API call per image); commit the filled records,
  or Netlify will re-geocode on every deploy (~85 rate-limited calls ≈ +90s
  per build) without persisting.
- **Convert the trip writeups to `![[img:…]]` embeds.** The notes are a
  build-time mirror of `coops-site-publish`, so the conversion happens in
  the vault, not here. Tradeoff to accept first: `![[img:…]]` is dead
  markup *inside Obsidian* (the current hardcoded paths are equally dead
  there, so nothing is lost — but nothing is gained vault-side either).
- **Concert attachments** (`_notes/**/attachments/*.jpeg`, source of the
  harmless `_site/:slug.jpeg` build-conflict warning) — same vault-repo
  consideration.

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
