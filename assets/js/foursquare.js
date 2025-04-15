// Replace with your Foursquare personal access token
const ACCESS_TOKEN = 'fsq3qh3H+Bcvo06G4VTtxgN7/nUMSeHA2XWN0ymynYz9pPM=';
const API_VERSION = '20240101';

async function getLastCheckin() {
  try {
    // Using the correct endpoint structure for v2 API
    const response = await fetch(`https://api.foursquare.com/v2/checkins/recent?v=${API_VERSION}&limit=1`, {
      headers: {
        'Authorization': `Bearer ${ACCESS_TOKEN}`
      }
    });
    
    if (!response.ok) {
      const errorText = await response.text();
      console.error('API Response:', errorText);
      throw new Error(`Failed to fetch Swarm data: ${response.status}`);
    }
    
    const data = await response.json();
    console.log('API Response:', data); // Debug log
    
    if (data.response && data.response.recent && data.response.recent.length > 0) {
      const lastCheckin = data.response.recent[0];
      const venueName = lastCheckin.venue.name;
      const location = lastCheckin.venue.location.city || lastCheckin.venue.location.neighborhood || '';
      const checkinTime = new Date(lastCheckin.createdAt * 1000).toLocaleDateString('en-US', {
        month: 'short',
        day: 'numeric'
      });
      
      // Update the DOM with the last check-in info
      document.getElementById('last-checkin').innerHTML = `Last checked in at ${venueName}${location ? ` in ${location}` : ''} on ${checkinTime}`;
    } else {
      document.getElementById('last-checkin').innerHTML = 'No recent check-ins found';
    }
  } catch (error) {
    console.error('Error details:', error);
    document.getElementById('last-checkin').innerHTML = 'Unable to load check-in data';
  }
}

// Call the function when the page loads
document.addEventListener('DOMContentLoaded', getLastCheckin); 