<div id="pagination-content">
  <a href="/" class="back-button">
    <i class="bi bi-arrow-left"></i>
    Back to Dashboard
  </a>

  <div class="container py-4">
    <!-- HEADER SECTION WITH BATTLE LOG CARD -->
    <div class="card border-dark mb-4 shadow">
      <div class="card-header bg-white">
        <h2 class="my-2"><i class="bi bi-journal-x"></i> Battle Log</h2>
      </div>
      <div class="card-body">
        <div class="row align-items-center">
          <div class="col-md-2 text-center mb-3 mb-md-0">
            <div class="rounded p-3 d-inline-block">
              <i class="bi bi-boxing fs-1"></i>
            </div>
          </div>
          <div class="col-md-10">
            <p class="mb-0">Check out your battle stats here.</p>
            <div class="mt-2">
              <i class="bi bi-info-circle"></i> Need helps
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- BAD HABITS SECTION -->
    <div class="card border-dark mb-4 shadow">
      <div class="card-header bg-white d-flex justify-content-between align-items-center">
        <h3 class="my-2"><i class="bi bi-exclamation-triangle"></i> Your Bad Habits</h3>
        <div class="d-flex">
          <button type="button" class="btn btn-outline-dark btn-sm" data-bs-toggle="modal"
            data-bs-target="#createTaskModal">
            <i class="bi bi-plus"></i> Add New
          </button>
        </div>
      </div>

      <div class="card-body">
        <!-- BAD HABITS GRID -->
        <div class="row row-cols-1 row-cols-md-3 g-4">
          <?php if (empty($badHabits)): ?>
            <div class="col-12">
              <div class="alert alert-dark">
                <i class="bi bi-info-circle"></i> No bad habits found. Create your first one!
              </div>
            </div>
          <?php else: ?>
            <?php foreach ($paginator->items() as $badHabit): ?>
              <div class="col">
                <div class="card border-dark h-100 habit-card">
                  <div class="card-header bg-white d-flex justify-content-between align-items-center py-3">
                    <h5 class="mb-0">
                      <i class="bi bi-exclamation-triangle me-2"></i> <?= htmlspecialchars($badHabit['title']) ?>
                    </h5>
                    <div class="dropdown">
                      <button class="btn btn-sm btn-outline-dark" type="button" data-bs-toggle="dropdown"
                        aria-expanded="false">
                        <i class="bi bi-three-dots"></i>
                      </button>
                      <ul class="dropdown-menu">
                        <li>
                          <button class="dropdown-item edit-task-btn" type="button" data-bs-toggle="modal"
                            data-bs-target="#editTaskModal" data-task-id="<?= $badHabit['id'] ?>"
                            data-task-title="<?= htmlspecialchars($badHabit['title']) ?>"
                            data-task-category="<?= htmlspecialchars($badHabit['category']) ?>"
                            data-task-difficulty="<?= $badHabit['difficulty'] ?>"
                            data-task-status="<?= $badHabit['status'] ?>">
                            Edit
                          </button>
                        </li>
                        <li>
                          <button class="dropdown-item text-danger delete-habit-btn" type="button" data-bs-toggle="modal"
                            data-bs-target="#directDeleteModal" data-habit-id="<?= $badHabit['id'] ?>"
                            data-habit-title="<?= htmlspecialchars($badHabit['title']) ?>">
                            Delete
                          </button>
                        </li>
                      </ul>
                    </div>
                  </div>
                  <div class="card-body">
                    <div class="mb-2">
                      <span
                        class="badge bg-<?= \App\Core\Helpers::getDifficultyBadgeColor($badHabit['difficulty']) ?> me-2">
                        <?= ucfirst($badHabit['difficulty']) ?>
                      </span>
                      <span class="badge bg-secondary">
                        <?= ucfirst($badHabit['category']) ?>
                      </span>
                    </div>
                    <div class="mb-3">
                      <span class="<?= $badHabit['status'] === 'completed' ? 'text-decoration-line-through' : '' ?>">
                        Status: <?= ucfirst($badHabit['status']) ?>
                      </span>
                    </div>
                    <form action="/badhabit/<?= $badHabit['id'] ?>/toggle" method="POST">
                      <?php if ($badHabit['status'] === 'completed'): ?>
                        <button type="submit" class="btn btn-dark w-100" disabled>
                          <?= $badHabit['status'] === 'completed' ? 'COMPLETED' : 'CRAP I DID...' ?>
                        </button>
                      <?php else: ?>
                        <button type="submit" class="btn btn-dark w-100">
                          <?= $badHabit['status'] === 'completed' ? 'COMPLETED' : 'CRAP I DID...' ?>
                        </button>
                      <?php endif; ?>
                    </form>
                  </div>
                </div>
              </div>
            <?php endforeach; ?>
          <?php endif; ?>
        </div>
        <?= $paginator->links() ?>
      </div>
    </div>
  </div>

  <!-- Include Modal Forms -->
  <?php include __DIR__ . '/modals/create.php'; ?>
  <?php include __DIR__ . '/modals/edit.php'; ?>
  <?php include __DIR__ . '/modals/delete.php'; ?>

</div>

<script>
  document.addEventListener('DOMContentLoaded', function () {
    const contentContainer = document.getElementById('pagination-content');

    // Handle pagination clicks
    contentContainer.addEventListener('click', function (e) {
      const link = e.target.closest('a');
      if (link && link.getAttribute('href').includes('page=')) {
        e.preventDefault();
        const url = link.getAttribute('href');

        // Show loading state
        contentContainer.style.opacity = '0.5';

        // Fetch the new page content
        fetch(url)
          .then(response => response.text())
          .then(html => {
            // Create a temporary element to parse the HTML
            const tempDiv = document.createElement('div');
            tempDiv.innerHTML = html;

            // Extract just the pagination content
            const newContent = tempDiv.querySelector('#pagination-content');

            if (newContent) {
              // Replace only the content inside the container
              contentContainer.innerHTML = newContent.innerHTML;
            } else {
              console.error('Could not find pagination content in response');
            }

            contentContainer.style.opacity = '1';

            // Update browser history
            window.history.pushState({}, '', url);
          })
          .catch(error => {
            console.error('Error:', error);
            contentContainer.style.opacity = '1';
          });
      }
    });

    // Handle browser back/forward buttons
    window.addEventListener('popstate', function () {
      fetch(window.location.href)
        .then(response => response.text())
        .then(html => {
          const tempDiv = document.createElement('div');
          tempDiv.innerHTML = html;

          const newContent = tempDiv.querySelector('#pagination-content');
          if (newContent) {
            contentContainer.innerHTML = newContent.innerHTML;
          }
        });
    });
  });
</script>