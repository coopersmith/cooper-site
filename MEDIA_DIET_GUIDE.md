# Dynamic 2025 Media Diet Page

## What I've Built

✅ **Dynamic 2025 Reading List** at `/2025-reading-list/`  
✅ **Removed dashes** from note lists (cleaner date styling)  
✅ **Auto-updating content** that pulls from your actual notes  
✅ **Beautiful card-based design** with status indicators  
✅ **Statistics dashboard** showing your progress  

## How It Works

The page automatically finds and displays content based on your existing tagging system:

### Books
- **Currently Reading**: Notes with `books` + `MediaDiet2025` tags + `start` date but no `end` date
- **Completed**: Notes with `books` + `MediaDiet2025` tags + `end` date
- **Shows**: Title, author, rating, start/end dates

### Movies  
- **Finds**: Notes with `movies` + `MediaDiet2025` tags
- **Shows**: Title, director, year, rating, watch date

### TV Shows
- **Finds**: Notes with `tv`/`television` + `MediaDiet2025` tags  
- **Shows**: Title, creator, season, rating, watch date

## Visual Features

### Status Indicators
- 📖 **Currently Reading** (yellow badge)
- ✅ **Completed** (green badge)  
- 🎬 **Movie** (purple badge)
- 📺 **TV Show** (pink badge)

### Cards Show
- Title (linked to full note)
- Author/Director/Creator
- Star ratings (★★★★☆)
- Dates (started/finished/watched)
- Year and season info

### Stats Dashboard
- Books completed this year
- Currently reading count  
- Movies watched
- TV shows consumed

## Your Tagging System

The page works with your existing structure:

```yaml
---
title: "📚 Book Title"
author: ["Author Name"]
tags:
  - books
  - MediaDiet2025  # or mediadiet/2025
start: 2025-01-21
end: 2025-03-14
rating: 8
---
```

## What You Get

### Automatic Updates
- Add a book note with `MediaDiet2025` tag → appears automatically
- Set `start` date → shows in "Currently Reading"  
- Set `end` date → moves to "Completed"
- Add `rating` → shows star display

### Clean Design
- Responsive grid layout
- Hover effects and smooth transitions
- Color-coded status badges
- Dark mode support

### Easy Management
- No manual list maintenance
- Just write notes with proper tags
- Page updates automatically
- Links directly to full reviews

## Next Steps

1. **Test the page** - Visit `/2025-reading-list/` 
2. **Add content** - Create new media notes with `MediaDiet2025` tag
3. **Set dates** - Use `start`/`end` for reading progress tracking
4. **Add ratings** - Use 1-10 scale for star displays

The page will grow automatically as you add more media consumption notes throughout 2025!

## Navigation

The page is already linked in your main navigation as "Media Diet" - no additional setup needed.