---
title: Concerts and Live Music
description: A collection of concert experiences and live music memories
permalink: /concerts/
---

<h2>Concerts and Live Music</h2>

<div class="notes-entry-container">
  {% assign concert_notes = site.notes | where_exp: "item", "item.tags contains '#concerts'" | sort: "Dates" | reverse %}
  {% for note in concert_notes %}
    <div class="notes-entry">
      <a class="internal-link" href="{{ site.baseurl }}{{ note.url }}">{{ note.title }}</a>
      <span class="notes-entry-date">{{ note.Dates | date: "%B %d, %Y" }}</span>
    </div>
  {% endfor %}
</div>