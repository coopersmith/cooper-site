---
title: Concerts and Live Music
description: A running list of concerts attended
permalink: /concerts/
---

<h2>A running list of concerts I've attended, with setlists if available</h2>

<!-- Concert Statistics -->
<div class="concert-stats">
  <h3>Statistics</h3>
  
  <!-- Most Seen Artists -->
  <div class="stat-block">
    <h4>Most Seen Artists</h4>
    {% assign artists_count = {} %}
    {% assign concert_notes = site.notes | where_exp: "item", "item.tags contains 'concerts'" %}
    
    {% for note in concert_notes %}
      {% if note.Artists %}
        {% for artist in note.Artists %}
          {% assign artist_name = artist | replace: "[[", "" | replace: "]]", "" %}
          {% assign count = artists_count[artist_name] | default: 0 | plus: 1 %}
          {% assign artists_count = artists_count | merge: {artist_name: count} %}
        {% endfor %}
      {% endif %}
    {% endfor %}
    
    {% assign artists_array = "" %}
    {% for artist in artists_count %}
      {% assign artist_entry = artist[1] | append: ":" | append: artist[0] | append: "," %}
      {% assign artists_array = artists_array | append: artist_entry %}
    {% endfor %}
    {% assign sorted_artists = artists_array | split: "," | sort | reverse %}
    
    <ul>
      {% for artist_entry in sorted_artists limit:5 %}
        {% if artist_entry != "" %}
          {% assign artist_parts = artist_entry | split: ":" %}
          {% assign artist_count = artist_parts[0] %}
          {% assign artist_name = artist_parts[1] %}
          <li>{{ artist_name }} - {{ artist_count }} {% if artist_count > 1 %}times{% else %}time{% endif %}</li>
        {% endif %}
      {% endfor %}
    </ul>
  </div>
  
  <!-- Most Visited Venues -->
  <div class="stat-block">
    <h4>Most Visited Venues</h4>
    {% assign venues_count = {} %}
    
    {% for note in concert_notes %}
      {% if note.Venue %}
        {% assign venue_name = note.Venue %}
        {% assign count = venues_count[venue_name] | default: 0 | plus: 1 %}
        {% assign venues_count = venues_count | merge: {venue_name: count} %}
      {% endif %}
    {% endfor %}
    
    {% assign venues_array = "" %}
    {% for venue in venues_count %}
      {% assign venue_entry = venue[1] | append: ":" | append: venue[0] | append: "," %}
      {% assign venues_array = venues_array | append: venue_entry %}
    {% endfor %}
    {% assign sorted_venues = venues_array | split: "," | sort | reverse %}
    
    <ul>
      {% for venue_entry in sorted_venues limit:5 %}
        {% if venue_entry != "" %}
          {% assign venue_parts = venue_entry | split: ":" %}
          {% assign venue_count = venue_parts[0] %}
          {% assign venue_name = venue_parts[1] %}
          <li>{{ venue_name }} - {{ venue_count }} {% if venue_count > 1 %}times{% else %}time{% endif %}</li>
        {% endif %}
      {% endfor %}
    </ul>
  </div>
  
  <!-- Concerts By Year -->
  <div class="stat-block">
    <h4>Concerts By Year</h4>
    {% assign years_count = {} %}
    
    {% for note in concert_notes %}
      {% if note.Dates %}
        {% assign year = note.Dates | date: "%Y" %}
        {% assign count = years_count[year] | default: 0 | plus: 1 %}
        {% assign years_count = years_count | merge: {year: count} %}
      {% endif %}
    {% endfor %}
    
    {% assign years_array = "" %}
    {% for year in years_count %}
      {% assign year_entry = year[1] | append: ":" | append: year[0] | append: "," %}
      {% assign years_array = years_array | append: year_entry %}
    {% endfor %}
    {% assign sorted_years = years_array | split: "," | sort | reverse %}
    
    <ul>
      {% for year_entry in sorted_years limit:5 %}
        {% if year_entry != "" %}
          {% assign year_parts = year_entry | split: ":" %}
          {% assign year_count = year_parts[0] %}
          {% assign year_name = year_parts[1] %}
          <li>{{ year_name }} - {{ year_count }} {% if year_count > 1 %}concerts{% else %}concert{% endif %}</li>
        {% endif %}
      {% endfor %}
    </ul>
  </div>
</div>

<div class="notes-entry-container">
  {% assign concert_notes = site.notes | where_exp: "item", "item.tags contains 'concerts'" | sort: "Dates" | reverse %}
  {% for note in concert_notes %}
    <div class="notes-entry">
      <a class="internal-link" href="{{ site.baseurl }}{{ note.url }}">{{ note.title }}</a>
      <span class="notes-entry-date">&nbsp;&mdash;&nbsp;{{ note.Dates | date: "%B %d, %Y" }}</span>
    </div>
  {% endfor %}
</div>