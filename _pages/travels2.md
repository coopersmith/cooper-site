---
title: Travel and Adventures2
description: 
permalink: /travels2/
layout: two-column
---

<div class="left-column">
  <h2>Travel Notes</h2>
  {% assign travel_notes = site.notes | where_exp: "item", "item.tags contains '#travel'" | sort: "year" | reverse %}

  {% assign years = travel_notes | group_by: "year" %}
  {% for year in years %}
    <h3>{{ year.name }}</h3>
    <ul>
      {% for note in year.items %}
        <li>
          <a class="internal-link" href="{{ site.baseurl }}{{ note.url }}">{{ note.title }}</a>
        </li>
      {% endfor %}
    </ul>
  {% endfor %}
</div>

<div class="right-column">
  {{ content }}
</div>