# Ephemera Section Setup

## Overview

The Ephemera section integrates with Airtable to display a collection of ephemeral moments, scanned documents, and found objects. This implementation includes API quota optimization to prevent exceeding Airtable's limits.

## API Quota Optimization

To prevent hitting Airtable's API quota (1,000 calls/month on free plan), the implementation includes:

1. **Caching**: Data is cached for 1 hour to avoid unnecessary API calls
2. **Limited Requests**: Maximum of 3 API requests per build
3. **Rate Limiting**: 0.25 second delays between requests (respects 5 req/sec limit)
4. **Batch Processing**: Uses maximum page size (100 records) to minimize requests
5. **Error Handling**: Graceful fallback when API limits are reached

## Setup Instructions

### 1. Environment Variables

Create or update `.env` file with your Airtable credentials:

```bash
AIRTABLE_API_KEY=path3fVIEgwke1Xea.a8d390efc5c1b6e0cbbbb790cedad1ca88413b06533bf4f5069ec43ef71d88e5
AIRTABLE_BASE_ID=applqniEnWwfSHIax
AIRTABLE_TABLE_NAME=tblzLdJRyUzTYUMzq
```

**Note**: The table name should be the table ID (starting with `tbl`), not the display name.

### 2. Airtable Table Structure

Your Airtable table should include these fields:
- **Title** (Single line text)
- **Description** (Long text)
- **Date** (Date field)
- **Location** (Single line text)
- **Tags** (Multiple select or Single line text)
- **Attachments** (Attachment field for images)

### 3. Local Development

Use the provided development script:

```bash
./dev-server.sh
```

Or manually:

```bash
export GEM_HOME=$HOME/.gems
export PATH=$HOME/.gems/bin:$PATH
source .env
bundle exec jekyll serve --livereload --host 0.0.0.0 --port 4000
```

### 4. Netlify Development

For Netlify development (as mentioned in your workflow):

```bash
netlify dev --command "./dev-server.sh"
```

## Troubleshooting API Issues

### 403 Permission Error

If you see a 403 error:
1. Verify your API key has the correct permissions
2. Check that the base ID and table name are correct
3. Ensure your token has `data.records:read` scope

### API Quota Exceeded

If you hit the quota limit:
1. The plugin will use cached data automatically
2. Wait for your quota to reset (monthly)
3. Consider upgrading your Airtable plan for higher limits
4. Reduce build frequency during development

### Table Not Found

The plugin automatically tries multiple table name formats:
- Table name (e.g., "Ephemera")
- Table ID (extracted from your Airtable URL)

## File Structure

```
_plugins/airtable_ephemera.rb    # Main plugin
_data/ephemera.yml               # Cached data (auto-generated)
_pages/ephemera.html             # Display page
dev-server.sh                    # Development server script
.env                             # Environment variables (not in git)
```

## Performance Notes

- Data is cached for 1 hour to balance freshness with API usage
- Images are lazy-loaded for better performance
- Responsive grid layout adapts to different screen sizes
- Lightbox integration for full-size image viewing