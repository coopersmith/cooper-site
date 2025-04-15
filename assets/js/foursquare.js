// Replace with your Foursquare personal access token
const ACCESS_TOKEN = 'fsq3qh3H+Bcvo06G4VTtxgN7/nUMSeHA2XWN0ymynYz9pPM=';
const API_VERSION = '20240101';

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
    const location = data.location.city || data.location.neighborhood || '';
    const checkinTime = new Date(data.createdAt * 1000).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric'
    });
    
    document.getElementById('last-checkin').innerHTML = `Last checked in at ${venueName}${location ? ` in ${location}` : ''} on ${checkinTime}`;
  } catch (error) {
    console.error('Error fetching check-in data:', error);
    document.getElementById('last-checkin').innerHTML = 'Unable to load check-in data';
  }
}

// Call the function when the page loads
document.addEventListener('DOMContentLoaded', getLastCheckin); 