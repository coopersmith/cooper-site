---
# Front matter so Jekyll renders this through Liquid — the CARTO key below
# comes from _config.yml. Nothing else in this file is Liquid.
# layout: null is load-bearing: _config.yml defaults every path to the
# "default" layout, which would otherwise wrap this script in a full HTML page.
layout: null
---
// Shared Leaflet runtime for the Places maps: the full map view on /places/
// and the mini-map on destination and trip notes. All of them render pins
// from table rows — the row *is* the data: coordinates, popup facts, and
// (on /places/) filter visibility all come off its data attributes.
//
//   PlacesMap.create(container, rows, opts) -> handle
//     opts.locate    add a "places near me" geolocation control
//     opts.trips     rows for trip pins (see "Trips" below)
//     handle.map     the Leaflet map
//     handle.sync(focusSlug)
//       re-syncs markers with row visibility (.is-hidden), fits the view,
//       and optionally focuses one venue's popup (unfolding its cluster);
//       returns {shown, unpinned} counts for the caller's messaging.
//
// Tiles are CARTO's Positron / Dark Matter following prefers-color-scheme;
// overlapping pins cluster into count badges (falling back to plain markers
// if Leaflet.markercluster didn't load).
//
// == Trips
//
// A trip (a /travels/ writeup) is a coarser thing than a place: one pin for a
// whole visit, sitting on top of however many places it produced. So trip pins
// share the places' cluster — zoomed out, a city is one badge covering both,
// which is the honest reading of "20 things here" — but they leave it sooner.
// Below TRIP_BREAKOUT_ZOOM a trip clusters with everything else; at or above
// it, trip markers move onto the map in their own right while the places
// underneath stay rolled up until their own clustering distance breaks them
// apart. The effect is that panning out to a country shows you the trips, and
// zooming in past them dissolves into the individual recommendations.
(function () {
  if (typeof L === 'undefined') return;

  // Country/region zoom: far enough out that individual places are still
  // usefully clustered, close enough in that a trip is worth naming.
  var TRIP_BREAKOUT_ZOOM = 5;

  var darkQuery = window.matchMedia('(prefers-color-scheme: dark)');

  // CARTO stamps "API KEY REQUIRED" across tiles fetched without a key —
  // their raster endpoint stopped being anonymous in 2026. The key is public
  // by design (it rides along in every tile request the browser makes), so it
  // sits in _config.yml, not the build environment. Blank key still renders,
  // just watermarked: a degraded map beats no map.
  var CARTO_KEY = {{ site.carto_api_key | default: '' | jsonify }};

  function tileUrl() {
    var flavor = darkQuery.matches ? 'dark_all' : 'light_all';
    var url = 'https://{s}.basemaps.cartocdn.com/' + flavor + '/{z}/{x}/{y}{r}.png';
    return CARTO_KEY ? url + '?key=' + encodeURIComponent(CARTO_KEY) : url;
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

  // Trip pin: a hollow diamond head on a needle (drawn in _places.scss),
  // against the places' flat dots. The tall anchor is deliberate — a trip
  // usually sits at the centroid of its own places, which is exactly where
  // their cluster badge is, so the head is lifted clear of a 30px badge while
  // the needle keeps the tip honest about the coordinate. A divIcon rather
  // than a circleMarker so the shape is CSS, which also re-skins it on a theme
  // flip for free.
  function tripIcon() {
    return L.divIcon({
      html: '<span></span>',
      className: 'places-trip-pin',
      iconSize: L.point(26, 42),
      iconAnchor: L.point(13, 42),
      popupAnchor: L.point(0, -40)
    });
  }

  function tripPopupHtml(row) {
    var d = row.dataset;
    var name = row.querySelector('.index-title a');
    var html = '<span class="pp-kind">Trip</span>' +
      '<a class="pp-name internal-link" href="' + esc(d.url) + '">' + esc(name ? name.textContent : '') + '</a>';
    var sub = [];
    if (d.dates) sub.push(esc(d.dates));
    // A trip is usually named for where it went ("New Orleans 2019"), so only
    // spell the destination out when the title doesn't already.
    var label = name ? name.textContent.toLowerCase() : '';
    if (d.where && label.indexOf(d.where.toLowerCase()) === -1) sub.push(esc(d.where));
    if (sub.length) html += '<span class="pp-sub">' + sub.join(' · ') + '</span>';
    var n = parseInt(d.places, 10) || 0;
    if (n) html += '<span class="pp-facts">' + n + (n === 1 ? ' place' : ' places') + ' of mine here</span>';
    return '<div class="places-popup places-popup-trip">' + html + '</div>';
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

    function latLng(row) {
      var lat = parseFloat(row.dataset.lat);
      var lng = parseFloat(row.dataset.lng);
      return (isNaN(lat) || isNaN(lng)) ? null : [lat, lng];
    }

    var style = markerStyle();
    rows.forEach(function (row) {
      var at = latLng(row);
      if (!at) return;
      row._marker = L.circleMarker(at, style).bindPopup(popupHtml(row, opts));
    });

    var trips = opts.trips ? Array.prototype.slice.call(opts.trips) : [];
    trips.forEach(function (row) {
      var at = latLng(row);
      if (!at) return;
      // Above the places, so a trip pin is never buried under the dots of the
      // recommendations it produced.
      row._marker = L.marker(at, { icon: tripIcon(), zIndexOffset: 1000 })
        .bindPopup(tripPopupHtml(row));
    });

    // A trip rides in the cluster only while zoomed out past the breakout —
    // see "Trips" at the top. With no markercluster plugin there's nothing to
    // break out of and every pin is already standalone.
    function tripHost() {
      return (pins === map || map.getZoom() >= TRIP_BREAKOUT_ZOOM) ? map : pins;
    }

    function placeTrips() {
      var host = tripHost();
      var other = host === map ? pins : map;
      trips.forEach(function (row) {
        var m = row._marker;
        if (!m) return;
        if (other !== host && other.hasLayer(m)) other.removeLayer(m);
        var visible = !row.classList.contains('is-hidden');
        if (visible && !host.hasLayer(m)) host.addLayer(m);
        else if (!visible && host.hasLayer(m)) host.removeLayer(m);
      });
    }

    if (trips.length) map.on('zoomend', placeTrips);

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
      var bounds = [];
      var shown = 0;
      var unpinned = 0;
      rows.forEach(function (row) {
        var visible = !row.classList.contains('is-hidden');
        if (!row._marker) {
          if (visible) unpinned++;
          return;
        }
        if (visible) {
          pins.addLayer(row._marker);
          bounds.push(row._marker.getLatLng());
          shown++;
        } else {
          pins.removeLayer(row._marker);
        }
      });

      // Trips join the fit, so filtering to a destination I've written up but
      // have no places in yet still frames something. They stay out of the
      // shown/unpinned counts, which are the caller's messaging about places.
      placeTrips();
      trips.forEach(function (row) {
        if (row._marker && !row.classList.contains('is-hidden')) bounds.push(row._marker.getLatLng());
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
      } else if (bounds.length) {
        map.fitBounds(L.latLngBounds(bounds), { padding: [40, 40], maxZoom: 15 });
      }
      return { shown: shown, unpinned: unpinned };
    }

    return { map: map, sync: sync };
  }

  window.PlacesMap = { create: create };
})();
