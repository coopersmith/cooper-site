import fetch from 'node-fetch';

export const handler = async () => {
  const CLIENT_ID = process.env.FOURSQUARE_CLIENT_ID;
  const CLIENT_SECRET = process.env.FOURSQUARE_CLIENT_SECRET;
  const endpoint = `https://api.foursquare.com/v2/users/self/checkins?client_id=${CLIENT_ID}&client_secret=${CLIENT_SECRET}&v=20250415&limit=1`;

  try {
    const response = await fetch(endpoint);
    const data = await response.json();
    
    if (!data.response || !data.response.checkins || !data.response.checkins.items.length) {
      return {
        statusCode: 404,
        body: JSON.stringify({ error: 'No check-ins found' })
      };
    }

    const checkin = data.response.checkins.items[0];
    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({
        venue: checkin.venue.name,
        location: checkin.venue.location,
        createdAt: checkin.createdAt
      })
    };
  } catch (error) {
    console.error('Foursquare API Error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Failed to fetch check-in data' })
    };
  }
}; 