// TEMPORARY debug endpoint — shows the 6 most recent check-ins with the same
// neighborhood resolution as the homepage (Foursquare tag first, OSM reverse-
// geocode fallback), labeling where each neighborhood came from. Throttled to
// respect Nominatim's ~1 req/sec. Remove before merging to main.

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function usableNeighborhood(hood) {
  if (Array.isArray(hood)) hood = hood[0];
  return hood && /[A-Z]/.test(hood) ? hood : '';
}

async function reverseGeocodeNeighborhood(lat, lng) {
  if (lat == null || lng == null) return '';
  try {
    const url = `https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lng}&format=json&addressdetails=1`;
    const res = await fetch(url, {
      headers: { 'User-Agent': 'coopersmith.nyc-checkin/1.0 (coopersmi@gmail.com)' }
    });
    if (!res.ok) return '';
    const data = await res.json();
    const a = data.address || {};
    return a.neighbourhood || a.suburb || a.quarter || a.city_district || '';
  } catch (error) {
    return '';
  }
}

function formatPlace(loc) {
  loc = loc || {};
  const rawCity = (loc.city || loc.state || '')
    .replace(/^(Town|City|Township|Village|Borough) of /i, '');
  const neighborhood = usableNeighborhood(loc.neighborhood);

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
  if (!OAUTH_TOKEN) return { statusCode: 500, body: 'Missing FOURSQUARE_OAUTH_TOKEN' };

  const endpoint = `https://api.foursquare.com/v2/users/self/checkins?oauth_token=${OAUTH_TOKEN}&v=20250415&limit=6`;

  try {
    const response = await fetch(endpoint);
    const data = await response.json();

    if (data.meta && data.meta.code !== 200) {
      return { statusCode: data.meta.code, body: data.meta.errorDetail || 'Foursquare API error' };
    }

    const items = (data.response && data.response.checkins && data.response.checkins.items) || [];
    const lines = [];

    for (let i = 0; i < items.length; i++) {
      const c = items[i];
      const loc = (c.venue && c.venue.location) || {};
      const fsHood = usableNeighborhood(loc.neighborhood);

      let source = fsHood ? 'foursquare' : 'none';
      if (!fsHood) {
        await sleep(1000); // be polite to Nominatim
        const geoHood = await reverseGeocodeNeighborhood(loc.lat, loc.lng);
        if (geoHood) {
          loc.neighborhood = geoHood;
          source = 'geocoded';
        }
      }

      const venue = (c.venue && c.venue.name) || '(unknown venue)';
      const place = formatPlace(loc);
      const date = new Date(c.createdAt * 1000).toLocaleDateString('en-US', {
        year: 'numeric', month: 'short', day: 'numeric'
      });
      const line = `Last seen at ${venue}${place ? ` in ${place}` : ''}`;
      lines.push(`${String(i + 1).padStart(2, ' ')}. ${line}\n      [${date} · neighborhood source: ${source} -> ${loc.neighborhood || '—'}]`);
    }

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
