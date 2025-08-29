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
    
    // Enhance highlights with better attribution data
    const enhancedHighlights = (data.results || []).map(highlight => ({
      ...highlight,
      // Ensure we have all possible attribution fields available
      book_title: highlight.book_title || highlight.title,
      author: highlight.author,
      source: highlight.source,
      location: highlight.location,
      note: highlight.note,
      url: highlight.url,
      tags: highlight.tags,
      text: highlight.text
    }));
    
    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      body: JSON.stringify(enhancedHighlights),
    };
  } catch (error) {
    console.error('Readwise API Error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Failed to fetch highlights' }),
    };
  }
};
