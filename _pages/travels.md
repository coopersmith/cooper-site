---
title: Travel and Adventures
description: A running list of places I've traveled, with writeups and photos where I have them.
permalink: /travels/
---

<h1>Travel and Adventures</h1>
<p class="subtitle">{{ page.description }}</p>

{% assign travel_notes = site.notes | where_exp: "item", "item.tags contains '#travel'" | sort: "year" | reverse %}
<table class="index-table">
  {% for note in travel_notes %}
  <tr>
    <td class="index-title"><a class="internal-link" href="{{ site.baseurl }}{{ note.url }}">{{ note.title }}</a></td>
    <td class="index-date muted">{{ note.year }}</td>
  </tr>
  {% endfor %}
</table>
