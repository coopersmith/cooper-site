---
layout: page
title: Media Diet
id: media
permalink: /media/
---

# Media Diet

Everything I've been reading, watching, listening to, and seeing live — in one place.

{% assign entries = site.notes | where_exp: "n", "n.cover" | where_exp: "n", "n.path contains 'MediaDiet/'" | sort: "created" | reverse %}
{% assign concerts = site.notes | where_exp: "n", "n.tags contains 'concerts'" | sort: "Dates" | reverse %}

<div class="media-toolbar">
  <div class="media-filters" role="group" aria-label="Filter by type">
    <button type="button" class="tag is-active" data-filter="all">All</button>
    <button type="button" class="tag" data-filter="book">Books</button>
    <button type="button" class="tag" data-filter="movie">Movies</button>
    <button type="button" class="tag" data-filter="album">Albums</button>
    <button type="button" class="tag" data-filter="concert">Live</button>
    <select class="sort-select media-filter-select" aria-label="Filter by type">
      <option value="all">All</option>
      <option value="book">Books</option>
      <option value="movie">Movies</option>
      <option value="album">Albums</option>
      <option value="concert">Live</option>
    </select>
  </div>
  <div class="media-toolbar-controls">
    <span class="sort-control">
      <label for="media-sort">Sort</label>
      <select id="media-sort" class="sort-select" data-sort-scope="#media-library .media-list, #media-library .media-grid" data-sort-item="tr, li">
        <option value="date">Date</option>
        <option value="az">A→Z</option>
        <option value="rating">Rating</option>
      </select>
    </span>
    <div class="media-toggle" role="group" aria-label="View mode">
      <button type="button" class="media-view-btn is-active" data-view="list">List</button>
      <button type="button" class="media-view-btn" data-view="covers">Covers</button>
    </div>
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
      {% assign sorttitle = clean_title | downcase | strip %}
      {%- comment -%} Display/sort by when it was consumed, not when it came out.
        Books: end (finished). Movies/Albums: last. Albums: First Listen fallback.
        No consumption date → blank, sorts to the bottom. {%- endcomment -%}
      {% assign consumed = '' %}
      {% if e.last and e.last != '' %}{% assign consumed = e.last %}{% elsif e.end and e.end != '' %}{% assign consumed = e.end %}{% elsif e['First Listen'] and e['First Listen'] != '' %}{% assign consumed = e['First Listen'] %}{% endif %}
      {% assign sortdate = '' %}
      {% if consumed != '' %}{% assign sortdate = consumed | date: '%Y-%m-%d' %}{% endif %}
      <tr data-type="{{ type | downcase }}" data-title="{{ sorttitle | escape }}" data-date="{{ sortdate }}" data-rating="{{ e.rating | default: 0 }}">
        <td class="index-title"><a class="internal-link" href="{{ site.baseurl }}{{ e.url }}">{{ clean_title }}</a></td>
        <td class="index-meta"><span class="tag">{{ type }}</span></td>
        <td class="index-meta muted">{{ creator }}</td>
        <td class="index-date muted">{% if consumed != '' %}{{ consumed | date: '%b %Y' }}{% endif %}</td>
        <td class="index-date muted media-rating">{%- if e.rating -%}{%- assign filled = e.rating -%}{%- if filled > 7 -%}{%- assign filled = 7 -%}{%- endif -%}{%- assign unfilled = 7 | minus: filled -%}<span class="rating-marks" title="{{ e.rating }}/7" aria-label="{{ e.rating }} out of 7">{%- if filled > 0 -%}{%- for i in (1..filled) -%}◆{%- endfor -%}{%- endif -%}{%- if unfilled > 0 -%}{%- for i in (1..unfilled) -%}◇{%- endfor -%}{%- endif -%}</span>{%- endif -%}</td>
      </tr>
    {% endfor %}
    {% for c in concerts %}
      {% assign artists = c.Artists | join: ', ' | replace: '[', '' | replace: ']', '' | replace: '  ', ' ' | strip %}
      {% if artists == '' %}{% assign artists = c.title %}{% endif %}
      {% assign venue = c.Venue | replace: '[', '' | replace: ']', '' | replace: '  ', ' ' | strip %}
      <tr data-type="concert" data-title="{{ artists | downcase | escape }}" data-date="{{ c.Dates | date: '%Y-%m-%d' }}" data-rating="0">
        <td class="index-title"><a class="internal-link" href="{{ site.baseurl }}{{ c.url }}">{{ artists }}</a></td>
        <td class="index-meta"><span class="tag">Live</span></td>
        <td class="index-meta muted">{{ venue }}</td>
        <td class="index-date muted">{{ c.Dates | date: "%b %Y" }}</td>
        <td class="index-date muted"></td>
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
      {% assign sorttitle = clean_title | downcase | strip %}
      {% assign consumed = '' %}
      {% if e.last and e.last != '' %}{% assign consumed = e.last %}{% elsif e.end and e.end != '' %}{% assign consumed = e.end %}{% elsif e['First Listen'] and e['First Listen'] != '' %}{% assign consumed = e['First Listen'] %}{% endif %}
      {% assign sortdate = '' %}
      {% if consumed != '' %}{% assign sortdate = consumed | date: '%Y-%m-%d' %}{% endif %}
      <li class="media-card" data-type="{{ type | downcase }}" data-title="{{ sorttitle | escape }}" data-date="{{ sortdate }}" data-rating="{{ e.rating | default: 0 }}">
        <a href="{{ site.baseurl }}{{ e.url }}" title="{{ clean_title }}">
          <img class="media-cover" src="{{ e.cover }}" alt="Cover of {{ clean_title }}" loading="lazy" />
          <span class="media-card-meta">
            <span class="media-card-title">{{ clean_title }}</span>
            <span class="tag">{{ type }}</span>
          </span>
        </a>
      </li>
    {% endfor %}
    {% for c in concerts %}
      {% assign artists = c.Artists | join: ', ' | replace: '[', '' | replace: ']', '' | replace: '  ', ' ' | strip %}
      {% if artists == '' %}{% assign artists = c.title %}{% endif %}
      {% assign venue = c.Venue | replace: '[', '' | replace: ']', '' | replace: '  ', ' ' | strip %}
      <li class="media-card" data-type="concert" data-title="{{ artists | downcase | escape }}" data-date="{{ c.Dates | date: '%Y-%m-%d' }}" data-rating="0">
        <a href="{{ site.baseurl }}{{ c.url }}" title="{{ artists }}">
          {% if c.cover %}
          <img class="media-cover" src="{{ c.cover }}" alt="{{ artists }} at {{ venue }}" loading="lazy" />
          {% else %}
          <span class="media-cover media-cover--gig">
            <span class="gig-artist">{{ artists }}</span>
            <span class="gig-venue">{{ venue }}</span>
            <span class="gig-year">{{ c.Dates | date: "%Y" }}</span>
          </span>
          {% endif %}
          <span class="media-card-meta">
            {% if c.cover %}<span class="media-card-title">{{ artists }}</span>{% endif %}
            <span class="tag">Live</span>
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
  .media-toolbar-controls { display: inline-flex; align-items: center; gap: 0.9em; }
  .media-filter-select { display: none; }

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

  /* Typographic fallback "cover" for concerts with no image */
  .media-cover--gig {
    box-sizing: border-box;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    text-align: center;
    gap: 0.3em;
    padding: 0.9em 0.8em;
    border: 1px solid var(--color-border);
    box-shadow: none;
    overflow: hidden;
  }
  .media-cover--gig .gig-artist {
    font-weight: var(--weight-medium);
    color: var(--color-text-primary);
    font-size: 0.92em;
    line-height: var(--leading-snug, 1.25);
  }
  .media-cover--gig .gig-venue {
    color: var(--color-text-tertiary);
    font-size: 0.8em;
    line-height: var(--leading-snug, 1.25);
  }
  .media-cover--gig .gig-year {
    color: var(--color-text-tertiary);
    font-size: 0.78em;
    font-variant-numeric: tabular-nums;
  }
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
    /* Filter chips wrap awkwardly on narrow screens — use a dropdown */
    .media-filters .tag { display: none; }
    .media-filter-select { display: inline-block; }
  }
