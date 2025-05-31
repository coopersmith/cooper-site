// Last.fm API configuration
const apiKey = "c45fbeb0d318aac9d7698d798b639811";
const username = "coopersmith";
const topArtistsUrl = `https://ws.audioscrobbler.com/2.0/?method=user.gettopartists&user=${username}&api_key=${apiKey}&format=json&period=3month&limit=5`;
const recentTracksUrl = `https://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&user=${username}&api_key=${apiKey}&format=json&limit=1`;

// Function to fetch and display top artists
function fetchTopArtists() {
    const recentlyPlayedDiv = document.getElementById("recently-played");
    
    fetch(topArtistsUrl)
        .then(response => {
            if (!response.ok) {
                throw new Error('Network response was not ok');
            }
            return response.json();
        })
        .then(data => {
            const artistData = data.topartists.artist;
            const artistNames = artistData.map(artist => artist.name);
            const commaSeparatedArtists = artistNames.join(", ");
            
            recentlyPlayedDiv.innerHTML = `<p>Recently I've been listening to a lot of ${commaSeparatedArtists}</p>`;
            
            // After fetching top artists, get currently playing track
            fetchCurrentTrack();
        })
        .catch(error => {
            console.error("Error fetching data from Last.fm:", error);
            recentlyPlayedDiv.innerHTML = `<p>Unable to load music data at the moment.</p>`;
        });
}

// Function to fetch and display currently playing track
function fetchCurrentTrack() {
    const recentlyPlayedDiv = document.getElementById("recently-played");
    
    fetch(recentTracksUrl)
        .then(response => {
            if (!response.ok) {
                throw new Error('Network response was not ok');
            }
            return response.json();
        })
        .then(data => {
            if (data.recenttracks && data.recenttracks.track && data.recenttracks.track.length > 0) {
                const track = data.recenttracks.track[0];
                
                // Check if the track is currently playing
                if (track['@attr'] && track['@attr'].nowplaying === 'true') {
                    const trackName = track.name;
                    const artistName = track.artist['#text'];
                    const trackUrl = track.url;
                    
                    // Add the currently playing info to the existing content
                    recentlyPlayedDiv.innerHTML += `<p>Currently listening to <a href="${trackUrl}" target="_blank">${trackName}</a> by ${artistName}</p>`;
                }
            }
        })
        .catch(error => {
            console.error("Error fetching current track from Last.fm:", error);
        });
}

// Call the function when the page loads
document.addEventListener('DOMContentLoaded', fetchTopArtists); 