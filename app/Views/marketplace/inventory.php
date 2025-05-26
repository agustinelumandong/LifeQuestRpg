<div id="pagination-content">
  <a href="/" class="back-button">
    <i class="bi bi-arrow-left"></i>
    Back to Dashboard
  </a>

  <div class="container py-4">
    <div class="card border-dark mb-4">
      <div class="card-header bg-white">
        <div class="d-flex justify-content-between align-items-center">
          <h2 class="my-2" style="font-family: 'Pixelify Sans', serif;">
            <i class="bi bi-bag-fill"></i> <?= $title ?? 'My Inventory' ?>
          </h2>
          <div class="d-flex align-items-center gap-2">
            <?php if (isset($totalItemCount) && $totalItemCount > 0): ?>
              <span class="badge bg-dark">
                <i class="bi bi-collection-fill"></i> <?= number_format($totalItemCount) ?> Items
              </span>
            <?php endif; ?>
          </div>
        </div>
      </div>
      <div class="card-body">

        <?php if (empty($items)): ?>
          <div class="alert alert-info">
            <p>Your inventory is empty. Visit the <a href="/marketplace" class="btn btn-sm btn-primary">marketplace</a> to
              purchase items.</p>
          </div>
        <?php else: ?>

          <div class="row row-cols-1 row-cols-md-2 row-cols-lg-4 g-4">
            <?php foreach ($items as $item): ?>
              <div class="col">
                <div class="marketplace-item border border-dark rounded shadow h-100"
                  data-item-type="<?= $item['item_type'] ?? '' ?>" data-inventory-id="<?= $item['inventory_id'] ?? '' ?>">
                  <div class="card-body d-flex flex-column p-3">                    <!-- Item Header with Category Badge and Quantity -->
                    <div class="d-flex justify-content-between align-items-start mb-2">
                      <h5 class="card-title mb-0">
                        <i class="bi bi-box-seam"></i> <?= $item['item_name'] ?>
                      </h5>
                      <div class="d-flex flex-column align-items-end gap-1">
                        <?php if (!empty($item['category_name'])): ?>
                          <span class="badge bg-dark rounded-pill">
                            <?= $item['category_name'] ?>
                          </span>
                        <?php endif; ?>
                        
                        <!-- Enhanced Quantity Badge -->
                        <?php if (isset($item['quantity'])): ?>
                          <?php if ($item['quantity'] > 1): ?>
                            <span class="badge bg-primary fs-6">
                              <i class="bi bi-stack"></i> Qty: <?= number_format($item['quantity']) ?>
                            </span>
                          <?php else: ?>
                            <span class="badge bg-success">
                              <i class="bi bi-check-circle"></i> x1
                            </span>
                          <?php endif; ?>
                        <?php endif; ?>
                      </div>
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
                    <p class="card-text flex-grow-1"><?= $item['item_description'] ?? 'No description available' ?></p>                    <!-- Item type and effects -->
                    <?php if (!empty($item['item_type'])): ?>
                      <div class="small mb-2">
                        <span class="badge bg-secondary">
                          <?= ucfirst($item['item_type']) ?>
                        </span>

                        <?php if (!empty($item['effect_type']) && !empty($item['effect_value'])): ?>
                          <div class="mt-1 p-1 bg-light rounded">
                            <strong><?= ucwords(str_replace('_', ' ', $item['effect_type'])) ?>:</strong>
                            <?= $item['effect_value'] ?>
                          </div>
                        <?php endif; ?>
                      </div>
                    <?php endif; ?>                    <!-- Enhanced Item Details with Quantity Info -->
                    <div class="small text-muted mb-2 bg-light p-2 rounded">
                      <div class="row">
                        <div class="col-6">
                          <?php if (isset($item['quantity'])): ?>
                            <div><strong><i class="bi bi-hash"></i> Quantity:</strong> <?= number_format($item['quantity']) ?></div>
                          <?php endif; ?>
                          <?php if (isset($item['item_price']) && $item['item_price'] > 0): ?>
                            <div><strong><i class="bi bi-coin"></i> Unit Value:</strong> <?= number_format($item['item_price']) ?></div>
                          <?php endif; ?>
                        </div>
                        <div class="col-6">
                          <?php if (isset($item['quantity']) && isset($item['item_price']) && $item['quantity'] > 1): ?>
                            <div><strong><i class="bi bi-calculator"></i> Total Value:</strong> <?= number_format($item['item_price'] * $item['quantity']) ?></div>
                          <?php endif; ?>
                          <?php if (isset($item['acquired_at'])): ?>
                            <div><strong><i class="bi bi-calendar"></i> Acquired:</strong><br><small><?= date('M j, Y', strtotime($item['acquired_at'])) ?></small></div>
                          <?php endif; ?>
                        </div>
                      </div>
                    </div>                    <!-- Enhanced Use Item Button with Quantity Info -->
                    <?php if (in_array($item['item_type'] ?? '', ['consumable', 'boost'])): ?>
                      <button class="use-item-btn btn btn-sm btn-success w-100"
                        data-inventory-id="<?= $item['inventory_id'] ?>"
                        <?= (isset($item['quantity']) && $item['quantity'] <= 0) ? 'disabled' : '' ?>>
                        <i class="bi bi-lightning"></i> Use Item
                        <?php if (isset($item['quantity'])): ?>
                          <span class="badge bg-white text-success ms-1"><?= $item['quantity'] ?> left</span>
                        <?php endif; ?>
                      </button>
                    <?php elseif (($item['item_type'] ?? '') === 'equipment'): ?>
                      <button class="use-item-btn btn btn-sm btn-primary w-100"
                        data-inventory-id="<?= $item['inventory_id'] ?>">
                        <i class="bi bi-shield"></i> Equip
                        <?php if (isset($item['quantity']) && $item['quantity'] > 1): ?>
                          <span class="badge bg-white text-primary ms-1"><?= $item['quantity'] ?> owned</span>
                        <?php endif; ?>
                      </button>
                    <?php else: ?>
                      <div class="text-muted small fst-italic text-center p-2 bg-light rounded">
                        <i class="bi bi-gem"></i> Collectible item
                        <?php if (isset($item['quantity']) && $item['quantity'] > 1): ?>
                          <br><span class="badge bg-secondary mt-1"><?= $item['quantity'] ?> collected</span>
                        <?php endif; ?>
                      </div>
                    <?php endif; ?>
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

          <!-- Item Usage History -->
          <?php if (!empty($usageHistory)): ?>
            <div class="mt-5">
              <h3 class="mb-3">Recent Item Usage</h3>
              <div class="table-responsive">
                <table class="table table-hover table-bordered">
                  <thead class="table-light">
                    <tr>
                      <th>Item</th>
                      <th>Effect</th>
                      <th>Used At</th>
                    </tr>
                  </thead>
                  <tbody>
                    <?php foreach ($usageHistory as $usage): ?>
                      <tr>
                        <td>
                          <div class="d-flex align-items-center">
                            <?php if (!empty($usage['image_url'])): ?>
                              <img src="<?= $usage['image_url'] ?>" class="me-2 rounded"
                                style="width: 32px; height: 32px; object-fit: cover;"
                                alt="<?= htmlspecialchars($usage['item_name'] ?? 'Item') ?>">
                            <?php endif; ?>
                            <span><?= htmlspecialchars($usage['item_name'] ?? 'Unknown Item') ?></span>
                          </div>
                        </td>
                        <td><?= htmlspecialchars($usage['effect_applied'] ?? '-') ?></td>
                        <td class="text-muted">
                          <?= date('M j, Y g:i A', strtotime($usage['used_at'])) ?>
                        </td>
                      </tr>
                    <?php endforeach; ?>
                  </tbody>
                </table>
              </div>
            </div>
          <?php endif; ?>

        <?php endif; ?>

        <div class="mt-4">
          <a href="/marketplace" class="btn btn-primary">
            Back to Marketplace
          </a>
        </div>
      </div>
    </div>
  </div>
