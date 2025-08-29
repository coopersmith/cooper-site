document.addEventListener('DOMContentLoaded', function() {
  // Check if user prefers reduced motion
  const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  
  // Include all heading levels explicitly
  const contentElements = document.querySelectorAll('h1, h2, h3, h4, h5, h6, p, img, ul, ol, hr');
  
  const fadeInOptions = {
    threshold: 0.2,
    rootMargin: "0px 0px -50px 0px"
  };

  const fadeInObserver = new IntersectionObserver(function(entries, observer) {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        // If it's any heading level
        if (entry.target.matches('h1, h2, h3, h4, h5, h6')) {
          let currentElement = entry.target;
          // Show the heading
          currentElement.classList.add('is-visible');
          
          // Show content until next heading of any level
          while (currentElement.nextElementSibling && 
                 !currentElement.nextElementSibling.matches('h1, h2, h3, h4, h5, h6')) {
            currentElement = currentElement.nextElementSibling;
            currentElement.classList.add('is-visible');
          }
        } else {
          // For non-heading elements
          entry.target.classList.add('is-visible');
        }
        observer.unobserve(entry.target);
      }
    });
  }, fadeInOptions);

  // Get the current scroll position
  const scrollPosition = window.scrollY + window.innerHeight;

  contentElements.forEach(element => {
    // If user prefers reduced motion, make all elements visible immediately
    if (prefersReducedMotion) {
      element.classList.add('is-visible');
    } else {
      element.classList.add('fade-in-section');
      
      // If element is above current viewport bottom, make it visible immediately
      if (element.getBoundingClientRect().top + window.scrollY <= scrollPosition) {
        element.classList.add('is-visible');
      } else {
        // Only observe elements that are below the current viewport
        fadeInObserver.observe(element);
      }
    }
  });
}); 