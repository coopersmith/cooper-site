// Reusable client-side sort for index views (media, concerts, travels).
// A <select class="sort-select"> drives one or more containers:
//   data-sort-scope : CSS selector matching the container(s) to reorder
//   data-sort-item  : selector for the sortable items within each container
// Items expose data-title / data-date / data-rating for the sort keys.
// data-ranking (optional) is Coop's hand-ordered favourites list (1 = best);
// it rides on top of the rating sort so ranked items lead in rank order.
(function () {
  function compare(key) {
    return function (a, b) {
      if (key === 'az') {
        return (a.getAttribute('data-title') || '').localeCompare(b.getAttribute('data-title') || '');
      }
      if (key === 'rating') {
        // A hand-picked ranking (e.g. Coop's 100 movies) outranks the coarse
        // 1–7 rating: ranked items sort first by rank, the rest fall back to
        // rating, highest first.
        var ra = parseInt(a.getAttribute('data-ranking'), 10);
        var rb = parseInt(b.getAttribute('data-ranking'), 10);
        var aRanked = !isNaN(ra);
        var bRanked = !isNaN(rb);
        if (aRanked && bRanked) return ra - rb;
        if (aRanked) return -1;
        if (bRanked) return 1;
        return (parseFloat(b.getAttribute('data-rating')) || 0) - (parseFloat(a.getAttribute('data-rating')) || 0);
      }
      // 'date' — newest first
      return (b.getAttribute('data-date') || '').localeCompare(a.getAttribute('data-date') || '');
    };
  }

  function wire(sel) {
    function apply() {
      var key = sel.value;
      var containers = document.querySelectorAll(sel.getAttribute('data-sort-scope'));
      Array.prototype.forEach.call(containers, function (container) {
        var items = Array.prototype.slice.call(container.querySelectorAll(sel.getAttribute('data-sort-item')));
        if (!items.length) return;
        items.sort(compare(key));
        var parent = items[0].parentNode;
        items.forEach(function (it) { parent.appendChild(it); });
      });
    }
    sel.addEventListener('change', apply);
    // Apply the default sort on load so content merged from multiple
    // sources (e.g. media + concerts) interleaves correctly rather than
    // appearing in source order.
    apply();
  }

  Array.prototype.forEach.call(document.querySelectorAll('.sort-select'), wire);
})();
