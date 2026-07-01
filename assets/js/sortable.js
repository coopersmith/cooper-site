// Reusable client-side sort for index views (media, concerts, travels).
// A <select class="sort-select"> drives one or more containers:
//   data-sort-scope : CSS selector matching the container(s) to reorder
//   data-sort-item  : selector for the sortable items within each container
// Items expose data-title / data-date / data-rating for the sort keys.
(function () {
  function compare(key) {
    return function (a, b) {
      if (key === 'az') {
        return (a.getAttribute('data-title') || '').localeCompare(b.getAttribute('data-title') || '');
      }
      if (key === 'rating') {
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
  }

  Array.prototype.forEach.call(document.querySelectorAll('.sort-select'), wire);
})();
