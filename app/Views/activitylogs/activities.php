<a href="/" class="back-button">
    <i class="bi bi-arrow-left"></i>
    Back to Dashboard
</a>
<div class="card shadow-sm" id="pagination-container">
    <div class="card-header d-flex justify-content-between align-items-center bg-light text-dark">
        <h1 class="mb-0"><i class="bi bi-activity me-2"></i> <?= $title ?></h1>
    </div>

    <div class="card-body">
        <?php if (empty($activities)): ?>
            <div class="alert alert-dark text-center p-4">
                <div class="mb-3"><i class="bi bi-search fs-3"></i></div>
                <p class="mb-0"> No Activities Found. </p>
            </div>
        <?php else: ?>
            <div class="card">
                <div class="card-header text-dark">
                    <div class="row">
                        <div class="col-md-2">Date/Time</div>
                        <div class="col-md-4">Activity</div>
                        <div class="col-md-2">Rewards/Penalties</div>
                        <div class="col-md-2">Difficulty</div>
                        <div class="col-md-2">Category</div>
                    </div>
                </div>
                <div class="card-body p-0">
                    <?php if (empty($activities)): ?>
                        <div class="p-4 text-center">
                            <p class="mb-0">No activities recorded yet. Start completing tasks to see your progress!</p>
                        </div>
                    <?php else: ?>
                        <?php foreach ($paginator->items() as $activity): ?>
                            <div
                                class="activity-entry p-3 border-bottom <?= isset($activity['coins']) && $activity['xp'] == 0 ? 'bg-light-danger' : '' ?>">
                                <div class="row align-items-center">
                                    <!-- Date/Time -->
                                    <div class="col-md-2">
                                        <div class="small text-muted mb-1">
                                            <?= date('M d, Y', strtotime($activity['log_timestamp'])) ?>
                                        </div>
                                        <div class="small">
                                            <?= date('g:i A', strtotime($activity['log_timestamp'])) ?>
                                        </div>
                                    </div>

                                    <!-- Activity Title -->
                                    <div class="col-md-4">
                                        <h5 class="mb-1" style="font-family: 'Pixelify Sans', serif;">
                                            <?= htmlspecialchars($activity['task_title'] ?? $activity['activity_title'] ?? 'Unknown Activity') ?>
                                        </h5>
                                        <?php if (!empty($activity['description'])): ?>
                                            <p class="small mb-0"><?= htmlspecialchars($activity['description']) ?></p>
                                        <?php endif; ?>
                                    </div>

                                    <!-- Rewards/Penalties -->
                                    <div class="col-md-2">
                                        <?php if (isset($activity['coins']) && $activity['xp'] == 0): ?>
                                            <div class="text-danger">
                                                <i class="bi bi-x-circle"></i> N/A
                                            </div>
                                        <?php else: ?>
                                            <div class="text-success mb-1">
                                                <i class="bi bi-stars"></i> +<?= htmlspecialchars($activity['xp']) ?> XP
                                            </div>
                                            <div class="text-warning">
                                                <i class="bi bi-coin"></i> +<?= htmlspecialchars($activity['coins']) ?> Coins
                                            </div>
                                        <?php endif; ?>
                                    </div>

                                    <!-- Difficulty -->
                                    <div class="col-md-2">
                                        <?php
                                        $badgeClass = 'bg-secondary';
                                        if (!empty($activity['difficulty'])) {
                                            switch (strtolower($activity['difficulty'])) {
                                                case 'easy':
                                                    $badgeClass = 'bg-success';
                                                    break;
                                                case 'medium':
                                                    $badgeClass = 'bg-info';
                                                    break;
                                                case 'hard':
                                                    $badgeClass = 'bg-warning';
                                                    break;
                                                case 'extreme':
                                                    $badgeClass = 'bg-danger';
                                                    break;
                                            }
                                        }
                                        ?>
                                        <span class="badge <?= $badgeClass ?>">
                                            <?= htmlspecialchars(ucfirst($activity['difficulty'] ?? 'No Difficulty')) ?>
                                        </span>
                                    </div>

                                    <!-- Category -->
                                    <div class="col-md-2">
                                        <span class="badge bg-dark">
                                            <?= htmlspecialchars($activity['category'] ?? 'No Category') ?>
                                        </span>
                                    </div>
                                </div>
                            </div>
                        <?php endforeach; ?>
                        <?= $paginator->links() ?>
                    <?php endif; ?>
                </div>
            </div>
        <?php endif; ?>
    </div>
</div>

<style>
    .activity-entry:hover {
        background-color: rgba(0, 0, 0, 0.03);
    }

    .bg-light-danger {
        background-color: rgba(220, 53, 69, 0.1);
    }

    .btn-pixel {
        font-family: 'Pixelify Sans', serif;
        border-radius: 0;
        box-shadow: 3px 3px 0px rgba(0, 0, 0, 0.2);
        transition: all 0.2s ease;
    }

    .btn-pixel:hover {
        transform: translate(1px, 1px);
        box-shadow: 2px 2px 0px rgba(0, 0, 0, 0.3);
    }
</style>

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