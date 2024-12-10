---
layout: page
title: Home
id: home
permalink: /
---

# Hey, I'm Cooper


I'm a Director of Product Design at Asana. I have over a decade of experience building products and teams at Lyft, Twitter, Foursquare [among others](https://read.cv/coops). 

I also roast coffee out of my barn and run a small micro-roastery called [Farm Coast Coffee](https://farmcoastcoffee.com/) as a fun side project.

I split my time between Brooklyn, NY and our 1754 farmhouse on the [Rhode Island Farm Coast.](https://www.nytimes.com/2023/10/09/travel/east-bay-rhode-island.html)

I'm rarely without a camera, and share my adventures on [Instagram](https://www.instagram.com/coopersmith) and [Glass](https://glass.photo/coop).

I will forever be in a struggle of levaraging the amazing tools available to us throughout the web, or rolling my own version of them. To that end, this site is a bit of experiment of bringing a bit more of those "in house". Below please find my:

<strong>Recently updated notes</strong>

<ul>
  {% assign recent_notes = site.notes | sort: "last_modified_at_timestamp" | reverse %}
  {% for note in recent_notes limit: 5 %}
    <li>
      {{ note.last_modified_at | date: "%Y-%m-%d" }} — <a class="internal-link" href="{{ site.baseurl }}{{ note.url }}">{{ note.title }}</a>
    </li>
  {% endfor %}
</ul>

<style>
  .wrapper {
    max-width: 46em;
  }
</style>
