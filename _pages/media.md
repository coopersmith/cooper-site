---
layout: page
title: Media Diet
id: media
permalink: /media/
---

# Media Diet

Everything I've been reading and watching, in one place.

{% assign entries = site.notes | where_exp: "n", "n.cover" | where_exp: "n", "n.path contains 'MediaDiet/'" | sort: "created" | reverse %}

<div class="media-toolbar">
  <span class="media-count">{{ entries | size }} entries</span>
  <div class="media-toggle" role="group" aria-label="View mode">
    <button type="button" class="media-view-btn is-active" data-view="list">List</button>
    <button type="button" class="media-view-btn" data-view="covers">Covers</button>
  </div>
</div>

<div id="media-library" class="view-list">

  <ul class="media-list">
    {% for e in entries %}
      {% assign type = 'Media' %}
      {% if e.path contains '/Books/' %}{% assign type = 'Book' %}
      {% elsif e.path contains '/Movies/' %}{% assign type = 'Movie' %}
      {% elsif e.path contains '/Shows/' or e.path contains '/TV/' %}{% assign type = 'Show' %}
      {% endif %}
      {% if e.type %}{% assign type = e.type %}{% endif %}
      {% assign clean_title = e.title | replace: '📚 ', '' | replace: '🎬 ', '' | replace: '📺 ', '' | replace: '🦖 ', '' %}
      {% assign creator = '' %}
      {% if e.author %}{% assign creator = e.author | join: ', ' | replace: '[[', '' | replace: ']]', '' %}
      {% elsif e.director %}{% assign creator = e.director | join: ', ' | replace: '[[', '' | replace: ']]', '' %}{% endif %}
      <li class="media-row">
        <a class="internal-link media-row-title" href="{{ site.baseurl }}{{ e.url }}">{{ clean_title }}</a>
        <span class="media-row-meta">
          <span class="media-type media-type--{{ type | downcase }}">{{ type }}</span>
          {% if creator != '' %}<span class="media-creator">{{ creator }}</span>{% endif %}
          {% if e.year %}<span class="media-year">{{ e.year }}</span>{% endif %}
          {% if e.rating %}<span class="media-rating">Rated {{ e.rating }}</span>{% endif %}
        </span>
      </li>
    {% endfor %}
  </ul>

  <ul class="media-grid">
    {% for e in entries %}
      {% assign clean_title = e.title | replace: '📚 ', '' | replace: '🎬 ', '' | replace: '📺 ', '' | replace: '🦖 ', '' %}
      <li class="media-card">
        <a href="{{ site.baseurl }}{{ e.url }}" title="{{ clean_title }}">
          <img class="media-cover" src="{{ e.cover }}" alt="Cover of {{ clean_title }}" loading="lazy" />
          <span class="media-card-title">{{ clean_title }}</span>
        </a>
      </li>
    {% endfor %}
  </ul>

</div>

<style>
  .wrapper { max-width: 46em; }

  .media-toolbar {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin: 2em 0 1.4em;
    gap: 1em;
  }

  .media-count {
    font-size: var(--text-caption);
    text-transform: uppercase;
    letter-spacing: var(--tracking-caps);
    color: var(--color-text-tertiary);
    font-weight: var(--weight-medium);
  }

  .media-toggle {
    display: inline-flex;
    border: 1px solid var(--color-border, rgba(128,128,128,0.3));
    border-radius: 999px;
    overflow: hidden;
  }

  .media-view-btn {
    appearance: none;
    border: 0;
    background: transparent;
    color: var(--color-text-tertiary);
    font: inherit;
    font-size: var(--text-ui, 0.9em);
    padding: 0.3em 0.9em;
    cursor: pointer;
    transition: background 0.15s ease, color 0.15s ease;
  }

  .media-view-btn.is-active {
    background: var(--color-accent, #555);
    color: #fff;
  }

  /* Toggle visibility driven by the container class */
  .media-list, .media-grid { list-style: none; margin: 0; padding: 0; }

  #media-library.view-list .media-grid { display: none; }
  #media-library.view-covers .media-list { display: none; }

  /* ---- List view ---- */
  .media-row {
    display: flex;
    flex-wrap: wrap;
    align-items: baseline;
    gap: 0.5em 0.7em;
    padding: 0.55em 0;
    border-bottom: 1px solid var(--color-border, rgba(128,128,128,0.12));
  }

  .media-row-title {
    text-decoration: none;
    font-weight: var(--weight-medium);
    color: var(--color-text-primary);
  }
  .media-row-title:hover {
    text-decoration: underline;
    text-decoration-color: var(--color-accent);
  }

  .media-row-meta {
    display: inline-flex;
    align-items: baseline;
    flex-wrap: wrap;
    gap: 0.7em;
    font-size: 0.9em;
    color: var(--color-text-subtle);
  }

  .media-type {
    font-size: 0.72em;
    text-transform: uppercase;
    letter-spacing: var(--tracking-caps);
    font-weight: var(--weight-medium);
    color: var(--color-text-tertiary);
    border: 1px solid var(--color-border, rgba(128,128,128,0.3));
    border-radius: 4px;
    padding: 0.05em 0.45em;
  }

  .media-year { font-variant-numeric: tabular-nums; }

  /* ---- Covers view ---- */
  .media-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
    gap: 1.4em 1.1em;
  }

  .media-card a {
    display: block;
    text-decoration: none;
    color: var(--color-text-secondary, var(--color-text-tertiary));
  }

  .media-cover {
    display: block;
    width: 100%;
    aspect-ratio: 2 / 3;
    object-fit: cover;
    border-radius: 4px;
    background: var(--color-border, rgba(128,128,128,0.12));
    box-shadow: 0 2px 8px rgba(0,0,0,0.18);
    transition: transform 0.15s ease;
  }
  .media-card a:hover .media-cover { transform: translateY(-3px); }

  .media-card-title {
    display: block;
    margin-top: 0.5em;
    font-size: 0.82em;
    line-height: var(--leading-snug, 1.3);
    color: var(--color-text-subtle);
  }

  @media (max-width: 600px) {
    .media-grid { grid-template-columns: repeat(auto-fill, minmax(90px, 1fr)); }
  }
</style>

<script>
  (function () {
    var lib = document.getElementById('media-library');
    var btns = document.querySelectorAll('.media-view-btn');
    if (!lib || !btns.length) return;

    function setView(view) {
      lib.classList.remove('view-list', 'view-covers');
      lib.classList.add('view-' + view);
      btns.forEach(function (b) {
        b.classList.toggle('is-active', b.dataset.view === view);
      });
      try { localStorage.setItem('mediaView', view); } catch (e) {}
    }

    btns.forEach(function (b) {
      b.addEventListener('click', function () { setView(b.dataset.view); });
    });

    var saved;
    try { saved = localStorage.getItem('mediaView'); } catch (e) {}
    if (saved === 'covers' || saved === 'list') setView(saved);
  })();
</script>
