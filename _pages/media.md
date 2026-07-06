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
      <label for="media-status">Status</label>
      <select id="media-status" class="sort-select">
        <option value="all">All</option>
        <option value="queue">Queue</option>
        <option value="active">Active</option>
        <option value="finished">Finished</option>
      </select>
    </span>
    <span class="sort-control">
      <label for="media-sort">Sort</label>
      <select id="media-sort" class="sort-select" data-sort-scope="#media-library .media-list, #media-library .media-grid" data-sort-item="tr, li">
        <option value="date">Date</option>
        <option value="az">A→Z</option>
        <option value="rating">Rating</option>
        <option value="ranked" hidden>Coop&rsquo;s 100</option>
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
      {%- comment -%}shelf is a scalar for some collections (movies: "watched")
      and a YAML list for others (books: ["read"]/["queue"]); join reads both.
      Map to a status bucket; anything not explicitly in-progress or want-to
      (incl. read/watched/listened and untagged) falls through to finished.{%- endcomment -%}
      {% assign shelfval = e.shelf | join: ' ' | downcase | strip %}
      {% assign statusbucket = 'finished' %}
      {% if shelfval contains 'reading' or shelfval == 'watching' or shelfval == 'listening' or shelfval == 'playing' or shelfval == 'current' or shelfval == 'in progress' or shelfval == 'in-progress' %}{% assign statusbucket = 'active' %}
      {% elsif shelfval == 'queue' or shelfval == 'queued' or shelfval == 'want' or shelfval == 'backlog' or shelfval == 'unread' or shelfval == 'wishlist' or shelfval == 'watchlist' or shelfval == 'to-watch' or shelfval == 'to watch' or shelfval contains 'to-read' or shelfval contains 'to read' or shelfval contains 'want to read' %}{% assign statusbucket = 'queue' %}{% endif %}
      <tr data-type="{{ type | downcase }}" data-title="{{ sorttitle | escape }}" data-date="{{ sortdate }}" data-rating="{{ e.rating | default: 0 }}" data-ranking="{{ e.ranking }}" data-shelf="{{ statusbucket }}">
        <td class="index-title"><a class="internal-link" href="{{ site.baseurl }}{{ e.url }}" title="{{ clean_title | escape }}">{{ clean_title }}</a></td>
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
      <tr data-type="concert" data-title="{{ artists | downcase | escape }}" data-date="{{ c.Dates | date: '%Y-%m-%d' }}" data-rating="0" data-shelf="finished">
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
      {% assign creator = '' %}
      {% if e.author %}{% assign creator = e.author | join: ', ' %}
      {% elsif e.director %}{% assign creator = e.director | join: ', ' %}
      {% elsif e.artist %}{% assign creator = e.artist | join: ', ' %}{% endif %}
      {% assign creator = creator | replace: '[', '' | replace: ']', '' | replace: '  ', ' ' | strip %}
      {%- comment -%}shelf is a scalar for some collections (movies: "watched")
      and a YAML list for others (books: ["read"]/["queue"]); join reads both.
      Map to a status bucket; anything not explicitly in-progress or want-to
      (incl. read/watched/listened and untagged) falls through to finished.{%- endcomment -%}
      {% assign shelfval = e.shelf | join: ' ' | downcase | strip %}
      {% assign statusbucket = 'finished' %}
      {% if shelfval contains 'reading' or shelfval == 'watching' or shelfval == 'listening' or shelfval == 'playing' or shelfval == 'current' or shelfval == 'in progress' or shelfval == 'in-progress' %}{% assign statusbucket = 'active' %}
      {% elsif shelfval == 'queue' or shelfval == 'queued' or shelfval == 'want' or shelfval == 'backlog' or shelfval == 'unread' or shelfval == 'wishlist' or shelfval == 'watchlist' or shelfval == 'to-watch' or shelfval == 'to watch' or shelfval contains 'to-read' or shelfval contains 'to read' or shelfval contains 'want to read' %}{% assign statusbucket = 'queue' %}{% endif %}
      <li class="media-card" data-type="{{ type | downcase }}" data-title="{{ sorttitle | escape }}" data-date="{{ sortdate }}" data-rating="{{ e.rating | default: 0 }}" data-ranking="{{ e.ranking }}" data-shelf="{{ statusbucket }}">
        <a href="{{ site.baseurl }}{{ e.url }}" title="{{ clean_title | escape }}">
          <img class="media-cover" src="{{ e.cover }}" alt="Cover of {{ clean_title }}" loading="lazy" />
          <span class="media-card-info">
            <span class="mci-title">{{ clean_title }}</span>
            {% if creator != '' %}<span class="mci-sub">{{ creator }}</span>{% endif %}
            <span class="mci-foot"><span class="tag">{{ type }}</span>{% if e.year %}<span class="mci-year">{{ e.year }}</span>{% endif %}{%- if e.rating -%}{%- assign filled = e.rating -%}{%- if filled > 7 -%}{%- assign filled = 7 -%}{%- endif -%}{%- assign unfilled = 7 | minus: filled -%}<span class="mci-rating" title="{{ e.rating }}/7">{%- for i in (1..filled) -%}◆{%- endfor -%}{%- if unfilled > 0 -%}{%- for i in (1..unfilled) -%}◇{%- endfor -%}{%- endif -%}</span>{%- endif -%}</span>
          </span>
        </a>
      </li>
    {% endfor %}
    {% for c in concerts %}
      {% assign artists = c.Artists | join: ', ' | replace: '[', '' | replace: ']', '' | replace: '  ', ' ' | strip %}
      {% if artists == '' %}{% assign artists = c.title %}{% endif %}
      {% assign venue = c.Venue | replace: '[', '' | replace: ']', '' | replace: '  ', ' ' | strip %}
      <li class="media-card" data-type="concert" data-title="{{ artists | downcase | escape }}" data-date="{{ c.Dates | date: '%Y-%m-%d' }}" data-rating="0" data-shelf="finished">
        <a href="{{ site.baseurl }}{{ c.url }}" title="{{ artists | escape }}">
          {% if c.cover %}
          <img class="media-cover" src="{{ c.cover }}" alt="{{ artists }} at {{ venue }}" loading="lazy" />
          <span class="media-card-info">
            <span class="mci-title">{{ artists }}</span>
            {% if venue != '' %}<span class="mci-sub">{{ venue }}</span>{% endif %}
            <span class="mci-foot"><span class="tag">Live</span><span class="mci-year">{{ c.Dates | date: "%Y" }}</span></span>
          </span>
          {% else %}
          <span class="media-cover media-cover--gig">
            <span class="gig-artist">{{ artists }}</span>
            <span class="gig-venue">{{ venue }}</span>
            <span class="gig-year">{{ c.Dates | date: "%Y" }}</span>
          </span>
          {% endif %}
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
    /* Fixed width + equal-flex halves so "List" and "Covers" occupy the
       same width despite their different label lengths (the shorter label
       just centres in its half). */
    width: 10em;
    border: 1px solid var(--color-border);
    border-radius: 1em;
    overflow: hidden;
  }
  .media-view-btn {
    appearance: none; border: 0; background: transparent;
    flex: 1 1 0; text-align: center;
    color: var(--color-text-tertiary); font: inherit; font-size: 0.78em;
    padding: 0.3em 0.85em; cursor: pointer;
    transition: background 0.15s ease, color 0.15s ease;
  }
  .media-view-btn.is-active { background: var(--color-text-primary); color: var(--color-bg-primary); }

  .media-grid { list-style: none; margin: 0; padding: 0; }
  /* List view is a shared .index-table; sit it right under the toolbar */
  .media-list.index-table { margin: 0; }

  /* The media list carries more columns than the other index tables
     (type · creator · year · rating). With auto table layout a long,
     nowrap creator — e.g. a two-name director credit — stole width from
     the title column and crushed long book titles to one word per line.
     Pin the layout: the title takes the remainder, the secondary columns
     are fixed, and an over-long creator/venue truncates with an ellipsis
     rather than hogging the row. */
  .media-list.index-table { table-layout: fixed; }
  .media-list td { padding-left: 0.9em; }
  .media-list .index-title { width: auto; padding-left: 0; }
  /* Some titles run book-jacket long ("Boom Town: The Fantastical Saga…").
     Clamp the display to two lines with an ellipsis so one entry can't
     balloon its row; the full title stays on hover and on the entry page. */
  .media-list .index-title a {
    display: -webkit-box;
    -webkit-line-clamp: 2;
    line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }
  .media-list td:nth-child(2) { width: 4.2em; }            /* type tag */
  .media-list td:nth-child(3) {                            /* creator / venue */
    width: 8.5em;
    overflow: hidden;
    text-overflow: ellipsis;
  }
  .media-list td:nth-child(4) { width: 3em; }              /* year */
  .media-list td:nth-child(5) { width: 7em; }              /* rating */
  #media-library.view-list .media-grid { display: none; }
  #media-library.view-covers .media-list { display: none; }
  .is-hidden { display: none !important; }

  /* ---- Covers view ---- */
  /* A clean wall of covers: no meta below the artwork. Details live in a
     card that fades in on hover / keyboard focus (see .media-card-info). */
  .media-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(112px, 1fr));
    gap: 1em 0.9em;
  }
  .media-card a {
    position: relative; display: block; text-decoration: none;
    color: var(--color-text-subtle); transition: transform 0.15s ease;
  }
  .media-card a:hover { transform: translateY(-3px); }
  .media-cover {
    display: block; width: 100%; aspect-ratio: 2 / 3; object-fit: cover;
    border-radius: var(--border-radius, 4px); background: var(--color-bg-secondary);
    box-shadow: 0 2px 8px rgba(0,0,0,0.16); transition: box-shadow 0.15s ease;
  }
  .media-card a:hover .media-cover { box-shadow: 0 8px 20px rgba(0,0,0,0.28); }

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
  /* Hover metadata card, laid over the artwork */
  .media-card-info {
    position: absolute; inset: 0;
    display: flex; flex-direction: column; justify-content: flex-end;
    gap: 0.15em;
    padding: 0.7em 0.65em;
    border-radius: var(--border-radius, 4px);
    background: linear-gradient(to top,
      rgba(12,13,16,0.94) 0%, rgba(12,13,16,0.82) 38%,
      rgba(12,13,16,0.18) 78%, rgba(12,13,16,0) 100%);
    color: #fff;
    opacity: 0; transition: opacity 0.18s ease;
    pointer-events: none;
  }
  .media-card a:hover .media-card-info,
  .media-card a:focus-visible .media-card-info { opacity: 1; }
  .mci-title {
    font-size: 0.8em; font-weight: var(--weight-semibold, 600); line-height: 1.25;
    display: -webkit-box; -webkit-line-clamp: 3; line-clamp: 3;
    -webkit-box-orient: vertical; overflow: hidden;
  }
  .mci-sub {
    font-size: 0.72em; line-height: 1.3; color: rgba(255,255,255,0.75);
    display: -webkit-box; -webkit-line-clamp: 2; line-clamp: 2;
    -webkit-box-orient: vertical; overflow: hidden;
  }
  .mci-foot {
    display: flex; align-items: center; flex-wrap: wrap; gap: 0.3em 0.45em;
    margin-top: 0.4em; font-size: 0.7em; color: rgba(255,255,255,0.72);
    font-variant-numeric: tabular-nums;
  }
  .media-card-info .tag {
    color: rgba(255,255,255,0.85); border-color: rgba(255,255,255,0.35);
  }
  .mci-rating { letter-spacing: 0.03em; color: #fff; white-space: nowrap; }

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
    var statusSelect = document.getElementById('media-status');

    // The "Coop's 100" option is detached from the DOM when we're not scoped to
    // Movies (see syncSortOption). It starts out `hidden` for the no-JS case;
    // once JS owns it, presence in the <select> — not the attribute — controls
    // visibility, so drop the attribute up front.
    var rankedOpt = sortSelect ? sortSelect.querySelector('option[value="ranked"]') : null;
    if (rankedOpt) rankedOpt.removeAttribute('hidden');

    var TYPES = { all: 1, book: 1, movie: 1, album: 1, concert: 1 };
    var VIEWS = { list: 1, covers: 1 };
    // 'ranked' (Coop's 100) is a movies-only sort that also subsets to ranked
    // titles — see syncSortOption() / applyVisibility().
    var SORTS = { date: 1, az: 1, rating: 1, ranked: 1 };
    // Reading status, from each item's normalized data-shelf bucket.
    var STATUSES = { all: 1, queue: 1, active: 1, finished: 1 };

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
      var status = statusSelect ? statusSelect.value : 'all';
      if (status !== 'all') params.set('status', status);
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

    // "Coop's 100" (sort value 'ranked') only makes sense for movies, so its
    // option is present in the dropdown only under the Movies filter. We remove
    // the node entirely rather than toggling `hidden`/`disabled`: browsers don't
    // reliably honour `hidden` on <option>, which left it lingering as a
    // confusing greyed-out entry. Returns true if it had to reset the sort
    // because we left Movies while ranked was selected.
    function syncSortOption() {
      if (!sortSelect || !rankedOpt) return false;
      var allow = currentFilter === 'movie';
      var present = rankedOpt.parentNode === sortSelect;
      if (allow && !present) {
        sortSelect.appendChild(rankedOpt);
      } else if (!allow && present) {
        var wasSelected = sortSelect.value === 'ranked';
        sortSelect.removeChild(rankedOpt);
        if (wasSelected) {
          sortSelect.value = 'date';
          return true;
        }
      }
      return false;
    }

    // Show/hide items for the current type + status filters. The ranked sort
    // doubles as a filter: it keeps only movies that carry a hand-ranking.
    function applyVisibility() {
      var ranked = sortSelect && sortSelect.value === 'ranked';
      var status = statusSelect ? statusSelect.value : 'all';
      lib.querySelectorAll('[data-type]').forEach(function (el) {
        var hide = currentFilter !== 'all' && el.dataset.type !== currentFilter;
        if (!hide && ranked && !(el.dataset.type === 'movie' && el.dataset.ranking)) hide = true;
        if (!hide && status !== 'all' && el.dataset.shelf !== status) hide = true;
        el.classList.toggle('is-hidden', hide);
      });
    }

    function setFilter(type) {
      currentFilter = type;
      chips.forEach(function (c) { c.classList.toggle('is-active', c.dataset.filter === type); });
      if (filterSelect && filterSelect.value !== type) filterSelect.value = type;
      var sortReset = syncSortOption();
      applyVisibility();
      // If leaving Movies forced the sort back to Date, re-run the ordering.
      if (sortReset && sortSelect) sortSelect.dispatchEvent(new Event('change'));
      updateUrl();
    }

    viewBtns.forEach(function (b) { b.addEventListener('click', function () { setView(b.dataset.view); }); });
    chips.forEach(function (c) { c.addEventListener('click', function () { setFilter(c.dataset.filter); }); });
    if (filterSelect) filterSelect.addEventListener('change', function () { setFilter(filterSelect.value); });
    // Re-apply visibility on sort change so the ranked sort subsets/unsubsets.
    if (sortSelect) sortSelect.addEventListener('change', function () { applyVisibility(); updateUrl(); });
    if (statusSelect) statusSelect.addEventListener('change', function () { applyVisibility(); updateUrl(); });

    // ---- Initial state: URL params take precedence, then saved view ----
    var params = new URLSearchParams(location.search);
    var urlType = params.get('type');
    var urlView = params.get('view');
    var urlSort = params.get('sort');
    var urlStatus = params.get('status');

    var initView = 'list';
    if (urlView && VIEWS[urlView]) {
      initView = urlView;
    } else {
      try { var saved = localStorage.getItem('mediaView'); if (VIEWS[saved]) initView = saved; } catch (e) {}
    }
    setView(initView, urlView ? false : true);

    // Set the sort value before sortable.js runs its load-time sort.
    if (sortSelect && urlSort && SORTS[urlSort]) sortSelect.value = urlSort;

    if (statusSelect && urlStatus && STATUSES[urlStatus]) statusSelect.value = urlStatus;

    if (urlType && TYPES[urlType]) setFilter(urlType);

    // Reconcile the ranked option + visibility for the restored state (e.g. a
    // ?sort=ranked link, or a Movies deep link) before sortable.js sorts.
    syncSortOption();
    applyVisibility();

    ready = true;
  })();
</script>
<script src="{{ site.baseurl }}/assets/js/sortable.js"></script>
