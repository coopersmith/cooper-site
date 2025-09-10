---
layout: page
title: All Notes
id: tableofcontents
permalink: /tableofcontents/
---

# All Notes

A comprehensive view of all my notes, organized and accessible.

{% comment %} Featured Notes Section {% endcomment %}
{% assign featured_notes = site.notes | where: "featured", true %}
{% if featured_notes.size > 0 %}
<div class="featured-notes">
  {% include notes-grid.html 
     notes=featured_notes 
     title="Featured Notes" 
     subtitle="Highlights from my digital garden"
     show_excerpt=true 
     show_tags=true 
     grid_columns="auto" %}
</div>
{% endif %}

{% comment %} All Notes by Category {% endcomment %}
{% include notes-list.html 
   notes=site.notes 
   title="All Notes" 
   subtitle="Everything I've written, sorted by most recent updates"
   limit=100 
   show_excerpt=false 
   show_tags=true 
   show_date=true %}
