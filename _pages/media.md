---
layout: page
title: Media Diet
id: media
permalink: /media/
---

# Media Diet

Everything I've been reading, watching, and listening to — in one place.

{% assign entries = site.notes | where_exp: "n", "n.cover" | where_exp: "n", "n.path contains 'MediaDiet/'" | sort: "created" | reverse %}

<div class="media-toolbar">
  <div class="media-filters" role="group" aria-label="Filter by type">
    <button type="button" class="media-chip is-active" data-filter="all">All</button>
    <button type="button" class="media-chip media-chip--book" data-filter="book">Books</button>
    <button type="button" class="media-chip media-chip--movie" data-filter="movie">Movies</button>
    <button type="button" class="media-chip media-chip--album" data-filter="album">Albums</button>
  </div>
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
      {% elsif e.path contains '/Albums/' %}{% assign type = 'Album' %}
      {% elsif e.path contains '/Shows/' or e.path contains '/TV/' %}{% assign type = 'Show' %}
      {% endif %}
      {% if e.type %}{% assign type = e.type %}{% endif %}
      {% assign clean_title = e.title | replace: '📚 ', '' | replace: '🎬 ', '' | replace: '📺 ', '' | replace: '🦖 ', '' %}
      {% assign creator = '' %}
      {% if e.author %}{% assign creator = e.author | join: ', ' %}
      {% elsif e.director %}{% assign creator = e.director | join: ', ' %}
      {% elsif e.artist %}{% assign creator = e.artist | join: ', ' %}{% endif %}
      {% assign creator = creator | replace: '[', '' | replace: ']', '' | replace: '  ', ' ' | strip %}
      <li class="media-row" data-type="{{ type | downcase }}">
        <a class="internal-link media-row-title" href="{{ site.baseurl }}{{ e.url }}">{{ clean_title }}</a>
        <span class="media-row-meta">
          <span class="media-type media-type--{{ type | downcase }}">{{ type }}</span>
          {% if creator != '' %}<span class="media-creator">{{ creator }}</span>{% endif %}
          {% if e.year %}<span class="media-year">{{ e.year }}</span>{% endif %}
          {% if e.rating %}<span class="media-rating">★ {{ e.rating }}</span>{% endif %}
        </span>
      </li>
    {% endfor %}
  </ul>

  <ul class="media-grid">
    {% for e in entries %}
      {% assign type = 'Media' %}
      {% if e.path contains '/Books/' %}{% assign type = 'Book' %}
      {% elsif e.path contains '/Movies/' %}{% assign type = 'Movie' %}
      {% elsif e.path contains '/Albums/' %}{% assign type = 'Album' %}
      {% elsif e.path contains '/Shows/' or e.path contains '/TV/' %}{% assign type = 'Show' %}
      {% endif %}
      {% if e.type %}{% assign type = e.type %}{% endif %}
      {% assign clean_title = e.title | replace: '📚 ', '' | replace: '🎬 ', '' | replace: '📺 ', '' | replace: '🦖 ', '' %}
      <li class="media-card" data-type="{{ type | downcase }}">
        <a href="{{ site.baseurl }}{{ e.url }}" title="{{ clean_title }}">
          <span class="media-cover-wrap">
            <img class="media-cover" src="{{ e.cover }}" alt="Cover of {{ clean_title }}" loading="lazy" />
            <span class="media-type media-type--{{ type | downcase }} media-type--corner">{{ type }}</span>
          </span>
          <span class="media-card-title">{{ clean_title }}</span>
        </a>
      </li>
    {% endfor %}
  </ul>

</div>

