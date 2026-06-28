export const handler = async () => {
  // The /users/self/checkins endpoint is personal data, so it requires a
  // user OAuth token (oauth_token=...), NOT the userless client_id/client_secret
  // pair, which only works for public place lookups.
  const OAUTH_TOKEN = process.env.FOURSQUARE_OAUTH_TOKEN;

  if (!OAUTH_TOKEN) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Missing FOURSQUARE_OAUTH_TOKEN' })
    };
  }

  const endpoint = `https://api.foursquare.com/v2/users/self/checkins?oauth_token=${OAUTH_TOKEN}&v=20250415&limit=1`;

  try {
    const response = await fetch(endpoint);
    const data = await response.json();

    // Foursquare returns its real status inside meta.code, even on a 200 HTTP
    // response. Surface auth/rate-limit failures instead of treating them as
    // "no check-ins found".
    if (data.meta && data.meta.code !== 200) {
      return {
        statusCode: data.meta.code,
        body: JSON.stringify({ error: data.meta.errorDetail || 'Foursquare API error' })
      };
    }

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
        'Access-Control-Allow-Origin': '*',
        // Cache at the CDN for 10 min so page loads don't hammer the API.
        'Cache-Control': 'public, max-age=0, s-maxage=600'
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
