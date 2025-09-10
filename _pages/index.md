---
layout: page
title: Home
id: home
permalink: /
---

# Hey, I'm Cooper

I split my time between Brooklyn, NY and Rhode Island's [Farm Coast.](https://www.nytimes.com/2023/10/09/travel/east-bay-rhode-island.html) 

When I'm in NYC, I'm a Director of Product Design at Asana, where I lead design for our Align organization, as well as our Mobile organization. I have over a decade of experience building products and teams at Lyft, Twitter, Foursquare [among others](https://read.cv/coops). 

When I'm in Rhode Island, I look after our 1754 farmhouse and roast coffee in my barn and run a small micro-roastery called [Farm Coast Coffee](https://farmcoastcoffee.square.site) as a fun side project.

I'm rarely without a camera, and share my adventures on [Instagram](https://www.instagram.com/coopersmith) and [Glass](https://glass.photo/coop). 

<div id="recently-played">
  <p>Loading recently played tracks...</p>
</div>

<!-- <div id="last-checkin">
  <p>Loading last location...</p>
</div> -->

{% comment %} Featured Notes {% endcomment %}
{% assign featured_notes = site.notes | where: "featured", true %}
{% if featured_notes.size > 0 %}
<div class="featured-notes">
  {% include notes-list.html 
     notes=featured_notes 
     title="Featured Notes" 
     limit=3 
     show_excerpt=true 
     show_tags=true 
     compact=true %}
</div>
{% endif %}

{% comment %} Recent Updates {% endcomment %}
{% include notes-list.html 
   notes=site.notes 
   title="Recently Updated" 
   subtitle="My latest thoughts and explorations"
   limit=5 
   show_excerpt=false 
   show_tags=true 
   exclude_path="Concerts" 
   show_more_link="/tableofcontents" 
   show_more_text="notes" %}

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
