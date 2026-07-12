// /photos/ stream behavior: progressive image loading plus the floating
// date/location pill that tracks whichever photo is in view.
document.addEventListener('DOMContentLoaded', function() {
  // Progressive image loading: swap data-src in as photos approach the
  // viewport, fading each one in once it has actually decoded.
  const images = document.querySelectorAll('.photo-thumbnail[data-src]');

  const imageObserver = new IntersectionObserver((entries, observer) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        const img = entry.target;
        const src = img.getAttribute('data-src');

        if (src) {
          const newImg = new Image();
          newImg.onload = function() {
            img.src = src;
            img.removeAttribute('data-src');
            img.classList.add('loaded');
          };
          newImg.onerror = function() {
            img.classList.add('loaded'); // Still show placeholder on error
          };
          newImg.src = src;
        }

        observer.unobserve(img);
      }
    });
  }, {
    rootMargin: '300px' // Start loading a couple of screens ahead
  });

  images.forEach(img => imageObserver.observe(img));

  // Date pill
  const photos = document.querySelectorAll('.photo-item');
  const datePill = document.getElementById('photo-date-pill');
  const dateText = document.getElementById('photo-date-text');
  const locationText = document.getElementById('photo-location-text');

  if (!photos.length || !datePill || !dateText) {
    return;
  }

  // Format location: "City, Country" but hide the country for the US.
  const formatLocation = (location) => {
    if (!location) return null;

    const parts = location.split(',').map(s => s.trim());

    if (parts.length >= 2) {
      const city = parts[0];
      const country = parts.slice(1).join(', ');

      if (country.toLowerCase().includes('united states') ||
          country.toLowerCase() === 'usa' ||
          country.toLowerCase() === 'us') {
        return city;
      }

      return `${city}, ${country}`;
    }

    return location;
  };

  const photoData = Array.from(photos).map(photo => {
    return {
      date: photo.getAttribute('data-date') || null,
      location: formatLocation(photo.getAttribute('data-location'))
    };
  });

  let currentData = { date: null, location: null };

  const updatePill = (data) => {
    if (data.date && (data.date !== currentData.date || data.location !== currentData.location)) {
      currentData = data;
      datePill.style.opacity = '0';
      setTimeout(() => {
        dateText.textContent = data.date;
        if (locationText) {
          if (data.location) {
            locationText.textContent = data.location;
            locationText.style.display = 'block';
          } else {
            locationText.textContent = '';
            locationText.style.display = 'none';
          }
        }
        datePill.style.opacity = '1';
      }, 150);
    }
  };

  // A narrow band across the middle of the viewport decides which photo the
  // pill describes.
  const observerOptions = {
    root: null,
    rootMargin: '-45% 0px -45% 0px',
    threshold: [0, 0.1, 0.5, 1]
  };

  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        const index = Array.from(photos).indexOf(entry.target);
        const data = photoData[index];
        if (data && data.date) {
          updatePill(data);
        }
      }
    });
  }, observerOptions);

  photos.forEach(photo => observer.observe(photo));

  // Show the first photo's date on load.
  if (photoData[0] && photoData[0].date) {
    updatePill(photoData[0]);
  }
});