</style>

<script>
  (function () {
    var lib = document.getElementById('media-library');
    if (!lib) return;
    var viewBtns = document.querySelectorAll('.media-view-btn');
    var chips = document.querySelectorAll('.media-filters .tag');
    var filterSelect = document.querySelector('.media-filter-select');
    var sortSelect = document.getElementById('media-sort');

    var TYPES = { all: 1, book: 1, movie: 1, album: 1, concert: 1 };
    var VIEWS = { list: 1, covers: 1 };
    var SORTS = { date: 1, az: 1, rating: 1 };

    var currentFilter = 'all';
    var currentView = 'list';
    var ready = false;

    // Reflect filter + view + sort in the URL so a view can be linked/shared.
    function updateUrl() {
      if (!ready) return;
      var params = new URLSearchParams();
      if (currentFilter !== 'all') params.set('type', currentFilter);
      if (currentView !== 'list') params.set('view', currentView);
      var sort = sortSelect ? sortSelect.value : 'date';
      if (sort !== 'date') params.set('sort', sort);
      var qs = params.toString();
      history.replaceState(null, '', location.pathname + (qs ? '?' + qs : '') + location.hash);
    }

    function setView(view, persist) {
      currentView = view;
      lib.classList.remove('view-list', 'view-covers');
      lib.classList.add('view-' + view);
      viewBtns.forEach(function (b) { b.classList.toggle('is-active', b.dataset.view === view); });
      if (persist !== false) { try { localStorage.setItem('mediaView', view); } catch (e) {} }
      updateUrl();
    }

    function setFilter(type) {
      currentFilter = type;
      lib.querySelectorAll('[data-type]').forEach(function (el) {
        el.classList.toggle('is-hidden', type !== 'all' && el.dataset.type !== type);
      });
      chips.forEach(function (c) { c.classList.toggle('is-active', c.dataset.filter === type); });
      if (filterSelect && filterSelect.value !== type) filterSelect.value = type;
      updateUrl();
    }

    viewBtns.forEach(function (b) { b.addEventListener('click', function () { setView(b.dataset.view); }); });
    chips.forEach(function (c) { c.addEventListener('click', function () { setFilter(c.dataset.filter); }); });
    if (filterSelect) filterSelect.addEventListener('change', function () { setFilter(filterSelect.value); });
    if (sortSelect) sortSelect.addEventListener('change', updateUrl);

    // ---- Initial state: URL params take precedence, then saved view ----
    var params = new URLSearchParams(location.search);
    var urlType = params.get('type');
    var urlView = params.get('view');
    var urlSort = params.get('sort');

    var initView = 'list';
    if (urlView && VIEWS[urlView]) {
      initView = urlView;
    } else {
      try { var saved = localStorage.getItem('mediaView'); if (VIEWS[saved]) initView = saved; } catch (e) {}
    }
    setView(initView, urlView ? false : true);

    // Set the sort value before sortable.js runs its load-time sort.
    if (sortSelect && urlSort && SORTS[urlSort]) sortSelect.value = urlSort;

    if (urlType && TYPES[urlType]) setFilter(urlType);

    ready = true;
  })();
</script>
<script src="{{ site.baseurl }}/assets/js/sortable.js"></script>
