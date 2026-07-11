// Shared Last.fm client. Load this before any page script that talks to
// Last.fm (home-lately.js on the homepage, listening.js on /listening) so
// the account details and request plumbing live in exactly one place.
const LASTFM = (() => {
  const API_KEY = "c45fbeb0d318aac9d7698d798b639811";
  const USERNAME = "coopersmith";
  const ROOT = "https://ws.audioscrobbler.com/2.0/";

  // GET a Last.fm API method as JSON; extra params join the query string.
  function api(method, params = {}) {
    const url = new URL(ROOT);
    url.search = new URLSearchParams({
      method,
      user: USERNAME,
      api_key: API_KEY,
      format: "json",
      ...params,
    }).toString();
    return fetch(url).then((r) => {
      if (!r.ok) throw new Error(`Last.fm ${method} → ${r.status}`);
      return r.json();
    });
  }

  return { api };
})();
