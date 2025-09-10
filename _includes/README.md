# Index View Components

This directory contains reusable Jekyll components for creating beautiful, functional index views inspired by Kepano's design approach.

## Components

### 1. `note-card.html`
A card-style component for displaying individual notes in a grid layout.

**Usage:**
```liquid
{% include note-card.html 
   note=note 
   show_excerpt=true 
   show_tags=true 
   show_date=true 
   card_size="standard" %}
```

**Parameters:**
- `note` (required): The note object to display
- `show_excerpt` (default: false): Show note excerpt
- `show_tags` (default: true): Show note tags
- `show_date` (default: true): Show note date
- `card_size` (default: "standard"): Card size ("standard", "compact", "large")

### 2. `notes-grid.html`
A grid layout for displaying multiple notes as cards.

**Usage:**
```liquid
{% include notes-grid.html 
   notes=site.notes 
   title="Recent Notes"
   subtitle="My latest thoughts"
   limit=6 
   show_excerpt=true 
   grid_columns="auto" %}
```

**Parameters:**
- `notes` (default: site.notes): Collection of notes to display
- `title`: Grid section title
- `subtitle`: Grid section subtitle
- `limit` (default: 10): Maximum number of notes to show
- `show_excerpt` (default: false): Show note excerpts
- `show_tags` (default: true): Show note tags
- `show_date` (default: true): Show note dates
- `grid_columns` (default: "auto"): Grid layout ("auto", "2", "3")
- `card_size` (default: "standard"): Card size
- `filter_tag`: Only show notes with this tag
- `exclude_path`: Exclude notes containing this path
- `featured_only` (default: false): Only show featured notes
- `show_more_link`: Link to view more notes
- `show_more_text` (default: "notes"): Text for the more link

### 3. `notes-list.html`
A list layout for displaying notes in a clean, scannable format.

**Usage:**
```liquid
{% include notes-list.html 
   notes=site.notes 
   title="Recent Updates"
   limit=5 
   show_excerpt=true 
   compact=false %}
```

**Parameters:**
- `notes` (default: site.notes): Collection of notes to display
- `title`: List section title
- `subtitle`: List section subtitle
- `limit` (default: 10): Maximum number of notes to show
- `show_excerpt` (default: false): Show note excerpts
- `show_tags` (default: true): Show note tags
- `show_date` (default: true): Show note dates
- `filter_tag`: Only show notes with this tag
- `exclude_path`: Exclude notes containing this path
- `featured_only` (default: false): Only show featured notes
- `compact` (default: false): Use compact spacing
- `show_more_link`: Link to view more notes
- `show_more_text` (default: "notes"): Text for the more link

## YAML Front Matter Properties

These components recognize the following YAML properties in your notes:

### Standard Properties
- `title`: Note title (required)
- `date`: Publication date
- `last_modified_at`: Last modification date
- `tags`: Array of tags
- `excerpt`: Note excerpt/description

### Custom Properties for Index Views
- `featured`: Set to `true` to mark as featured content
- `hide_from_index`: Set to `true` to exclude from index views
- `index_priority`: Number (1-10) for custom sorting

### Example Front Matter
```yaml
---
title: My Amazing Note
date: 2024-01-15
featured: true
tags:
  - important
  - featured
  - example
excerpt: This is a brief description of my note that will appear in index views.
---
```

## Styling

The components use CSS custom properties for theming and are fully responsive. The main styles are defined in `_sass/_index-views.scss`.

### CSS Classes
- `.featured-notes`: Special styling for featured content sections
- `.note-card`: Individual note cards
- `.notes-grid`: Grid container
- `.notes-list`: List container

## Examples

### Homepage with Featured and Recent Notes
```liquid
{% comment %} Featured Notes {% endcomment %}
{% assign featured_notes = site.notes | where: "featured", true %}
{% if featured_notes.size > 0 %}
<div class="featured-notes">
  {% include notes-list.html 
     notes=featured_notes 
     title="Featured Notes" 
     limit=3 
     show_excerpt=true 
     compact=true %}
</div>
{% endif %}

{% comment %} Recent Updates {% endcomment %}
{% include notes-list.html 
   notes=site.notes 
   title="Recently Updated" 
   limit=5 
   exclude_path="Concerts" 
   show_more_link="/tableofcontents" %}
```

### Category-Specific Grid
```liquid
{% include notes-grid.html 
   notes=site.notes 
   title="Travel Adventures" 
   filter_tag="travel"
   limit=6 
   show_excerpt=true 
   grid_columns="3" %}
```

### Compact List for Sidebar
```liquid
{% include notes-list.html 
   notes=site.notes 
   title="Quick Links" 
   limit=5 
   compact=true 
   show_excerpt=false 
   show_tags=false %}
```