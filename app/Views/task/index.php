<div class="container py-4">
    <!-- User Welcome Card -->

    <?php include __DIR__ . '/../UserStats/statsBar.php'; ?>

    <!-- Tasks Header -->
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h1 class="h3"><?= ucfirst($title) ?></h1>
   <button type="button" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#createTaskModal">
     <i class="fas fa-plus"></i> Create new Tasks
   </button>
    </div>

    <!-- Tasks List -->
    <?php if (empty($tasks)): ?>
        <div class="alert alert-info">
            <i class="fas fa-info-circle"></i> No tasks found. Create your first task!
        </div>
    <?php else: ?>
        <div class="list-group">
            <?php foreach ($tasks as $task): ?>
                <div class="list-group-item d-flex justify-content-between align-items-center">
                    <div class="d-flex align-items-center">
                        <form action="/task/<?= $task['id'] ?>/toggle" method="POST" class="me-3">
                            <input type="checkbox" class="form-check-input" 
                                   onchange="this.form.submit()" 
                                   <?= $task['status'] === 'completed' ? 'checked' : '' ?>>
                        </form>
                        <div>
                            <span class="<?= $task['status'] === 'completed' ? 'text-decoration-line-through' : '' ?>">
                                <?= htmlspecialchars($task['title']) ?>
                            </span>
                            <span class=" badge bg-secondary ms-2">
                                <?= ucfirst($task['category']) ?>
                            </span>
                            <span class="badge bg-<?= \App\Core\Helpers::getDifficultyBadgeColor($task['difficulty']) ?> ms-2">
                                <?= ucfirst($task['difficulty']) ?>
                            </span>
                        </div>
                    </div>
                    <div class="btn-group">

                    <button class="btn btn-sm btn-outline-primary edit-task-btn" type="button"
                         data-bs-toggle="modal"
                         data-bs-target="#editTaskModal"
                         data-task-id="<?= $task['id'] ?>"
                         data-task-title="<?= htmlspecialchars($task['title']) ?>"
                         data-task-category="<?= $task['category'] ?>"
                         data-task-difficulty="<?= $task['difficulty'] ?>"
                         data-form-action="/task">        
                       <i class="fas fa-edit"></i> Edit
                    </button>

    <form action="/task/<?= $task['id'] ?>/delete" method="post" class="d-inline">
        <input type="hidden" name="_method" value="DELETE">
        <button type="submit" class="btn btn-sm btn-outline-danger">Delete</button>
    </form>
</div>
                </div>
            <?php endforeach; ?>
        </div>
    <?php endif; ?>
</div>



<div class="card mt-4">
    <div class="card-header bg-primary text-white">
        <h5 class="mb-0">Recent Activities</h5>
    </div>
    <div class="card-body">
        <?php if (!empty($activities)): ?>
            <div class="list-group">
                <?php foreach ($activities as $activity): ?>
                    <div class="list-group-item">
                        <div class="d-flex w-100 justify-content-between">
                            <h6 class="mb-1"><?= htmlspecialchars($activity['action']) ?></h6>
                            <small class="text-muted">
                                <?= date('M d, Y H:i', strtotime($activity['created_at'])) ?>
                            </small>
                        </div>
                        <p class="mb-1"> <?= htmlspecialchars($activity['description']) ?></p>
                        <p class="mb-1"> <?= htmlspecialchars($activity['category']) ?></p>

                        <?php if (isset($activity['coins']) && $activity['coins'] > 0): ?>
                        <div class="mt-1">
                            <span class="badge bg-warning text-dark">
                                <i class="fas fa-coins me-1"></i> Earned: <?= htmlspecialchars($activity['coins']) ?> coins
                            </span>
                        </div>
                        <?php endif; ?>

                  
                    </div>
                <?php endforeach; ?>
            </div>
        <?php else: ?>
            <p class="text-muted">No recent activities</p>
        <?php endif; ?>
    </div>
</div>

<!-- Create Task Modal -->
<div class="modal fade" id="createTaskModal" tabindex="-1" aria-labelledby="createTaskModalLabel" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="createTaskModalLabel">Create New Task</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        <form method="post" action="/tasks" id="createTaskForm">
          <div class="mb-3">
            <label for="title" class="form-label">Title</label>
            <input type="text" class="form-control" id="title" name="title" required>
          </div>
          <div class="mb-3">
            <label for="category" class="form-label">Category</label>
            <input type="hidden" name="status" value="pending">
            <select name="category" class="form-select">
              <option value="Physical Health">Physical Health</option>
              <option value="Mental Wellness">Mental Wellness</option>
              <option value="Personal Growth">Personal Growth</option>
              <option value="Career / Studies">Career / Studies</option>
              <option value="Finance">Finance</option>
              <option value="Home Environment">Home & Environment</option>
              <option value="Relationships Social">Relationships & Social</option>
              <option value="Passion Hobbies">Passion & Hobbies</option>
            </select>
          </div>
          <div class="mb-3">
            <label for="difficulty" class="form-label">Difficulty</label>
            <select name="difficulty" class="form-select">
              <option value="easy" selected>Easy</option>
              <option value="medium">Medium</option>
              <option value="hard">Hard</option>
            </select>
          </div>
        </form>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
        <button type="submit" form="createTaskForm" class="btn btn-primary">Create Task</button>
      </div>
    </div>
  </div>
</div>

<!-- Edit Task Modal -->
<div class="modal fade" id="editTaskModal" tabindex="-1" aria-labelledby="editTaskModalLabel" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="editTaskModalLabel">Edit Task</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        <form method="post" id="editTaskForm">
          <input type="hidden" name="_method" value="PUT">
          <input type="hidden" id="edit-task-id" name="task_id">
          
          <div class="mb-3">
            <label for="edit-title" class="form-label">Title</label>
            <input type="text" class="form-control" id="edit-title" name="title" required>
          </div>
          
          <div class="mb-3">
            <label for="edit-category" class="form-label">Category</label>
            <select name="category" id="edit-category" class="form-select">
              <option value="Physical Health">Physical Health</option>
              <option value="Mental Wellness">Mental Wellness</option>
              <option value="Personal Growth">Personal Growth</option>
              <option value="Career / Studies">Career / Studies</option>
              <option value="Finance">Finance</option>
              <option value="Home Environment">Home & Environment</option>
              <option value="Relationships Social">Relationships & Social</option>
              <option value="Passion Hobbies">Passion & Hobbies</option>
            </select>
          </div>
          
          <div class="mb-3">
            <label for="edit-difficulty" class="form-label">Difficulty</label>
            <select name="difficulty" id="edit-difficulty" class="form-select">
              <option value="easy">Easy</option>
              <option value="medium">Medium</option>
              <option value="hard">Hard</option>
            </select>
          </div>
          <input type="hidden" name="status" value="pending">
        </form>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
        <button type="submit" form="editTaskForm" class="btn btn-primary">Update Task</button>
      </div>
    </div>
  </div>
</div>
