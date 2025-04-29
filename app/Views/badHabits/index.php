<div class="container py-4">
    <!-- User Welcome Card -->

    <!-- Tasks Header -->
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h1 class="h3"><?= ucfirst($title) ?></h1>
        <button type="button" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#createTaskModal">
     <i class="fas fa-plus"></i> Create new Tasks
        </button>
    </div>

    <!-- Tasks List -->
    <?php if (empty($badHabits)): ?>
        <div class="alert alert-info">
            <i class="fas fa-info-circle"></i> No tasks found. Create your first task!
        </div>
    <?php else: ?>
        <div class="list-group">
            <?php foreach ($badHabits as $badHabit): ?>
                <div class="list-group-item d-flex justify-content-between align-items-center">
                    <div class="d-flex align-items-center">
                        <form action="/badHabits/<?= $badHabit['id'] ?>/toggle" method="POST" class="me-3">
                            <input type="checkbox" class="form-check-input" 
                                   onchange="this.form.submit()" 
                                   <?= $badHabit['status'] === 'completed' ? 'checked' : '' ?>>
                        </form>
                        <div>
                            <span class="<?= $badHabit['status'] === 'completed' ? 'text-decoration-line-through' : '' ?>">
                                <?= htmlspecialchars($badHabit['title']) ?>
                            </span>
                            <span class=" badge bg-secondary ms-2">
                                <?= ucfirst($badHabit['category']) ?>
                            </span>
                            <span class="badge bg-<?= \App\Core\Helpers::getDifficultyBadgeColor($badHabit['difficulty']) ?> ms-2">
                                <?= ucfirst($badHabit['difficulty']) ?>
                            </span>
                        </div>
                    </div>
                   
                    <div class="btn-group">

                    <button class="btn btn-sm btn-outline-primary edit-task-btn" type="button"
                         data-bs-toggle="modal"
                         data-bs-target="#editTaskModal"
                         data-task-id="<?= $badHabit['id'] ?>"
                         data-task-title="<?= htmlspecialchars($badHabit['title']) ?>"
                         data-task-category="<?= $badHabit['category'] ?>"
                         data-task-difficulty="<?= $badHabit['difficulty'] ?>"
                         data-form-action="/badHabits">        
                       <i class="fas fa-edit"></i> Edit
                    </button>

    <form action="/badHabits/<?= $badHabit['id'] ?>/delete" method="post" class="d-inline">
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
