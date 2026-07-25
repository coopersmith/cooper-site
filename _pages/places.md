---
layout: page
title: Places
id: places
permalink: /places/
---

# Places

My recommended restaurants, bars, and haunts around the world. Pick where you're going, or browse the map.

{%- comment -%}Venues only — destination notes (type: Cities) are context
pages, not rows. place_* fields are distilled from the vault frontmatter by
_plugins/places.rb. The destination and type filters below are built from the
data, so they grow on their own as more places sync from Obsidian.{%- endcomment -%}
{% assign venues = site.notes | where: "place_kind", "venue" | sort: "title" %}

{% assign cities = "" | split: "" %}
{% assign types = "" | split: "" %}
{% for v in venues %}
  {% if v.place_city and v.place_city != '' %}{% unless cities contains v.place_city %}{% assign cities = cities | push: v.place_city %}{% endunless %}{% endif %}
  {% if v.place_type and v.place_type != '' %}{% unless types contains v.place_type %}{% assign types = types | push: v.place_type %}{% endunless %}{% endif %}
{% endfor %}
{% assign cities = cities | sort %}
{% assign types = types | sort %}

<div class="media-toolbar places-toolbar">
  <div class="media-filters" role="group" aria-label="Filter by destination">
    <button type="button" class="tag is-active" data-dest="all">Everywhere</button>
    {% for c in cities %}
    <button type="button" class="tag" data-dest="{{ c | slugify }}">{{ c }}</button>
    {% endfor %}
    <select class="sort-select media-filter-select" aria-label="Filter by destination">
      <option value="all">Everywhere</option>
      {% for c in cities %}
      <option value="{{ c | slugify }}">{{ c }}</option>
      {% endfor %}
    </select>
  </div>
  <div class="media-toolbar-controls">
    <span class="sort-control">
      <label for="places-type">Type</label>
      <select id="places-type" class="sort-select">
        <option value="all">All</option>
        {% for t in types %}
        <option value="{{ t | slugify }}">{{ t }}</option>
        {% endfor %}
      </select>
    </span>
    <span class="sort-control">
      <label for="places-sort">Sort</label>
      <select id="places-sort" class="sort-select" data-sort-scope="#places-library .places-list" data-sort-item="tbody tr">
        <option value="rating">Rating</option>
        <option value="visits">Most visited</option>
        <option value="date">Recent</option>
        <option value="az">A→Z</option>
      </select>
    </span>
    <div class="media-toggle" role="group" aria-label="View mode">
      <button type="button" class="media-view-btn is-active" data-view="list">List</button>
      <button type="button" class="media-view-btn" data-view="map">Map</button>
    </div>
  </div>
</div>

<div id="places-library" class="view-list">

  <table class="index-table places-list">
    <thead>
      <tr>
        <th class="index-title">Name</th>
        <th class="index-meta">Type</th>
        <th class="index-meta">Where</th>
        <th class="index-date">Visits</th>
        <th class="index-date">Rating</th>
      </tr>
    </thead>
    <tbody>
    {% for v in venues %}
      {% assign disp = v.title | titlecase %}
      {% assign where = v.place_area | default: v.place_city %}
      <tr {% include place-row-attrs.html v=v %}>
        <td class="index-title"><a class="internal-link" href="{{ site.baseurl }}{{ v.url }}" title="{{ disp | escape }}">{{ disp }}</a></td>
        <td class="index-meta"><span class="tag">{{ v.place_type }}</span></td>
        <td class="index-meta muted" title="{% if v.place_area %}{{ v.place_area | escape }}, {% endif %}{{ v.place_city | escape }}">{{ where }}</td>
        <td class="index-date muted places-visits">{% if v.visit_count %}{{ v.visit_count }}{% endif %}</td>
        <td class="index-date muted media-rating">{%- if v.rating -%}<span class="rating-num" aria-label="{{ v.rating }} out of 7">{{ v.rating }}</span>{%- endif -%}</td>
      </tr>
    {% endfor %}
    </tbody>
  </table>

  <div class="places-map-outer">
    <div id="places-map" aria-label="Map of recommended places"></div>
    <p class="places-map-note muted" hidden></p>
  </div>

</div>

{%- comment -%}Leaflet 1.9.4 + Leaflet.markercluster 1.5.3, vendored
(assets/vendor/leaflet) rather than CDN-loaded so the page has one fewer
third-party dependency; only the CARTO basemap tiles are fetched
cross-origin. Cluster badges are styled in _sass/_places.scss (the plugin's
Default.css is deliberately not shipped).{%- endcomment -%}
<link rel="stylesheet" href="{{ site.baseurl }}/assets/vendor/leaflet/leaflet.css" />
<link rel="stylesheet" href="{{ site.baseurl }}/assets/vendor/leaflet/MarkerCluster.css" />
<script src="{{ site.baseurl }}/assets/vendor/leaflet/leaflet.js"></script>
<script src="{{ site.baseurl }}/assets/vendor/leaflet/leaflet.markercluster.js"></script>
<script src="{{ site.baseurl }}/assets/js/places-map.js"></script>

