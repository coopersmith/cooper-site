import fetch from 'node-fetch';

export const handler = async () => {
  const token = process.env.READWISE_TOKEN;
  const endpoint = 'https://readwise.io/api/v2/highlights/?page_size=20';

  try {
    const response = await fetch(endpoint, {
      headers: {
        Authorization: `Token ${token}`,
      },
    });

    if (!response.ok) {
      return {
        statusCode: response.status,
        body: JSON.stringify({ error: 'Failed to fetch highlights' }),
      };
    }

    const data = await response.json();
    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      body: JSON.stringify(data.results || []),
    };
  } catch (error) {
    console.error('Readwise API Error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Failed to fetch highlights' }),
    };
  }
};
