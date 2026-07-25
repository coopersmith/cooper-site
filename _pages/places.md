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
      <tr data-dest="{{ v.place_city | slugify }}"
          data-area="{{ v.place_area | slugify }}"
          data-type="{{ v.place_type | slugify }}"
          data-slug="{{ v.title | slugify }}"
          data-title="{{ disp | downcase | escape }}"
          data-rating="{{ v.rating | default: 0 }}"
          data-visits="{{ v.visit_count | default: 0 }}"
          data-date="{% if v.last_visit %}{{ v.last_visit | date: '%Y-%m-%d' }}{% endif %}"
          data-lat="{{ v.place_lat }}"
          data-lng="{{ v.place_lng }}"
          data-typename="{{ v.place_type | escape }}"
          data-where="{% if v.place_area %}{{ v.place_area | escape }}, {% endif %}{{ v.place_city | escape }}"
          data-desc="{{ v.description | default: '' | strip | escape }}"
          data-url="{{ site.baseurl }}{{ v.url }}">
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

    // ---- Map (Leaflet + CARTO's Positron/Dark Matter raster tiles) ----
    // Built lazily on the first switch to Map view so the list stays as light
    // as every other index page. Markers mirror the table rows: the row *is*
    // the data (coords, popup facts) and filters drive both views at once.
    var map = null;
    var tiles = null;
    var pins = null; // the cluster group (or the map itself if the plugin is missing)
    var darkQuery = window.matchMedia('(prefers-color-scheme: dark)');

    function tileUrl() {
      var flavor = darkQuery.matches ? 'dark_all' : 'light_all';
      return 'https://{s}.basemaps.cartocdn.com/' + flavor + '/{z}/{x}/{y}{r}.png';
    }

    function markerStyle() {
      var css = getComputedStyle(document.documentElement);
      return {
        radius: 7,
        weight: 1.5,
        color: css.getPropertyValue('--color-bg-primary').trim() || '#fff',
        fillColor: css.getPropertyValue('--color-accent').trim() || '#121316',
        fillOpacity: 0.92
      };
    }

    function diamonds(n) {
      n = Math.max(0, Math.min(7, parseInt(n, 10) || 0));
      return '◆'.repeat(n) + '◇'.repeat(7 - n);
    }

    function popupHtml(row) {
      var d = row.dataset;
      var name = row.querySelector('.index-title a');
      var html = '<a class="pp-name internal-link" href="' + d.url + '">' + (name ? name.textContent : '') + '</a>';
      var sub = [];
      if (d.typename) sub.push(d.typename);
      if (d.where) sub.push(d.where);
      if (sub.length) html += '<span class="pp-sub">' + sub.join(' · ') + '</span>';
      var facts = [];
      if (parseInt(d.rating, 10) > 0) facts.push('<span class="pp-rating" title="' + d.rating + '/7">' + diamonds(d.rating) + '</span>');
      var visits = parseInt(d.visits, 10) || 0;
      if (visits > 1) facts.push(visits + ' visits');
      else if (visits === 1) facts.push('1 visit');
      if (facts.length) html += '<span class="pp-facts">' + facts.join(' · ') + '</span>';
      if (d.desc) html += '<span class="pp-desc">' + d.desc + '</span>';
      return '<div class="places-popup">' + html + '</div>';
    }

    function initMap() {
      if (map) return true;
      if (typeof L === 'undefined') {
        var el = document.getElementById('places-map');
        if (el) el.innerHTML = '<p class="muted places-map-fallback">The map couldn’t load — the list above has everything.</p>';
        return false;
      }
      // Wheel zoom only after the map is clicked, so scrolling the page past
      // a full-width map doesn't hijack into a zoom.
      map = L.map('places-map', { scrollWheelZoom: false, worldCopyJump: true });
      map.on('focus click', function () { map.scrollWheelZoom.enable(); });
      map.on('mouseout', function () { map.scrollWheelZoom.disable(); });

      tiles = L.tileLayer(tileUrl(), {
        maxZoom: 19,
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>'
      }).addTo(map);

      // Overlapping pins (same block, or the same building — hi, Gift Horse
      // and Oberlin) roll up into a count badge that zooms in on click and
      // fans out (spiderfies) at max zoom. Falls back to plain markers if the
      // cluster plugin didn't load.
      if (typeof L.markerClusterGroup === 'function') {
        pins = L.markerClusterGroup({
          maxClusterRadius: 44,
          showCoverageOnHover: false,
          iconCreateFunction: function (cluster) {
            var n = cluster.getChildCount();
            return L.divIcon({
              html: '<span>' + n + '</span>',
              className: 'places-cluster',
              iconSize: L.point(30, 30)
            });
          }
        });
        map.addLayer(pins);
      } else {
        pins = map;
      }

      var style = markerStyle();
      rows.forEach(function (row) {
        var lat = parseFloat(row.dataset.lat);
        var lng = parseFloat(row.dataset.lng);
        if (isNaN(lat) || isNaN(lng)) return;
        row._marker = L.circleMarker([lat, lng], style).bindPopup(popupHtml(row));
      });

      // Re-skin tiles + markers if the OS theme flips while the page is open.
      var onTheme = function () {
        tiles.setUrl(tileUrl());
        var s = markerStyle();
        rows.forEach(function (row) { if (row._marker) row._marker.setStyle(s); });
      };
      if (darkQuery.addEventListener) darkQuery.addEventListener('change', onTheme);

      map.setView([20, 0], 2); // placeholder; syncMarkers fits to the pins
      return true;
    }

    function syncMarkers(focusSlug) {
      if (!map) return;
      var shown = [];
      var unpinned = 0;
      rows.forEach(function (row) {
        var visible = !row.classList.contains('is-hidden');
        if (!row._marker) {
          if (visible) unpinned++;
          return;
        }
        if (visible) {
          pins.addLayer(row._marker);
          shown.push(row._marker.getLatLng());
        } else {
          pins.removeLayer(row._marker);
        }
      });
      if (mapNote) {
        mapNote.hidden = unpinned === 0;
        mapNote.textContent = unpinned === 1
          ? '1 place here has no pin yet — it’s in the list view.'
          : unpinned + ' places here have no pins yet — they’re in the list view.';
      }

      var focused = null;
      if (focusSlug) {
        rows.some(function (row) {
          if (row.dataset.slug === focusSlug && row._marker && !row.classList.contains('is-hidden')) {
            focused = row._marker;
            return true;
          }
          return false;
        });
      }
      if (focused) {
        // The focused marker may be swallowed by a cluster; let the plugin
        // unfold down to it (spiderfying if it shares a spot) before opening.
        if (pins !== map && pins.zoomToShowLayer) {
          pins.zoomToShowLayer(focused, function () { focused.openPopup(); });
        } else {
          map.setView(focused.getLatLng(), 16);
          focused.openPopup();
        }
      } else if (shown.length) {
        map.fitBounds(L.latLngBounds(shown), { padding: [40, 40], maxZoom: 15 });
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
        map.invalidateSize();
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
