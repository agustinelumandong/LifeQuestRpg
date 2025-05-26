<div class="card">
  <div class="card-header">
    <h1><?= $title ?? 'Edit Product' ?></h1>
  </div>
  <div class="card-body">
    <form method="POST" action="/marketplace/<?= $items['item_id'] ?? '' ?>" enctype="multipart/form-data">
      <input type="hidden" name="_method" value="PUT" />
      <div class="mb-3">
        <label for="productName" class="form-label">Product Name</label>
        <input type="text" class="form-control" id="productName" name="productName" value="<?= $items['item_name'] ?>"
          required>
      </div>
      <div class="mb-3">
        <label for="productDescription" class="form-label">Product Description</label>
        <input type="text" class="form-control" id="productDescription" name="productDescription"
          value="<?= $items['item_description'] ?>">
      </div>
      <div class="mb-3">
        <label for="productPrice" class="form-label">Product Price</label>
        <input type="number" class="form-control" id="productPrice" name="productPrice"
          value="<?= $items['item_price'] ?>" required>
      </div>
      <div class="mb-3">
        <label for="productImage" class="form-label">Product Image</label>
        <input type="text" class="form-control" id="productImage" name="productImage"
          value="<?= $items['image_url'] ?>">
        <?php if (isset($items['image_url']) && !empty($items['image_url'])): ?>
          <div class="mt-2">Current image: <?= $items['image_url'] ?></div>
        <?php endif; ?>
      </div>

      <!-- Category Selection -->
      <div class="mb-3">
        <label for="category" class="form-label">Category</label>
        <select class="form-select" id="category" name="category">
          <?php
          // Get all categories
          $categories = (new \App\Models\Marketplace())->getAllCategories();
          foreach ($categories as $category): ?>
            <option value="<?= $category['category_id'] ?>" <?= ($items['category_id'] == $category['category_id']) ? 'selected' : '' ?>>
              <?= $category['category_name'] ?>
            </option>
          <?php endforeach; ?>
        </select>
      </div>

      <!-- Item Type -->
      <div class="mb-3">
        <label for="itemType" class="form-label">Item Type</label>
        <select class="form-select" id="itemType" name="itemType">
          <option value="consumable" <?= ($items['item_type'] == 'consumable') ? 'selected' : '' ?>>Consumable</option>
          <option value="equipment" <?= ($items['item_type'] == 'equipment') ? 'selected' : '' ?>>Equipment</option>
          <option value="collectible" <?= ($items['item_type'] == 'collectible') ? 'selected' : '' ?>>Collectible</option>
          <option value="boost" <?= ($items['item_type'] == 'boost') ? 'selected' : '' ?>>Boost</option>
        </select>
      </div>

      <!-- Effect Fields (conditionally shown based on item type) -->
      <div id="effectFields" class="mb-3">
        <label for="effectType" class="form-label">Effect Type</label>
        <select class="form-select" id="effectType" name="effectType">
          <option value="">None</option>
          <option value="health" <?= ($items['effect_type'] == 'health') ? 'selected' : '' ?>>Health</option>
          <option value="coins" <?= ($items['effect_type'] == 'coins') ? 'selected' : '' ?>>Coins</option>
          <option value="xp" <?= ($items['effect_type'] == 'xp') ? 'selected' : '' ?>>XP</option>
          <option value="xp_multiplier" <?= ($items['effect_type'] == 'xp_multiplier') ? 'selected' : '' ?>>XP Multiplier
          </option>
          <option value="coin_multiplier" <?= ($items['effect_type'] == 'coin_multiplier') ? 'selected' : '' ?>>Coin
            Multiplier</option>
          <option value="completion_bonus" <?= ($items['effect_type'] == 'completion_bonus') ? 'selected' : '' ?>>
            Completion Bonus</option>
        </select>
      </div>

      <div class="mb-3">
        <label for="effectValue" class="form-label">Effect Value</label>
        <input type="number" class="form-control" id="effectValue" name="effectValue"
          value="<?= $items['effect_value'] ?? '' ?>">
      </div>

      <div class="mb-3">
        <label for="durability" class="form-label">Durability (for equipment)</label>
        <input type="number" class="form-control" id="durability" name="durability"
          value="<?= $items['durability'] ?? '' ?>">
      </div>
      <div class="mb-3">
        <label for="cooldownPeriod" class="form-label">Cooldown Period (in hours)</label>
        <input type="number" class="form-control" id="cooldownPeriod" name="cooldownPeriod"
          value="<?= $items['cooldown_period'] ?? '' ?>">
      </div>

      <!-- Status Field -->
      <div class="mb-3">
        <label for="status" class="form-label">Status</label>
        <select class="form-select" id="status" name="status">
          <option value="available" <?= ($items['status'] ?? 'available') == 'available' ? 'selected' : '' ?>>Available
          </option>
          <option value="disabled" <?= ($items['status'] ?? 'available') == 'disabled' ? 'selected' : '' ?>>Disabled
          </option>
        </select>
        <div class="form-text">Available items can be purchased by users. Disabled items are hidden from the
          marketplace.</div>
      </div>

      <button type="submit" class="btn btn-primary">Update Product</button>
      <a href="/marketplace" class="btn btn-secondary">Cancel</a>
    </form>
  </div>
</div>