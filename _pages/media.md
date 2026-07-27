---
layout: page
title: Media Diet
id: media
permalink: /media/
---

# Media Diet

Everything I've been reading, watching, listening to, and seeing live. For a more detailed view into music, see my [last.fm listening report]({{ site.baseurl }}/listening){: .internal-link}.

{%- comment -%}TV is modelled season-by-season: a season/standalone is a diet
entry, but a series is context only (no rating, no watch date) and is flagged
`hide_from_diet` by the tv_shows plugin — as are abandoned (`dnf`) shows. Keep
both out of the library.{%- endcomment -%}
{% assign entries = site.notes | where_exp: "n", "n.cover" | where_exp: "n", "n.path contains 'MediaDiet/'" | where_exp: "n", "n.hide_from_diet != true" | sort: "created" | reverse %}
{% assign concerts = site.notes | where_exp: "n", "n.tags contains 'concerts'" | sort: "Dates" | reverse %}

<div class="media-toolbar">
  <div class="media-filters" role="group" aria-label="Filter by type">
    <button type="button" class="tag is-active" data-filter="all">All</button>
    <button type="button" class="tag" data-filter="book">Books</button>
    <button type="button" class="tag" data-filter="movie">Movies</button>
    <button type="button" class="tag" data-filter="show">TV</button>
    <button type="button" class="tag" data-filter="album">Albums</button>
    <button type="button" class="tag" data-filter="concert">Live</button>
    <select class="sort-select media-filter-select" aria-label="Filter by type">
      <option value="all">All</option>
      <option value="book">Books</option>
      <option value="movie">Movies</option>
      <option value="show">TV</option>
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
      <select id="media-sort" class="sort-select" data-sort-scope="#media-library .media-list, #media-library .media-grid" data-sort-item="tbody tr, li">
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
    <thead>
      <tr>
        <th class="index-title">Title</th>
        <th class="index-meta">Type</th>
        <th class="index-meta">By</th>
        <th class="index-date">Completed</th>
        <th class="index-date">Rating</th>
      </tr>
    </thead>
    <tbody>
    {% for e in entries %}
      {% assign type = 'Media' %}
      {% if e.path contains '/Books/' %}{% assign type = 'Book' %}
      {% elsif e.path contains '/Movies/' %}{% assign type = 'Movie' %}
      {% elsif e.path contains '/Albums/' %}{% assign type = 'Album' %}
      {% elsif e.path contains '/Shows/' or e.path contains '/TV/' %}{% assign type = 'Show' %}
      {% endif %}
      {% if e.type %}{% assign type = e.type %}{% endif %}
      {% assign clean_title = e.title | replace: '📚 ', '' | replace: '🎬 ', '' | replace: '📺 ', '' | replace: '🦖 ', '' %}
      {%- comment -%}TV seasons render as "Series Season N" (the plugin's
      display_title), not their raw filename ("Hacks s03"); everything else
      falls back to its cleaned title.{%- endcomment -%}
      {% assign disp = e.display_title | default: clean_title | titlecase %}
      {% assign creator = '' %}
      {% if e.author %}{% assign creator = e.author | join: ', ' %}
      {% elsif e.director %}{% assign creator = e.director | join: ', ' %}
      {% elsif e.artist %}{% assign creator = e.artist | join: ', ' %}
      {% elsif e.creator %}{% assign creator = e.creator | join: ', ' %}{% endif %}
      {% assign creator = creator | replace: '[', '' | replace: ']', '' | replace: '  ', ' ' | strip %}
      {% assign sorttitle = disp | downcase | strip %}
      {%- comment -%}The Completed column shows only when I finished something —
      books store it in `end`, movies/albums in `last` (concerts use the gig
      date, below). Anything not finished shows nothing here. The date sort is a
      single reverse-chronological stream keyed on the watch/consume date
      (`end`/`last`); entries with no watch date fall back to the release `year`
      (as `YYYY-00-00`) so they interleave under their release year. Entries with
      neither ('') sink to the bottom. The release year is a fallback sort key
      only — it's never shown as a completion date.{%- endcomment -%}
      {% assign finished = nil %}
      {% if e.end %}{% assign finished = e.end %}{% elsif e.last %}{% assign finished = e.last %}{% endif %}
      {% assign datedisp = '' %}{% if finished %}{% assign datedisp = finished | date: '%b %Y' %}{% endif %}
      {% assign sortdate = '' %}
      {% if finished %}{% assign sortdate = finished | date: '%Y-%m-%d' %}{% elsif e.year %}{% assign sortdate = e.year | append: '-00-00' %}{% endif %}
      {%- comment -%}shelf is a scalar for some collections (movies: "watched")
      and a YAML list for others (books: ["read"]/["queue"]); join reads both.
      Map to a status bucket; anything not explicitly in-progress or want-to
      (incl. read/watched/listened and untagged) falls through to finished.{%- endcomment -%}
      {% assign shelfval = e.shelf | join: ' ' | downcase | strip %}
      {% assign statusbucket = 'finished' %}
      {% if shelfval contains 'reading' or shelfval == 'watching' or shelfval == 'listening' or shelfval == 'playing' or shelfval == 'current' or shelfval == 'in progress' or shelfval == 'in-progress' %}{% assign statusbucket = 'active' %}
      {% elsif shelfval == 'queue' or shelfval == 'queued' or shelfval == 'want' or shelfval == 'backlog' or shelfval == 'unread' or shelfval == 'wishlist' or shelfval == 'watchlist' or shelfval == 'to-watch' or shelfval == 'to watch' or shelfval contains 'to-read' or shelfval contains 'to read' or shelfval contains 'want to read' %}{% assign statusbucket = 'queue' %}{% endif %}
      <tr data-type="{{ type | downcase }}" data-title="{{ sorttitle | escape }}" data-date="{{ sortdate }}" data-rating="{{ e.rating | default: 0 }}" data-ranking="{{ e.ranking }}" data-shelf="{{ statusbucket }}">
        <td class="index-title"><a class="internal-link" href="{{ site.baseurl }}{{ e.url }}" title="{{ disp | escape }}">{{ disp }}</a></td>
        <td class="index-meta"><span class="tag">{{ type }}</span></td>
        <td class="index-meta muted">{{ creator }}</td>
        <td class="index-date muted">{{ datedisp }}</td>
        <td class="index-date muted media-rating">{%- if e.rating -%}<span class="rating-num" aria-label="{{ e.rating }} out of 7">{{ e.rating }}</span>{%- endif -%}</td>
      </tr>
    {% endfor %}
    {% for c in concerts %}
      {% assign artists = c.Artists | join: ', ' | replace: '[', '' | replace: ']', '' | replace: '  ', ' ' | strip %}
      {% if artists == '' %}{% assign artists = c.title %}{% endif %}
      {% assign venue = c.Venue | replace: '[', '' | replace: ']', '' | replace: '  ', ' ' | strip %}
      {%- comment -%}A concert's gig date is its watch/consume date, so key on it
      directly — same reverse-chronological stream as the media rows.{%- endcomment -%}
      <tr data-type="concert" data-title="{{ artists | downcase | escape }}" data-date="{{ c.Dates | date: '%Y-%m-%d' }}" data-rating="0" data-shelf="finished">
        <td class="index-title"><a class="internal-link" href="{{ site.baseurl }}{{ c.url }}">{{ artists }}</a></td>
        <td class="index-meta"><span class="tag">Live</span></td>
        <td class="index-meta muted">{{ venue }}</td>
        <td class="index-date muted">{{ c.Dates | date: "%b %Y" }}</td>
        <td class="index-date muted"></td>
      </tr>
    {% endfor %}
    </tbody>
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
      {% assign disp = e.display_title | default: clean_title | titlecase %}
      {% assign sorttitle = disp | downcase | strip %}
      {%- comment -%}Same sort key as the list view: watch/consume date
      (`end`/`last`), falling back to the release `year` (as `YYYY-00-00`) when
      there's no watch date, so both views share one reverse-chronological
      order.{%- endcomment -%}
      {% assign finished = nil %}
      {% if e.end %}{% assign finished = e.end %}{% elsif e.last %}{% assign finished = e.last %}{% endif %}
      {% assign sortdate = '' %}
      {% if finished %}{% assign sortdate = finished | date: '%Y-%m-%d' %}{% elsif e.year %}{% assign sortdate = e.year | append: '-00-00' %}{% endif %}
      {% assign creator = '' %}
      {% if e.author %}{% assign creator = e.author | join: ', ' %}
      {% elsif e.director %}{% assign creator = e.director | join: ', ' %}
      {% elsif e.artist %}{% assign creator = e.artist | join: ', ' %}
      {% elsif e.creator %}{% assign creator = e.creator | join: ', ' %}{% endif %}
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
        <a href="{{ site.baseurl }}{{ e.url }}" title="{{ disp | escape }}">
          <img class="media-cover" src="{{ e.cover }}" alt="Cover of {{ disp }}" loading="lazy" />
          <span class="media-card-info">
            <span class="mci-title">{{ disp }}</span>
            {% if creator != '' %}<span class="mci-sub">{{ creator }}</span>{% endif %}
            <span class="mci-foot"><span class="tag">{{ type }}</span>{% if e.year %}<span class="mci-year">{{ e.year }}</span>{% endif %}{%- if e.rating -%}{%- assign filled = e.rating | plus: 0 -%}{%- if filled > 7 -%}{%- assign filled = 7 -%}{%- endif -%}{%- assign unfilled = 7 | minus: filled -%}<span class="mci-rating" title="{{ e.rating }}/7">{%- for i in (1..filled) -%}◆{%- endfor -%}{%- if unfilled > 0 -%}{%- for i in (1..unfilled) -%}◇{%- endfor -%}{%- endif -%}</span>{%- endif -%}</span>
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

    var TYPES = { all: 1, book: 1, movie: 1, show: 1, album: 1, concert: 1 };
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

  // ---- Scroll reveal for cover thumbnails ----
  // Fade the cards in as they enter the viewport, matching the sitewide text
  // animation. This runs independently of the load-time view: cards start
  // hidden only after the class is applied here, so they reveal whether Covers
  // is the initial view or you switch to it later. Cards hidden by a filter
  // (display:none) never intersect, so they stay ready and reveal when shown.
  (function () {
    var lib = document.getElementById('media-library');
    if (!lib || !('IntersectionObserver' in window)) return;
    var cards = lib.querySelectorAll('.media-card');
    if (!cards.length) return;

    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
      cards.forEach(function (c) { c.classList.add('reveal-on-scroll', 'is-revealed'); });
      return;
    }

    var revealObserver = new IntersectionObserver(function (entries, observer) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add('is-revealed');
          observer.unobserve(entry.target);
        }
      });
    }, { threshold: 0.1, rootMargin: '0px 0px -40px 0px' });

    cards.forEach(function (c) {
      c.classList.add('reveal-on-scroll');
      revealObserver.observe(c);
    });
  })();
</script>
<script src="{{ site.baseurl }}/assets/js/sortable.js"></script>
