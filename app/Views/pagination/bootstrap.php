<?php if (isset($pagination) && $pagination['totalPages'] > 1): ?>
  <nav aria-label="Pagination">
    <div class="d-flex justify-content-between align-items-center">
      <div class="pagination-info">
        <small class="text-muted">
          Showing <?= ($pagination['currentPage'] - 1) * $pagination['perPage'] + 1 ?> to
          <?= min($pagination['currentPage'] * $pagination['perPage'], $pagination['totalItems']) ?> of
          <?= $pagination['totalItems'] ?> results
        </small>
      </div>
      <ul class="pagination mb-0">
        <?php if (!$paginator->onFirstPage()): ?>
          <li class="page-item">
            <a class="page-link" href="<?= $paginator->getPageUrl($paginator->previousPage()) ?>" aria-label="Previous">
              <span aria-hidden="true">&laquo;</span>
            </a>
          </li>
        <?php endif; ?>

        <?php
        $startPage = max(1, $pagination['currentPage'] - 2);
        $endPage = min($pagination['totalPages'], $pagination['currentPage'] + 2);

        if ($startPage > 1) {
          echo '<li class="page-item"><a class="page-link" href="' . $paginator->getPageUrl(1) . '">1</a></li>';
          if ($startPage > 2) {
            echo '<li class="page-item disabled"><span class="page-link">...</span></li>';
          }
        }

        for ($i = $startPage; $i <= $endPage; $i++):
          ?>
          <li class="page-item <?= $i == $pagination['currentPage'] ? 'active' : '' ?>">
            <a class="page-link" href="<?= $paginator->getPageUrl($i) ?>"><?= $i ?></a>
          </li>
        <?php endfor;

        if ($endPage < $pagination['totalPages']) {
          if ($endPage < $pagination['totalPages'] - 1) {
            echo '<li class="page-item disabled"><span class="page-link">...</span></li>';
          }
          echo '<li class="page-item"><a class="page-link" href="' . $paginator->getPageUrl($pagination['totalPages']) . '">' . $pagination['totalPages'] . '</a></li>';
        }
        ?>

        <?php if (!$paginator->onLastPage()): ?>
          <li class="page-item">
            <a class="page-link" href="<?= $paginator->getPageUrl($paginator->nextPage()) ?>" aria-label="Next">
              <span aria-hidden="true">&raquo;</span>
            </a>
          </li>
        <?php endif; ?>
      </ul>
    </div>
  </nav>
<?php endif; ?>