---
layout: page
title: Index Views Showcase
permalink: /showcase/
published: false
---

# Index Views Showcase

This page demonstrates the new index view components and how they can be controlled with YAML properties.

## Grid Layout - Featured Notes Only
{% include notes-grid.html 
   notes=site.notes 
   title="Featured Content" 
   subtitle="Handpicked notes worth highlighting"
   featured_only=true
   limit=6 
   show_excerpt=true 
   show_tags=true 
   grid_columns="auto" %}

## List Layout - Recent Travel Notes
{% include notes-list.html 
   notes=site.notes 
   title="Travel Adventures" 
   subtitle="Exploring the world, one note at a time"
   filter_tag="travel"
   limit=5 
   show_excerpt=true 
   show_tags=true %}

## Compact List - Media Diet
{% include notes-list.html 
   notes=site.notes 
   title="Media Consumption" 
   filter_tag="mediadiet"
   limit=3 
   show_excerpt=false 
   show_tags=false 
   compact=true %}

## Grid Layout - City Guides
{% include notes-grid.html 
   notes=site.notes 
   title="City Guides" 
   subtitle="Local insights and recommendations"
   limit=4 
   show_excerpt=true 
   show_tags=true 
   grid_columns="2" 
   card_size="standard" %}

## Simple List - All Notes (Excluding Concerts)
{% include notes-list.html 
   notes=site.notes 
   title="All Notes" 
   exclude_path="Concerts"
   limit=10 
   show_excerpt=false 
   show_tags=true 
   show_more_link="/tableofcontents" %}