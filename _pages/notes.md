---
title: Notes
description: A digital garden — guides, essays, and half-formed ideas I keep tending.
permalink: /notes/
---

<h1>Notes</h1>
<p class="subtitle">{{ page.description }}</p>

<div class="index-toolbar">
  <span class="sort-control">
    <label for="notes-sort">Sort</label>
    <select id="notes-sort" class="sort-select" data-sort-scope=".index-table" data-sort-item="tr">
      <option value="date">Date</option>
      <option value="az">A→Z</option>
    </select>
  </span>
</div>

{% assign all_notes = site.notes | sort: "created_at_timestamp" | reverse %}
<table class="index-table">
  {% for note in all_notes %}
    {% unless note.path contains 'Concerts' or note.path contains 'MediaDiet' or note.path contains 'Travel' %}
  <tr data-title="{{ note.title | downcase | escape }}" data-date="{{ note.created_at | date: '%Y-%m-%d' }}">
    <td class="index-title"><a class="internal-link" href="{{ site.baseurl }}{{ note.url }}">{{ note.title }}</a></td>
    <td class="index-date muted">{{ note.created_at | date: "%b %Y" }}</td>
  </tr>
    {% endunless %}
  {% endfor %}
</table>

<script src="{{ site.baseurl }}/assets/js/sortable.js"></script>

<style>
  .wrapper { max-width: 46em; }
</style>
