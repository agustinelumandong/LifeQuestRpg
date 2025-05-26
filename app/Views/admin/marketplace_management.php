<?php require_once VIEWS_PATH . 'layouts/header.php'; ?>
<div class="admin-dashboard">
  <div class="container-fluid">
    <h1 class="display-5 fw-bold mb-4 fade-in" style="font-family: 'Pixelify Sans', serif;">Marketplace Management</h1>


    <!-- Marketplace Dashboard -->
    <div class="row g-4 mb-4 fade-in">
      <!-- Total Items Card -->
      <div class="col-md-3">
        <div class="stat-card primary">
          <p>Total Items</p>
          <h3><?= count($items) ?></h3>
          <div class="mt-2">
            <small>Available in marketplace</small>
          </div>
          <div class="icon">
            <i class="bi bi-bag"></i>
          </div>
        </div>
      </div>

      <!-- Total Value Card -->
      <div class="col-md-3">
        <div class="stat-card success">
          <p>Total Gold Value</p>
          <?php
          $totalValue = 0;
          foreach ($items as $item) {
            $totalValue += $item['item_price'];
          }
          ?>
          <h3><?= $totalValue ?> G</h3>
          <div class="mt-2">
            <small>Combined item worth</small>
          </div>
          <div class="icon">
            <i class="bi bi-coin"></i>
          </div>
        </div>
      </div>

      <!-- Most Expensive Card -->
      <div class="col-md-3">
        <div class="stat-card warning">
          <p>Most Valuable</p>
          <?php
          $mostExpensive = 0;
          $expensiveItem = '';
          foreach ($items as $item) {
            if ($item['item_price'] > $mostExpensive) {
              $mostExpensive = $item['item_price'];
              $expensiveItem = $item['item_name'];
            }
          }
          ?>
          <h3><?= $mostExpensive ?> G</h3>
          <div class="mt-2">
            <small><?= htmlspecialchars(substr($expensiveItem, 0, 20)) ?><?= (strlen($expensiveItem) > 20) ? '...' : '' ?></small>
          </div>
          <div class="icon">
            <i class="bi bi-trophy"></i>
          </div>
        </div>
      </div>

      <!-- Categories Card -->
      <div class="col-md-3">
        <div class="stat-card danger">
          <p>Categories</p>
          <?php
          $categories = [];
          foreach ($items as $item) {
            if (isset($item->category) && !empty($item)) {
              if (isset($categories[$item->category])) {
                $categories[$item->category]++;
              } else {
                $categories[$item->category] = 1;
              }
            }
          }
          ?>
          <h3><?= count($categories) ?></h3>
          <div class="mt-2">
            <small>Item categories</small>
          </div>
          <div class="icon">
            <i class="bi bi-tags"></i>
          </div>
        </div>
      </div>
    </div>

    <!-- Item Management Section -->
    <div class="admin-card mb-4 fade-in">
      <div class="d-flex justify-content-between align-items-center mb-4">
        <div>
          <h2 class="h3" style="font-family: 'Pixelify Sans', serif;">Marketplace Items</h2>
          <p class="text-muted">Manage all available items and rewards in the marketplace</p>
        </div> <a href="/marketplace/create" class="rpg-btn rpg-btn-success">
          <i class="bi bi-plus-circle me-1"></i> Add New Item
        </a>
      </div>

      <!-- Filter & Search Controls -->
      <div class="row mb-4">
        <div class="col-md-5 mb-3">
          <label class="rpg-form-label">Search Items</label>
          <div class="input-group">
            <span class="input-group-text">
              <i class="bi bi-search"></i>
            </span>
            <input type="text" class="form-control rpg-form-control" placeholder="Search by name or description...">
          </div>
        </div>
        <div class="col-md-3 mb-3">
          <label class="rpg-form-label">Filter by Category</label>
          <select class="form-select rpg-form-select">
            <option value="">All Categories</option>
            <?php foreach ($categories as $category => $count): ?>
              <option value="<?= htmlspecialchars($category) ?>"><?= htmlspecialchars($category) ?> (<?= $count ?>)
              </option>
            <?php endforeach; ?>
          </select>
        </div>
        <div class="col-md-4 mb-3">
          <label class="rpg-form-label">Price Range</label>
          <select class="form-select rpg-form-select">
            <option value="">All Prices</option>
            <option value="0-50">0-50 Gold</option>
            <option value="51-100">51-100 Gold</option>
            <option value="101-500">101-500 Gold</option>
            <option value="501+">501+ Gold</option>
          </select>
        </div>
      </div>

      <div class="table-responsive">
        <table class="table rpg-table">
          <thead>
            <tr>
              <th>Name</th>
              <th>Description</th>
              <th>Price</th>
              <th>Category</th>
              <th>Available</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <?php if (count($items) > 0): ?>
              <?php foreach ($items as $item): ?>
                <tr>
                  <td>
                    <div class="d-flex align-items-center">
                      <?php if (isset($item['image_url']) && !empty($item['image_url'])): ?>
                        <div class="me-2">
                          <img class="img-avatar" width="40" height="40" src="<?= htmlspecialchars($item['image_url']) ?>"
                            alt="<?= htmlspecialchars($item['item_name']) ?>">
                        </div>
                      <?php endif; ?>
                      <div class="fw-medium"><?= htmlspecialchars($item['item_name']) ?></div>
                    </div>
                  </td>
                  <td>
                    <div class="text-wrap" style="max-width: 250px;">
                      <?= htmlspecialchars(substr($item['item_description'], 0, 100)) ?>
                      <?= (strlen($item['item_description']) > 100) ? '...' : '' ?>
                    </div>
                  </td>
                  <td>
                    <div class="fw-medium">
                      <?= $item['item_price'] ?> <span class="text-warning">G</span>
                    </div>
                  </td>
                  <td>
                    <?php if (isset($item['category']) && !empty($item['category'])): ?>
                      <span class="rpg-badge rpg-badge-primary">
                        <?= htmlspecialchars($item['category']) ?>
                      </span>
                    <?php else: ?>
                      <span class="rpg-badge rpg-badge-secondary">Uncategorized</span>
                    <?php endif; ?>

                    <!-- Add purchase type indicator -->
                    <?php
                    $itemType = $item['item_type'] ?? '';
                    $isOneTime = in_array($itemType, ['collectible', 'equipment']);
                    ?>
                    <div class="mt-1">
                      <small class="badge <?= $isOneTime ? 'bg-warning text-dark' : 'bg-info' ?>">
                        <?= $isOneTime ? 'One-time Purchase' : 'Multi-purchase' ?>
                      </small>
                    </div>
                  </td>
                  <td>
                    <?php $isAvailable = !isset($item['is_disabled']) || !$item['is_disabled']; ?>
                    <span class="rpg-badge <?= $isAvailable ? 'rpg-badge-success' : 'rpg-badge-danger' ?>">
                      <?= $isAvailable ? 'Yes' : 'No' ?>
                    </span>
                  </td>
                  <td>
                    <div class="action-cell">
                      <a href="/marketplace/edit/<?= $item['item_id'] ?>" class="btn btn-sm rpg-btn-outline" title="Edit">
                        <i class="bi bi-pencil-fill"></i>
                      </a>
                      <form class="d-inline" action="/marketplace/<?= $item['item_id'] ?>" method="POST"
                        onsubmit="return confirm('Are you sure you want to remove this item from the marketplace?');">
                        <input type="hidden" name="_method" value="DELETE">
                        <button type="submit" class="btn btn-sm rpg-btn-outline text-danger" title="Delete">
                          <i class="bi bi-trash-fill"></i>
                        </button>
                      </form>
                    </div>
                  </td>
                </tr>
              <?php endforeach; ?>
            <?php else: ?>
              <tr>
                <td colspan="6" class="text-center">
                  <div class="alert alert-dark" role="alert">
                    <i class="bi bi-emoji-dizzy me-2"></i>
                    No marketplace items found
                  </div>
                </td>
              </tr>
            <?php endif; ?>
          </tbody>
        </table>
      </div>
    </div> <!-- Category Management Section -->
    <div class="admin-card mb-4 fade-in">
      <div class="d-flex justify-content-between align-items-center mb-3">
        <div>
          <h2 class="h3" style="font-family: 'Pixelify Sans', serif;">Category Management</h2>
          <p class="text-muted">Organize items into categories for better management</p>
        </div> <button class="rpg-btn rpg-btn-success add-category-trigger" data-bs-toggle="modal"
          data-bs-target="#addCategoryModal">
          <i class="bi bi-plus-circle me-1"></i> Add Category
        </button>
      </div>

      <div class="row g-4">
        <?php foreach ($categories as $category => $count): ?>
          <div class="col-md-4">
            <div class="card shadow border-dark h-100">
              <div class="card-body d-flex justify-content-between align-items-center">
                <div>
                  <h3 class="card-title h5"><?= htmlspecialchars($category) ?></h3>
                  <p class="card-text text-muted"><?= $count ?> items</p>
                </div>
                <div class="d-flex gap-2">
                  <button class="btn btn-sm rpg-btn-outline" title="Edit Category">
                    <i class="bi bi-pencil-fill"></i>
                  </button>
                  <button class="btn btn-sm rpg-btn-outline text-danger" title="Delete Category">
                    <i class="bi bi-trash-fill"></i>
                  </button>
                </div>
              </div>
            </div>
          </div>
        <?php endforeach; ?> <!-- Add new category card -->
        <div class="col-md-4">
          <div class="card shadow border-dark border-dashed h-100 cursor-pointer add-category-trigger"
            style="border-style: dashed; cursor: pointer;" data-bs-toggle="modal" data-bs-target="#addCategoryModal">
            <div class="card-body d-flex flex-column justify-content-center align-items-center text-center"
              style="min-height: 120px;">
              <i class="bi bi-plus-circle mb-2" style="font-size: 2rem;"></i>
              <span class="fw-medium text-primary">Add New Category</span>
            </div>
          </div>
        </div>
      </div>
    </div><!-- Bulk Operations Section -->
    <div class="admin-card mb-4 fade-in">
      <div class="d-flex justify-content-between align-items-center mb-3">
        <div>
          <h2 class="h3" style="font-family: 'Pixelify Sans', serif;">Bulk Operations</h2>
          <p class="text-muted">Perform operations on multiple items at once</p>
        </div>
      </div>

      <div class="row">
        <div class="col-md-6 mb-4">
          <div class="card border-dark shadow h-100">
            <div class="card-header bg-dark text-white">
              <h3 class="h5 mb-0">Price Adjustment</h3>
            </div>
            <div class="card-body">
              <p class="card-text text-muted mb-4">Apply percentage-based price adjustment to items in a category</p>

              <form>
                <div class="mb-3">
                  <label class="rpg-form-label">Category</label>
                  <select class="form-select rpg-form-select">
                    <option value="">Select Category</option>
                    <?php foreach ($categories as $category => $count): ?>
                      <option value="<?= htmlspecialchars($category) ?>"><?= htmlspecialchars($category) ?></option>
                    <?php endforeach; ?>
                  </select>
                </div>

                <div class="mb-3">
                  <label class="rpg-form-label">Adjustment Type</label>
                  <div class="d-flex gap-4">
                    <div class="form-check">
                      <input class="form-check-input" type="radio" name="adjustment_type" id="increase"
                        value="increase">
                      <label class="form-check-label" for="increase">
                        Increase
                      </label>
                    </div>
                    <div class="form-check">
                      <input class="form-check-input" type="radio" name="adjustment_type" id="decrease"
                        value="decrease">
                      <label class="form-check-label" for="decrease">
                        Decrease
                      </label>
                    </div>
                  </div>
                </div>

                <div class="mb-3">
                  <label class="rpg-form-label">Percentage</label>
                  <div class="input-group">
                    <input type="number" min="1" max="100" class="form-control rpg-form-control">
                    <span class="input-group-text">%</span>
                  </div>
                </div>

                <div class="text-end">
                  <button type="button" class="rpg-btn rpg-btn-primary">
                    <i class="bi bi-check-circle me-1"></i> Apply Price Changes
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>

        <div class="col-md-6 mb-4">
          <div class="card border-dark shadow h-100">
            <div class="card-header bg-dark text-white">
              <h3 class="h5 mb-0">Bulk Availability</h3>
            </div>
            <div class="card-body">
              <p class="card-text text-muted mb-4">Change availability status for multiple items at once</p>

              <form>
                <div class="mb-3">
                  <label class="rpg-form-label">Category</label>
                  <select class="form-select rpg-form-select">
                    <option value="">Select Category</option>
                    <?php foreach ($categories as $category => $count): ?>
                      <option value="<?= htmlspecialchars($category) ?>"><?= htmlspecialchars($category) ?></option>
                    <?php endforeach; ?>
                  </select>
                </div>

                <div class="mb-3">
                  <label class="rpg-form-label">Set Status</label>
                  <div class="d-flex gap-4">
                    <div class="form-check">
                      <input class="form-check-input" type="radio" name="availability_status" id="available"
                        value="available">
                      <label class="form-check-label" for="available">
                        Available
                      </label>
                    </div>
                    <div class="form-check">
                      <input class="form-check-input" type="radio" name="availability_status" id="unavailable"
                        value="unavailable">
                      <label class="form-check-label" for="unavailable">
                        Unavailable
                      </label>
                    </div>
                  </div>
                </div>

                <div class="text-end mt-5">
                  <button type="button" class="rpg-btn rpg-btn-primary">
                    <i class="bi bi-check-circle me-1"></i> Update Availability
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      </div>
    </div> <!-- Modal for adding category -->
    <div id="addCategoryModal" class="modal fade" tabindex="-1" aria-hidden="true">
      <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content border border-dark shadow">
          <div class="modal-header bg-dark text-white">
            <h5 class="modal-title" style="font-family: 'Pixelify Sans', serif;">Add New Category</h5>
            <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
          </div>
          <div class="modal-body">
            <form id="addCategoryForm">
              <div class="mb-3">
                <label for="category-name" class="rpg-form-label">Category Name</label>
                <input type="text" id="category-name" name="name" class="form-control rpg-form-control" required>
              </div>
              <div class="mb-3">
                <label for="category-desc" class="rpg-form-label">Description (Optional)</label>
                <textarea id="category-desc" name="description" rows="3"
                  class="form-control rpg-form-control"></textarea>
              </div>
              <div class="mb-3">
                <label for="category-color" class="rpg-form-label">Category Color</label>
                <select id="category-color" name="color" class="form-select rpg-form-select">
                  <option value="blue">Blue</option>
                  <option value="green">Green</option>
                  <option value="red">Red</option>
                  <option value="purple">Purple</option>
                  <option value="yellow">Yellow</option>
                  <option value="gray">Gray</option>
                </select>
              </div>
            </form>
          </div>
          <div class="modal-footer">
            <button type="button" class="rpg-btn rpg-btn-outline" data-bs-dismiss="modal">Cancel</button>
            <button type="button" class="rpg-btn rpg-btn-primary" id="addCategoryBtn">Add Category</button>
          </div>
        </div>
      </div>
    </div>
  </div>

  <script>
    document.addEventListener('DOMContentLoaded', function () {
      // Initialize modal functionality
      const addCategoryButtons = document.querySelectorAll('[data-bs-toggle="modal"][data-bs-target="#addCategoryModal"]');
      const addCategoryModal = new bootstrap.Modal(document.getElementById('addCategoryModal'));

      // For buttons that don't use data attributes
      document.querySelectorAll('.category-add-btn').forEach(btn => {
        btn.addEventListener('click', function () {
          addCategoryModal.show();
        });
      });

      // Button click to show modal (for non-Bootstrap buttons)
      document.querySelectorAll('.add-category-trigger').forEach(el => {
        el.addEventListener('click', function () {
          addCategoryModal.show();
        });
      });
    });
  </script>

  <?php require_once VIEWS_PATH . 'layouts/footer.php'; ?>