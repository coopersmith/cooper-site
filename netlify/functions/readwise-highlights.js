export const handler = async () => {
  const token = process.env.READWISE_TOKEN;
  // Use the books endpoint with highlights included to get both highlights and book metadata
  const endpoint = 'https://readwise.io/api/v2/books/?page_size=20&highlights_limit=10';

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
    
    // Extract highlights from books with proper attribution
    const highlights = [];
    
    if (data.results) {
      data.results.forEach(book => {
        if (book.highlights && book.highlights.length > 0) {
          book.highlights.forEach(highlight => {
            highlights.push({
              ...highlight,
              book_title: book.title,
              author: book.author,
              source: book.source || book.category,
              book_id: book.id
            });
          });
        }
      });
    }
    
    // Sort by updated date (most recent first)
    highlights.sort((a, b) => new Date(b.updated) - new Date(a.updated));
    
    // Limit to 20 highlights
    const limitedHighlights = highlights.slice(0, 20);
    
    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      body: JSON.stringify(limitedHighlights),
    };
  } catch (error) {
    console.error('Readwise API Error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Failed to fetch highlights' }),
    };
  }
};
