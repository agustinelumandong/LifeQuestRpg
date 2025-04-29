<div class="container py-4">
    <div class="mb-4">
        <a href="/journal/index" class="btn btn-outline-secondary">
            <i class="fas fa-arrow-left"></i> Back to Journal
        </a>
    </div>
    
    <div class="card">
        <div class="card-header bg-white">
            <h1 class="mb-0"><?= htmlspecialchars($journal['title']) ?></h1>
            <div class="text-muted mt-2">
                <i class="far fa-calendar"></i> <?= date('F j, Y', strtotime($journal['date'])) ?>
            </div>
        </div>
  <div class="card-body">
  <div class="journal-content">
    <?= $journal['content'] ?>
</div>
</div>
        <div class="card-footer bg-white d-flex justify-content-between">
            <div class="text-muted small">
                <i class="far fa-clock"></i> Created: <?= date('M j, Y g:i a', strtotime($journal['created_at'])) ?>
                <?php if ($journal['created_at'] != $journal['updated_at']): ?>
                    <br><i class="fas fa-pencil-alt"></i> Updated: <?= date('M j, Y g:i a', strtotime($journal['updated_at'])) ?>
                <?php endif; ?>
            </div>
            <div>
                <a href="/journal/<?= $journal['id'] ?>/edit" class="btn btn-sm btn-primary">
                    <i class="fas fa-edit"></i> Edit
                </a>
                <form action="/journal/<?= $journal['id'] ?>/delete" method="post" class="d-inline">
                <input type="hidden" name="_method" value="DELETE">
                    <button type="submit" class="btn btn-sm btn-danger" onclick="return confirm('Are you sure you want to delete this entry?')">
                        <i class="fas fa-trash"></i> Delete
                    </button>
                </form>
            </div>
        </div>
    </div>
</div>
