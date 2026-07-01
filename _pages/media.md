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
  <div class="media-filter-groups">
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
    <div class="media-status-filters" role="group" aria-label="Filter by status">
      <button type="button" class="tag is-active" data-status-filter="finished">Finished</button>
      <button type="button" class="tag" data-status-filter="current">Current</button>
      <button type="button" class="tag" data-status-filter="queue">Queue</button>
      <button type="button" class="tag" data-status-filter="all">All</button>
      <select class="sort-select media-status-select" aria-label="Filter by status">
        <option value="finished" selected>Finished</option>
        <option value="current">Current</option>
        <option value="queue">Queue</option>
        <option value="all">Any status</option>
      </select>
    </div>
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
      {% assign sortdate = '' %}
      {% if e.created %}{% assign sortdate = e.created | date: '%Y-%m-%d' %}{% elsif e.last %}{% assign sortdate = e.last | date: '%Y-%m-%d' %}{% elsif e.year %}{% assign sortdate = e.year | append: '-00-00' %}{% endif %}
      {% assign shelfval = e.shelf | join: ',' | downcase %}
      {% assign status = 'finished' %}
      {% if shelfval contains 'queue' or shelfval contains 'to-read' or shelfval contains 'want' %}{% assign status = 'queue' %}
      {% elsif shelfval contains 'reading' or shelfval contains 'watching' or shelfval contains 'listening' %}{% assign status = 'current' %}
      {% endif %}
      <tr data-type="{{ type | downcase }}" data-status="{{ status }}" data-title="{{ sorttitle | escape }}" data-date="{{ sortdate }}" data-rating="{{ e.rating | default: 0 }}">
        <td class="index-title"><a class="internal-link" href="{{ site.baseurl }}{{ e.url }}">{{ clean_title }}</a></td>
        <td class="index-meta"><span class="tag">{{ type }}</span></td>
        <td class="index-meta muted">{{ creator }}</td>
        <td class="index-date muted">{% if e.year %}{{ e.year }}{% endif %}</td>
        <td class="index-date muted media-rating">{%- if e.rating -%}{%- assign filled = e.rating -%}{%- if filled > 7 -%}{%- assign filled = 7 -%}{%- endif -%}{%- assign unfilled = 7 | minus: filled -%}<span class="rating-marks" title="{{ e.rating }}/7" aria-label="{{ e.rating }} out of 7">{%- if filled > 0 -%}{%- for i in (1..filled) -%}◆{%- endfor -%}{%- endif -%}{%- if unfilled > 0 -%}{%- for i in (1..unfilled) -%}◇{%- endfor -%}{%- endif -%}</span>{%- endif -%}</td>
      </tr>
    {% endfor %}
    {% for c in concerts %}
      {% assign artists = c.Artists | join: ', ' | replace: '[', '' | replace: ']', '' | replace: '  ', ' ' | strip %}
      {% if artists == '' %}{% assign artists = c.title %}{% endif %}
      {% assign venue = c.Venue | replace: '[', '' | replace: ']', '' | replace: '  ', ' ' | strip %}
      <tr data-type="concert" data-status="finished" data-title="{{ artists | downcase | escape }}" data-date="{{ c.Dates | date: '%Y-%m-%d' }}" data-rating="0">
        <td class="index-title"><a class="internal-link" href="{{ site.baseurl }}{{ c.url }}">{{ artists }}</a></td>
        <td class="index-meta"><span class="tag">Live</span></td>
        <td class="index-meta muted">{{ venue }}</td>
        <td class="index-date muted">{{ c.Dates | date: "%Y" }}</td>
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
      {% assign sortdate = '' %}
      {% if e.created %}{% assign sortdate = e.created | date: '%Y-%m-%d' %}{% elsif e.last %}{% assign sortdate = e.last | date: '%Y-%m-%d' %}{% elsif e.year %}{% assign sortdate = e.year | append: '-00-00' %}{% endif %}
      {% assign shelfval = e.shelf | join: ',' | downcase %}
      {% assign status = 'finished' %}
      {% if shelfval contains 'queue' or shelfval contains 'to-read' or shelfval contains 'want' %}{% assign status = 'queue' %}
      {% elsif shelfval contains 'reading' or shelfval contains 'watching' or shelfval contains 'listening' %}{% assign status = 'current' %}
      {% endif %}
      <li class="media-card" data-type="{{ type | downcase }}" data-status="{{ status }}" data-title="{{ sorttitle | escape }}" data-date="{{ sortdate }}" data-rating="{{ e.rating | default: 0 }}">
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
      <li class="media-card" data-type="concert" data-status="finished" data-title="{{ artists | downcase | escape }}" data-date="{{ c.Dates | date: '%Y-%m-%d' }}" data-rating="0">
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
  .media-filter-groups {
    display: inline-flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 0.5em 0.9em;
  }
  .media-filters { display: inline-flex; flex-wrap: wrap; gap: 0.4em; }
  /* Status filters sit alongside the type filters, set off by a hairline divider */
  .media-status-filters {
    display: inline-flex;
    flex-wrap: wrap;
    gap: 0.4em;
    padding-left: 0.9em;
    border-left: 1px solid var(--color-border);
  }
  .media-toolbar-controls { display: inline-flex; align-items: center; gap: 0.9em; }
  .media-filter-select,
  .media-status-select { display: none; }

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
    /* Filter chips wrap awkwardly on narrow screens — use dropdowns */
    .media-filters .tag,
    .media-status-filters .tag { display: none; }
    .media-filter-select,
    .media-status-select { display: inline-block; }
    /* Divider/padding make no sense once the chips collapse to selects */
    .media-status-filters { padding-left: 0; border-left: 0; }
  }
