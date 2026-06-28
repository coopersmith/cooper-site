---
layout: page
title: Home
id: home
permalink: /
---

# Hey, I'm Cooper

I split my time between Brooklyn, NY and Rhode Island's [Farm Coast.](https://www.nytimes.com/2023/10/09/travel/east-bay-rhode-island.html) 

When I'm in NYC, I'm a Director of Product Design at Asana, where I lead design for our Align and Mobile organizations. I have over a decade of experience building products and teams at [[Lyft]], [[Twitter]], [[Foursquare]] and [[Asana]].

When I'm in Rhode Island, I look after our 1754 farmhouse. I roast coffee in my barn and run a small micro-roastery called [Farm Coast Coffee](https://farmcoastcoffee.square.site) as a fun side project.

I'm rarely without a camera, and share my adventures on [Instagram](https://www.instagram.com/coopersmith) and [Glass](https://glass.photo/coop). 

<section class="home-section">
  <p class="home-label">Recent notes</p>
  <ul class="home-list">
    {% assign all_notes = site.notes | sort: "created_at_timestamp" | reverse %}
    {% assign count = 0 %}
    {% for note in all_notes %}
      {% unless note.path contains 'Concerts' %}
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
</section>

<section class="home-section">
  <p class="home-label">Elsewhere</p>
  <ul class="home-list">
    <li><a href="{{ site.baseurl }}/travels/">Travels</a> <span class="desc">— adventures and misadventures around the world.</span></li>
    <li><a href="{{ site.baseurl }}/photos/">Photos</a> <span class="desc">— urban geometry, the farm, and Henry the lab.</span></li>
    <li><a href="{{ site.baseurl }}/2025-reading-list/">Media Diet</a> <span class="desc">— what I'm reading, watching, and listening to.</span></li>
    <li><a href="{{ site.baseurl }}/concerts">Concerts</a> <span class="desc">— shows I've caught, in roughly the order I caught them.</span></li>
    <li><a href="{{ site.baseurl }}/about">About</a> <span class="desc">— the longer version, and where to find me.</span></li>
  </ul>
</section>

<section class="home-section">
  <p class="home-label">Lately</p>
  <div id="recently-played">
    <p>Loading recently played tracks…</p>
  </div>
</section>

<style>
  .wrapper { max-width: 46em; }

  .home-section { margin-top: 3em; }

  .home-label {
    font-size: var(--text-caption);
    text-transform: uppercase;
    letter-spacing: var(--tracking-caps);
    color: var(--color-text-tertiary);
    font-weight: var(--weight-medium);
    margin: 0 0 0.9em;
  }

  .home-list {
    list-style: none;
    margin: 0;
    padding: 0;
  }

  .home-list li {
    margin: 0;
    line-height: var(--leading-relaxed);
  }

  .home-list li + li {
    margin-top: 0.7em;
  }

  .home-list .date {
    display: inline-block;
    min-width: 4.5em;
    margin-right: 0.4em;
    color: var(--color-text-tertiary);
    font-size: 0.92em;
    font-variant-numeric: tabular-nums;
  }

  .home-list a {
    text-decoration: none;
    font-weight: var(--weight-medium);
    color: var(--color-text-primary);
    text-decoration-color: transparent;
  }

  .home-list a:hover {
    text-decoration: underline;
    text-decoration-color: var(--color-accent);
  }

  .home-list .desc {
    color: var(--color-text-subtle);
  }

  #recently-played p {
    margin: 0;
    color: var(--color-text-subtle);
  }

  @media (max-width: 600px) {
    .home-list .date { display: block; min-width: 0; margin-bottom: 0.1em; }
  }
</style>

<script src="{{ site.baseurl }}/assets/js/lastfm.js"></script>
