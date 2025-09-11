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
  {% include basic-notes-list.html 
     notes=featured_notes 
     title="Featured Notes" 
     limit=6 %}
{% endif %}

{% comment %} All Notes {% endcomment %}
{% include basic-notes-list.html 
   notes=site.notes 
   title="All Notes" 
   subtitle="Everything I've written, sorted by most recent updates"
   limit=100 %}
