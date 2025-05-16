<div id="pagination-content">
  <a href="/" class="back-button">
    <i class="bi bi-arrow-left"></i>
    Back to Dashboard
  </a>

  <div class="container py-4">
    <div class="card border-dark mb-4 shadow">
      <div class="card-header bg-white">
        <h2 class="my-2"><i class="bi bi-bag"></i> <?= $title ?></h2>
      </div>

      <div class="card-body">
        <?php if (!empty($items)): ?>
          <div class="row row-cols-1 row-cols-md-2 row-cols-lg-4 g-4">
            <?php foreach ($paginator->items() as $item): ?>
              <div class="col">
                <div class="inventory-item border border-dark rounded shadow h-100">
                  <div class="card-body d-flex flex-column p-3">
                    <h5 class="card-title border-bottom border-dark pb-2">
                      <i class="bi bi-box-seam"></i> <?= $item['item_name'] ?>
                    </h5>
                    <p class="card-text flex-grow-1"><?= $item['item_description'] ?? 'No description available' ?></p>
                  </div>
                </div>
              </div>
            <?php endforeach; ?>
          </div>
          <?= $paginator->links() ?>
        <?php else: ?>
          <div class="alert alert-dark text-center" role="alert">
            <i class="bi bi-emoji-dizzy display-4 d-block mb-3"></i>
            <p class="mb-0">No items found in your inventory. Visit the marketplace to purchase items!</p>
          </div>
        <?php endif; ?>
      </div>
    </div>
  </div>
</div>

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
            // Create a temporary element to parse the HTML
            const tempDiv = document.createElement('div');
            tempDiv.innerHTML = html;

            // Extract just the pagination content
            const newContent = tempDiv.querySelector('#pagination-content');

            if (newContent) {
              // Replace only the content inside the container
              contentContainer.innerHTML = newContent.innerHTML;
            } else {
              console.error('Could not find pagination content in response');
            }

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
          const tempDiv = document.createElement('div');
          tempDiv.innerHTML = html;

          const newContent = tempDiv.querySelector('#pagination-content');
          if (newContent) {
            contentContainer.innerHTML = newContent.innerHTML;
          }
        });
    });
  });
</script>