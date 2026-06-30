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
    <button type="button" class="tag is-active" data-filter="all">All</button>
    <button type="button" class="tag" data-filter="book">Books</button>
    <button type="button" class="tag" data-filter="movie">Movies</button>
    <button type="button" class="tag" data-filter="album">Albums</button>
  </div>
  <div class="media-toggle" role="group" aria-label="View mode">
    <button type="button" class="media-view-btn is-active" data-view="list">List</button>
    <button type="button" class="media-view-btn" data-view="covers">Covers</button>
  </div>
</div>

<div id="media-library" class="view-list">

  <table class="index-table media-list">
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
      <tr data-type="{{ type | downcase }}">
        <td class="index-title"><a class="internal-link" href="{{ site.baseurl }}{{ e.url }}">{{ clean_title }}</a></td>
        <td class="index-meta"><span class="tag">{{ type }}</span></td>
        <td class="index-meta muted">{{ creator }}</td>
        <td class="index-date muted">{% if e.year %}{{ e.year }}{% endif %}</td>
        <td class="index-date muted media-rating">{%- if e.rating -%}{%- assign filled = e.rating -%}{%- if filled > 7 -%}{%- assign filled = 7 -%}{%- endif -%}{%- assign unfilled = 7 | minus: filled -%}<span class="rating-marks" title="{{ e.rating }}/7" aria-label="{{ e.rating }} out of 7">{%- if filled > 0 -%}{%- for i in (1..filled) -%}◆{%- endfor -%}{%- endif -%}{%- if unfilled > 0 -%}{%- for i in (1..unfilled) -%}◇{%- endfor -%}{%- endif -%}</span>{%- endif -%}</td>
      </tr>
    {% endfor %}
  </table>

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
          <img class="media-cover" src="{{ e.cover }}" alt="Cover of {{ clean_title }}" loading="lazy" />
          <span class="media-card-meta">
            <span class="media-card-title">{{ clean_title }}</span>
            <span class="tag">{{ type }}</span>
          </span>
        </a>
      </li>
    {% endfor %}
  </ul>

</div>

<style>
  .wrapper { max-width: 46em; }

  /* `.tag` is defined globally (Slash Packaging style) in _sass/_style.scss */

  .media-toolbar {
    display: flex;
    align-items: center;
    justify-content: space-between;
    flex-wrap: wrap;
    gap: 0.7em 1em;
    margin: 2em 0 1.4em;
  }
  .media-filters { display: inline-flex; flex-wrap: wrap; gap: 0.4em; }

  .media-toggle {
    display: inline-flex;
    border: 1px solid var(--color-border);
    border-radius: 1em;
    overflow: hidden;
  }
  .media-view-btn {
    appearance: none; border: 0; background: transparent;
    color: var(--color-text-tertiary); font: inherit; font-size: 0.78em;
    padding: 0.3em 0.85em; cursor: pointer;
    transition: background 0.15s ease, color 0.15s ease;
  }
  .media-view-btn.is-active { background: var(--color-text-primary); color: var(--color-bg-primary); }

  .media-grid { list-style: none; margin: 0; padding: 0; }
  /* List view is a shared .index-table; sit it right under the toolbar */
  .media-list.index-table { margin: 0; }
  #media-library.view-list .media-grid { display: none; }
  #media-library.view-covers .media-list { display: none; }
  .is-hidden { display: none !important; }

  .rating-marks { letter-spacing: 0.12em; white-space: nowrap; font-size: 0.92em; }

  /* ---- Covers view ---- */
  .media-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
    gap: 1.6em 1.1em;
  }
  .media-card a { display: block; text-decoration: none; color: var(--color-text-subtle); }
  .media-cover {
    display: block; width: 100%; aspect-ratio: 2 / 3; object-fit: cover;
    border-radius: var(--border-radius, 4px); background: var(--color-bg-secondary);
    box-shadow: 0 2px 8px rgba(0,0,0,0.16); transition: transform 0.15s ease;
  }
  .media-card a:hover .media-cover { transform: translateY(-3px); }
  .media-card-meta {
    display: flex; align-items: baseline; justify-content: space-between; gap: 0.5em;
    margin-top: 0.55em;
  }
  .media-card-title {
    font-size: 0.82em; line-height: var(--leading-snug, 1.3);
    color: var(--color-text-subtle);
  }
  .media-card .tag { flex: none; }

  @media (max-width: 600px) {
    .media-grid { grid-template-columns: repeat(auto-fill, minmax(90px, 1fr)); }
  }
</style>

<script>
  (function () {
    var lib = document.getElementById('media-library');
    if (!lib) return;
    var viewBtns = document.querySelectorAll('.media-view-btn');
    var chips = document.querySelectorAll('.media-filters .tag');

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