<style>
  .wrapper { max-width: 46em; }

  /* Per-type accent colors */
  #media-library, .media-toolbar {
    --type-book: #2a9d8f;
    --type-movie: #e76f51;
    --type-album: #6a67ce;
    --type-show: #e9c46a;
    --type-media: var(--color-text-tertiary);
  }

  .media-toolbar {
    display: flex;
    align-items: center;
    justify-content: space-between;
    flex-wrap: wrap;
    gap: 0.8em 1em;
    margin: 2em 0 1.4em;
  }

  .media-filters { display: inline-flex; flex-wrap: wrap; gap: 0.4em; }

  .media-chip {
    appearance: none;
    border: 1px solid var(--color-border, rgba(128,128,128,0.3));
    background: transparent;
    color: var(--color-text-tertiary);
    font: inherit;
    font-size: 0.82em;
    padding: 0.25em 0.75em;
    border-radius: 999px;
    cursor: pointer;
    transition: background 0.15s ease, color 0.15s ease, border-color 0.15s ease;
  }
  .media-chip:hover { color: var(--color-text-primary); }
  .media-chip.is-active { background: var(--color-text-primary); color: var(--color-bg, #fff); border-color: var(--color-text-primary); }
  .media-chip--book.is-active { background: var(--type-book); border-color: var(--type-book); color: #fff; }
  .media-chip--movie.is-active { background: var(--type-movie); border-color: var(--type-movie); color: #fff; }
  .media-chip--album.is-active { background: var(--type-album); border-color: var(--type-album); color: #fff; }

  .media-toggle {
    display: inline-flex;
    border: 1px solid var(--color-border, rgba(128,128,128,0.3));
    border-radius: 999px;
    overflow: hidden;
  }
  .media-view-btn {
    appearance: none; border: 0; background: transparent;
    color: var(--color-text-tertiary); font: inherit; font-size: 0.82em;
    padding: 0.3em 0.9em; cursor: pointer;
    transition: background 0.15s ease, color 0.15s ease;
  }
  .media-view-btn.is-active { background: var(--color-accent, #555); color: #fff; }

  /* Type badge — prominent, color-coded */
  .media-type {
    display: inline-block;
    font-size: 0.66em;
    text-transform: uppercase;
    letter-spacing: var(--tracking-caps);
    font-weight: 700;
    color: #fff;
    background: var(--type-media);
    border-radius: 4px;
    padding: 0.18em 0.5em;
    vertical-align: middle;
  }
  .media-type--book { background: var(--type-book); }
  .media-type--movie { background: var(--type-movie); }
  .media-type--album { background: var(--type-album); }
  .media-type--show { background: var(--type-show); color: #3a2f00; }

  .media-list, .media-grid { list-style: none; margin: 0; padding: 0; }
  #media-library.view-list .media-grid { display: none; }
  #media-library.view-covers .media-list { display: none; }
  .is-hidden { display: none !important; }

  /* ---- List view ---- */
  .media-row {
    display: flex; flex-wrap: wrap; align-items: baseline; gap: 0.5em 0.7em;
    padding: 0.6em 0;
    border-bottom: 1px solid var(--color-border, rgba(128,128,128,0.12));
  }
  .media-row-title {
    text-decoration: none; font-weight: var(--weight-medium);
    color: var(--color-text-primary);
  }
  .media-row-title:hover { text-decoration: underline; text-decoration-color: var(--color-accent); }
  .media-row-meta {
    display: inline-flex; align-items: baseline; flex-wrap: wrap; gap: 0.7em;
    font-size: 0.9em; color: var(--color-text-subtle);
  }
  .media-year { font-variant-numeric: tabular-nums; }
  .media-rating { color: var(--color-text-tertiary); }

  /* ---- Covers view ---- */
  .media-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
    gap: 1.4em 1.1em;
  }
  .media-card a { display: block; text-decoration: none; color: var(--color-text-subtle); }
  .media-cover-wrap { position: relative; display: block; }
  .media-cover {
    display: block; width: 100%; aspect-ratio: 2 / 3; object-fit: cover;
    border-radius: 4px; background: var(--color-border, rgba(128,128,128,0.12));
    box-shadow: 0 2px 8px rgba(0,0,0,0.18); transition: transform 0.15s ease;
  }
  .media-card a:hover .media-cover { transform: translateY(-3px); }
  .media-type--corner { position: absolute; top: 0.4em; left: 0.4em; box-shadow: 0 1px 3px rgba(0,0,0,0.3); }
  .media-card-title {
    display: block; margin-top: 0.5em; font-size: 0.82em;
    line-height: var(--leading-snug, 1.3); color: var(--color-text-subtle);
  }

  @media (max-width: 600px) {
    .media-grid { grid-template-columns: repeat(auto-fill, minmax(90px, 1fr)); }
  }
</style>

<script>
  (function () {
    var lib = document.getElementById('media-library');
    if (!lib) return;
    var viewBtns = document.querySelectorAll('.media-view-btn');
    var chips = document.querySelectorAll('.media-chip');

    function setView(view) {
      lib.classList.remove('view-list', 'view-covers');
      lib.classList.add('view-' + view);
      viewBtns.forEach(function (b) { b.classList.toggle('is-active', b.dataset.view === view); });
      try { localStorage.setItem('mediaView', view); } catch (e) {}
    }

    function setFilter(type) {
      lib.querySelectorAll('[data-type]').forEach(function (el) {
        el.classList.toggle('is-hidden', type !== 'all' && el.dataset.type !== type);
      });
      chips.forEach(function (c) { c.classList.toggle('is-active', c.dataset.filter === type); });
    }

    viewBtns.forEach(function (b) { b.addEventListener('click', function () { setView(b.dataset.view); }); });
    chips.forEach(function (c) { c.addEventListener('click', function () { setFilter(c.dataset.filter); }); });

    var saved;
    try { saved = localStorage.getItem('mediaView'); } catch (e) {}
    if (saved === 'covers' || saved === 'list') setView(saved);
  })();
</script>
