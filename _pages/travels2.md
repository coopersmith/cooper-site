---
layout: page
title: Travel and Adventures
permalink: /travels2/
---

# Travel and Adventures

A collection of my travels, adventures, and explorations around the world.

## Recent Adventures

{% comment %} Get all travel notes and sort by year {% endcomment %}
{% assign travel_notes = site.notes | where_exp: "item", "item.tags contains '#travel' or item.tags contains 'travel'" | sort: "year" | reverse %}

{% if travel_notes.size > 0 %}
<div class="travel-grid">
  {% for trip in travel_notes %}
    <div class="travel-item">
      <div class="travel-year">{{ trip.year }}</div>
      <div class="travel-content">
        <h3><a href="{{ site.baseurl }}{{ trip.url }}">{{ trip.title }}</a></h3>
        {% if trip.subtitle %}
          <p class="travel-subtitle">{{ trip.subtitle }}</p>
        {% endif %}
        {% if trip.start and trip.end %}
          <p class="travel-dates">
            {{ trip.start | date: "%B %d" }} - {{ trip.end | date: "%B %d, %Y" }}
          </p>
        {% elsif trip.start %}
          <p class="travel-dates">{{ trip.start | date: "%B %Y" }}</p>
        {% endif %}
        {% if trip.loc %}
          <div class="travel-locations">
            {% for location in trip.loc %}
              <span class="travel-location">📍 {{ location | remove: "[[" | remove: "]]" }}</span>
            {% endfor %}
          </div>
        {% endif %}
        {% if trip.excerpt %}
          <p class="travel-excerpt">{{ trip.excerpt | strip_html | truncatewords: 25 }}</p>
        {% endif %}
      </div>
    </div>
  {% endfor %}
</div>
{% else %}
<p><em>No travel adventures logged yet.</em></p>
{% endif %}

## City Guides

{% comment %} Get city guide notes {% endcomment %}
{% assign city_guides = site.notes | where_exp: "item", "item.path contains 'City-Guides'" | sort: "title" %}

{% if city_guides.size > 0 %}
{% include basic-notes-list.html 
   notes=city_guides 
   title="City Guides & Local Recommendations" 
   subtitle="Local insights and recommendations from places I've explored" %}
{% endif %}

## Travel Stats

{% assign total_trips = travel_notes.size %}
{% assign unique_years = travel_notes | map: "year" | uniq | size %}
{% assign recent_trips = travel_notes | where_exp: "item", "item.year >= 2020" | size %}

<div class="travel-stats">
  <div class="stat-item">
    <span class="stat-number">{{ total_trips }}</span>
    <span class="stat-label">Total Adventures</span>
  </div>
  <div class="stat-item">
    <span class="stat-number">{{ unique_years }}</span>
    <span class="stat-label">Years of Travel</span>
  </div>
  <div class="stat-item">
    <span class="stat-number">{{ recent_trips }}</span>
    <span class="stat-label">Since 2020</span>
  </div>
</div>

---

<small>Each adventure is documented with photos, stories, and reflections from my journeys around the world.</small>