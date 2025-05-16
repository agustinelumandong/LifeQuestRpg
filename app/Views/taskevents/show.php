<a href="/taskevents" class="back-button">
  <i class="bi bi-arrow-left"></i>
  Go to All Events
</a>
<div class="card shadow-sm">

  <div class="card-header d-flex justify-content-between align-items-center bg-light text-dark">
    <h1 class="mb-0"><i class="bi bi-trophy"></i> <?= $title ?></h1>
  </div>

  <div class="card-body">
    <?php if (empty($event)): ?>
      <div class="alert alert-info text-center p-4">
        <div class="mb-3"><i class="bi bi-search fs-3"></i></div>
        <p class="mb-0">No quests found. New adventures will appear here soon!</p>
      </div>
    <?php else: ?>
      <div class="taskShowSventCard card bg-white border-0 mb-4">
        <div class="card-header bg-white text-dark d-flex justify-content-between align-items-center ">
          <h2 class="h4 mb-0">
            <i class="bi bi-flag-fill me-2"></i><?= $event['event_name'] ?>
          </h2>
          <span class="badge bg-light text-dark"><?= $event['reward_xp'] ?> XP | <?= $event['reward_coins'] ?>
            <i class="bi bi-coin"></i>
          </span>
        </div>
        <div class="card-body">
          <p class=""><?= $event['event_description'] ?></p>
          <div class="row mb-4">
            <div class="col-md-2">
              <div class="d-flex align-items-center mb-2">
                <i class="bi bi-calendar-event me-2"></i>
                <span><strong>Starts:</strong> <?= date('F j, Y', strtotime($event['start_date'])); ?></span>
              </div>
            </div>
            <div class="col-md-2">
              <div class="d-flex align-items-center">
                <i class="bi bi-calendar-check me-2"></i>
                <span><strong>Ends:</strong> <?= date('F j, Y', strtotime($event['end_date'])); ?></span>
              </div>
            </div>
          </div>

          <?php if (isset($_GET['completion_success'])): ?>
            <div class="alert alert-success">
              <i class="bi bi-trophy me-2"></i> Congratulations! You've claimed your rewards!
            </div>
          <?php elseif (isset($_GET['completion_error'])): ?>
            <div class="alert alert-danger">
              <i class="bi bi-exclamation-triangle me-2"></i> There was an error marking this event as complete.
            </div>
          <?php elseif (isset($_GET['already_completed'])): ?>
            <div class="alert alert-secondary">
              <i class="bi bi-check-circle me-2"></i> You have already completed this event.
            </div>
          <?php else: ?>
            <?php if (!$userHasCompleted): ?>
              <form action="/taskevents/complete/<?= $event['id'] ?>" method="post" class="mb-3">
                <button type="submit" class="btn btn-dark btn-hover-effect">
                  <i class="bi bi-check-lg me-2"></i> Mark as Complete
                </button>
              </form>
            <?php else: ?>
              <button type="button" class="btn btn-secondary btn-sm" disabled></button>Completed</button>
            <?php endif; ?>
          <?php endif; ?>
        </div>
      </div>
    <?php endif; ?>
  </div>
</div>