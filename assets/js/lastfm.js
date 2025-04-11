// Last.fm API configuration
const apiKey = "c45fbeb0d318aac9d7698d798b639811";
const username = "coopersmith";
const lastFmApiUrl = `https://ws.audioscrobbler.com/2.0/?method=user.gettopartists&user=${username}&api_key=${apiKey}&format=json&period=3month&limit=5`;

// Function to fetch and display top artists
function fetchTopArtists() {
    const recentlyPlayedDiv = document.getElementById("recently-played");
    
    fetch(lastFmApiUrl)
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
            
            recentlyPlayedDiv.innerHTML = `<p>Recently listening to a lot of ${commaSeparatedArtists}</p>`;
        })
        .catch(error => {
            console.error("Error fetching data from Last.fm:", error);
            recentlyPlayedDiv.innerHTML = `<p>Unable to load music data at the moment.</p>`;
        });
}

// Call the function when the page loads
document.addEventListener('DOMContentLoaded', fetchTopArtists); 