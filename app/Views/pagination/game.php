<?php if (isset($pagination) && $pagination['totalPages'] > 1): ?>
  <nav aria-label="Pagination" class="game-pagination">
    <div class="d-flex justify-content-between align-items-center">
      <div class="pagination-info">
        <small class="text-muted" style="font-family: 'Pixelify Sans', serif;">
          <i class="bi bi-controller"></i> <?= $pagination['currentPage'] ?> of <?= $pagination['totalPages'] ?>
        </small>
      </div>
      <ul class="pagination mb-0 game-pagination-list">
        <?php if (!$paginator->onFirstPage()): ?>
          <li class="page-item">
            <a class="page-link game-page-link" href="<?= $paginator->getPageUrl($paginator->previousPage()) ?>"
              aria-label="Previous">
              <i class="bi bi-arrow-left-circle-fill"></i>
            </a>
          </li>
        <?php endif; ?>

        <?php
        $startPage = max(1, $pagination['currentPage'] - 2);
        $endPage = min($pagination['totalPages'], $pagination['currentPage'] + 2);

        if ($startPage > 1) {
          echo '<li class="page-item"><a class="page-link game-page-link" href="' . $paginator->getPageUrl(1) . '">1</a></li>';
          if ($startPage > 2) {
            echo '<li class="page-item disabled"><span class="page-link game-page-link">...</span></li>';
          }
        }

        for ($i = $startPage; $i <= $endPage; $i++):
          ?>
          <li class="page-item <?= $i == $pagination['currentPage'] ? 'active' : '' ?>">
            <a class="page-link game-page-link" href="<?= $paginator->getPageUrl($i) ?>"><?= $i ?></a>
          </li>
        <?php endfor;

        if ($endPage < $pagination['totalPages']) {
          if ($endPage < $pagination['totalPages'] - 1) {
            echo '<li class="page-item disabled"><span class="page-link game-page-link">...</span></li>';
          }
          echo '<li class="page-item"><a class="page-link game-page-link" href="' . $paginator->getPageUrl($pagination['totalPages']) . '">' . $pagination['totalPages'] . '</a></li>';
        }
        ?>

        <?php if (!$paginator->onLastPage()): ?>
          <li class="page-item">
            <a class="page-link game-page-link" href="<?= $paginator->getPageUrl($paginator->nextPage()) ?>"
              aria-label="Next">
              <i class="bi bi-arrow-right-circle-fill"></i>
            </a>
          </li>
        <?php endif; ?>
      </ul>
    </div>
  </nav>

  <style>
    .game-pagination {
      margin-top: 1rem;
      padding: 0.5rem;
      border: 2px solid #212529;
      border-radius: 8px;
      background-color: white;
      box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
      transition: transform 0.3s ease;
    }

    .game-pagination:hover {
      transform: translateY(-2px);
      box-shadow: 0 5px 15px rgba(0, 0, 0, 0.15);
    }

    .game-pagination-list {
      display: flex;
      gap: 0.5rem;
    }

    .game-page-link {
      border: 2px solid #212529 !important;
      border-radius: 6px !important;
      color: #212529 !important;
      font-family: 'Pixelify Sans', serif;
      font-weight: bold;
      padding: 0.5rem 1rem;
      transition: all 0.3s ease;
      background-color: white !important;
      min-width: 40px;
      text-align: center;
    }

    .game-page-link:hover {
      transform: translateY(-2px);
      box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
      background-color: #f8f9fa !important;
    }

    .page-item.active .game-page-link {
      background-color: #212529 !important;
      color: white !important;
      transform: translateY(-2px);
      box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
    }

    .page-item.disabled .game-page-link {
      opacity: 0.5;
      cursor: not-allowed;
      transform: none;
      box-shadow: none;
    }

    .pagination-info {
      font-size: 0.9rem;
      padding: 0.5rem;
      border: 2px solid #212529;
      border-radius: 6px;
      background-color: #f8f9fa;
    }

    .pagination-info i {
      margin-right: 0.5rem;
    }
  </style>
<?php endif; ?>