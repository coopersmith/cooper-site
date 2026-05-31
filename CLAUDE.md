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

- **`_notes/`** - Main content collection (digital garden notes). Supports `[[wikilinks]]` syntax for internal linking.
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

### Layouts

- `default.html` - Base layout with nav/footer
- `note.html` - Digital garden notes with backlinks
- `concert.html` - Concert entries with artist/venue/date display
- `photo.html` / `photos_stream.html` - Photo gallery
- `two-column.html` - Year/content grid (used for travels)

### Styling

SCSS in `_sass/_style.scss`. Supports light/dark mode via CSS custom properties (`--color-*`).

## Wikilink Syntax

When adding internal links in notes, use double brackets. The plugin handles both filename and title matching:
- `[[Guide to New Orleans]]` - links by title
- `[[guide-to-new-orleans]]` - links by filename
- `[[Guide to New Orleans|NOLA Guide]]` - custom link text
