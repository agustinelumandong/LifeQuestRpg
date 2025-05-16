<div id="pagination-content">
  <a href="/" class="back-button">
    <i class="bi bi-arrow-left"></i>
    Back to Dashboard
  </a>

  <div class="container py-4">
    <div class="card border-dark mb-4 shadow">
      <div class="card-header bg-white">
        <div class="d-flex justify-content-between align-items-center">
          <h2 class="my-2"><i class="bi bi-shop"></i> <?= $title ?></h2>
          <?php if (\App\Core\Auth::isAdmin()): ?>
            <a class="btn btn-dark shadow-sm" href="/marketplace/create">
              <i class="bi bi-plus-circle"></i> Create Product
            </a>
          <?php endif; ?>
        </div>
      </div>

      <div class="card-body">
        <div class="mb-3 bg-light p-3 rounded border border-dark">
          <p class="mb-0"><i class="bi bi-info-circle"></i> Available Items</p>
        </div>

        <?php if (!empty($items)): ?>
          <?php if (\App\Core\Auth::isAdmin()): ?>
            <div class="card border-dark shadow mb-4">
              <div class="card-header bg-white d-flex justify-content-between align-items-center py-2">
                <h3 class="my-2"><i class="bi bi-box-seam"></i> Product Inventory</h3>

                <span class="badge bg-dark"><?= $paginator->getPageInfo()['totalItems'] ?> Items</span>
              </div>
              <div class="card-body p-0">
                <div class="table-responsive">
                  <table class="table table-hover mb-0">
                    <thead class="bg-dark text-white">
                      <tr>
                        <th class="ps-3">ID</th>
                        <th>Product Name</th>
                        <th>Description</th>
                        <th>Price</th>
                        <th class="text-end pe-3">Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      <?php foreach ($paginator->items() as $item): ?>
                        <tr class="product-row">
                          <td class="ps-3"><?= $item['item_id'] ?></td>
                          <td>
                            <div class="d-flex align-items-center">
                              <i class="bi bi-box-seam me-2"></i>
                              <strong><?= $item['item_name'] ?></strong>
                            </div>
                          </td>
                          <td class="text-muted"><?= $item['item_description'] ?></td>
                          <td>
                            <div class="price-badge">
                              <i class="bi bi-coin me-1"></i> <?= $item['item_price'] ?>
                            </div>
                          </td>
                          <td class="text-end pe-3">
                            <div class="btn-group" role="group">
                              <a href="/marketplace/edit/<?= $item['item_id'] ?>" class="btn btn-sm btn-dark">
                                <i class="bi bi-pencil"></i> Edit
                              </a>
                              <a href="/marketplace/delete/<?= $item['item_id'] ?>" class="btn btn-sm btn-outline-dark"
                                onclick="return confirm('Are you sure you want to delete this item?')">
                                <i class="bi bi-trash"></i> Delete
                              </a>
                            </div>
                          </td>
                        </tr>
                      <?php endforeach; ?>
                    </tbody>
                  </table>
                </div>
              </div>

              <!-- Pagination -->
              <div class="card-footer bg-white">
                <?= $paginator->links() ?>
              </div>
            </div>

          <?php else: ?>
            <div class="row row-cols-1 row-cols-md-2 row-cols-lg-4 g-4">
              <?php foreach ($paginator->items() as $item): ?>
                <div class="col">
                  <div class="marketplace-item border border-dark rounded shadow h-100">
                    <div class="card-body d-flex flex-column p-3">
                      <h5 class="card-title border-bottom border-dark pb-2">
                        <i class="bi bi-box-seam"></i> <?= $item['item_name'] ?>
                      </h5>
                      <p class="card-text flex-grow-1"><?= $item['item_description'] ?></p>
                      <div class="d-flex justify-content-between align-items-center mt-3">
                        <div class="price-tag">
                          <span class="fw-bold">
                            <i class="bi bi-coin"></i> <?= $item['item_price'] ?>
                          </span>
                        </div>

                        <?php
                        $currentUserId = App\Core\Auth::getByUserId($currentUser);
                        $isOwned = $currentUserId && in_array($item['item_id'], $ownedItemIds ?? []);
                        ?>

                        <?php if ($currentUserId): ?>
                          <form action="/marketplace/purchase/<?= $currentUserId ?>/<?= $item['item_id'] ?>" method="post">
                            <input type="hidden" name="_method" value="PUT">
                            <?php if ($isOwned): ?>
                              <button type="button" class="btn btn-secondary btn-sm" disabled>
                                <i class="bi bi-check-circle"></i> Owned
                              </button>
                            <?php else: ?>
                              <button type="submit" class="btn btn-dark btn-sm purchase-btn">
                                <i class="bi bi-bag"></i> Buy
                              </button>
                            <?php endif; ?>
                          </form>
                        <?php else: ?>
                          <a href="/login" class="btn btn-dark btn-sm">
                            <i class="bi bi-key"></i> Login to Buy
                          </a>
                        <?php endif; ?>
                      </div>
                    </div>
                  </div>
                </div>
              <?php endforeach; ?>
            </div>
            <?= $paginator->links() ?>
          <?php endif; ?>
        <?php else: ?>
          <div class="alert alert-dark text-center" role="alert">
            <i class="bi bi-emoji-dizzy display-4 d-block mb-3"></i>
            <p class="mb-0">No items found in the marketplace. Check back later!</p>
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