---
title: Concerts and Live Music
description: A running list of concerts I've attended, with setlists where I have them.
permalink: /concerts/
---

<h1>Concerts</h1>
<p class="subtitle">A running list of concerts I've attended, with setlists where I have them.</p>

{% assign concert_notes = site.notes | where_exp: "item", "item.tags contains 'concerts'" | sort: "Dates" | reverse %}
<table class="index-table">
  {% for note in concert_notes %}
    {% assign artists = note.Artists | join: ', ' | replace: '[', '' | replace: ']', '' | replace: '  ', ' ' | strip %}
    {% if artists == '' %}{% assign artists = note.title %}{% endif %}
    {% assign venue = note.Venue | replace: '[', '' | replace: ']', '' | replace: '  ', ' ' | strip %}
  <tr>
    <td class="index-title"><a class="internal-link" href="{{ site.baseurl }}{{ note.url }}">{{ artists }}</a></td>
    <td class="index-meta muted">{{ venue }}</td>
    <td class="index-date muted">{{ note.Dates | date: "%b %Y" }}</td>
  </tr>
  {% endfor %}
</table>
