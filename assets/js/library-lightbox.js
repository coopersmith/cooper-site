// Lightbox for library image embeds (image_embeds.click: lightbox).
// Clicking an embedded figure opens an overlay scoped to THAT post's
// images — prev/next cycle only through embeds inside the same <article>
// (or the whole page when there's no article), never the rest of the
// library. No dependencies; does nothing on pages without lightbox embeds.
document.addEventListener('DOMContentLoaded', function() {
  if (!document.querySelector('.library-image a[data-lightbox]')) return;

  var overlay = null;
  var group = [];
  var index = 0;
  var lastFocus = null;

  function build() {
    overlay = document.createElement('div');
    overlay.className = 'library-lightbox';
    overlay.setAttribute('role', 'dialog');
    overlay.setAttribute('aria-modal', 'true');
    overlay.setAttribute('aria-label', 'Photo viewer');
    overlay.innerHTML =
      '<button class="library-lightbox-close" aria-label="Close">&times;</button>' +
      '<button class="library-lightbox-prev" aria-label="Previous photo">&#8592;</button>' +
      '<figure>' +
      '  <img alt="">' +
      '  <figcaption></figcaption>' +
      '</figure>' +
      '<button class="library-lightbox-next" aria-label="Next photo">&#8594;</button>' +
      '<div class="library-lightbox-counter"></div>';
    document.body.appendChild(overlay);

    overlay.querySelector('.library-lightbox-close').addEventListener('click', close);
    overlay.querySelector('.library-lightbox-prev').addEventListener('click', function() { step(-1); });
    overlay.querySelector('.library-lightbox-next').addEventListener('click', function() { step(1); });
    // Click on the backdrop (not the image or buttons) closes.
    overlay.addEventListener('click', function(e) {
      if (e.target === overlay || e.target.tagName === 'FIGURE') close();
    });
  }

  function show(i) {
    index = (i + group.length) % group.length;
    var link = group[index];
    var thumb = link.querySelector('img');
    var img = overlay.querySelector('img');
    img.src = link.href;
    img.alt = thumb ? thumb.alt : '';
    var figcap = link.closest('figure');
    var caption = figcap && figcap.querySelector('figcaption');
    overlay.querySelector('figcaption').textContent = caption ? caption.textContent : '';
    overlay.querySelector('.library-lightbox-counter').textContent =
      group.length > 1 ? (index + 1) + ' / ' + group.length : '';
    var multi = group.length > 1;
    overlay.querySelector('.library-lightbox-prev').hidden = !multi;
    overlay.querySelector('.library-lightbox-next').hidden = !multi;
  }

  function step(delta) {
    show(index + delta);
  }

  function open(link) {
    if (!overlay) build();
    var scope = link.closest('article') || document;
    group = Array.prototype.slice.call(scope.querySelectorAll('.library-image a[data-lightbox]'));
    lastFocus = document.activeElement;
    overlay.classList.add('is-open');
    document.documentElement.classList.add('library-lightbox-open');
    show(group.indexOf(link));
    overlay.querySelector('.library-lightbox-close').focus();
  }

  function close() {
    overlay.classList.remove('is-open');
    document.documentElement.classList.remove('library-lightbox-open');
    overlay.querySelector('img').src = '';
    if (lastFocus) lastFocus.focus();
  }

  document.addEventListener('click', function(e) {
    var link = e.target.closest && e.target.closest('.library-image a[data-lightbox]');
    if (!link) return;
    e.preventDefault();
    open(link);
  });

  document.addEventListener('keydown', function(e) {
    if (!overlay || !overlay.classList.contains('is-open')) return;
    if (e.key === 'Escape') close();
    else if (e.key === 'ArrowLeft') step(-1);
    else if (e.key === 'ArrowRight') step(1);
  });
});
