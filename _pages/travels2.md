---
title: Travel and Adventures2
description: 
permalink: /travels2/
---

<h2>Travels and Adventures</h2>

<div class="notes-entry-container">
  {% assign travel_notes = site.notes | where_exp: "item", "item.tags contains '#travel'" | sort: "year" | reverse %}
  {% for note in travel_notes %}
    <div class="notes-entry">
      <a class="internal-link" href="{{ site.baseurl }}{{ note.url }}">{{ note.title }}</a>
      <span class="notes-entry-date">{{ note.year }}</span>
    </div>
  {% endfor %}
</div>