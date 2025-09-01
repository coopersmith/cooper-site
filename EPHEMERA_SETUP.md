# Ephemera Section Setup Guide

This guide will help you set up the Ephemera section on your Jekyll website using your existing Airtable data and scanned ephemera.

## Prerequisites

- Jekyll site (already set up)
- Airtable account with your ephemera data
- Scanned ephemera images uploaded to Airtable

## Setup Instructions

### 1. Install Dependencies

Run the following command to install the required gems:

```bash
bundle install
```

### 2. Configure Airtable Credentials

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Edit the `.env` file with your actual Airtable credentials:
   ```bash
   # Get your API key from https://airtable.com/account
   AIRTABLE_API_KEY=your_actual_api_key
   
   # Find your base ID in your Airtable URL (starts with "app")
   AIRTABLE_BASE=appXXXXXXXXXXXXXX
   
   # The name of your table containing ephemera data
   AIRTABLE_EPHEMERA_TABLE=Ephemera
   ```

### 3. Airtable Table Structure

Your Airtable table should include these fields (field names can be customized in the plugin):

- **Title** or **Name** (Single line text) - Required
- **Description** or **Notes** (Long text) - Optional
- **Date** (Date) - Optional but recommended
- **Location** (Single line text) - Optional
- **Tags** (Multiple select or single line text) - Optional
- **Attachments** (Attachment field) - For your scanned images

### 4. Build and Test

1. Build your site:
   ```bash
   bundle exec jekyll build
   ```

2. Serve locally to test:
   ```bash
   bundle exec jekyll serve
   ```

3. Visit `http://localhost:4000/ephemera/` to see your Ephemera section

## Features

- **Responsive Grid Layout**: Displays ephemera items in a responsive masonry-style grid
- **Image Gallery**: Shows your scanned ephemera with hover effects
- **Metadata Display**: Shows title, date, location, description, and tags
- **Automatic Data Sync**: Fetches fresh data from Airtable on each build
- **Mobile Optimized**: Responsive design that works on all devices

## Customization

### Styling
Edit `_sass/_ephemera.scss` to customize the appearance of your ephemera section.

### Layout
Modify `_layouts/ephemera.html` to change how ephemera items are displayed.

### Data Fields
Update `_plugins/airtable_ephemera.rb` to map different Airtable field names to the display fields.

## Troubleshooting

- **No items showing**: Check your `.env` file credentials and table name
- **Images not loading**: Ensure your Airtable attachments are publicly accessible
- **Build errors**: Run `bundle exec jekyll build --verbose` for detailed error messages

## Navigation

The Ephemera section has been automatically added to your site navigation between "Travel and Adventures" and "Media Diet".

---

For more information about the original Ephemera concept, see: https://github.com/dnywh/ephemera