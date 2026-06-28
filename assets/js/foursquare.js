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
  } catch (error) {
    console.error('Error fetching check-in data:', error);
    // Fail quietly so the homepage never shows an error line.
    const el = document.getElementById('last-checkin');
    if (el) el.innerHTML = '';
  }
}

// Call the function when the page loads
document.addEventListener('DOMContentLoaded', getLastCheckin);