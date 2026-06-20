---
layout: page
title: ToC
id: tableofcontents
permalink: /tableofcontents/
---



<strong>My recently created notes</strong>

<!-- <h3>Recently Created</h3> -->
<ul>
  {% assign recent_notes = site.notes | sort: "created_at_timestamp" | reverse %}
  {% for note in recent_notes limit: 500 %}
    <li>
      {{ note.created_at | date: "%Y-%m-%d" }} — <a class="internal-link" href="{{ site.baseurl }}{{ note.url }}">{{ note.title }}</a>
    </li>
  {% endfor %}
</ul>
<style>
  .wrapper {
    max-width: 46em;
  }
</style>
