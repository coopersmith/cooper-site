---
layout: page
title: Home
id: home
permalink: /
---

# Hey, I'm Cooper

I split my time between Brooklyn, NY and Rhode Island's Farm Coast.

When I'm in NYC, I'm a Director of Product Design at Asana, where I lead design for our Align organization, as well as our Mobile organization. I have over a decade of experience building products and teams at Lyft, Twitter, Foursquare [among others](https://read.cv/coops). 

When I'm in Rhode Island, I'm in our 1754 farmhouse on the [Rhode Island Farm Coast.](https://www.nytimes.com/2023/10/09/travel/east-bay-rhode-island.html). I also roast coffee out of my barn and run a small micro-roastery called [Farm Coast Coffee](https://farmcoastcoffee.square.site) as a fun side project.

I'm rarely without a camera, and share my adventures on [Instagram](https://www.instagram.com/coopersmith) and [Glass](https://glass.photo/coop).

<div id="recently-played">
  <p>Loading recently played tracks...</p>
</div>

<!-- <div id="last-checkin">
  <p>Loading last location...</p>
</div> -->

<strong>My recently updated notes</strong>

<!-- <h3>Recently Updated</h3> -->
<ul>
  {% assign recent_notes = site.notes | sort: "last_modified_at_timestamp" | reverse %}
  {% for note in recent_notes limit: 5 %}
    <li>
      {{ note.last_modified_at | date: "%Y-%m-%d" }} — <a class="internal-link" href="{{ site.baseurl }}{{ note.url }}">{{ note.title }}</a>
    </li>
  {% endfor %}
</ul>

<!-- <h3>Recently Created</h3>
<ul>
  {% assign new_notes = site.notes | sort: "created_at_timestamp" | reverse %}
  {% for note in new_notes limit: 5 %}
    <li>
      {{ note.created_at | date: "%Y-%m-%d" }} — <a class="internal-link" href="{{ site.baseurl }}{{ note.url }}">{{ note.title }}</a>
    </li>
  {% endfor %}
</ul>
-->
<style>
  .wrapper {
    max-width: 46em;
  }
</style>

<script src="{{ site.baseurl }}/assets/js/lastfm.js"></script>
<!-- <script src="{{ site.baseurl }}/assets/js/foursquare.js"></script> -->
