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
        <label for="productDescription" class="form-label">Product Discription</label>
        <input type="text" class="form-control" id="productDescription" name="productDescription">
      </div>
      <div class="mb-3">
        <label for="productPrice" class="form-label">Product Price</label>
        <input type="number" class="form-control" id="productPrice" name="productPrice" value="0" required>
      </div>
      <div class="mb-3">
        <label for="productImage" class="form-label">Product Image</label>
        <input type="file" class="form-control" id="productImage" name="productImage" accept="image/*">
      </div>
      <button type="submit" class="btn btn-primary">Create Product</button>
      <a href="/marketplace" class="btn btn-secondary">Cancel</a>
    </form>
  </div>
</div>