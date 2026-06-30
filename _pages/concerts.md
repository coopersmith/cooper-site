---
title: Concerts and Live Music
description: A running list of concerts I've attended, with setlists where I have them.
permalink: /concerts/
---

<h1>Concerts</h1>
<p class="subtitle">A running list of concerts I've attended, with setlists where I have them.</p>

{% assign concert_notes = site.notes | where_exp: "item", "item.tags contains 'concerts'" | sort: "Dates" | reverse %}

<div class="index-toolbar">
  <span class="sort-control">
    <label for="concerts-sort">Sort</label>
    <select id="concerts-sort" class="sort-select" data-sort-scope=".index-table" data-sort-item="tr">
      <option value="date">Date</option>
      <option value="az">A→Z</option>
    </select>
  </span>
</div>

<table class="index-table">
  {% for note in concert_notes %}
    {% assign artists = note.Artists | join: ', ' | replace: '[', '' | replace: ']', '' | replace: '  ', ' ' | strip %}
    {% if artists == '' %}{% assign artists = note.title %}{% endif %}
    {% assign venue = note.Venue | replace: '[', '' | replace: ']', '' | replace: '  ', ' ' | strip %}
  <tr data-title="{{ artists | downcase | escape }}" data-date="{{ note.Dates | date: '%Y-%m-%d' }}">
    <td class="index-title"><a class="internal-link" href="{{ site.baseurl }}{{ note.url }}">{{ artists }}</a></td>
    <td class="index-meta muted">{{ venue }}</td>
    <td class="index-date muted">{{ note.Dates | date: "%b %Y" }}</td>
  </tr>
  {% endfor %}
</table>

<script src="{{ site.baseurl }}/assets/js/sortable.js"></script>
