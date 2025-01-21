---
title: Travel and Adventures2
description: 
permalink: /travels2/
---



<h2>Travel Notes</h2>
<ul>
  {% assign travel_notes = site.notes | where_exp: "item", "item.tags contains '#travels'" | sort: "last_modified_at_timestamp" | reverse %}
  {% for note in travel_notes %}
    <li>
      <a class="internal-link" href="{{ site.baseurl }}{{ note.url }}">{{ note.title }}</a>
    </li>
  {% endfor %}
</ul>