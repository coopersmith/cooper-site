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
    
    if (!data.results || data.results.length === 0) {
      return {
        statusCode: 200,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
        body: JSON.stringify([]),
      };
    }
    
    // Get unique book IDs from highlights
    const bookIds = [...new Set(data.results.map(h => h.book_id).filter(Boolean))];
    
    // Fetch book details for all unique books (with timeout and error handling)
    const bookDetailsMap = {};
    
    const bookFetchPromises = bookIds.map(async (bookId) => {
      try {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 5000); // 5 second timeout
        
        const bookResponse = await fetch(`https://readwise.io/api/v2/books/${bookId}/`, {
          headers: {
            Authorization: `Token ${token}`,
          },
          signal: controller.signal
        });
        
        clearTimeout(timeoutId);
        
        if (bookResponse.ok) {
          const bookData = await bookResponse.json();
          bookDetailsMap[bookId] = bookData;
        }
      } catch (error) {
        console.error(`Error fetching book ${bookId}:`, error);
        // Continue without book details for this book
      }
    });
    
    // Wait for all book fetches to complete (or timeout)
    await Promise.allSettled(bookFetchPromises);
    
    // Enhance highlights with book information
    const enhancedHighlights = data.results.map(highlight => {
      const book = bookDetailsMap[highlight.book_id];
      return {
        ...highlight,
        book_title: book?.title || highlight.title || 'Unknown Source',
        author: book?.author || highlight.author,
        source: book?.source || book?.category || highlight.source,
        location: highlight.location,
        note: highlight.note,
        url: highlight.url,
        tags: highlight.tags,
        text: highlight.text
      };
    });
    
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
