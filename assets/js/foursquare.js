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
    const city = loc.city || loc.neighborhood || loc.state || '';
    const when = relativeTime(data.createdAt);

    document.getElementById('last-checkin').innerHTML = `<p>last seen at ${venueName}${city ? ` in ${city}` : ''} ${when}</p>`;
  } catch (error) {
    console.error('Error fetching check-in data:', error);
    // Fail quietly so the homepage never shows an error line.
    const el = document.getElementById('last-checkin');
    if (el) el.innerHTML = '';
  }
}

// Call the function when the page loads
document.addEventListener('DOMContentLoaded', getLastCheckin);