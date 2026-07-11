// Listening report — a rolling / yearly view of my Last.fm scrobbles.
//
// Two kinds of window:
//   • Rolling periods (7 / 30 / 90 days) use Last.fm's built-in `period`
//     param on the user.getTop{Artists,Albums,Tracks} methods. These come
//     pre-ranked and include artwork.
//   • Fixed years (2025, 2026-so-far, …) use the user.getWeekly*Chart methods
//     with explicit from/to UTC timestamps, since `period` can't express an
//     arbitrary date range. We slice the top N client-side.
//
// Total scrobbles for any window comes from a single cheap getRecentTracks
// call (limit=1) — its `@attr.total` is the exact count for the range without
// paging through every scrobble.

// Account details + request plumbing live in the shared client (lastfm-api.js).
const { api } = LASTFM;

const TOP_N = 10;          // how many artists/albums/tracks to show
const FIRST_YEAR = 2021;   // earliest year to offer a report for

// ---------------------------------------------------------------------------
// Window definitions
// ---------------------------------------------------------------------------

// Rolling windows map to Last.fm's period vocabulary. `days` is only used to
// derive a from/to for the total-scrobbles count.
const ROLLING = [
  { id: "7day",  label: "7 days",  period: "7day",  days: 7 },
  { id: "30day", label: "30 days", period: "1month", days: 30 },
  { id: "90day", label: "90 days", period: "3month", days: 90 },
];

const NOW = Math.floor(Date.now() / 1000);

// Build a year window from FIRST_YEAR up to the current year. The current year
// is "ongoing" (to = now); past years span the full calendar year in UTC.
function yearWindows() {
  const thisYear = new Date().getUTCFullYear();
  const out = [];
  for (let y = thisYear; y >= FIRST_YEAR; y--) {
    const from = Math.floor(Date.UTC(y, 0, 1, 0, 0, 0) / 1000);
    const isCurrent = y === thisYear;
    const to = isCurrent ? NOW : Math.floor(Date.UTC(y + 1, 0, 1, 0, 0, 0) / 1000) - 1;
    out.push({
      id: `y${y}`,
      label: isCurrent ? `${y} (so far)` : `${y}`,
      from,
      to,
    });
  }
  return out;
}

const YEARS = yearWindows();

// ---------------------------------------------------------------------------
// API helpers
// ---------------------------------------------------------------------------

// Last.fm's grey-star default image, served whenever real art is missing.
// It shows up for basically every artist (Last.fm dropped artist imagery in
// ~2019 over a licensing dispute) and most tracks, so we treat it as "no image"
// and fall back to a letter tile instead.
const PLACEHOLDER_IMG = "2a96cbd8b46e442fc41c2b86b821562f";

// Pull the biggest real image URL from Last.fm's image array (ignoring the
// grey-star placeholder).
function pickImage(images) {
  if (!Array.isArray(images)) return "";
  const sized = images.filter(
    (i) => i["#text"] && !i["#text"].includes(PLACEHOLDER_IMG)
  );
  return sized.length ? sized[sized.length - 1]["#text"] : "";
}

function num(n) {
  return Number(n || 0).toLocaleString();
}

// Normalise the various response shapes into a common item:
// { rank, name, sub, plays, image, url }
function artistItem(a, i) {
  return {
    rank: i + 1,
    name: a.name,
    sub: "",
    plays: Number(a.playcount || 0),
    image: pickImage(a.image),
    url: a.url,
  };
}
function albumItem(a, i) {
  return {
    rank: i + 1,
    name: a.name,
    sub: a.artist ? a.artist.name || a.artist["#text"] : "",
    plays: Number(a.playcount || 0),
    image: pickImage(a.image),
    url: a.url,
  };
}
function trackItem(t, i) {
  return {
    rank: i + 1,
    name: t.name,
    sub: t.artist ? t.artist.name || t.artist["#text"] : "",
    plays: Number(t.playcount || 0),
    image: pickImage(t.image),
    url: t.url,
  };
}

// Last.fm has no usable artist images, so tracks borrow their album's cover
// art via track.getInfo. The top-level image on getTop/weekly tracks is the
// grey-star placeholder, so we always look this up. Mutates item.image.
async function fillTrackArt(item) {
  if (!item.sub) return item;
  try {
    const d = await api("track.getinfo", {
      artist: item.sub,
      track: item.name,
      autocorrect: 1,
    });
    const img = pickImage(d.track && d.track.album && d.track.album.image);
    if (img) item.image = img;
  } catch (_) {
    /* leave the letter-tile fallback in place */
  }
  return item;
}

