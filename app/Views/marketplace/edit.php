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
        <input type="file" class="form-control" id="productImage" name="productImage" accept="image/*">
        <?php if (isset($items['image_url']) && !empty($items['image_url'])): ?>
          <div class="mt-2">Current image: <?= $item['image_url'] ?></div>
        <?php endif; ?>
      </div>
      <button type="submit" class="btn btn-primary">Update Product</button>
      <a href="/marketplace" class="btn btn-secondary">Cancel</a>
    </form>
  </div>
</div>