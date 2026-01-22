export const handler = async (event) => {
  // Only allow POST requests
  if (event.httpMethod !== 'POST') {
    return {
      statusCode: 405,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      body: JSON.stringify({ error: 'Method not allowed' }),
    };
  }

  // Check for authentication token
  const authToken = event.headers.authorization?.replace('Bearer ', '') || 
                    event.queryStringParameters?.token;
  
  const expectedToken = process.env.PHOTO_UPLOAD_TOKEN;
  if (!expectedToken || authToken !== expectedToken) {
    return {
      statusCode: 401,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      body: JSON.stringify({ error: 'Unauthorized' }),
    };
  }

  try {
    // Parse JSON body (expecting base64 encoded image)
    const body = JSON.parse(event.body);
    const { file, filename } = body;

    if (!file || !filename) {
      return {
        statusCode: 400,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
        body: JSON.stringify({ error: 'Missing file or filename' }),
      };
    }

    const githubToken = process.env.GITHUB_TOKEN;
    if (!githubToken) {
      return {
        statusCode: 500,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
        body: JSON.stringify({ error: 'GitHub token not configured' }),
      };
    }

    const repoOwner = process.env.GITHUB_REPO_OWNER || 'coopersmith';
    const repoName = process.env.GITHUB_REPO_NAME || 'digital-garden-jekyll-template';
    const branch = process.env.GITHUB_BRANCH || 'main';

    // Generate file path with date-based folder structure
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const timestamp = now.getTime();
    const sanitizedFileName = `${timestamp}-${filename.replace(/[^a-zA-Z0-9.-]/g, '_')}`;
    const filePath = `assets/photos/${year}/${month}/${sanitizedFileName}`;

    // Get current file content (if exists) to get SHA for update
    let fileSha = null;
    try {
      const getContentResponse = await fetch(
        `https://api.github.com/repos/${repoOwner}/${repoName}/contents/${filePath}?ref=${branch}`,
        {
          headers: {
            'Authorization': `token ${githubToken}`,
            'Accept': 'application/vnd.github.v3+json',
          },
        }
      );

      if (getContentResponse.ok) {
        const contentData = await getContentResponse.json();
        fileSha = contentData.sha;
      }
    } catch (error) {
      // File doesn't exist yet, that's fine
      console.log('File does not exist yet, will create new file');
    }

    // Upload file to GitHub
    const uploadPayload = {
      message: `Add photo: ${sanitizedFileName}`,
      content: file, // Base64 encoded file content
      branch: branch,
    };

    if (fileSha) {
      uploadPayload.sha = fileSha;
    }

    const uploadResponse = await fetch(
      `https://api.github.com/repos/${repoOwner}/${repoName}/contents/${filePath}`,
      {
        method: 'PUT',
        headers: {
          'Authorization': `token ${githubToken}`,
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(uploadPayload),
      }
    );

    if (!uploadResponse.ok) {
      const errorData = await uploadResponse.json();
      throw new Error(`GitHub API error: ${JSON.stringify(errorData)}`);
    }

    const uploadData = await uploadResponse.json();

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      body: JSON.stringify({
        success: true,
        message: 'Photo uploaded successfully',
        path: filePath,
        url: `/${filePath}`,
        commit: uploadData.commit,
      }),
    };
  } catch (error) {
    console.error('Upload error:', error);
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      body: JSON.stringify({
        error: 'Failed to upload photo',
        details: error.message,
      }),
    };
  }
};
