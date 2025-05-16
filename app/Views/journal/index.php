<div class="container py-4">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h1>My Journal</h1>
        <a href="/journal/create" class="btn btn-primary">
            <i class="fas fa-plus"></i> New Entry
        </a>
    </div>

    <?php if (empty($journals)): ?>
        <div class="alert alert-info">
            <i class="fas fa-info-circle"></i> No journal entries found. Create your first entry!
        </div>
    <?php else: ?>
        <div class="row row-cols-1 row-cols-md-2 g-5">
            <?php foreach ($journals as $journal): ?>
                <div class="col">
                    <div class="card h-100">
                        <div class="card-body">
                            <h5 class="card-title"><?= htmlspecialchars($journal['title']) ?></h5>
                            <hr>
                            <h6 class="card-subtitle mb-2 text-muted">
                                <?= date('F j, Y', strtotime($journal['date'])) ?>
                            </h6>

                        </div>
                        <div class="card-footer bg-transparent d-flex justify-content-end">
                            <a href="/journal/<?= $journal['id'] ?>/peek" class="btn btn-sm btn-outline-secondary me-2">
                                <i class="fas fa-book-open"></i> Read
                            </a>
                            <a href="/journal/<?= $journal['id'] ?>/edit" class="btn btn-sm btn-outline-primary me-2">
                                <i class="fas fa-edit"></i> Edit
                            </a>
                            <form action="/journal/<?= $journal['id'] ?>/delete" method="post" class="d-inline">
                                <input type="hidden" name="_method" value="DELETE">
                                <button type="submit" class="btn btn-sm btn-outline-danger"
                                    onclick="return confirm('Are you sure you want to delete this entry?')">
                                    <i class="fas fa-trash"></i> Delete
                                </button>
                            </form>
                        </div>
                    </div>
                </div>
            <?php endforeach; ?>
        </div>
    <?php endif; ?>
</div>