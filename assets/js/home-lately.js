// Homepage "Lately" music line: a sentence of recent top artists, the track
// playing right now (if any), and a link to the fuller /listening report.
// Uses the shared Last.fm client in lastfm-api.js.

// How long after a scrobble we still call it "currently listening".
//
// Last.fm distinguishes a live "now playing" ping (track.updateNowPlaying,
// flagged @attr.nowplaying) from a completed scrobble (track.scrobble, stamped
// with a time). Apps like Spotify send the live ping; the Sonos plugin that
// scrobbles radio (e.g. Radio FIP) only ever sends completed scrobbles, so it
// would never satisfy a strict nowplaying check. Treating a fresh scrobble as
// still-playing bridges that gap: on a continuous stream the previous track's
// scrobble stays "current" until the next one lands, and when you actually stop
// it lingers for at most this window before disappearing. Comfortably longer
// than a typical song so continuous listening never blinks out mid-stream.
const NOW_PLAYING_DECAY_MS = 10 * 60 * 1000; // 10 minutes

// A track counts as "currently listening" if Last.fm flags it as now-playing,
// or if it was scrobbled within the decay window above.
function isCurrentlyListening(track) {
  if (track["@attr"] && track["@attr"].nowplaying === "true") return true;
  const uts = track.date && Number(track.date.uts);
  if (!uts) return false;
  return Date.now() - uts * 1000 <= NOW_PLAYING_DECAY_MS;
}

document.addEventListener("DOMContentLoaded", async () => {
  const el = document.getElementById("recently-played");
  if (!el) return;

  // Lead sentence: top artists over the last three months.
  try {
    const data = await LASTFM.api("user.gettopartists", { period: "3month", limit: 5 });
    const names = (data.topartists.artist || []).map((a) => a.name);
    el.innerHTML = `<p>Recently I've been listening to a lot of ${names.join(", ")}.</p>`;
  } catch (err) {
    console.error("Error fetching data from Last.fm:", err);
    el.innerHTML = `<p>Unable to load music data at the moment.</p>`;
    return; // without the lead sentence there's nothing to append to
  }

  // If something is playing right now, append it as a second sentence inside
  // the existing paragraph, so it reads inline rather than as its own line.
  try {
    const data = await LASTFM.api("user.getrecenttracks", { limit: 1 });
    const track = data.recenttracks && data.recenttracks.track && data.recenttracks.track[0];
    if (track && isCurrentlyListening(track)) {
      const sentence = ` Currently listening to <a href="${track.url}" target="_blank" rel="noopener">${track.name}</a> by ${track.artist["#text"]}.`;
      const existing = el.querySelector("p");
      if (existing) {
        existing.innerHTML += sentence;
      } else {
        el.innerHTML = `<p>${sentence.trim()}</p>`;
      }
    }
  } catch (err) {
    // The artists sentence still loaded, so keep going to the link.
    console.error("Error fetching current track from Last.fm:", err);
  }

  // "See more" goes last, after the now-playing sentence if there is one.
  const paragraph = el.querySelector("p");
  if (paragraph && !paragraph.querySelector(".recently-see-more")) {
    paragraph.innerHTML += ` <a class="recently-see-more" href="/listening">See more &rarr;</a>`;
  }
});
