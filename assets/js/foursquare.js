// Turn a Unix timestamp (seconds) into a relative string like "4 days ago".
function relativeTime(unixSeconds) {
  const seconds = Math.max(0, Math.round(Date.now() / 1000 - unixSeconds));
  const minutes = Math.round(seconds / 60);
  const hours = Math.round(minutes / 60);
  const days = Math.round(hours / 24);
  const weeks = Math.round(days / 7);
  const months = Math.round(days / 30);
  const years = Math.round(days / 365);

  const ago = (n, unit) => `${n} ${unit}${n === 1 ? '' : 's'} ago`;

  if (seconds < 60) return 'just now';
  if (minutes < 60) return ago(minutes, 'minute');
  if (hours < 24) return ago(hours, 'hour');
  if (days < 7) return ago(days, 'day');
  if (weeks < 5) return ago(weeks, 'week');
  if (months < 12) return ago(months, 'month');
  return ago(years, 'year');
}

async function getLastCheckin() {
  try {
    const response = await fetch('/.netlify/functions/last-checkin');
    
    if (!response.ok) {
      throw new Error('Failed to fetch check-in data');
    }
    
    const data = await response.json();
    
    if (data.error) {
      throw new Error(data.error);
    }
    
    const venueName = data.venue;
    const loc = data.location || {};

    // Show the city (falling back to state); prepend the neighborhood when
    // Foursquare has one, e.g. "Greenwich Village, New York".
    // Strip bureaucratic prefixes like "Town of Westport" -> "Westport".
    const rawCity = (loc.city || loc.state || '')
      .replace(/^(Town|City|Township|Village|Borough) of /i, '');

    // Take the first neighborhood if it's an array, and reject all-lowercase
    // junk — Foursquare sometimes returns usernames like "berthaharvey".
    let neighborhood = loc.neighborhood;
    if (Array.isArray(neighborhood)) neighborhood = neighborhood[0];
    if (!neighborhood || !/[A-Z]/.test(neighborhood)) neighborhood = '';

    // Most check-ins are in NYC, where the neighborhood alone is enough — so
    // drop the redundant city for New York and its boroughs when we have a
    // neighborhood to show. Edit this list to taste.
    const nycCities = [
      'new york', 'new york city', 'manhattan', 'brooklyn',
      'queens', 'bronx', 'the bronx', 'staten island'
    ];
    const isNYC = nycCities.includes(rawCity.trim().toLowerCase());
    const city = isNYC && neighborhood ? '' : rawCity;

    const place = [neighborhood, city]
      .filter((part, i, parts) => part && parts.indexOf(part) === i)
      .join(', ');

    const when = relativeTime(data.createdAt);

    document.getElementById('last-checkin').innerHTML = `<p>Last seen at ${venueName}${place ? ` in ${place}` : ''} ${when}</p>`;

    // Let the homepage intro reflect where I actually am right now.
    applyLocationAwareness(data);
  } catch (error) {
    console.error('Error fetching check-in data:', error);
    // Fail quietly so the homepage never shows an error line.
    const el = document.getElementById('last-checkin');
    if (el) el.innerHTML = '';
  }
}

// Build a human place string for a check-in that's away from home, e.g.
// "Rome, Italy" or "Denver, Colorado". Abroad we pair the city with the
// country; in the US we pair it with the state. Returns '' if we can't
// name anywhere useful.
function travelPlace(loc) {
  const city = (loc.city || '')
    .replace(/^(Town|City|Township|Village|Borough) of /i, '')
    .trim();
  const cc = (loc.cc || '').toUpperCase();
  const region = (cc === 'US' ? (loc.state || '') : (loc.country || '')).trim();

  return [city, region]
    .filter((part, i, parts) => part && parts.indexOf(part) === i)
    .join(', ');
}

// Sort my most recent check-in into how the homepage should talk about it.
// Returns { bucket: 'nyc' | 'ri' | 'travel', place? } or null. Stale check-ins
// return null so the page falls back to neutral rather than confidently lying
// about where I am after I've gone a while without checking in.
function classifyCheckin(data) {
  if (!data || !data.createdAt) return null;

  const STALE_AFTER_SECONDS = 2 * 24 * 60 * 60; // 2 days
  const age = Date.now() / 1000 - data.createdAt;
  if (age > STALE_AFTER_SECONDS) return null;

  const loc = data.location || {};
  const city = (loc.city || '')
    .replace(/^(Town|City|Township|Village|Borough) of /i, '')
    .trim()
    .toLowerCase();
  const state = (loc.state || '').trim().toLowerCase();

  const nycCities = [
    'new york', 'new york city', 'manhattan', 'brooklyn',
    'queens', 'bronx', 'the bronx', 'staten island'
  ];
  if (nycCities.includes(city) || state === 'ny' || state === 'new york') {
    return { bucket: 'nyc' };
  }

  // The Farm Coast straddles the RI/MA line and it's all basically the same
  // place, so treat both states as "Rhode Island" for the intro.
  if (state === 'ri' || state === 'rhode island' ||
      state === 'ma' || state === 'massachusetts') {
    return { bucket: 'ri' };
  }

  // A recent check-in anywhere else means I'm on the road.
  return { bucket: 'travel', place: travelPlace(loc) };
}

// Reflect my most recent check-in in the intro: home check-ins reorder the
// two paragraphs and swap the opening line to "I'm currently in…"; a check-in
// away from home swaps in a travel line that points at Instagram. No-ops
// gracefully if the markup is missing or the location is unknown.
function applyLocationAwareness(data) {
  const result = classifyCheckin(data);
  if (!result) return;

  const leadNeutral = document.getElementById('intro-lead-neutral');
  if (!leadNeutral) return;

  // On the road: nudge toward the Instagram feed instead of reordering the
  // two home paragraphs (I'm in neither place right now).
  if (result.bucket === 'travel') {
    const leadTravel = document.getElementById('intro-lead-travel');
    if (!leadTravel) return;
    const placeEl = document.getElementById('travel-place');
    if (placeEl) placeEl.textContent = result.place ? ` in ${result.place}` : '';
    leadNeutral.classList.add('loc-alt');
    leadTravel.classList.remove('loc-alt');
    return;
  }

  const bucket = result.bucket;

  // Move the paragraph for wherever I am ahead of the other one.
  const active = document.getElementById(bucket === 'nyc' ? 'intro-nyc' : 'intro-ri');
  const other = document.getElementById(bucket === 'nyc' ? 'intro-ri' : 'intro-nyc');
  if (active && other &&
      (active.compareDocumentPosition(other) & Node.DOCUMENT_POSITION_PRECEDING)) {
    active.parentNode.insertBefore(active, other);
  }

  // Swap the neutral "I split my time between…" opening line for the
  // present-tense "I'm currently in…" variant that matches where I am.
  const leadActive = document.getElementById(bucket === 'nyc' ? 'intro-lead-nyc' : 'intro-lead-ri');
  if (leadActive) {
    leadNeutral.classList.add('loc-alt');
    leadActive.classList.remove('loc-alt');
  }
}

// Call the function when the page loads
document.addEventListener('DOMContentLoaded', getLastCheckin);