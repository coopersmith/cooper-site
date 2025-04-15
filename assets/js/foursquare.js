// Replace with your Foursquare/Swarm API credentials
const FOURSQUARE_ACCESS_TOKEN = 'fsq39T8ScLXPRGTrsVev6H7lntR23sMT7EAZ8qMy4lVIOlA=';

async function getLastCheckin() {
  try {
    const response = await fetch('https://api.foursquare.com/v2/users/self/checkins?v=20240101&limit=1&oauth_token=' + FOURSQUARE_ACCESS_TOKEN);
    
    if (!response.ok) {
      throw new Error('Failed to fetch Swarm data');
    }
    
    const data = await response.json();
    if (data.response && data.response.checkins && data.response.checkins.items.length > 0) {
      const lastCheckin = data.response.checkins.items[0];
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
    console.error('Error fetching Swarm data:', error);
    document.getElementById('last-checkin').innerHTML = 'Unable to load check-in data';
  }
}

// Call the function when the page loads
document.addEventListener('DOMContentLoaded', getLastCheckin); 