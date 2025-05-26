<div class="card">
  <div class="card-header">
    <h1><?= $title ?></h1>
  </div>
  <div class="card-body">
    <form method="post" action="/marketplace/store" enctype="multipart/form-data">
      <div class="mb-3">
        <label for="productName" class="form-label">Product Name</label>
        <input type="text" class="form-control" id="productName" name="productName" required>
      </div>
      <div class="mb-3">
        <label for="productDescription" class="form-label">Product Description</label>
        <input type="text" class="form-control" id="productDescription" name="productDescription">
      </div>
      <div class="mb-3">
        <label for="productPrice" class="form-label">Product Price</label>
        <input type="number" class="form-control" id="productPrice" name="productPrice" value="0" required>
      </div>
      <div class="mb-3">
        <label for="productImage" class="form-label">Product Image</label>
        <input type="text" class="form-control" id="productImage" name="productImage"
          placeholder="/assets/images/items/example.png">
      </div>

      <!-- Category Selection -->
      <div class="mb-3">
        <label for="category" class="form-label">Category</label>
        <select class="form-select" id="category" name="category">
          <option value="" disabled selected>Select a category</option>
          <?php foreach ($categories as $category): ?>
            <option value="<?= $category['category_id'] ?>">
              <?= $category['category_name'] ?>
            </option>
          <?php endforeach; ?>
        </select>
      </div>

      <!-- Item Type -->
      <div class="mb-3">
        <label for="itemType" class="form-label">Item Type</label>
        <select class="form-select" id="itemType" name="itemType">
          <option value="collectible" selected>Collectible</option>
          <option value="consumable">Consumable</option>
          <option value="equipment">Equipment</option>
          <option value="boost">Boost</option>
        </select>
      </div>

      <!-- Effect Fields -->
      <div id="effectFields" class="mb-3">
        <label for="effectType" class="form-label">Effect Type</label>
        <select class="form-select" id="effectType" name="effectType">
          <option value="">None</option>
          <option value="health">Health</option>
          <option value="coins">Coins</option>
          <option value="xp">XP</option>
          <option value="xp_multiplier">XP Multiplier</option>
          <option value="coin_multiplier">Coin Multiplier</option>
          <option value="completion_bonus">Completion Bonus</option>
        </select>
      </div>

      <div class="mb-3">
        <label for="effectValue" class="form-label">Effect Value</label>
        <input type="number" class="form-control" id="effectValue" name="effectValue" value="0">
      </div>

      <div class="mb-3">
        <label for="durability" class="form-label">Durability (for equipment)</label>
        <input type="number" class="form-control" id="durability" name="durability" value="0">
      </div>
      <div class="mb-3">
        <label for="cooldownPeriod" class="form-label">Cooldown Period (in hours)</label>
        <input type="number" class="form-control" id="cooldownPeriod" name="cooldownPeriod" value="0">
      </div>

      <!-- Status Field -->
      <div class="mb-3">
        <label for="status" class="form-label">Status</label>
        <select class="form-select" id="status" name="status">
          <option value="available" selected>Available</option>
          <option value="disabled">Disabled</option>
        </select>
        <div class="form-text">Available items can be purchased by users. Disabled items are hidden from the
          marketplace.</div>
      </div>

      <button type="submit" class="btn btn-primary">Create Product</button>
      <a href="/marketplace" class="btn btn-secondary">Cancel</a>
    </form>
  </div>
</div>