---
title: Concerts and Live Music
description: A running list of concerts attended
permalink: /concerts/
---

<h2>Concerts</h2>
A running list of concerts I've attended, with setlists if available

<div class="notes-entry-container">
  {% assign concert_notes = site.notes | where_exp: "item", "item.tags contains 'concerts'" | sort: "Dates" | reverse %}
  {% for note in concert_notes %}
    <div class="notes-entry">
      <a class="internal-link" href="{{ site.baseurl }}{{ note.url }}">{{ note.title }}</a>
      <span class="notes-entry-date">&nbsp;&mdash;&nbsp;{{ note.Dates | date: "%B %d, %Y" }}</span>
    </div>
  {% endfor %}
</div>