</style>

<script>
  (function () {
    var lib = document.getElementById('media-library');
    if (!lib) return;
    var viewBtns = document.querySelectorAll('.media-view-btn');
    var chips = document.querySelectorAll('.media-filters .tag');
    var filterSelect = document.querySelector('.media-filter-select');
    var statusChips = document.querySelectorAll('.media-status-filters .tag');
    var statusSelect = document.querySelector('.media-status-select');
    var sortSelect = document.getElementById('media-sort');

    var TYPES = { all: 1, book: 1, movie: 1, album: 1, concert: 1 };
    var STATUSES = { all: 1, finished: 1, current: 1, queue: 1 };
    var VIEWS = { list: 1, covers: 1 };
    var SORTS = { date: 1, az: 1, rating: 1 };

    // The same three states read differently depending on the medium, so the
    // status chips relabel themselves to match the selected type.
    var STATUS_LABELS = {
      all:     { finished: 'Finished', current: 'Current',   queue: 'Queue' },
      book:    { finished: 'Read',     current: 'Reading',   queue: 'Queue' },
      movie:   { finished: 'Watched',  current: 'Watching',  queue: 'Queue' },
      album:   { finished: 'Listened', current: 'Listening', queue: 'Queue' },
      concert: { finished: 'Attended', current: 'Current',   queue: 'Queue' }
    };

    var currentFilter = 'all';
    var currentStatus = 'finished';
    var currentView = 'list';
    var ready = false;

    // Reflect filter + status + view + sort in the URL so a view can be linked/shared.
    function updateUrl() {
      if (!ready) return;
      var params = new URLSearchParams();
      if (currentFilter !== 'all') params.set('type', currentFilter);
      // 'finished' is the default landing state, so it stays out of the URL.
      if (currentStatus !== 'finished') params.set('status', currentStatus);
      if (currentView !== 'list') params.set('view', currentView);
      var sort = sortSelect ? sortSelect.value : 'date';
      if (sort !== 'date') params.set('sort', sort);
      var qs = params.toString();
      history.replaceState(null, '', location.pathname + (qs ? '?' + qs : '') + location.hash);
    }

    // An item is visible only when it satisfies BOTH the type and status filters.
    function applyFilters() {
      lib.querySelectorAll('[data-type]').forEach(function (el) {
        var typeOk = currentFilter === 'all' || el.dataset.type === currentFilter;
        var statusOk = currentStatus === 'all' || el.dataset.status === currentStatus;
        el.classList.toggle('is-hidden', !(typeOk && statusOk));
      });
    }

    function relabelStatus(type) {
      var labels = STATUS_LABELS[type] || STATUS_LABELS.all;
      statusChips.forEach(function (c) {
        var key = c.dataset.statusFilter;
        if (labels[key]) c.textContent = labels[key];
      });
      if (statusSelect) {
        Array.prototype.forEach.call(statusSelect.options, function (o) {
          if (labels[o.value]) o.textContent = labels[o.value];
        });
      }
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
      chips.forEach(function (c) { c.classList.toggle('is-active', c.dataset.filter === type); });
      if (filterSelect && filterSelect.value !== type) filterSelect.value = type;
      relabelStatus(type);
      applyFilters();
      updateUrl();
    }

    function setStatus(status) {
      currentStatus = status;
      statusChips.forEach(function (c) { c.classList.toggle('is-active', c.dataset.statusFilter === status); });
      if (statusSelect && statusSelect.value !== status) statusSelect.value = status;
      applyFilters();
      updateUrl();
    }

    viewBtns.forEach(function (b) { b.addEventListener('click', function () { setView(b.dataset.view); }); });
    chips.forEach(function (c) { c.addEventListener('click', function () { setFilter(c.dataset.filter); }); });
    if (filterSelect) filterSelect.addEventListener('change', function () { setFilter(filterSelect.value); });
    statusChips.forEach(function (c) { c.addEventListener('click', function () { setStatus(c.dataset.statusFilter); }); });
    if (statusSelect) statusSelect.addEventListener('change', function () { setStatus(statusSelect.value); });
    if (sortSelect) sortSelect.addEventListener('change', updateUrl);

    // ---- Initial state: URL params take precedence, then saved view ----
    var params = new URLSearchParams(location.search);
    var urlType = params.get('type');
    var urlStatus = params.get('status');
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
    // Default to the consumed ("finished") view; a URL param can override it.
    setStatus(urlStatus && STATUSES[urlStatus] ? urlStatus : 'finished');

    ready = true;
  })();
</script>
<script src="{{ site.baseurl }}/assets/js/sortable.js"></script>
