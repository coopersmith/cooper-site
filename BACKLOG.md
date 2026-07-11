# Backlog

Things worth doing, captured so they don't get lost. Not a commitment or a
priority order — just a place to park ideas with enough context to pick up cold.

## Photos

### Serve resized / optimized images on `/photos/`

The stream ships the full-resolution originals: **~91 MB across 69 photos**,
with individual files up to **3.5 MB**. Even with lazy-loading, scrolling
kicks off multi-megabyte downloads and full-res decodes, which is the main
source of the page feeling sluggish.

Approach: `_plugins/photo_exif_generator.rb` already walks every image at build
time, so it's the natural place to also emit a downsized web version (e.g.
~1600px on the long edge, ~200–400 KB) — and optionally a tiny blur/LQIP
placeholder. Point the stream markup at the resized version and keep the
original as the click-through / source of truth. Expect roughly a 10× drop in
transferred bytes.

### Reserve correct image space to kill the layout shift

The "weird load" — placeholders snapping to full height and shoving the page
down as you scroll — happens because each photo sits in a box with
`min-height: 200px` and an image that has no dimensions until it loads. When the
real image decodes, the box jumps from 200px to the photo's true height (often
800px+) and everything below reflows.

Approach: bake each photo's real aspect ratio into the markup from its EXIF
width/height and set `aspect-ratio` on the `.photo-placeholder`, so every box
reserves the correct height before its image loads. Cheap to do alongside the
resized-images work (both live in `photo_exif_generator.rb`), but it stands on
its own — it fixes the *jank* even if the images stay full-res.

### Paginate or windowize the `/photos/` stream

The page mounts all 69 photo items at once. As the library grows this only gets
worse. Options: build-time pagination (page-N pages), or a windowing approach
that keeps only the on-screen items in the DOM. The `/highlights` page already
does static build-time pagination with an IntersectionObserver-driven "load
more as you scroll" pattern (`readwise_highlights_page.rb`) — worth mirroring
that approach here rather than inventing a new one.
