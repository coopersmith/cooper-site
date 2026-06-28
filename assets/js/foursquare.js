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
    const location = loc.city || loc.neighborhood || loc.state || '';
    const checkinTime = new Date(data.createdAt * 1000).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric'
    });

    document.getElementById('last-checkin').innerHTML = `<p>Last checked in at ${venueName}${location ? ` in ${location}` : ''} on ${checkinTime}</p>`;
  } catch (error) {
    console.error('Error fetching check-in data:', error);
    // Fail quietly so the homepage never shows an error line.
    const el = document.getElementById('last-checkin');
    if (el) el.innerHTML = '';
  }
}

// Call the function when the page loads
document.addEventListener('DOMContentLoaded', getLastCheckin);