// Weekly (per-year) album charts omit artwork, so fetch it via album.getInfo.
// getTopAlbums already includes real covers, so skip items that have one.
async function fillAlbumArt(item) {
  if (item.image || !item.sub) return item;
  try {
    const d = await api("album.getinfo", {
      artist: item.sub,
      album: item.name,
      autocorrect: 1,
    });
    const img = pickImage(d.album && d.album.image);
    if (img) item.image = img;
  } catch (_) {
    /* leave the letter-tile fallback in place */
  }
  return item;
}

// Last.fm's API can't return artist photos, so pull the lead image from the
// artist's Wikipedia page. Wikipedia's REST API is CORS-enabled (plain fetch,
// same as the Last.fm calls — no injected <script>, which ad blockers often
// strip), needs no auth, and follows redirects for near-miss titles. A
// disambiguation page, an imageless page, or a miss keeps the letter tile.
async function fillArtistArt(item) {
  try {
    const res = await fetch(
      "https://en.wikipedia.org/api/rest_v1/page/summary/" +
        encodeURIComponent(item.name) +
        "?redirect=true"
    );
    if (!res.ok) return item;
    const d = await res.json();
    if (d.type !== "disambiguation" && d.thumbnail && d.thumbnail.source) {
      item.image = d.thumbnail.source;
    }
  } catch (_) {
    /* leave the letter-tile fallback in place */
  }
  return item;
}

// Kick off every artwork lookup and paint each cover into the DOM as it
// resolves, so the list is interactive immediately and art streams in. `token`
// pins the request: if the user has toggled to another window, paints are
// dropped rather than landing on the wrong list.
function enrichArtwork(data, token) {
  const run = (items, key, fill) =>
    items.forEach((item, i) =>
      fill(item).then(() => paintArt(`art-${key}-${i}`, item, token))
    );
  run(data.artists, "artist", fillArtistArt);
  run(data.albums, "album", fillAlbumArt);
  run(data.tracks, "track", fillTrackArt);
}

// Swap a letter tile for the real cover once it's known.
function paintArt(id, item, token) {
  if (token !== reqToken || !item.image) return;
  const el = document.getElementById(id);
  if (!el) return;
  if (el.tagName === "IMG") {
    el.src = item.image;
    return;
  }
  const img = new Image();
  img.className = "lr-art";
  img.id = id;
  img.loading = "lazy";
  img.alt = "";
  img.src = item.image;
  el.replaceWith(img);
}

// Fetch a full window's worth of data. Returns
// { artists, albums, tracks, totalScrobbles, uniqueArtists }.
async function loadWindow(win) {
  const totalFrom = win.from != null ? win.from : NOW - win.days * 86400;
  const totalTo = win.to != null ? win.to : NOW;

  if (win.period) {
    // Rolling window — built-in period methods (ranked + artwork).
    const [artists, albums, tracks, recent] = await Promise.all([
      api("user.gettopartists", { period: win.period, limit: TOP_N }),
      api("user.gettopalbums", { period: win.period, limit: TOP_N }),
      api("user.gettoptracks", { period: win.period, limit: TOP_N }),
      api("user.getrecenttracks", { from: totalFrom, to: totalTo, limit: 1 }),
    ]);
    return {
      artists: (artists.topartists.artist || []).map(artistItem),
      albums: (albums.topalbums.album || []).map(albumItem),
      tracks: (tracks.toptracks.track || []).map(trackItem),
      totalScrobbles: Number(recent.recenttracks["@attr"]?.total || 0),
      uniqueArtists: Number(artists.topartists["@attr"]?.total || 0),
    };
  }

  // Fixed date range — weekly chart methods accept from/to.
  const [artists, albums, tracks, recent] = await Promise.all([
    api("user.getweeklyartistchart", { from: win.from, to: win.to }),
    api("user.getweeklyalbumchart", { from: win.from, to: win.to }),
    api("user.getweeklytrackchart", { from: win.from, to: win.to }),
    api("user.getrecenttracks", { from: totalFrom, to: totalTo, limit: 1 }),
  ]);
  const artistList = artists.weeklyartistchart.artist || [];
  return {
    artists: artistList.slice(0, TOP_N).map(artistItem),
    albums: (albums.weeklyalbumchart.album || []).slice(0, TOP_N).map(albumItem),
    tracks: (tracks.weeklytrackchart.track || []).slice(0, TOP_N).map(trackItem),
    totalScrobbles: Number(recent.recenttracks["@attr"]?.total || 0),
    uniqueArtists: artistList.length,
  };
}

// ---------------------------------------------------------------------------
// Rendering
// ---------------------------------------------------------------------------

