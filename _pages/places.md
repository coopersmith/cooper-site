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
{% assign tree = site.data.places_tree %}

{% assign types = "" | split: "" %}
{% for v in venues %}
  {% if v.place_type and v.place_type != '' %}{% unless types contains v.place_type %}{% assign types = types | push: v.place_type %}{% endunless %}{% endif %}
{% endfor %}
{% assign types = types | sort %}

{%- comment -%}Destination filter: a drill-down over the country → city →
neighborhood tree, one row per tier. A flat chip per city didn't scale — the
number of chips grew with the number of places (47 venues had produced 26 city
chips, 17 of them filtering to a single venue), and neighborhoods had no chip
at all. The country row, by contrast, is bounded by how much of the world
you've been to, and the rows below it only appear for branches you've opened.

Every tier is multi-select and they compose: Italy, or Florence + Milan, or
Florence + Tokyo. Selecting a child of a selected parent narrows (Italy →
Florence) rather than un-checking it, which is the gesture people actually
want from a drill-down; the parent then renders "mixed". All three rows are
baked into the DOM and shown/hidden by the script, so there's nothing to
construct at runtime.{%- endcomment -%}
<div class="media-toolbar places-toolbar">
  <div class="places-dest" role="group" aria-label="Filter by destination">
    <div class="places-tier" data-tier="1">
      <button type="button" class="tag places-clear is-active" id="places-clear" aria-pressed="true">Everywhere</button>
      {% for c in tree %}{% include place-chip.html n=c %}{% endfor %}
    </div>
    <div class="places-tier" data-tier="2" hidden>
      {% for c in tree %}{% for city in c.children %}{% include place-chip.html n=city %}{% endfor %}{% endfor %}
    </div>
    <div class="places-tier" data-tier="3" hidden>
      {% for c in tree %}{% for city in c.children %}{% for a in city.children %}{% include place-chip.html n=a %}{% endfor %}{% endfor %}{% endfor %}
    </div>
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
    {%- comment -%}Recency scope: some recommendations are a decade stale, so
    this narrows the list to places I've actually been lately. Values are a
    number of years back (or "all"); the cutoff is computed at runtime, not
    baked, so a scoped view never goes stale itself.{%- endcomment -%}
    <span class="sort-control">
      <label for="places-visited">Visited</label>
      <select id="places-visited" class="sort-select">
        <option value="all">Any time</option>
        <option value="1">Past year</option>
        <option value="2">Past 2 years</option>
        <option value="5">Past 5 years</option>
        <option value="10">Past 10 years</option>
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
      {% assign where = v.place_area | default: v.place_city | default: v.place_country %}
      {%- comment -%}The jump targets the most specific node the venue has, so
      a country-only venue still lands somewhere real.{%- endcomment -%}
      {% assign root_slug = v.place_path | first %}
      {% assign where_slug = v.place_area_slug | default: v.place_city_slug | default: root_slug %}
      <tr {% include place-row-attrs.html v=v %}>
        <td class="index-title"><a class="internal-link" href="{{ site.baseurl }}{{ v.url }}" title="{{ disp | escape }}">{{ disp }}</a></td>
        <td class="index-meta"><span class="tag">{{ v.place_type }}</span></td>
        {%- comment -%}The where name is a jump control: it filters to that
        destination and swings the map to it (see jumpToDest). Falls back to
        plain text with no JS.{%- endcomment -%}
        <td class="index-meta muted" title="{% if v.place_area %}{{ v.place_area | escape }}, {% endif %}{{ v.place_city | default: v.place_country | escape }}"><button type="button" class="place-jump" data-dest-jump="{{ where_slug }}" aria-label="Show {{ where | escape }} on the map">{{ where }}</button></td>
        <td class="index-date muted places-visits"{% if v.last_visit %} title="Last visit {{ v.last_visit | date: '%B %Y' }}"{% endif %}>{% if v.visit_count %}{{ v.visit_count }}{% endif %}</td>
        <td class="index-date muted media-rating">{%- if v.rating -%}<span class="rating-num" aria-label="{{ v.rating }} out of 7">{{ v.rating }}</span>{%- endif -%}</td>
      </tr>
    {% endfor %}
    </tbody>
  </table>

  {%- comment -%}Filters could always come up empty, but the recency scope
  makes it likely (a city you last saw in 2016, scoped to the past year), so
  say so rather than showing a bare empty table.{%- endcomment -%}
  <p class="places-empty muted" hidden></p>

  <div class="places-map-outer">
    <div id="places-map" aria-label="Map of recommended places"></div>
    <p class="places-map-note muted" hidden></p>
  </div>

