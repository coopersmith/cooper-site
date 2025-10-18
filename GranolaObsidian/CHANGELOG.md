# Changelog

## [1.1.0] - 2025-10-18

### Added
- **Automatic Backlinks for People Mentions**: Person names from meeting attendees are now automatically wrapped in `[[Name]]` format throughout the note content, creating Obsidian backlinks to person pages. This helps build connections between meeting notes and the people involved.

- **Configurable Topic Linking**: Added a new settings field "Linkable Topics" where users can enter a comma-separated list of topics to automatically link in notes (e.g., "Product Strategy, Team Sync, Q4 Planning"). Any occurrence of these topics in imported notes will be wrapped in `[[Topic]]` format.

### Implementation Details
- Added `linkableTopics` setting to store user-configured topics
- Created `addBacklinks()` method that:
  - Extracts person names from attendee emails
  - Uses regex matching with word boundaries to find mentions in note content
  - Wraps both people names and configured topics in `[[brackets]]`
  - Prevents double-linking by checking for existing brackets
  - Sorts by length (longest first) to avoid partial matches
  - Preserves original text casing
  - Uses case-insensitive matching for topics

- Added settings UI with textarea input for comma-separated topics
- Includes helpful descriptions and instructions for users

### Technical Notes
- People names are derived from attendee email addresses using the existing `extractNameFromEmail()` method
- The name mapping CSV feature can be used for accurate person name display
- Backlink processing happens after markdown conversion but before file creation
- Both features work together seamlessly in the same sync process

## [1.0.0] - Previous Release
- Initial release with Granola notes sync functionality
