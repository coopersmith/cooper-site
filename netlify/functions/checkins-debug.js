// TEMPORARY debug endpoint — lists the last 30 check-ins formatted with the
// same place-resolution logic as assets/js/foursquare.js, so the rendering
// can be eyeballed on a deploy preview. Remove before merging to main.

// Mirror of the homepage place logic.
function formatPlace(loc) {
  loc = loc || {};
  const rawCity = loc.city || loc.state || '';
  let neighborhood = loc.neighborhood;
  if (Array.isArray(neighborhood)) neighborhood = neighborhood[0];

  const nycCities = [
    'new york', 'new york city', 'manhattan', 'brooklyn',
    'queens', 'bronx', 'the bronx', 'staten island'
  ];
  const isNYC = nycCities.includes(rawCity.trim().toLowerCase());
  const city = isNYC && neighborhood ? '' : rawCity;

  return [neighborhood, city]
    .filter((part, i, parts) => part && parts.indexOf(part) === i)
    .join(', ');
}

export const handler = async () => {
  const OAUTH_TOKEN = process.env.FOURSQUARE_OAUTH_TOKEN;

  if (!OAUTH_TOKEN) {
    return { statusCode: 500, body: 'Missing FOURSQUARE_OAUTH_TOKEN' };
  }

  const endpoint = `https://api.foursquare.com/v2/users/self/checkins?oauth_token=${OAUTH_TOKEN}&v=20250415&limit=30`;

  try {
    const response = await fetch(endpoint);
    const data = await response.json();

    if (data.meta && data.meta.code !== 200) {
      return { statusCode: data.meta.code, body: data.meta.errorDetail || 'Foursquare API error' };
    }

    const items = (data.response && data.response.checkins && data.response.checkins.items) || [];

    const lines = items.map((c, i) => {
      const venue = (c.venue && c.venue.name) || '(unknown venue)';
      const place = formatPlace(c.venue && c.venue.location);
      const date = new Date(c.createdAt * 1000).toLocaleDateString('en-US', {
        year: 'numeric', month: 'short', day: 'numeric'
      });
      const line = `Last seen at ${venue}${place ? ` in ${place}` : ''}`;
      const rawCity = (c.venue && c.venue.location && (c.venue.location.city || c.venue.location.state)) || '—';
      const hood = (c.venue && c.venue.location && c.venue.location.neighborhood) || '—';
      return `${String(i + 1).padStart(2, ' ')}. ${line}\n      [${date} · city: ${rawCity} · neighborhood: ${hood}]`;
    });

    return {
      statusCode: 200,
      headers: { 'Content-Type': 'text/plain; charset=utf-8' },
      body: lines.join('\n\n') || 'No check-ins found'
    };
  } catch (error) {
    console.error('Foursquare API Error:', error);
    return { statusCode: 500, body: 'Failed to fetch check-in data' };
  }
};
