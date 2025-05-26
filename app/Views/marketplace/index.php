<div id="pagination-content">
  <a href="/" class="back-button">
    <i class="bi bi-arrow-left"></i>
    Back to Dashboard
  </a>

  <div class="container py-4">
    <div class="card border-dark mb-4 shadow">
      <div class="card-header bg-white">
        <div class="d-flex justify-content-between align-items-center">
          <h2 class="my-2"><i class="bi bi-shop"></i>
            <?= $title ?></h2>
          <div class="d-flex align-items-center">
            <span class="badge bg-warning text-dark fs-6 me-2">
              <i class="bi bi-coin"></i> <?= number_format($userCoins ?? 0) ?> Coins
            </span>
            <a href="/marketplace/inventory" class="btn btn-outline-dark btn-sm">
              <i class="bi bi-bag"></i> My Inventory
            </a>
          </div>
        </div>
      </div>
      <div class="card-body">
        <div class="mb-3 bg-light p-3 rounded border border-dark">
          <div class="row">
            <div class="col-md-6">
              <p class="mb-0"><i class="bi bi-info-circle"></i> Available Items</p>
            </div>
            <div class="col-md-6">
              <form id="categoryFilterForm" method="get" class="d-flex justify-content-end" action="/marketplace">
                <div class="input-group">
                  <label class="input-group-text" for="categoryFilter">Category</label>
                  <select class="form-select" id="categoryFilter" name="category" onchange="this.form.submit()">
                    <option value="all" <?= $selectedCategory == 'all' ? 'selected' : '' ?>>All Categories</option>
                    <?php foreach ($categories as $category): ?>
                      <option value="<?= $category['category_id'] ?>" <?= $selectedCategory == $category['category_id'] ? 'selected' : '' ?>>
                        <?= $category['category_name'] ?>
                      </option>
                    <?php endforeach; ?>
                  </select>
                </div>
                <!-- Hidden field to preserve page parameter when filtering -->
                <?php if (isset($_GET['page']) && $_GET['page'] > 1): ?>
                  <input type="hidden" name="page" value="<?= htmlspecialchars($_GET['page']) ?>">
                <?php endif; ?>
              </form>
            </div>
          </div>
        </div><?php if (empty($items)): ?>
          <div class="alert alert-dark text-center" role="alert">
            <i class="bi bi-emoji-dizzy display-4 d-block mb-3"></i>
            <p class="mb-0">No items found in the marketplace. Check back later!</p>
          </div>
        <?php else: ?>
          <!-- Items Display Grid -->
          <div class="row row-cols-1 row-cols-md-2 row-cols-lg-4 g-4">
            <?php foreach ($items as $item): ?>
              <div class="col">
                <div class="marketplace-item border border-dark rounded shadow h-100"
                  data-item-id="<?= $item['item_id'] ?? '' ?>">
                  <div class="card-body d-flex flex-column p-3">
                    <!-- Item Header with Category Badge -->
                    <div class="d-flex justify-content-between align-items-start mb-2">
                      <h5 class="card-title mb-0">
                        <i class="bi bi-box-seam"></i> <?= $item['item_name'] ?>
                      </h5>
                      <?php if (!empty($item['category_name'])): ?>
                        <span class="badge bg-dark rounded-pill">
                          <?= $item['category_name'] ?>
                        </span>
                      <?php endif; ?>
                    </div>

                    <hr class="my-2">

                    <!-- Item image if available -->
                    <?php if (!empty($item['image_url'])): ?>
                      <div class="text-center mb-2">
                        <img src="<?= $item['image_url'] ?>" alt="<?= $item['item_name'] ?>" class="img-fluid item-image"
                          style="max-height: 80px;">
                      </div>
                    <?php endif; ?>

                    <!-- Item description -->
                    <p class="card-text flex-grow-1"><?= $item['item_description'] ?? 'No description available' ?></p>
                    <!-- Item type and effects -->
                    <?php if (!empty($item['item_type'])): ?>
                      <div class="small mb-2">
                        <span class="badge bg-secondary">
                          <?= ucfirst($item['item_type']) ?>
                        </span>

                        <!-- Add purchase type indicator -->
                        <?php
                        $itemType = $item['item_type'] ?? '';
                        $isOneTime = in_array($itemType, ['collectible', 'equipment']);
                        ?>
                        <span class="badge <?= $isOneTime ? 'bg-warning text-dark' : 'bg-info' ?> ms-1">
                          <?= $isOneTime ? 'One-time' : 'Multi-buy' ?>
                        </span>

                        <?php if (!empty($item['effect_type']) && !empty($item['effect_value'])): ?>
                          <div class="mt-1 p-1 bg-light rounded">
                            <strong><?= ucwords(str_replace('_', ' ', $item['effect_type'])) ?>:</strong>
                            <?= $item['effect_value'] ?>
                          </div>
                        <?php endif; ?>
                      </div>
                    <?php endif; ?><!-- Price and Purchase Button -->
                    <div class="mt-auto">
                      <div class="d-flex justify-content-between align-items-center mb-2">
                        <span class="badge bg-warning text-dark fs-6">
                          <i class="bi bi-coin"></i> <?= number_format($item['item_price'] ?? 0) ?>
                        </span>
                        <?php
                        $isOwned = in_array($item['item_id'], $ownedItemIds ?? []);
                        $itemType = $item['item_type'] ?? '';
                        $isOneTimePurchase = in_array($itemType, ['collectible', 'equipment']);
                        ?>

                        <?php if ($isOwned && $isOneTimePurchase): ?>
                          <span class="badge bg-success">Owned</span>
                        <?php elseif ($isOwned && !$isOneTimePurchase): ?>
                          <span class="badge bg-info">Owned (Can buy more)</span>
                        <?php endif; ?>
                      </div>

                      <?php if (!$isOwned || !$isOneTimePurchase): ?>
                        <?php if (!$isOneTimePurchase): ?>
                          <!-- Show quantity selector for multi-purchase items -->
                          <form action="/marketplace/purchase/<?= App\Core\Auth::getByUserId() ?>/<?= $item['item_id'] ?>"
                            method="POST" class="d-flex gap-1">
                            <input type="number" name="quantity" value="1" min="1" max="10" class="form-control form-control-sm"
                              style="width: 60px;" title="Quantity">
                            <button type="submit" class="btn btn-sm btn-primary flex-grow-1">
                              <i class="bi bi-cart-plus"></i> Buy
                            </button>
                          </form>
                        <?php else: ?>
                          <!-- Simple purchase button for one-time items -->
                          <a href="/marketplace/purchase/<?= App\Core\Auth::getByUserId() ?>/<?= $item['item_id'] ?>"
                            class="btn btn-sm btn-primary w-100">
                            <i class="bi bi-cart-plus"></i> Purchase
                          </a>
                        <?php endif; ?>
                      <?php else: ?>
                        <button class="btn btn-sm btn-secondary w-100" disabled>
                          <i class="bi bi-check-circle"></i> Already Owned
                        </button>
                      <?php endif; ?>
                    </div>
                  </div>
                </div>
              </div>
            <?php endforeach; ?>
          </div>

          <!-- Pagination -->
          <?php if (isset($paginator) && method_exists($paginator, 'links')): ?>
            <div class="mt-4">
              <?= $paginator->links() ?>
            </div>
          <?php endif; ?>
        <?php endif; ?>

      </div>
    </div>
  </div>

