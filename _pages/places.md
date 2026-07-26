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
    <button type="button" class="tag places-export-btn" id="places-export-btn" aria-controls="places-export" aria-expanded="false">Export</button>
  </div>
</div>

<div id="places-export" class="places-export" role="region" aria-label="Export this view" hidden>
  <div class="places-export-head">
    <strong id="places-export-title">Coop&rsquo;s Guide</strong>
    <span class="places-export-count" id="places-export-count"></span>
  </div>
  <textarea id="places-export-text" rows="12" readonly spellcheck="false" aria-label="Trip-planning prompt"></textarea>
  <div class="places-export-actions">
    <button type="button" class="tag" id="places-export-copy">Copy prompt</button>
    <button type="button" class="tag" id="places-export-kml">Download .kml for Google My Maps</button>
  </div>
  <p class="muted places-export-hint">The prompt takes this view to ChatGPT, Claude, or wherever you plan trips. The .kml imports at <a href="https://mymaps.google.com">Google My Maps</a> (Create a map → Import) and opens in Google Earth &amp; friends.</p>
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
      refreshExport();
    }

    // ---- Export: take the current filtered view with you ----
    // Two takeaways, both named from the active filters ("Coop's Guide to
    // Bars + Cocktails in Cobble Hill"): a copyable trip-planning prompt for
    // whatever LLM the visitor uses, and a .kml of the pinned venues that
    // imports into Google My Maps / Google Earth. Built entirely from the
    // visible table rows, so it always matches what's on screen.
    var exportBtn = document.getElementById('places-export-btn');
    var exportPanel = document.getElementById('places-export');
    var exportTitle = document.getElementById('places-export-title');
    var exportCount = document.getElementById('places-export-count');
    var exportText = document.getElementById('places-export-text');
    var exportCopy = document.getElementById('places-export-copy');
    var exportKml = document.getElementById('places-export-kml');

    function visibleRows() {
      // Query the live DOM (not the load-time `rows` array) so the export
      // follows the current sort order too.
      return Array.prototype.slice.call(lib.querySelectorAll('.places-list tbody tr:not(.is-hidden)'));
    }

    function rowName(row) {
      var a = row.querySelector('.index-title a');
      return a ? a.textContent.trim() : '';
    }

    function destLabel() {
      if (currentDest === 'all') return null;
      var chip = document.querySelector('.media-filters .tag[data-dest="' + currentDest + '"]');
      if (chip) return chip.textContent.trim();
      // A neighborhood deep-link has no chip; recover the display name from
      // any matching row's "area, city" string.
      for (var i = 0; i < rows.length; i++) {
        if (rows[i].dataset.area === currentDest) return rows[i].dataset.where.split(',')[0].trim();
      }
      return currentDest.replace(/-/g, ' ');
    }

    function typeLabel() {
      if (!typeSelect || typeSelect.value === 'all') return null;
      return typeSelect.options[typeSelect.selectedIndex].textContent.trim();
    }

    function guideTitle() {
      var t = typeLabel();
      var d = destLabel();
      if (t && d) return 'Coop’s Guide to ' + t + ' in ' + d;
      if (t) return 'Coop’s Guide to ' + t;
      if (d) return 'Coop’s Guide to ' + d;
      return 'Coop’s Favorite Places';
    }

    function promptEntry(row, i) {
      var d = row.dataset;
      var name = rowName(row);
      var head = (i + 1) + '. ' + name;
      var meta = [];
      if (d.typename) meta.push(d.typename);
      if (d.where) meta.push(d.where);
      if (meta.length) head += ' — ' + meta.join(' · ');
      var lines = [head];
      var facts = [];
      if (+d.rating > 0) facts.push('Coop’s rating: ' + d.rating + '/7');
      if (+d.visits > 0) facts.push(d.visits + (+d.visits === 1 ? ' visit' : ' visits'));
      if (facts.length) lines.push('   ' + facts.join(' · '));
      if (d.desc) lines.push('   ' + d.desc);
      if (d.lat) lines.push('   Coordinates: ' + (+d.lat).toFixed(5) + ', ' + (+d.lng).toFixed(5));
      lines.push('   Google Maps: https://www.google.com/maps/search/?api=1&query=' + encodeURIComponent(name + (d.where ? ', ' + d.where : '')));
      lines.push('   Coop’s notes: ' + location.origin + d.url);
      return lines.join('\n');
    }

    function buildPrompt(title, list) {
      var d = destLabel();
      return [
        title,
        '',
        'A hand-picked list from Cooper Smith’s site — live version: ' + location.href,
        '',
        'You are my trip-planning assistant. Below are ' + list.length + ' places Coop recommends' + (d ? ' in ' + d : '') + '. Help me make the most of them: answer questions about them, build an itinerary, or help me save them to my maps app of choice. Ratings are Coop’s own, out of 7; the visit count is how many times he’s actually been, which is a strong signal.',
        ''
      ].join('\n') + '\n' + list.map(promptEntry).join('\n\n') + '\n';
    }

    function xmlEscape(s) {
      return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
    }

    function buildKml(title, list) {
      var marks = list.filter(function (r) { return r.dataset.lat; }).map(function (row) {
        var d = row.dataset;
        var bits = [];
        if (d.typename) bits.push(d.typename + (d.where ? ' · ' + d.where : ''));
        if (+d.rating > 0) bits.push('Coop’s rating: ' + d.rating + '/7');
        if (+d.visits > 0) bits.push(d.visits + (+d.visits === 1 ? ' visit' : ' visits'));
        if (d.desc) bits.push(d.desc);
        bits.push(location.origin + d.url);
        return '    <Placemark>\n' +
          '      <name>' + xmlEscape(rowName(row)) + '</name>\n' +
          '      <description>' + xmlEscape(bits.join('\n')) + '</description>\n' +
          '      <Point><coordinates>' + d.lng + ',' + d.lat + '</coordinates></Point>\n' +
          '    </Placemark>';
      });
      return '<?xml version="1.0" encoding="UTF-8"?>\n' +
        '<kml xmlns="http://www.opengis.net/kml/2.2">\n  <Document>\n' +
        '    <name>' + xmlEscape(title) + '</name>\n' +
        marks.join('\n') + '\n  </Document>\n</kml>\n';
    }

    function slugifyTitle(s) {
      return s.toLowerCase().replace(/['’]/g, '').replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
    }

    function refreshExport() {
      if (!exportPanel || exportPanel.hidden) return;
      var list = visibleRows();
      var title = guideTitle();
      var pinned = list.filter(function (r) { return r.dataset.lat; }).length;
      exportTitle.textContent = title;
      exportCount.textContent = list.length + (list.length === 1 ? ' place' : ' places') +
        (pinned < list.length ? ' · ' + pinned + ' mappable' : '');
      exportText.value = list.length ? buildPrompt(title, list) : 'Nothing matches these filters.';
      if (exportCopy) exportCopy.disabled = !list.length;
      if (exportKml) exportKml.disabled = !pinned;
    }

    if (exportBtn && exportPanel) {
      exportBtn.addEventListener('click', function () {
        exportPanel.hidden = !exportPanel.hidden;
        exportBtn.classList.toggle('is-active', !exportPanel.hidden);
        exportBtn.setAttribute('aria-expanded', String(!exportPanel.hidden));
        refreshExport();
      });
      exportText.addEventListener('focus', function () { exportText.select(); });
      exportCopy.addEventListener('click', function () {
        var done = function () {
          exportCopy.textContent = 'Copied ✓';
          setTimeout(function () { exportCopy.textContent = 'Copy prompt'; }, 1600);
        };
        if (navigator.clipboard && navigator.clipboard.writeText) {
          navigator.clipboard.writeText(exportText.value).then(done, function () { exportText.select(); });
        } else {
          exportText.select();
          try { document.execCommand('copy'); done(); } catch (e) {}
        }
      });
      exportKml.addEventListener('click', function () {
        var title = guideTitle();
        var blob = new Blob([buildKml(title, visibleRows())], { type: 'application/vnd.google-earth.kml+xml' });
        var a = document.createElement('a');
        a.href = URL.createObjectURL(blob);
        a.download = slugifyTitle(title) + '.kml';
        document.body.appendChild(a);
        a.click();
        a.remove();
        setTimeout(function () { URL.revokeObjectURL(a.href); }, 5000);
      });
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