</div>

<div class="toast-container position-fixed bottom-0 end-0 p-3" id="toastContainer">
</div>

<!-- Item Use Modal -->
<div class="modal fade" id="useItemModal" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="modalTitle">Use Item</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body" id="modalBody">
        <p>Are you sure you want to use this item? This action cannot be undone.</p>
        <div id="itemDetails" class="mt-3 p-3 bg-light rounded"></div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
        <button type="button" id="confirmUseItem" class="btn btn-success">Use Item</button>
      </div>
    </div>
  </div>
</div>

<script>
  document.addEventListener('DOMContentLoaded', function () {
    // Item usage functionality
    const useItemBtns = document.querySelectorAll('.use-item-btn');
    const useItemModalEl = document.getElementById('useItemModal');
    const useItemModal = new bootstrap.Modal(useItemModalEl);
    const modalTitle = document.getElementById('modalTitle');
    const itemDetails = document.getElementById('itemDetails');
    const confirmUseBtn = document.getElementById('confirmUseItem');

    let selectedInventoryId = null;
    let selectedItemType = null;

    useItemBtns.forEach(btn => {
      btn.addEventListener('click', function () {
        selectedInventoryId = this.dataset.inventoryId;
        const itemCard = this.closest('[data-item-type]');
        selectedItemType = itemCard.dataset.itemType;

        // Set appropriate modal title based on item type
        if (selectedItemType === 'equipment') {
          modalTitle.textContent = 'Equip Item';
          confirmUseBtn.textContent = 'Equip';
          confirmUseBtn.classList.remove('btn-success');
          confirmUseBtn.classList.add('btn-primary');
        } else {
          modalTitle.textContent = 'Use Item';
          confirmUseBtn.textContent = 'Use Item';
          confirmUseBtn.classList.remove('btn-primary');
          confirmUseBtn.classList.add('btn-success');
        }

        // Show item details in modal
        const itemName = itemCard.querySelector('h5').textContent.trim();
        itemDetails.textContent = itemName;

        // Clear any previous messages from modal body
        const modalBody = document.getElementById('modalBody');
        const existingAlerts = modalBody.querySelectorAll('.alert');
        existingAlerts.forEach(alert => alert.remove());

        // Show modal
        useItemModal.show();
      });
    });

    // Handle item use confirmation
    confirmUseBtn.addEventListener('click', function () {
      if (!selectedInventoryId) return;

      // Show loading state
      this.disabled = true;
      const originalText = this.textContent;
      this.innerHTML = '<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span> Processing...';

      // Get item name for toast
      const itemCard = document.querySelector(`[data-inventory-id="${selectedInventoryId}"]`);
      const itemName = itemCard ? itemCard.querySelector('h5').textContent.trim().replace('📦 ', '') : '';

      // Use item via AJAX
      fetch(`/marketplace/use-item/${selectedInventoryId}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        },
        body: JSON.stringify({})
      })
        .then(response => {
          if (!response.ok) {
            throw new Error('Network response was not ok: ' + response.status);
          }
          return response.json();
        })
        .then(data => {
          if (data.success) {
            // Show success toast instead of modal message
            const toastMessage = data.message + (data.effect ? `: ${data.effect}` : '');
            showTaskToast(toastMessage, 'success', itemName);

            // Close modal immediately
            useItemModal.hide();

            // If item was consumed, update the UI
            if (data.itemType === 'consumable') {
              setTimeout(() => {
                const itemEl = document.querySelector(`[data-inventory-id="${selectedInventoryId}"]`);
                if (itemEl) {
                  itemEl.style.opacity = '0.5';
                  const useBtn = itemEl.querySelector('.use-item-btn');
                  if (useBtn) {
                    useBtn.disabled = true;
                    useBtn.textContent = 'Used';
                  }
                }
              }, 500);
            }

            // Reload the page after a short delay
            setTimeout(() => {
              window.location.reload();
            }, 2000);
          } else {
            // Show error toast instead of modal message
            showTaskToast(data.message || 'An error occurred', 'danger', itemName);
            
            // Close modal
            useItemModal.hide();
          }

          // Reset button state
          confirmUseBtn.disabled = false;
          confirmUseBtn.innerHTML = originalText;
        })
        .catch(error => {
          console.error('Error:', error);

          // Show error toast instead of modal message
          showTaskToast('An error occurred. Please try again.', 'danger', itemName);
          
          // Close modal
          useItemModal.hide();

          // Reset button
          confirmUseBtn.disabled = false;
          confirmUseBtn.innerHTML = originalText;
        });
    });
  });
</script>