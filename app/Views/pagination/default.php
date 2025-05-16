<?php if (isset($pagination) && $pagination['totalPages'] > 1): ?>
  <nav aria-label="Pagination">
    <div class="d-flex justify-content-between align-items-center">
      <div class="pagination-info">
        <small class="text-muted">
          Showing <?= count($items) ?> of <?= $pagination['totalItems'] ?> items
        </small>
      </div>
      <ul class="pagination pagination-sm mb-0">
        <li class="page-item <?= ($pagination['currentPage'] <= 1) ? 'disabled' : '' ?>">
          <a class="page-link" href="<?= $paginator->getPageUrl($paginator->previousPage()) ?>" aria-label="Previous">
            <span aria-hidden="true">&laquo;</span>
          </a>
        </li>
        <?php
        $startPage = max(1, $pagination['currentPage'] - 2);
        $endPage = min($pagination['totalPages'], $pagination['currentPage'] + 2);
        if ($endPage - $startPage < 4 && $pagination['totalPages'] > 5) {
          if ($startPage == 1) {
            $endPage = min($pagination['totalPages'], 5);
          } elseif ($endPage == $pagination['totalPages']) {
            $startPage = max(1, $pagination['totalPages'] - 4);
          }
        }
        for ($i = $startPage; $i <= $endPage; $i++):
          ?>
          <li class="page-item <?= ($i == $pagination['currentPage']) ? 'active' : '' ?>">
            <a class="page-link" href="<?= $paginator->getPageUrl($i) ?>"><?= $i ?></a>
          </li>
        <?php endfor; ?>
        <li class="page-item <?= ($pagination['currentPage'] >= $pagination['totalPages']) ? 'disabled' : '' ?>">
          <a class="page-link" href="<?= $paginator->getPageUrl($paginator->nextPage()) ?>" aria-label="Next">
            <span aria-hidden="true">&raquo;</span>
          </a>
        </li>
      </ul>
    </div>
  </nav>
<?php endif; ?>