<div>
  <a href="/" class="back-button">
    <i class="bi bi-arrow-left"></i>
    Back to Dashboard
  </a>

  <div class="container py-4">
    <!-- HEADER SECTION WITH MAP CARD -->
    <div class="card border-dark mb-4 shadow">
      <div class="card-header bg-white">
        <h2 class="my-2"><i class="bi bi-calendar-week"></i> Growth Heat Map</h2>
      </div>
      <div class="card-body">
        <div class="row align-items-center">
          <div class="col-md-2 text-center mb-3 mb-md-0">
            <div class=" rounded p-3 d-inline-block">
              <i class="bi bi-calendar-week fs-1"></i>
            </div>
          </div>
          <div class="col-md-10">
            <p class="mb-0">Check out your growth heat map here.</p>
            <div class="mt-2">
              <i class="bi bi-info-circle"></i> Track your habits and build consistency
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- TABS SECTION -->
    <div class="card border-dark mb-4 shadow">
      <div class="card-header bg-white d-flex justify-content-between align-items-center">
        <h3 class="my-2"><i class="bi bi-list-check"></i> Your Habits</h3>
        <div class="d-flex">
          <button type="button" class="btn btn-outline-dark btn-sm" data-bs-toggle="modal"
            data-bs-target="#createTaskModal">
            <i class="bi bi-plus"></i> Add New
          </button>
        </div>
      </div>

      <div class="card-body">
        <!-- HABITS GRID -->
        <div class="row row-cols-1 row-cols-md-2 row-cols-lg-3 g-4">
          <?php if (empty($goodHabits)): ?>
            <div class="col-12">
              <div class="alert alert-info">
                <i class="bi bi-info-circle"></i> No good habits found. Create your first one!
              </div>
            </div>
          <?php else: ?>
            <?php foreach ($goodHabits as $goodHabit): ?>
              <div class="col">
                <div class="card border-dark h-100 habit-card">
                  <div class="card-header bg-white d-flex justify-content-between align-items-center py-3">
                    <h5 class="mb-0">
                      <i class="bi bi-emoji-smile me-2"></i> <?= htmlspecialchars($goodHabit['title']) ?>
                    </h5>
                    <div class="dropdown">
                      <button class="btn btn-sm btn-outline-dark" type="button" data-bs-toggle="dropdown"
                        aria-expanded="false">
                        <i class="bi bi-three-dots"></i>
                      </button>
                      <ul class="dropdown-menu">
                        <li>
                          <button class="dropdown-item edit-task-btn" type="button" data-bs-toggle="modal"
                            data-bs-target="#editTaskModal" data-task-id="<?= $goodHabit['id'] ?>"
                            data-task-title="<?= htmlspecialchars($goodHabit['title']) ?>"
                            data-task-category="<?= htmlspecialchars($goodHabit['category']) ?>"
                            data-task-difficulty="<?= $goodHabit['difficulty'] ?>"
                            data-task-status="<?= $goodHabit['status'] ?>">
                            Edit
                          </button>
                        </li>
                        <li>
                          <button class="dropdown-item text-danger delete-habit-btn" type="button" data-bs-toggle="modal"
                            data-bs-target="#directDeleteModal" data-habit-id="<?= $goodHabit['id'] ?>"
                            data-habit-title="<?= htmlspecialchars($goodHabit['title']) ?>">
                            Delete
                          </button>
                        </li>
                      </ul>
                    </div>
                  </div>
                  <div class="card-body">
                    <div class="mb-2">
                      <span class="fw-bold">DIFFICULTY:</span>
                      <span
                        class="difficulty-<?= $goodHabit['difficulty'] ?>"><?= strtoupper($goodHabit['difficulty']) ?></span>
                    </div>
                    <div class="mb-2">
                      <span class="fw-bold"><i class="bi bi-stars"></i></span>
                      <span
                        class="text-success">+<?= $goodHabit['difficulty'] == 'easy' ? '5' : ($goodHabit['difficulty'] == 'medium' ? '10' : '15') ?></span>
                    </div>
                    <div class="mb-2">
                      <span class="fw-bold"><i class="bi bi-coin"></i></span>
                      <span
                        class="text-warning">+<?= $goodHabit['difficulty'] == 'easy' ? '5' : ($goodHabit['difficulty'] == 'medium' ? '10' : '15') ?></span>
                    </div>
                    <div class="mb-3">
                      <span class="fw-bold"><?= strtoupper($goodHabit['category']) ?></span>
                    </div>
                    <form action="/goodhabit/<?= $goodHabit['id'] ?>/toggle" method="POST">
                      <button type="submit" class="btn btn-dark w-100">
                        <?= $goodHabit['status'] === 'completed' ? 'ALREADY COMPLETED' : 'COMPLETE' ?>
                      </button>
                    </form>
                  </div>
                </div>
              </div>
            <?php endforeach; ?>
          <?php endif; ?>
        </div>
      </div>
    </div>
  </div>

  <!-- Include Modal Forms -->
  <?php include __DIR__ . '/modals/create.php'; ?>
  <?php include __DIR__ . '/modals/edit.php'; ?>
  <?php include __DIR__ . '/modals/delete.php'; ?>

</div>