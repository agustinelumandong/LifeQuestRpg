<div>
  <a href="/" class="back-button">
    <i class="bi bi-arrow-left"></i>
    Back to Dashboard
  </a>

  <div class="card">
    <div class="card-header">
      <h1><?= $title ?></h1>
    </div>
    <div class="card-body d-flex flex-row flex-wrap">
      <?php foreach ($items as $item): ?>
        <div class="c">
          <div class="card-head">
            <p><?= $item['item_name'] ?></p>
          </div>

        </div>
      <?php endforeach; ?>
    </div>
  </div>
</div>