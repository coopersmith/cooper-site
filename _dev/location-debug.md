# Location-aware intro — debug URLs

The homepage intro changes based on my most recent Foursquare check-in
(see `assets/js/foursquare.js`). To preview a specific state without
actually being there, append a `?loc=` query param to any homepage URL.

> This folder is ignored by Jekyll (underscore-prefixed **and** listed in
> `exclude` in `_config.yml`), so it never ships to the live site. It still
> lives in the git repo — it's "private" in the sense of not published.

## Preview URLs

Local dev (`bundle exec jekyll serve`):

| State | URL |
| --- | --- |
| In NYC / Brooklyn | http://127.0.0.1:4000/?loc=nyc |
| On the Farm Coast (RI/MA) | http://127.0.0.1:4000/?loc=ri |
| Travelling (default place) | http://127.0.0.1:4000/?loc=travel |
| Travelling, custom place | http://127.0.0.1:4000/?loc=travel&place=Rome,%20Italy |
| Neutral (no-JS / stale fallback) | http://127.0.0.1:4000/?loc=neutral |

Production (`https://coopersmith.nyc`) — same params:

| State | URL |
| --- | --- |
| In NYC / Brooklyn | https://coopersmith.nyc/?loc=nyc |
| On the Farm Coast (RI/MA) | https://coopersmith.nyc/?loc=ri |
| Travelling (default place) | https://coopersmith.nyc/?loc=travel |
| Travelling, custom place | https://coopersmith.nyc/?loc=travel&place=Rome,%20Italy |
| Neutral | https://coopersmith.nyc/?loc=neutral |

## Notes

- `?loc=travel` accepts an optional `?place=` (URL-encode spaces/commas,
  e.g. `Rome,%20Italy`). Without it, the place defaults to `Lisbon, Portugal`.
- The override only pins the **intro**. The "Last seen at…" line still
  fetches the real check-in, so it may not match the forced state.
- Accepted values: `nyc`, `ri`, `travel`, `neutral` (`home` is an alias
  for `neutral`). Anything else is ignored and the real check-in wins.
- Without any param, the intro uses the live check-in:
  - NY state / NYC boroughs → NYC
  - Rhode Island or Massachusetts → Farm Coast
  - anywhere else, checked in within the last 2 days → travelling
  - stale (older than 2 days) or unknown → neutral
