<div class="container py-4">

  <a href="/" class="back-button">
    <i class="bi bi-arrow-left"></i>
    Back to Dashboard
  </a>

  <!-- HEADER SECTION -->
  <div class="card border-dark mb-4 shadow">
    <div class="card-header bg-white">
      <h2 class="my-2"><i class="bi bi-check2-square"></i> <?= ucfirst($title) ?></h2>
    </div>
    <div class="card-body">
      <div class="row align-items-center">
        <div class="col-md-2 text-center mb-3 mb-md-0">
          <div class="rounded p-3 d-inline-block">
            <i class="bi bi-list-check fs-1"></i>
          </div>
        </div>
        <div class="col-md-10">
          <p class="mb-0">Manage your daily tasks and track your progress here.</p>
          <div class="mt-2">
            <i class="bi bi-info-circle"></i> Complete tasks to earn XP and level up your profile
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- TABS NAVIGATION -->
  <ul class="nav nav-tabs">
    <li class="nav-item">
      <a class="nav-link" href="/task">
        <i class="bi bi-list-task"></i> Regular Tasks
      </a>
    </li>
    <li class="nav-item">
      <a class="nav-link active" aria-current="page" href="/dailytask">
        <i class="bi bi-calendar-check"></i> Daily Tasks
      </a>
    </li>
  </ul>

  <!-- TASKS SECTION -->
  <div class="card border-dark mb-4 shadow">
    <div class="card-header bg-white d-flex justify-content-between align-items-center">
      <h3 class="my-2"><i class="bi bi-list-check"></i> Your Daily Tasks</h3>
      <button type="button" class="btn btn-dark" data-bs-toggle="modal" data-bs-target="#createTaskModal">
        <i class="bi bi-plus-circle"></i> Create New Daily Task
      </button>
    </div>

    <div class="card-body">
      <?php if (empty($dailyTasks)): ?>
        <div class="alert alert-dark text-center" role="alert">
          <i class="bi bi-emoji-neutral display-4 d-block mb-3"></i>
          <p class="mb-0">No daily tasks found. Create your first daily task!</p>
        </div>
      <?php else: ?>
        <div class="task-list">
          <?php foreach ($dailyTasks as $dailyTask): ?>
            <?php
            $isCompleted = $dailyTask['status'] === 'completed';
            $difficultyClass = getDifficultyClass($dailyTask['difficulty']);
            $difficultyLabel = ucfirst($dailyTask['difficulty']);
            $points = getDifficultyPoints($dailyTask['difficulty']);
            ?>
            <div class="task-row <?= $isCompleted ? 'completed' : '' ?> border border-dark rounded mb-2"
              onclick="taskRowClick(this, <?= $dailyTask['id'] ?>)">
              <div class="task-left">
                <div class="task-checkbox">
                  <input type="checkbox" class="form-check-input task-check" <?= $isCompleted ? 'checked' : '' ?>
                    onclick="event.stopPropagation()" onchange="return toggleTaskStatus(<?= $dailyTask['id'] ?>, this)">
                </div>
              </div>
              <div class="task-center">
                <h5 class="task-title <?= $isCompleted ? 'text-decoration-line-through' : '' ?>">
                  <?= htmlspecialchars($dailyTask['title']) ?>
                </h5>
                <div class="task-meta">
                  <span class="task-badge <?= $difficultyClass ?>">
                    <?= $difficultyLabel ?>
                  </span>
                  <span class="task-badge status-badge <?= $isCompleted ? 'status-completed' : 'status-pending' ?>">
                    <?= ucfirst($dailyTask['status']) ?>
                  </span>
                  <span class="task-badge reward-badge">
                    <i class="bi bi-stars"></i> <?= $points ?> XP
                  </span>
                </div>
              </div>
              <div class="task-actions">
                <div class="dropdown d-inline-block">
                  <button class="btn btn-sm btn-outline-dark " type="button" id="dropdownMenu<?= $dailyTask['id'] ?>"
                    data-bs-toggle="dropdown" aria-expanded="false" onclick="event.stopPropagation()">
                    <i class="bi bi-three-dots"></i>
                  </button>
                  <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="dropdownMenu<?= $dailyTask['id'] ?>">
                    <li>
                      <button class="dropdown-item" type="button" data-bs-toggle="modal" data-bs-target="#editTaskModal"
                        data-task-id="<?= $dailyTask['id'] ?>"
                        data-task-title="<?= htmlspecialchars($dailyTask['title']) ?>"
                        data-task-category="<?= $dailyTask['category'] ?>"
                        data-task-difficulty="<?= $dailyTask['difficulty'] ?>" data-form-action="/dailytask"
                        title="Edit Task" onclick="event.stopPropagation()">
                        <i class="bi bi-pencil"></i>
                        Edit
                      </button>
                    </li>
                    <form action="/dailytask/<?= $dailyTask['id'] ?>/delete" method="post">
                      <input type="hidden" name="_method" value="DELETE">
                      <button type="submit" class="dropdown-item text-danger" title="Delete Task"
                        onclick="event.stopPropagation(); return confirm('Are you sure you want to delete this task?')">
                        <i class="bi bi-trash"></i> Delete
                      </button>
                    </form>
                    </li>
                    <li>
                      <button class="dropdown-item" type="button" data-bs-toggle="modal" data-bs-target="#editTaskModal"
                        data-task-id="<?= $dailyTask['id'] ?>"
                        data-task-title="<?= htmlspecialchars($dailyTask['title']) ?>"
                        data-task-category="<?= $dailyTask['category'] ?>"
                        data-task-difficulty="<?= $dailyTask['difficulty'] ?>" data-form-action="/dailytask"><i
                          class="bi bi-pencil"></i>
                        Edit
                      </button>
                    </li>
                    <li>
                      <form action="/dailytask/<?= $dailyTask['id'] ?>/delete" method="post" class="d-inline">
                        <input type="hidden" name="_method" value="DELETE">
                        <button type="submit" class="dropdown-item text-danger"><i class="bi bi-trash"></i> Delete</button>
                      </form>
                    </li>
                  </ul>
                </div>
              </div>
            </div>
          <?php endforeach; ?>
        </div>
      <?php endif; ?>
    </div>
  </div>
</div>

<div class="toast-container position-fixed bottom-0 end-0 p-3" id="toastContainer">
</div>

<?php include __DIR__ . '/modals/create.php'; ?>
<?php include __DIR__ . '/modals/edit.php'; ?>

<?php
// Helper function for difficulty badge colors
function getDifficultyClass($difficulty)
{
  return [
    'easy' => 'difficulty-easy',
    'medium' => 'difficulty-medium',
    'hard' => 'difficulty-hard'
  ][$difficulty] ?? '';
}

// Helper function to get point values for difficulties
function getDifficultyPoints($difficulty)
{
  return [
    'easy' => 5,
    'medium' => 10,
    'hard' => 15
  ][$difficulty] ?? 5;
}
?>