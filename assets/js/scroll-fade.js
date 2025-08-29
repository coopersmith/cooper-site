/**
 * Enhanced Scroll Fade Animation
 * Provides smooth, performant fade-in animations for content elements as they enter the viewport
 */

class ScrollFadeManager {
  constructor(options = {}) {
    // Configuration with sensible defaults
    this.config = {
      // Element selectors
      selectors: options.selectors || 'h1, h2, h3, h4, h5, h6, p, img, ul, ol, hr, blockquote, pre, .highlight',
      
      // Animation settings
      threshold: options.threshold || 0.15,
      rootMargin: options.rootMargin || '0px 0px -50px 0px',
      staggerDelay: options.staggerDelay || 100, // ms between sequential animations
      
      // CSS classes
      classes: {
        section: options.sectionClass || 'fade-in-section',
        visible: options.visibleClass || 'is-visible',
        staggered: options.staggeredClass || 'fade-staggered'
      },
      
      // Performance options
      debounceMs: options.debounceMs || 16, // ~60fps
      maxBatchSize: options.maxBatchSize || 10
    };

    // State management
    this.observer = null;
    this.elements = new Map();
    this.animationQueue = [];
    this.isProcessing = false;
    this.respectsReducedMotion = this.checkReducedMotionPreference();

    // Bind methods
    this.handleIntersection = this.handleIntersection.bind(this);
    this.processAnimationQueue = this.processAnimationQueue.bind(this);
    this.handleVisibilityChange = this.handleVisibilityChange.bind(this);

    // Initialize when DOM is ready
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', () => this.init());
    } else {
      this.init();
    }
  }

  /**
   * Check if user prefers reduced motion
   */
  checkReducedMotionPreference() {
    return window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  }

  /**
   * Initialize the scroll fade system
   */
  init() {
    try {
      this.setupIntersectionObserver();
      this.processElements();
      this.setupEventListeners();
      
      // Handle elements already in view on page load
      this.handleInitialVisibleElements();
      
      console.log(`ScrollFade initialized with ${this.elements.size} elements`);
    } catch (error) {
      console.error('ScrollFade initialization failed:', error);
    }
  }

  /**
   * Set up the Intersection Observer
   */
  setupIntersectionObserver() {
    const options = {
      threshold: this.config.threshold,
      rootMargin: this.config.rootMargin
    };

    this.observer = new IntersectionObserver(this.handleIntersection, options);
  }

  /**
   * Process all eligible elements on the page
   */
  processElements() {
    const elements = document.querySelectorAll(this.config.selectors);
    
    elements.forEach((element, index) => {
      // Skip if element is already processed or hidden
      if (element.classList.contains(this.config.classes.section) || 
          element.offsetParent === null) {
        return;
      }

      // Store element metadata
      this.elements.set(element, {
        index,
        isHeading: this.isHeading(element),
        processed: false,
        staggerIndex: this.calculateStaggerIndex(element, index)
      });

      // Add base animation class
      element.classList.add(this.config.classes.section);
      
      // Add stagger class for enhanced animations
      if (!this.respectsReducedMotion) {
        element.classList.add(this.config.classes.staggered);
        element.style.setProperty('--stagger-delay', `${this.elements.get(element).staggerIndex * 50}ms`);
      }

      // Start observing
      this.observer.observe(element);
    });
  }

  /**
   * Calculate stagger index for more natural animation flow
   */
  calculateStaggerIndex(element, baseIndex) {
    // Group elements by their visual hierarchy
    if (this.isHeading(element)) {
      const level = parseInt(element.tagName.charAt(1));
      return Math.max(0, baseIndex - level); // Higher level headings animate first
    }
    return baseIndex;
  }

  /**
   * Check if element is a heading
   */
  isHeading(element) {
    return /^H[1-6]$/.test(element.tagName);
  }

  /**
   * Handle intersection events
   */
  handleIntersection(entries) {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        this.queueElementForAnimation(entry.target);
      }
    });

    // Process animation queue
    if (!this.isProcessing) {
      this.processAnimationQueue();
    }
  }

  /**
   * Queue element for animation with intelligent batching
   */
  queueElementForAnimation(element) {
    const metadata = this.elements.get(element);
    if (!metadata || metadata.processed) return;

    // Handle heading sections (show related content together)
    if (metadata.isHeading) {
      this.queueHeadingSection(element);
    } else {
      this.animationQueue.push(element);
    }
  }

  /**
   * Queue a heading and its related content
   */
  queueHeadingSection(headingElement) {
    const elementsToAnimate = [headingElement];
    let currentElement = headingElement;

    // Collect related content until next heading
    while (currentElement.nextElementSibling && 
           !this.isHeading(currentElement.nextElementSibling)) {
      currentElement = currentElement.nextElementSibling;
      
      // Only include elements we're managing
      if (this.elements.has(currentElement)) {
        elementsToAnimate.push(currentElement);
      }
    }

    // Add to animation queue
    this.animationQueue.push(...elementsToAnimate);
  }

  /**
   * Process the animation queue with smooth timing
   */
  async processAnimationQueue() {
    if (this.isProcessing || this.animationQueue.length === 0) return;
    
    this.isProcessing = true;

    try {
      // Process elements in batches for better performance
      while (this.animationQueue.length > 0) {
        const batch = this.animationQueue.splice(0, this.config.maxBatchSize);
        
        for (const element of batch) {
          await this.animateElement(element);
        }
      }
    } catch (error) {
      console.error('Animation queue processing failed:', error);
    } finally {
      this.isProcessing = false;
    }
  }

  /**
   * Animate a single element
   */
  async animateElement(element) {
    return new Promise(resolve => {
      const metadata = this.elements.get(element);
      if (!metadata || metadata.processed) {
        resolve();
        return;
      }

      // Mark as processed
      metadata.processed = true;

      // Stop observing this element
      this.observer.unobserve(element);

      // Apply animation
      requestAnimationFrame(() => {
        element.classList.add(this.config.classes.visible);
        
        // Resolve after a short delay for staggering
        setTimeout(resolve, this.respectsReducedMotion ? 0 : this.config.staggerDelay);
      });
    });
  }

  /**
   * Handle elements that are already visible on page load
   */
  handleInitialVisibleElements() {
    const viewportHeight = window.innerHeight;
    const scrollPosition = window.scrollY;

    this.elements.forEach((metadata, element) => {
      const rect = element.getBoundingClientRect();
      const elementTop = rect.top + scrollPosition;

      // If element is above the fold or partially visible
      if (elementTop <= scrollPosition + viewportHeight * 0.8) {
        this.queueElementForAnimation(element);
      }
    });

    // Process initial animations
    this.processAnimationQueue();
  }

  /**
   * Set up additional event listeners
   */
  setupEventListeners() {
    // Handle page visibility changes
    document.addEventListener('visibilitychange', this.handleVisibilityChange);

    // Handle reduced motion preference changes
    const mediaQuery = window.matchMedia('(prefers-reduced-motion: reduce)');
    mediaQuery.addEventListener('change', (e) => {
      this.respectsReducedMotion = e.matches;
      this.updateAnimationsForMotionPreference();
    });

    // Handle resize events (debounced)
    let resizeTimeout;
    window.addEventListener('resize', () => {
      clearTimeout(resizeTimeout);
      resizeTimeout = setTimeout(() => {
        this.handleResize();
      }, this.config.debounceMs);
    });
  }

  /**
   * Handle page visibility changes
   */
  handleVisibilityChange() {
    if (document.visibilityState === 'visible') {
      // Re-check elements when page becomes visible
      this.handleInitialVisibleElements();
    }
  }

  /**
   * Update animations based on motion preference
   */
  updateAnimationsForMotionPreference() {
    this.elements.forEach((metadata, element) => {
      if (this.respectsReducedMotion) {
        element.classList.remove(this.config.classes.staggered);
        element.style.removeProperty('--stagger-delay');
      } else if (!element.classList.contains(this.config.classes.visible)) {
        element.classList.add(this.config.classes.staggered);
        element.style.setProperty('--stagger-delay', `${metadata.staggerIndex * 50}ms`);
      }
    });
  }

  /**
   * Handle window resize
   */
  handleResize() {
    // Recalculate positions for elements that haven't been animated yet
    this.handleInitialVisibleElements();
  }

  /**
   * Clean up resources
   */
  destroy() {
    if (this.observer) {
      this.observer.disconnect();
    }
    
    document.removeEventListener('visibilitychange', this.handleVisibilityChange);
    
    this.elements.clear();
    this.animationQueue.length = 0;
    
    console.log('ScrollFade destroyed');
  }
}

// Initialize the scroll fade system
const scrollFade = new ScrollFadeManager({
  // Custom configuration can be passed here
  threshold: 0.1,
  staggerDelay: 80,
  rootMargin: '0px 0px -30px 0px'
});

// Export for potential external use
window.ScrollFadeManager = ScrollFadeManager;
window.scrollFade = scrollFade;