<div class="container py-4">
    <!-- User Welcome Card -->

    <!-- Tasks Header -->
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h1 class="h3"><?= ucfirst($title) ?></h1>
        <button type="button" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#createTaskModal">
     <i class="fas fa-plus"></i> Create Good Habits
        </button>
    </div>

    <!-- Tasks List -->
    <?php if (empty($goodHabits)): ?>
        <div class="alert alert-info">
            <i class="fas fa-info-circle"></i> No tasks found. Create your first task!
        </div>
    <?php else: ?>
        <div class="list-group">
            <?php foreach ($goodHabits as $goodHabit): ?>
                <div class="list-group-item d-flex justify-content-between align-items-center">
                    <div class="d-flex align-items-center">
                    <form action="/goodHabits/<?= $goodHabit['id'] ?>/toggle" method="POST" class="me-3">
    <button type="submit" class="btn btn-sm btn-primary">   
            <i class="fas fa-check-circle"></i> Did
    </button>
</form>
                        <div>
                               <span>
                                <?= htmlspecialchars($goodHabit['title']) ?>
                             </span>
                            <span class=" badge bg-secondary ms-2">
                                <?= ucfirst($goodHabit['category']) ?>
                            </span>
                            <span class="badge bg-<?= \App\Core\Helpers::getDifficultyBadgeColor($goodHabit['difficulty']) ?> ms-2">
                                <?= ucfirst($goodHabit['difficulty']) ?>
                            </span>
                        </div>
                    </div>
                    <div class="btn-group">

                    <button class="btn btn-sm btn-outline-primary edit-task-btn" type="button"
                         data-bs-toggle="modal"
                         data-bs-target="#editTaskModal"
                         data-task-id="<?= $goodHabit['id'] ?>"
                         data-task-title="<?= htmlspecialchars($goodHabit['title']) ?>"
                         data-task-category="<?= $goodHabit['category'] ?>"
                         data-task-difficulty="<?= $goodHabit['difficulty'] ?>"
                         data-form-action="/goodHabits">        
                       <i class="fas fa-edit"></i> Edit
                    </button>

    <form action="/goodHabits/<?= $goodHabit['id'] ?>/delete" method="post" class="d-inline">
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