<script>
  (function () {
    var lib = document.getElementById('places-library');
    if (!lib) return;
    var rows = Array.prototype.slice.call(lib.querySelectorAll('.places-list tbody tr'));
    var viewBtns = document.querySelectorAll('.media-view-btn');
    var chips = document.querySelectorAll('.media-filters .tag');
    var destSelect = document.querySelector('.media-filter-select');
    var typeSelect = document.getElementById('places-type');
    var sortSelect = document.getElementById('places-sort');
    var mapNote = document.querySelector('.places-map-note');

    // Valid param values, read off the DOM so they track the baked filters.
    var DESTS = { all: 1 };
    chips.forEach(function (c) { DESTS[c.dataset.dest] = 1; });
    rows.forEach(function (r) { if (r.dataset.area) DESTS[r.dataset.area] = 1; });
    var TYPES = { all: 1 };
    if (typeSelect) Array.prototype.forEach.call(typeSelect.options, function (o) { TYPES[o.value] = 1; });
    var VIEWS = { list: 1, map: 1 };
    var SORTS = { rating: 1, visits: 1, date: 1, az: 1 };

    var currentDest = 'all';
    var currentType = 'all';
    var currentView = 'list';
    var ready = false;

    // ---- Map ----
    // Built lazily on the first switch to Map view so the list stays as light
    // as every other index page. The Leaflet setup itself (tiles, clustering,
    // popups, the near-me control) lives in assets/js/places-map.js, shared
    // with the destination mini-maps; the table rows stay the single source
    // the markers are built from.
    var mapView = null;

    function initMap() {
      if (mapView) return true;
      if (!window.PlacesMap) {
        var el = document.getElementById('places-map');
        if (el) el.innerHTML = '<p class="muted places-map-fallback">The map couldn’t load — the list above has everything.</p>';
        return false;
      }
      mapView = PlacesMap.create(document.getElementById('places-map'), rows, { locate: true });
      return true;
    }

    function syncMarkers(focusSlug) {
      if (!mapView) return;
      var res = mapView.sync(focusSlug);
      if (mapNote) {
        mapNote.hidden = res.unpinned === 0;
        mapNote.textContent = res.unpinned === 1
          ? '1 place here has no pin yet — it’s in the list view.'
          : res.unpinned + ' places here have no pins yet — they’re in the list view.';
      }
    }

    // ---- Filters / views (same pattern as /media/) ----
    function updateUrl() {
      if (!ready) return;
      var params = new URLSearchParams();
      if (currentDest !== 'all') params.set('dest', currentDest);
      if (currentType !== 'all') params.set('type', currentType);
      if (currentView !== 'list') params.set('view', currentView);
      var sort = sortSelect ? sortSelect.value : 'rating';
      if (sort !== 'rating') params.set('sort', sort);
      var qs = params.toString();
      history.replaceState(null, '', location.pathname + (qs ? '?' + qs : '') + location.hash);
    }

    // A dest matches a row's city or its neighborhood, so both "Vienna" and
    // "Cobble Hill" work as destinations even though chips only list cities.
    function applyVisibility(focusSlug) {
      rows.forEach(function (row) {
        var hide = currentDest !== 'all' && row.dataset.dest !== currentDest && row.dataset.area !== currentDest;
        if (!hide && currentType !== 'all' && row.dataset.type !== currentType) hide = true;
        row.classList.toggle('is-hidden', hide);
      });
      syncMarkers(focusSlug);
    }

    function setView(view, persist, focusSlug) {
      currentView = view;
      lib.classList.remove('view-list', 'view-map');
      lib.classList.add('view-' + view);
      viewBtns.forEach(function (b) { b.classList.toggle('is-active', b.dataset.view === view); });
      if (view === 'map' && initMap()) {
        mapView.map.invalidateSize();
        syncMarkers(focusSlug);
      }
      if (persist !== false) { try { localStorage.setItem('placesView', view); } catch (e) {} }
      updateUrl();
    }

    function setDest(dest) {
      currentDest = dest;
      chips.forEach(function (c) { c.classList.toggle('is-active', c.dataset.dest === dest); });
      // The chips only list cities; a neighborhood dest (from a ?dest= link)
      // has no chip, so fall the select back to "all" rather than a bad value.
      if (destSelect) destSelect.value = DESTS[dest] && destSelect.querySelector('option[value="' + dest + '"]') ? dest : 'all';
      applyVisibility();
      updateUrl();
    }

    viewBtns.forEach(function (b) { b.addEventListener('click', function () { setView(b.dataset.view); }); });
    chips.forEach(function (c) { c.addEventListener('click', function () { setDest(c.dataset.dest); }); });
    if (destSelect) destSelect.addEventListener('change', function () { setDest(destSelect.value); });
    if (typeSelect) typeSelect.addEventListener('change', function () { currentType = typeSelect.value; applyVisibility(); updateUrl(); });
    if (sortSelect) sortSelect.addEventListener('change', updateUrl);

    // ---- Initial state: URL params take precedence, then saved view ----
    var params = new URLSearchParams(location.search);
    var urlDest = params.get('dest');
    var urlType = params.get('type');
    var urlView = params.get('view');
    var urlSort = params.get('sort');
    var urlFocus = params.get('focus');

    if (urlDest && DESTS[urlDest]) setDest(urlDest);
    if (urlType && TYPES[urlType] && typeSelect) { typeSelect.value = urlType; currentType = urlType; }

    // Set the sort value before sortable.js runs its load-time sort.
    if (sortSelect && urlSort && SORTS[urlSort]) sortSelect.value = urlSort;

    var initView = 'list';
    if (urlFocus) {
      initView = 'map'; // a focus link is a map link
    } else if (urlView && VIEWS[urlView]) {
      initView = urlView;
    } else {
      try { var saved = localStorage.getItem('placesView'); if (VIEWS[saved]) initView = saved; } catch (e) {}
    }
    applyVisibility();
    setView(initView, urlView || urlFocus ? false : true, urlFocus);

    ready = true;
    updateUrl();
  })();
</script>
<script src="{{ site.baseurl }}/assets/js/sortable.js"></script>
