---
title: Travel and Adventures2
description: 
permalink: /travels2/
---

<style>
  .wrapper {
    max-width: 46em;
  }
  .notes-entry {
    margin-bottom: 3em;
    text-align: center;
  }
  .notes-entry-thumbnail {
    width: 300px;
    height: 250px;
    object-fit: cover;
    border-radius: 4px;
    margin-bottom: 1em;
  }
  .notes-entry-content {
    margin-top: 0.5em;
  }
  .notes-entry-title {
    font-size: 1.2em;
    display: block;
    margin-bottom: 0.3em;
  }
  .notes-entry-date {
    color: #666;
  }
</style>

<h2>Travels and Adventures</h2>

<div class="notes-entry-container">
  {% assign travel_notes = site.notes | where_exp: "item", "item.tags contains '#travel'" | sort: "year" | reverse %}
  {% for note in travel_notes %}
    <div class="notes-entry">
      {% if note.content contains "<img" %}
        {% assign images = note.content | split: '<img ' %}
        {% assign first_image = images[1] | split: '>' | first %}
        {% assign src = first_image | split: 'src="' | last | split: '"' | first %}
        <img class="notes-entry-thumbnail" src="{{ src }}" alt="{{ note.title }}">
      {% endif %}
      <div class="notes-entry-content">
        <a class="internal-link notes-entry-title" href="{{ site.baseurl }}{{ note.url }}">{{ note.title }}</a>
        <span class="notes-entry-date">{{ note.year }}</span>
      </div>
    </div>
  {% endfor %}
</div>