// Shared Leaflet runtime for the Places maps: the full map view on /places/
// and the mini-map on destination notes (place layout). Both render pins
// from table rows — the row *is* the data: coordinates, popup facts, and
// (on /places/) filter visibility all come off its data attributes.
//
//   PlacesMap.create(container, rows, opts) -> handle
//     opts.locate    add a "places near me" geolocation control
//     handle.map     the Leaflet map
//     handle.sync(focusSlug)
//       re-syncs markers with row visibility (.is-hidden), fits the view,
//       and optionally focuses one venue's popup (unfolding its cluster);
//       returns {shown, unpinned} counts for the caller's messaging.
//
// Tiles are CARTO's Positron / Dark Matter following prefers-color-scheme;
// overlapping pins cluster into count badges (falling back to plain markers
// if Leaflet.markercluster didn't load).
(function () {
  if (typeof L === 'undefined') return;

  var darkQuery = window.matchMedia('(prefers-color-scheme: dark)');

  function tileUrl() {
    var flavor = darkQuery.matches ? 'dark_all' : 'light_all';
    return 'https://{s}.basemaps.cartocdn.com/' + flavor + '/{z}/{x}/{y}{r}.png';
  }

  function css(name, fallback) {
    return getComputedStyle(document.documentElement).getPropertyValue(name).trim() || fallback;
  }

  function markerStyle() {
    return {
      radius: 7,
      weight: 1.5,
      color: css('--color-bg-primary', '#fff'),
      fillColor: css('--color-accent', '#121316'),
      fillOpacity: 0.92
    };
  }

  // The visitor's own position: an inverted dot, so it can't be mistaken
  // for a venue.
  function youStyle() {
    return {
      radius: 6,
      weight: 2,
      color: css('--color-accent', '#121316'),
      fillColor: css('--color-bg-primary', '#fff'),
      fillOpacity: 0.95
    };
  }

  function diamonds(n) {
    n = Math.max(0, Math.min(7, parseInt(n, 10) || 0));
    return '◆'.repeat(n) + '◇'.repeat(7 - n);
  }

  function esc(s) {
    return String(s == null ? '' : s)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }

  // The popup's "Cobble Hill, New York City" — each part its own jump control
  // when the host page asked for them (opts.destLinks), plain text otherwise
  // (destination mini-maps have nothing to filter).
  function placeParts(d, destLinks) {
    var parts = [];
    if (d.areaname) parts.push([d.areaname, d.area]);
    if (d.cityname) parts.push([d.cityname, d.dest]);
    if (!parts.length) return d.where ? esc(d.where) : '';
    return parts.map(function (p) {
      if (!destLinks || !p[1]) return esc(p[0]);
      return '<button type="button" class="pp-place" data-dest-jump="' + esc(p[1]) +
        '" aria-label="Show ' + esc(p[0]) + ' on the map">' + esc(p[0]) + '</button>';
    }).join(', ');
  }

  function popupHtml(row, opts) {
    var d = row.dataset;
    var name = row.querySelector('.index-title a');
    var html = '<a class="pp-name internal-link" href="' + esc(d.url) + '">' + esc(name ? name.textContent : '') + '</a>';
    var sub = [];
    if (d.typename) sub.push(esc(d.typename));
    var place = placeParts(d, opts.destLinks);
    if (place) sub.push(place);
    if (sub.length) html += '<span class="pp-sub">' + sub.join(' · ') + '</span>';
    var facts = [];
    if (parseInt(d.rating, 10) > 0) facts.push('<span class="pp-rating" title="' + d.rating + '/7">' + diamonds(d.rating) + '</span>');
    var visits = parseInt(d.visits, 10) || 0;
    if (visits > 1) facts.push(visits + ' visits');
    else if (visits === 1) facts.push('1 visit');
    if (facts.length) html += '<span class="pp-facts">' + facts.join(' · ') + '</span>';
    if (d.desc) html += '<span class="pp-desc">' + esc(d.desc) + '</span>';
    return '<div class="places-popup">' + html + '</div>';
  }

  function create(container, rows, opts) {
    opts = opts || {};

    // Wheel zoom only after the map is clicked, so scrolling the page past
    // the map doesn't hijack into a zoom.
    var map = L.map(container, { scrollWheelZoom: false, worldCopyJump: true });
    map.on('focus click', function () { map.scrollWheelZoom.enable(); });
    map.on('mouseout', function () { map.scrollWheelZoom.disable(); });

    var tiles = L.tileLayer(tileUrl(), {
      maxZoom: 19,
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>'
    }).addTo(map);

    // Overlapping pins (same block, or the same building — hi, Gift Horse
    // and Oberlin) roll up into a count badge that zooms in on click and
    // fans out (spiderfies) at max zoom.
    var pins = map;
    if (typeof L.markerClusterGroup === 'function') {
      pins = L.markerClusterGroup({
        maxClusterRadius: 44,
        showCoverageOnHover: false,
        iconCreateFunction: function (cluster) {
          return L.divIcon({
            html: '<span>' + cluster.getChildCount() + '</span>',
            className: 'places-cluster',
            iconSize: L.point(30, 30)
          });
        }
      });
      map.addLayer(pins);
    }

    var style = markerStyle();
    rows.forEach(function (row) {
      var lat = parseFloat(row.dataset.lat);
      var lng = parseFloat(row.dataset.lng);
      if (isNaN(lat) || isNaN(lng)) return;
      row._marker = L.circleMarker([lat, lng], style).bindPopup(popupHtml(row, opts));
    });

    var you = null;

    // Re-skin tiles + markers if the OS theme flips while the page is open.
    var onTheme = function () {
      tiles.setUrl(tileUrl());
      var s = markerStyle();
      rows.forEach(function (row) { if (row._marker) row._marker.setStyle(s); });
      if (you) you.setStyle(youStyle());
    };
    if (darkQuery.addEventListener) darkQuery.addEventListener('change', onTheme);

    // "Places near me": geolocate, drop the visitor's dot, and frame it with
    // the nearest visible pin when that pin is plausibly nearby (≤50km) —
    // otherwise just centre on the visitor.
    function locate(btn) {
      btn.classList.add('is-busy');
      navigator.geolocation.getCurrentPosition(function (pos) {
        btn.classList.remove('is-busy');
        var here = L.latLng(pos.coords.latitude, pos.coords.longitude);
        if (you) you.setLatLng(here);
        else you = L.circleMarker(here, youStyle()).addTo(map);
        var nearest = null;
        var best = Infinity;
        rows.forEach(function (row) {
          if (!row._marker || row.classList.contains('is-hidden')) return;
          var d = here.distanceTo(row._marker.getLatLng());
          if (d < best) { best = d; nearest = row._marker; }
        });
        if (nearest && best <= 50000) {
          map.fitBounds(L.latLngBounds([here, nearest.getLatLng()]), { padding: [60, 60], maxZoom: 15 });
        } else {
          map.setView(here, 12);
        }
      }, function () {
        btn.classList.remove('is-busy');
        btn.classList.add('is-denied');
        btn.title = 'Location unavailable';
      }, { timeout: 10000, maximumAge: 60000 });
    }

    if (opts.locate && 'geolocation' in navigator) {
      var LocateControl = L.Control.extend({
        options: { position: 'topleft' },
        onAdd: function () {
          var div = L.DomUtil.create('div', 'leaflet-bar places-locate');
          var a = L.DomUtil.create('a', '', div);
          a.href = '#';
          a.innerHTML = '◎';
          a.title = 'Places near me';
          a.setAttribute('role', 'button');
          a.setAttribute('aria-label', 'Show places near me');
          L.DomEvent.on(a, 'click', function (e) { L.DomEvent.stop(e); locate(a); });
          return div;
        }
      });
      map.addControl(new LocateControl());
    }

    map.setView([20, 0], 2); // placeholder; sync() fits to the pins

    function sync(focusSlug) {
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
      return { shown: shown.length, unpinned: unpinned };
    }

    return { map: map, sync: sync };
  }

  window.PlacesMap = { create: create };
})();