</div>

<script>
  document.addEventListener('DOMContentLoaded', functi  on() {
    const contentContainer = document.getElementById('pagination-content');

    // Handle pagination clicks
    contentContainer.add  EventListener('click', function(e) {
      const link = e.target.closest('a');
      if (link &  & link.getAttribute('href').includes('page=  ')) {
        e.preventDefault();
        const url = link.getAttr  ibute('href');

        // Sh  ow loading state
        contentContainer.style.o  pacity = '0.5';

        // Fet  ch the new page content
        fetch(url)
          .then(response => response.text())
          .then(html => {
            // Create a temporary element   to parse the HTML
            const tempDiv = document.createElement('div');
            tempDiv.innerHTML = html;

            // Extract just the   pagination content
            const ne  wContent = tempDiv.querySelector('#pagination-conten  t');

            if (newContent) {
              // Replace only the content i  nside the container
              contentContainer.innerHTML = newContent.innerHTML;
            } else {
              console.error('Could not find pagination   content in response');
            }

            contentContainer.style.opacity = '1';

            // Update browse  r history
            window.history.pushState({}, '  ', url);
          })
          .catch(error => {
            console.error('Error:', error);
            contentContainer.style.opaci  ty = '1';
          });
      }
    });

  // Handle browser back/forward buttons
  window.a  ddEventListener('popstat  e', functi  on() {
    fetch(window.location.href)
    .then(response => response.text())
    .then(html => {
      const tempDiv = document.createElement('div');
          te  mpDiv.innerHTML = html;

      const newContent = tempDiv.querySelector('#pagin  ation-content');
      if (newCont  ent) {
    contentContainer.innerHTML = newContent.innerHTML;
  }
        });
    });
  });
</script>