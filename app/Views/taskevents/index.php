<div>
  <a href="/" class="back-button">
    <i class="bi bi-arrow-left"></i>
    Back to Dashboard
  </a>

  <div class="card shadow-sm">
    <div class="card-header d-flex justify-content-between align-items-center bg-light text-dark">
      <h1 class="mb-0"><i class="bi bi-trophy"></i> <?= $title ?></h1>
      <?php if (\App\Core\Auth::isAdmin()): ?>
        <a class="btn btn-dark btn-hover-effect" href="/taskevents/create">+ Create Event</a>
      <?php endif; ?>
    </div>

    <div class="card-body">

      <?php if (empty($taskEvents)): ?>
        <div class="alert alert-info text-center p-4">
          <div class="mb-3"><i class="bi bi-search fs-3"></i></div>
          <p class="mb-0">No quests found. New adventures will appear here soon!</p>
        </div>
      <?php else: ?>
        <?php if (\App\Core\Auth::isAdmin()): ?>
          <div class="table-responsive game-table">
            <table class="table table-hover">
              <thead class="table-light border-bottom border-dark">
                <tr>
                  <th>Quest ID</th>
                  <th>Title</th>
                  <th>Description</th>
                  <th>Starts</th>
                  <th>Ends</th>
                  <th><i class="bi bi-stars"></i> XP</th>
                  <th><i class="bi bi-coin"></i> Coins</th>
                  <th>Status</th>
                  <th>Created</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                <?php foreach ($taskEvents as $taskEvent): ?>
                  <tr class="event-row">
                    <td class="fw-bold">#<?= $taskEvent['id'] ?></td>
                    <td class="fw-bold"><?= $taskEvent['event_name'] ?></td>
                    <td>
                      <div class="description-cell">
                        <?= (mb_strlen($taskEvent['event_description']) > 10) ? mb_substr($taskEvent['event_description'], 0, 10) . '...' : $taskEvent['event_description'] ?>
                      </div>
                    </td>
                    <td><?= date('m-d-y', strtotime($taskEvent['start_date'])) ?></td>
                    <td><?= date('m-d-y', strtotime($taskEvent['end_date'])) ?></td>
                    <td class="fw-bold text-success">+<?= $taskEvent['reward_xp'] ?></td>
                    <td class="fw-bold text-warning">+<?= $taskEvent['reward_coins'] ?></td>
                    <td>
                      <?php if ($taskEvent['status'] == 'active'): ?>
                        <span class="badge bg-success pulse-animation">Active</span>
                      <?php else: ?>
                        <span class="badge bg-danger">Inactive</span>
                      <?php endif; ?>
                    </td>
                    <td>
                      <?= isset($taskEvent['created_at']) ? \App\Core\Helpers::formatDate($taskEvent['created_at']) : '-' ?>
                    </td>
                    <td class="action-buttons">
                      <a href="/taskevents/<?= $taskEvent['id'] ?>/edit" class="btn btn-sm btn-outline-dark action-btn"><i
                          class="bi bi-pencil"></i></a>
                      <form action="/taskevents/<?= $taskEvent['id'] ?>" method="post" class="d-inline"
                        onsubmit="return confirm('Are you sure you want to delete this quest?')">
                        <input type="hidden" name="_method" value="DELETE">
                        <button type="submit" class="btn btn-sm btn-outline-danger action-btn"><i
                            class="bi bi-trash"></i></button>
                      </form>
                    </td>
                  </tr>
                <?php endforeach; ?>
              </tbody>
            </table>
          </div>
        <?php else: ?>
          <?php foreach ($taskEvents as $event): ?>
            <?php if ($event['status'] != 'active' || $event['end_date'] < date('Y-m-d H:i:s'))
              continue ?>
              <a href="/taskevents/<?= $event['id'] ?>" class="text-decoration-none">
              <div class="taskEventCard card bg-white border-0 mb-4">
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

                  <?php endif; ?>
                </div>
              </div>
            </a>
          <?php endforeach; ?>
        <?php endif; ?>
      <?php endif; ?>
    </div>
  </div>
</div>