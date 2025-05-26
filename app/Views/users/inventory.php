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
          <div class="row row-cols-1 row-cols-md-2 row-cols-lg-4 g-4"> <?php foreach ($paginator->items() as $item): ?>
              <div class="col">
                <div class="inventory-item border border-dark rounded shadow h-100">
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
                      <div class="text-center mb-3">
                        <img src="<?= $item['image_url'] ?>" alt="<?= $item['item_name'] ?>" class="img-fluid item-image"
                          style="max-height: 80px;">
                      </div>
                    <?php endif; ?>

                    <!-- Item description -->
                    <p class="card-text flex-grow-1"><?= $item['item_description'] ?? 'No description available' ?></p>

                    <!-- Item type and effects -->
                    <?php if (!empty($item['item_type'])): ?>
                      <div class="item-attributes small mb-2">
                        <span class="item-type-badge item-type-<?= $item['item_type'] ?>">
                          <?= ucfirst($item['item_type']) ?>
                        </span>

                        <?php if (!empty($item['effect_type']) && !empty($item['effect_value'])): ?>
                          <div class="effect-display mt-1">
                            <strong><?= ucwords(str_replace('_', ' ', $item['effect_type'])) ?>:</strong>
                            <?= $item['effect_value'] ?>
                          </div>
                        <?php endif; ?>
                      </div>
                    <?php endif; ?>

                    <!-- Use item button for appropriate item types -->
                    <?php if (!empty($item['item_type']) && in_array($item['item_type'], ['consumable', 'boost', 'equipment'])): ?>
                      <a href="/marketplace/use-item/<?= $item['inventory_id'] ?>" class="btn btn-sm btn-primary mt-2">
                        <?= $item['item_type'] === 'equipment' ? 'Equip' : 'Use Item' ?>
                      </a>
                    <?php endif; ?>
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

