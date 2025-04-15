// Replace with your Foursquare API credentials
const FOURSQUARE_ACCESS_TOKEN = 'fsq39T8ScLXPRGTrsVev6H7lntR23sMT7EAZ8qMy4lVIOlA=';

async function getLastCheckin() {
  try {
    const response = await fetch('https://api.foursquare.com/v3/users/self/checkins?limit=1', {
      headers: {
        'Authorization': FOURSQUARE_ACCESS_TOKEN,
        'Accept': 'application/json'
      }
    });
    
    if (!response.ok) {
      throw new Error('Failed to fetch Foursquare data');
    }
    
    const data = await response.json();
    if (data.checkins && data.checkins.length > 0) {
      const lastCheckin = data.checkins[0];
      const venueName = lastCheckin.venue.name;
      const checkinTime = new Date(lastCheckin.createdAt * 1000).toLocaleDateString();
      
      // Update the DOM with the last check-in info
      document.getElementById('last-checkin').innerHTML = `Last seen at ${venueName} on ${checkinTime}`;
    }
  } catch (error) {
    console.error('Error fetching Foursquare data:', error);
    document.getElementById('last-checkin').innerHTML = 'Unable to load Foursquare check-in data';
  }
}

// Call the function when the page loads
document.addEventListener('DOMContentLoaded', getLastCheckin); 