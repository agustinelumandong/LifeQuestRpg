<div class="admin-dashboard">
  <div class="container-fluid">
    <h1 class="display-5 fw-bold mb-4 fade-in" style="font-family: 'Pixelify Sans', serif;">Admin Dashboard</h1>

    <!-- Main Stats Overview -->
    <div class="row g-4 mb-4 fade-in">
      <div class="col-12 col-md-6 col-lg-3">
        <div class="stat-card primary">
          <p>Total Users</p>
          <h3><?= $stats['total_users'] ?></h3>
          <?php if (isset($stats['user_growth'])): ?>
            <div class="badge">
              <?= $stats['user_growth'] >= 0 ? '↑' : '↓' ?>   <?= abs($stats['user_growth']) ?>%
            </div>
          <?php endif; ?>
          <div class="icon">
            <i class="bi bi-people"></i>
          </div>
        </div>
      </div>

      <div class="col-12 col-md-6 col-lg-3">
        <div class="stat-card success">
          <p>Total Tasks</p>
          <h3><?= $stats['total_tasks'] ?></h3>
          <div class="mt-2">
            <small><?= ceil($stats['total_tasks'] / max(1, $stats['total_users'])) ?> tasks per user avg.</small>
          </div>
          <div class="icon">
            <i class="bi bi-check2-square"></i>
          </div>
        </div>
      </div>

      <div class="col-12 col-md-6 col-lg-3">
        <div class="stat-card warning">
          <p>Task Events</p>
          <h3><?= $stats['task_events'] ?></h3>
          <div class="mt-2">
            <small>Missions available</small>
          </div>
          <div class="icon">
            <i class="bi bi-flag"></i>
          </div>
        </div>
      </div>

      <div class="col-12 col-md-6 col-lg-3">
        <div class="stat-card danger">
          <p>Marketplace Items</p>
          <h3><?= $stats['marketplace_items'] ?></h3>
          <div class="mt-2">
            <small>Available rewards</small>
          </div>
          <div class="icon">
            <i class="bi bi-shop"></i>
          </div>
        </div>
      </div>
    </div>
    <!-- Task Type Distribution -->
    <div class="row g-4 mb-4 fade-in">
      <div class="col-md-6">
        <div class="admin-card">
          <h2 class="card-title mb-4">Task Distribution</h2>
          <div class="progress-container">
            <div class="progress-label">
              <span>One-Time Tasks</span>
              <span class="badge bg-primary rounded-pill"><?= $stats['total_tasks'] ?></span>
            </div>
            <div class="progress">
              <div class="progress-bar bg-primary" role="progressbar"
                style="width: <?= min(100, ($stats['total_tasks'] / max(1, $stats['total_tasks'] + $stats['daily_tasks'] + $stats['good_habits'] + $stats['bad_habits'])) * 100) ?>%"
                aria-valuenow="<?= $stats['total_tasks'] ?>" aria-valuemin="0" aria-valuemax="100"></div>
            </div>
          </div>

          <div class="progress-container mt-4">
            <div class="progress-label">
              <span>Daily Tasks</span>
              <span class="badge bg-success rounded-pill"><?= $stats['daily_tasks'] ?></span>
            </div>
            <div class="progress">
              <div class="progress-bar bg-success" role="progressbar"
                style="width: <?= min(100, ($stats['daily_tasks'] / max(1, $stats['total_tasks'] + $stats['daily_tasks'] + $stats['good_habits'] + $stats['bad_habits'])) * 100) ?>%"
                aria-valuenow="<?= $stats['daily_tasks'] ?>" aria-valuemin="0" aria-valuemax="100"></div>
            </div>
          </div>

          <div class="progress-container mt-4">
            <div class="progress-label">
              <span>Good Habits</span>
              <span class="badge bg-info rounded-pill"><?= $stats['good_habits'] ?></span>
            </div>
            <div class="progress">
              <div class="progress-bar bg-info" role="progressbar"
                style="width: <?= min(100, ($stats['good_habits'] / max(1, $stats['total_tasks'] + $stats['daily_tasks'] + $stats['good_habits'] + $stats['bad_habits'])) * 100) ?>%"
                aria-valuenow="<?= $stats['good_habits'] ?>" aria-valuemin="0" aria-valuemax="100"></div>
            </div>
          </div>

          <div class="progress-container mt-4">
            <div class="progress-label">
              <span>Bad Habits</span>
              <span class="badge bg-danger rounded-pill"><?= $stats['bad_habits'] ?></span>
            </div>
            <div class="progress">
              <div class="progress-bar bg-danger" role="progressbar"
                style="width: <?= min(100, ($stats['bad_habits'] / max(1, $stats['total_tasks'] + $stats['daily_tasks'] + $stats['good_habits'] + $stats['bad_habits'])) * 100) ?>%"
                aria-valuenow="<?= $stats['bad_habits'] ?>" aria-valuemin="0" aria-valuemax="100"></div>
            </div>
          </div>
        </div>
      </div>

      <div class="col-md-6">
        <div class="admin-card">
          <h2 class="card-title mb-4">System Overview</h2>
          <div class="row g-3">
            <div class="col-6">
              <div class="d-flex align-items-center p-3 border rounded">
                <div class="icon-box me-3 rounded-circle bg-light p-3">
                  <i class="bi bi-people text-primary"></i>
                </div>
                <div>
                  <div class="small text-muted">Total Users</div>
                  <div class="fs-4 fw-bold"><?= $stats['total_users'] ?></div>
                </div>
              </div>
            </div>

            <div class="col-6">
              <div class="d-flex align-items-center p-3 border rounded">
                <div class="icon-box me-3 rounded-circle bg-light p-3">
                  <i class="bi bi-check2-all text-success"></i>
                </div>
                <div>
                  <div class="small text-muted">Tasks</div>
                  <div class="fs-4 fw-bold"><?= $stats['total_tasks'] ?></div>
                </div>
              </div>
            </div>

            <div class="col-6">
              <div class="d-flex align-items-center p-3 border rounded">
                <div class="icon-box me-3 rounded-circle bg-light p-3">
                  <i class="bi bi-calendar-check text-warning"></i>
                </div>
                <div>
                  <div class="small text-muted">Daily Tasks</div>
                  <div class="fs-4 fw-bold"><?= $stats['daily_tasks'] ?></div>
                </div>
              </div>
            </div>

            <div class="col-6">
              <div class="d-flex align-items-center p-3 border rounded">
                <div class="icon-box me-3 rounded-circle bg-light p-3">
                  <i class="bi bi-emoji-smile text-info"></i>
                </div>
                <div>
                  <div class="small text-muted">Good Habits</div>
                  <div class="fs-4 fw-bold"><?= $stats['good_habits'] ?></div>
                </div>
              </div>
            </div>

            <div class="col-6">
              <div class="d-flex align-items-center p-3 border rounded">
                <div class="icon-box me-3 rounded-circle bg-light p-3">
                  <i class="bi bi-emoji-frown text-danger"></i>
                </div>
                <div>
                  <div class="small text-muted">Bad Habits</div>
                  <div class="fs-4 fw-bold"><?= $stats['bad_habits'] ?></div>
                </div>
              </div>
            </div>

            <div class="col-6">
              <div class="d-flex align-items-center p-3 border rounded">
                <div class="icon-box me-3 rounded-circle bg-light p-3">
                  <i class="bi bi-flag text-warning"></i>
                </div>
                <div>
                  <div class="small text-muted">Events</div>
                  <div class="fs-4 fw-bold"><?= $stats['task_events'] ?></div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="row g-4 fade-in">
      <!-- Recent Users -->
      <div class="col-md-4">
        <div class="admin-card h-100">
          <div class="d-flex justify-content-between align-items-center mb-4">
            <h2 class="card-title mb-0">Recent Users</h2>
            <i class="bi bi-people text-primary"></i>
          </div>
          <?php if (count($recentUsers) > 0): ?>
            <div class="list-group list-group-flush">
              <?php foreach ($recentUsers as $user): ?>
                <div class="list-group-item px-0 py-3 border-bottom">
                  <div class="d-flex justify-content-between">
                    <div class="d-flex align-items-center">
                      <div class="avatar-circle bg-light me-3 text-primary">
                        <i class="bi bi-person"></i>
                      </div>
                      <div>
                        <h6 class="mb-0"><?= htmlspecialchars($user['username'] ?? 'Unknown User') ?></h6>
                        <small class="text-muted"><?= htmlspecialchars($user['email'] ?? '') ?></small>
                      </div>
                    </div>
                    <span class="badge bg-light text-dark">
                      <?= isset($user['created_at']) ? date('M j, Y', strtotime($user['created_at'])) : 'Unknown' ?>
                    </span>
                  </div>
                </div>
              <?php endforeach; ?>
            </div>
            <div class="mt-3 text-end">
              <a href="/admin/users" class="btn btn-sm btn-outline-primary">View All Users <i
                  class="bi bi-arrow-right"></i></a>
            </div>
          <?php else: ?>
            <div class="alert alert-info">No recent user registrations.</div>
          <?php endif; ?>
        </div>
      </div>

      <!-- Recent Activity -->
      <div class="col-md-4">
        <div class="admin-card h-100">
          <div class="d-flex justify-content-between align-items-center mb-4">
            <h2 class="card-title mb-0">Recent Activity</h2>
            <i class="bi bi-activity text-success"></i>
          </div>
          <?php if (count($recentActivity) > 0): ?>
            <div class="activity-feed">
              <?php foreach ($recentActivity as $activity): ?>
                <div class="activity-item">
                  <div class="activity-icon">
                    <i class="bi bi-lightning-charge"></i>
                  </div>
                  <div class="activity-content">
                    <div class="d-flex justify-content-between">
                      <h6 class="mb-0"><?= htmlspecialchars($activity['activity_type'] ?? 'Unknown') ?></h6>
                      <span class="activity-time">
                        <?= isset($activity['log_timestamp']) ? date('M j, H:i', strtotime($activity['log_timestamp'])) : 'Unknown' ?>
                      </span>
                    </div>
                    <p class="mb-0 text-muted small">User ID: <?= $activity['user_id'] ?? 'N/A' ?></p>
                  </div>
                </div>
              <?php endforeach; ?>
            </div>
            <div class="mt-3 text-end">
              <a href="/activityLog/index" class="btn btn-sm btn-outline-success">View All Activity <i
                  class="bi bi-arrow-right"></i></a>
            </div>
          <?php else: ?>
            <div class="alert alert-info">No recent activity.</div>
          <?php endif; ?>
        </div>
      </div>

      <!-- System Health -->
      <div class="col-md-4">
        <div class="admin-card h-100">
          <div class="d-flex justify-content-between align-items-center mb-4">
            <h2 class="card-title mb-0">System Health</h2>
            <i class="bi bi-speedometer2 text-warning"></i>
          </div>

          <div class="health-indicator">
            <span>Server Load</span>
            <div class="health-status">
              <span class="dot green"></span>
              <span class="text-success fw-medium">Optimal</span>
            </div>
          </div>
          <div class="progress mb-3" style="height: 8px;">
            <div class="progress-bar bg-success" role="progressbar" style="width: 25%" aria-valuenow="25"
              aria-valuemin="0" aria-valuemax="100"></div>
          </div>

          <div class="health-indicator">
            <span>Database Status</span>
            <div class="health-status">
              <span class="dot green"></span>
              <span class="text-success fw-medium">Connected</span>
            </div>
          </div>
          <div class="progress mb-3" style="height: 8px;">
            <div class="progress-bar bg-success" role="progressbar" style="width: 100%" aria-valuenow="100"
              aria-valuemin="0" aria-valuemax="100"></div>
          </div>

          <div class="health-indicator">
            <span>Memory Usage</span>
            <div class="health-status">
              <span class="dot yellow"></span>
              <span class="text-warning fw-medium">Moderate</span>
            </div>
          </div>
          <div class="progress mb-3" style="height: 8px;">
            <div class="progress-bar bg-warning" role="progressbar" style="width: 65%" aria-valuenow="65"
              aria-valuemin="0" aria-valuemax="100"></div>
          </div>

          <div class="health-indicator">
            <span>Storage</span>
            <div class="health-status">
              <span class="dot green"></span>
              <span class="text-success fw-medium">72% Free</span>
            </div>
          </div>
          <div class="progress mb-3" style="height: 8px;">
            <div class="progress-bar bg-success" role="progressbar" style="width: 28%" aria-valuenow="28"
              aria-valuemin="0" aria-valuemax="100"></div>
          </div>

          <div class="text-end mt-4">
            <button type="button" class="btn btn-sm btn-outline-primary">
              <i class="bi bi-arrow-clockwise me-1"></i> Refresh Status
            </button>
          </div>
        </div>
      </div>
    </div>
    <div class="row mt-4 mb-3 fade-in">
      <div class="col-12">
        <div class="admin-card">
          <div class="d-flex justify-content-between align-items-center mb-4">
            <h2 class="card-title mb-0">Quick Actions</h2>
            <div class="badge bg-primary">Admin Tools</div>
          </div>
          <div class="row g-4">
            <div class="col-md-3">
              <a href="/taskevents/create" class="action-card text-decoration-none bg-success bg-opacity-10">
                <div class="icon text-success">
                  <i class="bi bi-flag"></i>
                </div>
                <h5 class="title text-success">Create Task Event</h5>
                <p class="subtitle text-success">Add new quests/missions</p>
              </a>
            </div>

            <div class="col-md-3">
              <a href="/marketplace/create" class="action-card text-decoration-none bg-primary bg-opacity-10">
                <div class="icon text-primary">
                  <i class="bi bi-bag-plus"></i>
                </div>
                <h5 class="title text-primary">Add Marketplace Item</h5>
                <p class="subtitle text-primary">Create new rewards</p>
              </a>
            </div>

            <div class="col-md-3">
              <a href="/admin/users" class="action-card text-decoration-none bg-info bg-opacity-10">
                <div class="icon text-info">
                  <i class="bi bi-people-fill"></i>
                </div>
                <h5 class="title text-info">Manage Users</h5>
                <p class="subtitle text-info">Review and edit users</p>
              </a>
            </div>

            <div class="col-md-3">
              <a href="/admin/analytics" class="action-card text-decoration-none bg-warning bg-opacity-10">
                <div class="icon text-warning">
                  <i class="bi bi-graph-up"></i>
                </div>
                <h5 class="title text-warning">View Analytics</h5>
                <p class="subtitle text-warning">Check system performance</p>
              </a>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- Add custom style for avatar circles used in user list -->
  <style>
    .avatar-circle {
      width: 40px;
      height: 40px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 18px;
    }
  </style>
</div>