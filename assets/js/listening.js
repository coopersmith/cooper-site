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

const API_KEY = "c45fbeb0d318aac9d7698d798b639811";
const USERNAME = "coopersmith";
const API = "https://ws.audioscrobbler.com/2.0/";
const TOP_N = 8;            // how many artists/albums/tracks to show
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

function api(method, params) {
  const url = new URL(API);
  url.search = new URLSearchParams({
    method,
    user: USERNAME,
    api_key: API_KEY,
    format: "json",
    ...params,
  }).toString();
  return fetch(url).then((r) => {
    if (!r.ok) throw new Error(`Last.fm ${method} → ${r.status}`);
    return r.json();
  });
}

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

// Enrich the displayed tracks/albums with cover art in parallel (one extra
// round-trip). Artists intentionally keep their letter tiles.
async function fillArtwork(data) {
  await Promise.all([
    ...data.tracks.map(fillTrackArt),
    ...data.albums.map(fillAlbumArt),
  ]);
  return data;
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
    return fillArtwork({
      artists: (artists.topartists.artist || []).map(artistItem),
      albums: (albums.topalbums.album || []).map(albumItem),
      tracks: (tracks.toptracks.track || []).map(trackItem),
      totalScrobbles: Number(recent.recenttracks["@attr"]?.total || 0),
      uniqueArtists: Number(artists.topartists["@attr"]?.total || 0),
    });
  }

  // Fixed date range — weekly chart methods accept from/to.
  const [artists, albums, tracks, recent] = await Promise.all([
    api("user.getweeklyartistchart", { from: win.from, to: win.to }),
    api("user.getweeklyalbumchart", { from: win.from, to: win.to }),
    api("user.getweeklytrackchart", { from: win.from, to: win.to }),
    api("user.getrecenttracks", { from: totalFrom, to: totalTo, limit: 1 }),
  ]);
  const artistList = artists.weeklyartistchart.artist || [];
  return fillArtwork({
    artists: artistList.slice(0, TOP_N).map(artistItem),
    albums: (albums.weeklyalbumchart.album || []).slice(0, TOP_N).map(albumItem),
    tracks: (tracks.weeklytrackchart.track || []).slice(0, TOP_N).map(trackItem),
    totalScrobbles: Number(recent.recenttracks["@attr"]?.total || 0),
    uniqueArtists: artistList.length,
  });
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

function artHtml(item) {
  if (item.image) {
    return `<img class="lr-art" src="${esc(item.image)}" alt="" loading="lazy">`;
  }
  const initial = (item.name || "?").trim().charAt(0).toUpperCase();
  return `<span class="lr-art lr-art--empty" aria-hidden="true">${esc(initial)}</span>`;
}

function rowHtml(item) {
  const sub = item.sub ? `<span class="lr-row__sub">${esc(item.sub)}</span>` : "";
  const plays = item.plays
    ? `<span class="lr-row__plays">${num(item.plays)} plays</span>`
    : "";
  const inner = `
    <span class="lr-row__rank">${item.rank}</span>
    ${artHtml(item)}
    <span class="lr-row__body">
      <span class="lr-row__name">${esc(item.name)}</span>
      ${sub}
    </span>
    ${plays}`;
  return item.url
    ? `<a class="lr-row" href="${esc(item.url)}" target="_blank" rel="noopener">${inner}</a>`
    : `<div class="lr-row">${inner}</div>`;
}

function listHtml(title, items) {
  if (!items.length) {
    return `<section class="lr-list"><h2>${esc(title)}</h2>
      <p class="lr-empty">Nothing here for this window.</p></section>`;
  }
  return `<section class="lr-list"><h2>${esc(title)}</h2>
    <div class="lr-rows">${items.map(rowHtml).join("")}</div></section>`;
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
    listHtml("Top artists", data.artists) +
    listHtml("Top albums", data.albums) +
    listHtml("Top tracks", data.tracks);
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
  try {
    const data = await loadWindow(win);
    if (token !== reqToken) return; // a newer toggle won
    render(data, win);
    status.textContent = "";
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