function esc(s) {
  return String(s)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

// `id` lets enrichArtwork() find this slot later and swap in the real cover.
function artHtml(item, id) {
  if (item.image) {
    return `<img class="lr-art" id="${id}" src="${esc(item.image)}" alt="" loading="lazy">`;
  }
  const initial = (item.name || "?").trim().charAt(0).toUpperCase();
  return `<span class="lr-art lr-art--empty" id="${id}" aria-hidden="true">${esc(initial)}</span>`;
}

function rowHtml(item, artId) {
  const sub = item.sub ? `<span class="lr-row__sub">${esc(item.sub)}</span>` : "";
  const plays = item.plays
    ? `<span class="lr-row__plays">${num(item.plays)} plays</span>`
    : "";
  const inner = `
    <span class="lr-row__rank">${item.rank}</span>
    ${artHtml(item, artId)}
    <span class="lr-row__body">
      <span class="lr-row__name">${esc(item.name)}</span>
      ${sub}
    </span>
    ${plays}`;
  return item.url
    ? `<a class="lr-row" href="${esc(item.url)}" target="_blank" rel="noopener">${inner}</a>`
    : `<div class="lr-row">${inner}</div>`;
}

// `key` namespaces each row's art id (e.g. art-album-3) to match paintArt().
function listHtml(title, items, key) {
  if (!items.length) {
    return `<section class="lr-list"><h2>${esc(title)}</h2>
      <p class="lr-empty">Nothing here for this window.</p></section>`;
  }
  const rows = items.map((item, i) => rowHtml(item, `art-${key}-${i}`)).join("");
  return `<section class="lr-list"><h2>${esc(title)}</h2>
    <div class="lr-rows">${rows}</div></section>`;
}

function statsHtml(data, win) {
  const days =
    win.days != null
      ? win.days
      : Math.max(1, Math.round((win.to - win.from) / 86400));
  const perDay = data.totalScrobbles ? Math.round(data.totalScrobbles / days) : 0;
  const stats = [
    [num(data.totalScrobbles), "scrobbles"],
    [num(data.uniqueArtists), "artists"],
    [num(perDay), "per day"],
  ];
  return `<div class="lr-stats">${stats
    .map(
      ([n, l]) =>
        `<div class="lr-stat"><span class="lr-stat__n">${n}</span><span class="lr-stat__l">${l}</span></div>`
    )
    .join("")}</div>`;
}

function render(data, win) {
  const out = document.getElementById("lr-report");
  out.innerHTML =
    statsHtml(data, win) +
    listHtml("Top artists", data.artists, "artist") +
    listHtml("Top albums", data.albums, "album") +
    listHtml("Top tracks", data.tracks, "track");
}

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

const WINDOWS = [...ROLLING, ...YEARS];
let activeId = ROLLING[0].id;
let reqToken = 0; // guards against out-of-order responses

function setActive(id) {
  activeId = id;
  document.querySelectorAll("#lr-toggle button").forEach((b) => {
    b.classList.toggle("is-active", b.dataset.id === id);
    b.setAttribute("aria-pressed", b.dataset.id === id ? "true" : "false");
  });
}

async function show(id) {
  const win = WINDOWS.find((w) => w.id === id);
  if (!win) return;
  setActive(id);
  const status = document.getElementById("lr-status");
  const out = document.getElementById("lr-report");
  const token = ++reqToken;
  status.textContent = "Loading…";
  out.setAttribute("aria-busy", "true");
  // First load leaves the static skeleton (baked into the HTML) in place so the
  // height stays reserved; later toggles keep the current report visible until
  // the new one is ready. Either way nothing collapses, so nothing jumps.
  try {
    const data = await loadWindow(win);
    if (token !== reqToken) return; // a newer toggle won
    render(data, win); // paint the list immediately (letter tiles)
    out.dataset.loaded = "1";
    status.textContent = "";
    enrichArtwork(data, token); // covers stream in as they resolve
  } catch (err) {
    if (token !== reqToken) return;
    console.error(err);
    out.innerHTML = "";
    status.textContent = "Couldn't load listening data right now.";
  } finally {
    if (token === reqToken) out.removeAttribute("aria-busy");
  }
}

function buildToggle() {
  const bar = document.getElementById("lr-toggle");
  const groups = [
    { label: "Rolling", items: ROLLING },
    { label: "Years", items: YEARS },
  ];
  bar.innerHTML = groups
    .map(
      (g) => `<div class="lr-toggle-group" role="group" aria-label="${g.label}">
        ${g.items
          .map(
            (w) =>
              `<button type="button" class="tag" data-id="${w.id}" aria-pressed="false">${esc(
                w.label
              )}</button>`
          )
          .join("")}
      </div>`
    )
    .join("");
  bar.addEventListener("click", (e) => {
    const btn = e.target.closest("button[data-id]");
    if (btn) show(btn.dataset.id);
  });
}

document.addEventListener("DOMContentLoaded", () => {
  buildToggle();
  show(activeId);
});
