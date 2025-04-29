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

<?php 
// create
include __DIR__ . '/create.php'; 
?>

<?php 
//edit
include __DIR__ . '/edit.php'; 
?>