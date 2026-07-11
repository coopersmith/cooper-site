---
layout: page
title: Home
id: home
permalink: /
---

# Hey, I'm Cooper

I split my time between Brooklyn, NY and Rhode Island's [Farm Coast](https://www.nytimes.com/2023/10/09/travel/east-bay-rhode-island.html).
{: #intro-lead-neutral}

I'm currently in Brooklyn, NY, though I spend equal time on Rhode Island's [Farm Coast](https://www.nytimes.com/2023/10/09/travel/east-bay-rhode-island.html).
{: #intro-lead-nyc .loc-alt}

I'm currently on Rhode Island's [Farm Coast](https://www.nytimes.com/2023/10/09/travel/east-bay-rhode-island.html), though I spend equal time in Brooklyn, NY.
{: #intro-lead-ri .loc-alt}

I'm currently traveling<span id="travel-place"></span> — follow the adventures on [Instagram](https://www.instagram.com/coopersmith).
{: #intro-lead-travel .loc-alt}

When I'm in NYC, I'm a Director of Product Design at Asana, where I lead design for our Align and Mobile organizations. I have over a decade of experience building products and teams at [[Lyft]], [[Twitter]], [[Foursquare]] and [[Asana]].
{: #intro-nyc}

When I'm in Rhode Island, I look after our 1754 farmhouse and work remotely for Asana. I roast coffee in my barn and run a small micro-roastery called [Farm Coast Coffee](https://farmcoastcoffee.square.site) as a fun side project.
{: #intro-ri}

I'm rarely without a camera, and share my adventures on [Instagram](https://www.instagram.com/coopersmith) and [Glass](https://glass.photo/coop). 

<section class="home-section">
  <p class="home-label">Recent notes</p>
  <ul class="home-list">
    {% assign all_notes = site.notes | sort: "created_at_timestamp" | reverse %}
    {% assign count = 0 %}
    {% for note in all_notes %}
      {% unless note.path contains 'Concerts' or note.path contains 'MediaDiet' or note.path contains 'Travel' %}
        {% if count < 5 %}
          <li>
            <span class="date">{{ note.created_at | date: "%b %Y" }}</span>
            <a class="internal-link" href="{{ site.baseurl }}{{ note.url }}">{{ note.title }}</a>
          </li>
          {% assign count = count | plus: 1 %}
        {% endif %}
      {% endunless %}
    {% endfor %}
  </ul>
  <p class="home-more"><a class="internal-link" href="{{ site.baseurl }}/notes/">See more →</a></p>
</section>

<section class="home-section">
  <p class="home-label">Elsewhere</p>
  <ul class="home-list">
    <li><a class="internal-link" href="{{ site.baseurl }}/travels/">Travels</a> <span class="desc">— adventures around the world.</span></li>
    <li><a class="internal-link" href="{{ site.baseurl }}/photos/">Visual Diary</a> <span class="desc">— my life through my lens.</span></li>
    <li><a class="internal-link" href="{{ site.baseurl }}/media/">Media Diet</a> <span class="desc">— what I'm reading, watching, and listening to.</span></li>
    <li><a class="internal-link" href="{{ site.baseurl }}/highlights">Commonplace</a> <span class="desc">— passages I've marked while reading.</span></li>
    <li><a class="internal-link" href="{{ site.baseurl }}/about">About</a> <span class="desc">— the longer version, and where to find me.</span></li>
  </ul>
</section>

<section class="home-section">
  <p class="home-label">Lately</p>
  <div id="recently-played">
    <p>Loading recently played tracks…</p>
  </div>
  <div id="last-checkin"></div>
</section>

<script src="{{ site.baseurl }}/assets/js/lastfm.js"></script>
<script src="{{ site.baseurl }}/assets/js/foursquare.js"></script>
