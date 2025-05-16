<?php

namespace App\Core;

class Paginator
{
  protected int $currentPage = 1;
  protected int $perPage = 10;
  protected int $totalItems = 0;
  protected int $totalPages = 0;
  protected string $orderBy = '';
  protected string $direction = 'ASC';
  protected array $data = [];
  protected string $pageName = 'page';
  protected bool $preserveQuery = true;
  protected array $queryParams = [];
  protected string $theme = 'default';

  public function __construct(int $perPage = 10, string $pageName = 'page')
  {
    $this->perPage = $perPage;
    $this->pageName = $pageName;
    $this->currentPage = $this->resolveCurrentPage();
    $this->queryParams = $_GET;
  }

  protected function resolveCurrentPage(): int
  {
    return isset($_GET[$this->pageName]) ? max(1, (int) $_GET[$this->pageName]) : 1;
  }

  public function links(?string $view = null): string
  {
    if ($view === null) {
      $view = "pagination/{$this->theme}";
    }

    // Get the pagination data
    $pagination = [
      'currentPage' => $this->currentPage,
      'totalPages' => $this->totalPages,
      'totalItems' => $this->totalItems,
      'perPage' => $this->perPage,
      'orderBy' => $this->orderBy,
      'direction' => $this->direction,
      'pageName' => $this->pageName
    ];

    // Extract to variables to make them available in the view
    extract(['pagination' => $pagination, 'paginator' => $this, 'items' => $this->data]);

    // Start output buffering
    ob_start();

    // Include the view file
    include_once dirname(__DIR__) . '/Views/' . $view . '.php';

    // Return the output
    return ob_get_clean();
  }

  public function setData(array $data, int $totalItems): self
  {
    $this->data = $data;
    $this->totalItems = $totalItems;
    $this->totalPages = ceil($totalItems / $this->perPage);
    return $this;
  }

  public function items(): array
  {
    return $this->data;
  }

  public function setOrderBy(string $orderBy, string $direction = 'ASC'): self
  {
    $this->orderBy = $orderBy;
    $this->direction = strtoupper($direction);
    return $this;
  }

  public function hasPages(): bool
  {
    return $this->totalPages > 1;
  }

  public function onFirstPage(): bool
  {
    return $this->currentPage <= 1;
  }

  public function onLastPage(): bool
  {
    return $this->currentPage >= $this->totalPages;
  }

  public function setPage(int $page): self
  {
    $this->currentPage = max(1, min($page, $this->totalPages));
    return $this;
  }

  public function previousPage(): int
  {
    return max(1, $this->currentPage - 1);
  }

  public function nextPage(): int
  {
    return min($this->totalPages, $this->currentPage + 1);
  }

  public function getPageUrl(int $page): string
  {
    $params = $this->preserveQuery ? $this->queryParams : [];
    $params[$this->pageName] = $page;
    return '?' . http_build_query($params);
  }

  public function getPageInfo(): array
  {
    return [
      'currentPage' => $this->currentPage,
      'totalPages' => $this->totalPages,
      'totalItems' => $this->totalItems,
      'perPage' => $this->perPage,
      'orderBy' => $this->orderBy,
      'direction' => $this->direction,
      'pageName' => $this->pageName
    ];
  }

  public function setTheme(string $theme): self
  {
    $this->theme = $theme;
    return $this;
  }

  public function preserveQuery(bool $preserve = true): self
  {
    $this->preserveQuery = $preserve;
    return $this;
  }

  public function setQueryParams(array $params): self
  {
    $this->queryParams = $params;
    return $this;
  }
}