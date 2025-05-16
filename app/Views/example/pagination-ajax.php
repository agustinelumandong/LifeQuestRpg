<div class="container mt-4">
  <h1>AJAX Pagination Example</h1>

  <!-- Content container for AJAX updates -->
  <div id="pagination-content">
    <!-- Display paginated items -->
    <div class="row">
      <?php foreach ($paginator->items() as $item): ?>
        <div class="col-md-4 mb-4">
          <div class="card">
            <div class="card-body">
              <h5 class="card-title"><?= htmlspecialchars($item['title'] ?? 'Item') ?></h5>
              <p class="card-text"><?= htmlspecialchars($item['description'] ?? 'Description') ?></p>
            </div>
          </div>
        </div>
      <?php endforeach; ?>
    </div>

    <!-- Display pagination links -->
    <?= $paginator->links() ?>
  </div>
</div>

<!-- Add JavaScript for AJAX pagination -->
<script>
  document.addEventListener('DOMContentLoaded', function () {
    const contentContainer = document.getElementById('pagination-content');

    // Handle pagination clicks
    contentContainer.addEventListener('click', function (e) {
      const link = e.target.closest('a');
      if (link && link.getAttribute('href').includes('page=')) {
        e.preventDefault();
        const url = link.getAttribute('href');

        // Show loading state
        contentContainer.style.opacity = '0.5';

        // Fetch the new page content
        fetch(url)
          .then(response => response.text())
          .then(html => {
            // Update the content
            contentContainer.innerHTML = html;
            contentContainer.style.opacity = '1';

            // Update browser history
            window.history.pushState({}, '', url);
          })
          .catch(error => {
            console.error('Error:', error);
            contentContainer.style.opacity = '1';
          });
      }
    });

    // Handle browser back/forward buttons
    window.addEventListener('popstate', function () {
      fetch(window.location.href)
        .then(response => response.text())
        .then(html => {
          contentContainer.innerHTML = html;
        });
    });
  });
</script>