</div>

{%- comment -%}Export sits under the list/map: it's what you do *after*
filtering to the trip you're planning, not another filter control.{%- endcomment -%}
<div class="places-export-bar">
  <button type="button" class="tag places-export-btn" id="places-export-btn" aria-controls="places-export" aria-expanded="false">Export this view</button>
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
    var destWrap = document.querySelector('.places-dest');
    var nodeBtns = Array.prototype.slice.call(destWrap.querySelectorAll('.places-node'));
    var tierRows = Array.prototype.slice.call(destWrap.querySelectorAll('.places-tier'));
    var clearBtn = document.getElementById('places-clear');
    var typeSelect = document.getElementById('places-type');
    var visitedSelect = document.getElementById('places-visited');
    var sortSelect = document.getElementById('places-sort');
    var mapNote = document.querySelector('.places-map-note');
    var emptyNote = document.querySelector('.places-empty');

    // ---- The destination tree, read off the chips ----
    // The markup is the index: each chip knows its slug, tier and parent, so
    // the script never needs a duplicate copy of site.data.places_tree.
    var NODES = {};
    nodeBtns.forEach(function (b) {
      NODES[b.dataset.node] = {
        slug: b.dataset.node,
        name: b.dataset.name,
        parent: b.dataset.parent || null,
        el: b,
        kids: []
      };
    });
    Object.keys(NODES).forEach(function (slug) {
      var p = NODES[slug].parent;
      if (p && NODES[p]) NODES[p].kids.push(NODES[slug]);
    });

    var TYPES = { all: 1 };
    if (typeSelect) Array.prototype.forEach.call(typeSelect.options, function (o) { TYPES[o.value] = 1; });
    var VISITED = { all: 1 };
    if (visitedSelect) Array.prototype.forEach.call(visitedSelect.options, function (o) { VISITED[o.value] = 1; });
    var VIEWS = { list: 1, map: 1 };
    var SORTS = { rating: 1, visits: 1, date: 1, az: 1 };

    // Selected destination nodes, in the order they were picked (the export
    // title reads back in that order). Empty means Everywhere.
    var selection = [];
    var currentType = 'all';
    var currentVisited = 'all';
    var currentView = 'list';
    var ready = false;

    // ---- Recency ----
    // Rows carry data-date = last_visit (YYYY-MM-DD), so the cutoff is just
    // another YYYY-MM-DD string and the compare stays a lexicographic one —
    // no Date parsing, no timezone drift. A venue with no recorded visit
    // can't be shown to be recent, so it drops out of any scoped view.
    function visitedCutoff() {
      if (currentVisited === 'all') return null;
      var years = parseInt(currentVisited, 10);
      if (!years) return null;
      var d = new Date();
      d.setFullYear(d.getFullYear() - years);
      var pad = function (n) { return (n < 10 ? '0' : '') + n; };
      return d.getFullYear() + '-' + pad(d.getMonth() + 1) + '-' + pad(d.getDate());
    }

    function withinScope(row, cutoff) {
      return !cutoff || (row.dataset.date && row.dataset.date >= cutoff);
    }

    // ---- Destination tree ----
    function isSelected(slug) { return selection.indexOf(slug) !== -1; }

    function ancestors(slug) {
      var out = [];
      var n = NODES[slug];
      while (n && n.parent) { out.push(n.parent); n = NODES[n.parent]; }
      return out;
    }

    function descendants(slug) {
      var out = [];
      var stack = NODES[slug] ? NODES[slug].kids.slice() : [];
      while (stack.length) {
        var n = stack.pop();
        out.push(n.slug);
        stack.push.apply(stack, n.kids);
      }
      return out;
    }

    // on = this whole branch; mixed = the visitor narrowed to some of it.
    function nodeState(slug) {
      if (isSelected(slug)) return 'on';
      return descendants(slug).some(isSelected) ? 'mixed' : 'off';
    }

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
      mapView = PlacesMap.create(document.getElementById('places-map'), rows, {
        locate: true,
        // Popup place names become jump controls, same as the list's "Where".
        destLinks: true
      });
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

    // ---- Destination selection ----
    // Clicking a chip toggles its branch. Two rules make multi-select and
    // drill-down coexist:
    //
    //   * Picking a node inside one you'd already selected *narrows* — "all of
    //     Italy" becomes "just Florence" — instead of un-checking Florence out
    //     of Italy, which is never what you meant. Italy then shows as mixed,
    //     and clicking it again re-selects the whole country.
    //   * Picking a node that contains selected ones subsumes them, so the
    //     selection never holds a node and its own descendant.
    //
    // Everything else is a plain toggle, so Florence + Milan + Tokyo compose.
    function toggleNode(slug) {
      if (!NODES[slug]) return;
      if (isSelected(slug)) {
        selection = selection.filter(function (s) { return s !== slug; });
      } else {
        var anc = ancestors(slug).filter(isSelected);
        var desc = descendants(slug);
        selection = selection.filter(function (s) {
          return anc.indexOf(s) === -1 && desc.indexOf(s) === -1;
        });
        selection.push(slug);
      }
      applyDest();
    }

    function renderChips() {
      nodeBtns.forEach(function (b) {
        var state = nodeState(b.dataset.node);
        b.classList.toggle('is-active', state === 'on');
        b.classList.toggle('is-mixed', state === 'mixed');
        b.setAttribute('aria-pressed', state === 'on' ? 'true' : state === 'mixed' ? 'mixed' : 'false');
        // A tier only opens under a branch that's on or narrowed into.
        var parent = b.dataset.parent;
        var parentState = parent ? nodeState(parent) : 'on';
        b.hidden = parentState === 'off';
      });
      tierRows.forEach(function (row) {
        if (row.dataset.tier === '1') return;
        row.hidden = !Array.prototype.some.call(
          row.querySelectorAll('.places-node'), function (b) { return !b.hidden; });
      });
      clearBtn.classList.toggle('is-active', selection.length === 0);
      clearBtn.setAttribute('aria-pressed', String(selection.length === 0));
      revealSelected();
    }

    // On a narrow screen each tier is a horizontal rail (see _places.scss), so
    // the branch you just opened can sit off to the right, out of sight. Nudge
    // each rail to its first on/mixed chip. Measured off bounding rects rather
    // than offsetLeft, which is relative to the offset parent and not the rail;
    // no-ops on desktop, where the rows wrap instead of scrolling.
    function revealSelected() {
      tierRows.forEach(function (row) {
        if (row.hidden || row.scrollWidth <= row.clientWidth) return;
        var chip = null;
        Array.prototype.some.call(row.querySelectorAll('.places-node'), function (b) {
          if (b.hidden || !(b.classList.contains('is-active') || b.classList.contains('is-mixed'))) return false;
          chip = b;
          return true;
        });
        if (!chip) return;
        var c = chip.getBoundingClientRect();
        var r = row.getBoundingClientRect();
        if (c.left < r.left || c.right > r.right) row.scrollLeft += c.left - r.left - 12;
      });
    }

    // Counts are live against the *other* filters (type and visited), so
    // "Poland 4" drops to "Poland 0" under Hotels — or under a visit window
    // Poland falls outside of — rather than promising places that aren't
    // there. A zero branch dims but stays clickable.
    function renderCounts() {
      var tally = {};
      var cutoff = visitedCutoff();
      rows.forEach(function (row) {
        if (currentType !== 'all' && row.dataset.type !== currentType) return;
        if (!withinScope(row, cutoff)) return;
        (row.dataset.path || '').split(' ').forEach(function (s) {
          if (s) tally[s] = (tally[s] || 0) + 1;
        });
      });
      nodeBtns.forEach(function (b) {
        var n = tally[b.dataset.node] || 0;
        var badge = b.querySelector('.places-node-n');
        if (badge) badge.textContent = n;
        b.classList.toggle('is-empty', n === 0);
      });
    }

    function applyDest(focusSlug) {
      renderChips();
      renderCounts();
      applyVisibility(focusSlug);
      updateUrl();
    }

    // ---- Filters / views (same pattern as /media/) ----
    function updateUrl() {
      if (!ready) return;
      var params = new URLSearchParams();
      if (selection.length) params.set('dest', selection.join(','));
      if (currentType !== 'all') params.set('type', currentType);
      if (currentVisited !== 'all') params.set('visited', currentVisited);
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

    // "Florence", "Florence & Milan", "Florence, Milan & Tokyo" — every
    // selected node has a chip, so the names come straight off them.
    function destLabel() {
      var names = selection.map(function (s) {
        return NODES[s] ? NODES[s].name : s.replace(/-/g, ' ');
      });
      if (!names.length) return null;
      if (names.length === 1) return names[0];
      return names.slice(0, -1).join(', ') + ' & ' + names[names.length - 1];
    }

    function typeLabel() {
      if (!typeSelect || typeSelect.value === 'all') return null;
      return typeSelect.options[typeSelect.selectedIndex].textContent.trim();
    }

    function visitedLabel() {
      if (!visitedSelect || currentVisited === 'all') return null;
      return visitedSelect.options[visitedSelect.selectedIndex].textContent.trim().toLowerCase();
    }

    // "2025-09-13" → "September 2025". Kept off Date parsing (a bare
    // YYYY-MM-DD is UTC, which slides a day back in western timezones).
    var MONTHS = ['January', 'February', 'March', 'April', 'May', 'June', 'July',
      'August', 'September', 'October', 'November', 'December'];
    function prettyDate(iso) {
      var m = /^(\d{4})-(\d{2})/.exec(iso || '');
      return m ? MONTHS[+m[2] - 1] + ' ' + m[1] : null;
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
      var last = prettyDate(d.date);
      if (last) facts.push('last visit ' + last);
      if (facts.length) lines.push('   ' + facts.join(' · '));
      if (d.desc) lines.push('   ' + d.desc);
      if (d.lat) lines.push('   Coordinates: ' + (+d.lat).toFixed(5) + ', ' + (+d.lng).toFixed(5));
      lines.push('   Google Maps: https://www.google.com/maps/search/?api=1&query=' + encodeURIComponent(name + (d.where ? ', ' + d.where : '')));
      lines.push('   Coop’s notes: ' + location.origin + d.url);
      return lines.join('\n');
    }

    function buildPrompt(title, list) {
      var d = destLabel();
      var v = visitedLabel();
      return [
        title,
        '',
        'A hand-picked list from Cooper Smith’s site — live version: ' + location.href,
        '',
        'You are my trip-planning assistant. Below are ' + list.length + ' places Coop recommends' + (d ? ' in ' + d : '') + (v ? ', each one he’s visited in the ' + v : '') + '. Help me make the most of them: answer questions about them, build an itinerary, or help me save them to my maps app of choice. Ratings are Coop’s own, out of 7; the visit count is how many times he’s actually been, which is a strong signal, and the last-visit date tells you how current the recommendation is.',
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
        var last = prettyDate(d.date);
        if (last) bits.push('Last visit: ' + last);
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

    // A row carries its whole ancestry in data-path ("united-states
    // new-york-city cobble-hill"), so one `indexOf` answers for every tier:
    // "United States", "New York City" and "Cobble Hill" all match this row,
    // and any one selected node matching is enough.
    function matchesDest(row) {
      if (!selection.length) return true;
      var path = (row.dataset.path || '').split(' ');
      return selection.some(function (s) { return path.indexOf(s) !== -1; });
    }

    function applyVisibility(focusSlug) {
      var cutoff = visitedCutoff();
      var shown = 0;
      rows.forEach(function (row) {
        var hide = !matchesDest(row);
        if (!hide && currentType !== 'all' && row.dataset.type !== currentType) hide = true;
        if (!hide && !withinScope(row, cutoff)) hide = true;
        row.classList.toggle('is-hidden', hide);
        if (!hide) shown++;
      });
      if (emptyNote) {
        emptyNote.hidden = shown > 0;
        var v = visitedLabel();
        emptyNote.textContent = v
          ? 'Nothing here I’ve been to in the ' + v + ' — try a wider visit window.'
          : 'Nothing matches these filters.';
      }
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

    // Clicking a place name — in the list's "Where" column or in a map popup
    // — filters to that destination and swings the map to it. It replaces the
    // selection rather than adding to it: it's a "take me there" gesture, and
    // the drill-down rows are how you build a set. The whole point is the map
    // move, so it switches to Map view when you're in the list.
    function jumpToDest(slug) {
      if (!slug || !NODES[slug]) return;
      if (mapView) mapView.map.closePopup();
      selection = [slug];
      applyDest(); // in map view this already refits to the new pin set
      if (currentView !== 'map') setView('map');
    }

    lib.addEventListener('click', function (e) {
      var el = e.target.closest && e.target.closest('[data-dest-jump]');
      if (!el) return;
      e.preventDefault();
      jumpToDest(el.getAttribute('data-dest-jump'));
    });

    viewBtns.forEach(function (b) { b.addEventListener('click', function () { setView(b.dataset.view); }); });
    destWrap.addEventListener('click', function (e) {
      var chip = e.target.closest && e.target.closest('.places-node');
      if (chip) toggleNode(chip.dataset.node);
    });
    clearBtn.addEventListener('click', function () { selection = []; applyDest(); });
    if (typeSelect) typeSelect.addEventListener('change', function () {
      currentType = typeSelect.value;
      renderCounts();
      applyVisibility();
      updateUrl();
    });
    if (visitedSelect) visitedSelect.addEventListener('change', function () {
      currentVisited = visitedSelect.value;
      renderCounts();
      applyVisibility();
      updateUrl();
    });
    if (sortSelect) sortSelect.addEventListener('change', updateUrl);

    // ---- Initial state: URL params take precedence, then saved view ----
    var params = new URLSearchParams(location.search);
    var urlDest = params.get('dest');
    var urlType = params.get('type');
    var urlVisited = params.get('visited');
    var urlView = params.get('view');
    var urlSort = params.get('sort');
    var urlFocus = params.get('focus');

    // ?dest= is a comma-separated list of node slugs; unknown ones are
    // dropped rather than emptying the page. A single-value link from before
    // the tree ("?dest=cobble-hill") still resolves — those slugs are nodes.
    if (urlDest) {
      var seenDest = {};
      selection = urlDest.split(',').map(function (s) { return s.trim(); })
        .filter(function (s) {
          if (!NODES[s] || seenDest[s]) return false;
          seenDest[s] = 1;
          return true;
        });
    }
    if (urlType && TYPES[urlType] && typeSelect) { typeSelect.value = urlType; currentType = urlType; }
    if (urlVisited && VISITED[urlVisited] && visitedSelect) { visitedSelect.value = urlVisited; currentVisited = urlVisited; }

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
    renderChips();
    renderCounts();
    applyVisibility();
    setView(initView, urlView || urlFocus ? false : true, urlFocus);

    ready = true;
    updateUrl();
  })();
</script>
<script src="{{ site.baseurl }}/assets/js/sortable.js"></script>
