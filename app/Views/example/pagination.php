<div class="container mt-4">
  <h1>Pagination Example</h1>

  <!-- Display paginated items -->
  <div class="row">
    <?php foreach ($paginator->items() as $item): ?>
      <div class="col-md-4 mb-4">
        <div class="card">
          <div class="card-body">
            <h5 class="card-title"><?= htmlspecialchars($item['title'] ?? 'Item') ?></h5>
            <p class="card-text"><?= htmlspecialchars($item['description'] ?? 'Description') ?></p>
          </div>
        </div>
      </div>
    <?php endforeach; ?>
  </div>

  <!-- Display pagination links -->
  <!-- < ?= $paginator->links() ?> -->

  <!-- Example of using different themes -->
  <div class="mt-4">
    <h3>Different Pagination Themes</h3>
    <div class="mb-4">
      <h4>Default Theme</h4>
      <?= $paginator->links() ?>
    </div>
    <div class="mb-4">
      <h4>Bootstrap Theme</h4>
      <?= $paginator->setTheme('bootstrap')->links() ?>
    </div>
    <div class="mb-4">
      <h4>Gamemified Theme</h4>
      <?= $paginator->setTheme('game')->links() ?>
    </div>
  </div>
</div>