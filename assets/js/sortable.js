// Reusable client-side sort for index views (media, concerts, travels).
// A <select class="sort-select"> drives one or more containers:
//   data-sort-scope : CSS selector matching the container(s) to reorder
//   data-sort-item  : selector for the sortable items within each container
// Items expose data-title / data-date / data-rating for the sort keys.
// data-ranking (optional) is a hand-ordered favourites list (1 = best). When
// the driving <select> carries data-rank-active="1", the rating sort leads
// with ranked items in rank order; otherwise ranking is ignored. The media
// page flips this on only while the Movies filter is active, so the ranked
// list surfaces as a contiguous 1→N run there without disturbing other views.
(function () {
  function compare(key, useRank) {
    return function (a, b) {
      if (key === 'az') {
        return (a.getAttribute('data-title') || '').localeCompare(b.getAttribute('data-title') || '');
      }
      if (key === 'rating') {
        if (useRank) {
          var ra = parseInt(a.getAttribute('data-ranking'), 10);
          var rb = parseInt(b.getAttribute('data-ranking'), 10);
          var aRanked = !isNaN(ra);
          var bRanked = !isNaN(rb);
          if (aRanked && bRanked) return ra - rb;
          if (aRanked) return -1;
          if (bRanked) return 1;
        }
        // Fall back to the coarse 1–7 rating, highest first.
        return (parseFloat(b.getAttribute('data-rating')) || 0) - (parseFloat(a.getAttribute('data-rating')) || 0);
      }
      // 'date' — newest first
      return (b.getAttribute('data-date') || '').localeCompare(a.getAttribute('data-date') || '');
    };
  }

  function wire(sel) {
    function apply() {
      var key = sel.value;
      var useRank = sel.getAttribute('data-rank-active') === '1';
      var containers = document.querySelectorAll(sel.getAttribute('data-sort-scope'));
      Array.prototype.forEach.call(containers, function (container) {
        var items = Array.prototype.slice.call(container.querySelectorAll(sel.getAttribute('data-sort-item')));
        if (!items.length) return;
        items.sort(compare(key, useRank));
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
