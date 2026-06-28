---
title: Concerts and Live Music
description: A running list of concerts attended
permalink: /concerts/
---

<h1>Concerts</h1>
<p class="subtitle">A running list of concerts I've attended, with setlists if available.</p>

{% assign concert_notes = site.notes | where_exp: "item", "item.tags contains 'concerts'" | sort: "Dates" | reverse %}
<table class="index-table">
  {% for note in concert_notes %}
  <tr>
    <td class="index-title"><a class="internal-link" href="{{ site.baseurl }}{{ note.url }}">{{ note.title }}</a></td>
    <td class="index-date muted">{{ note.Dates | date: "%B %-d, %Y" }}</td>
  </tr>
  {% endfor %}
</table>
