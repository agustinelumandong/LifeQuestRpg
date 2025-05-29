<div class="admin-dashboard">
  <div class="container-fluid">
    <h1 class="display-5 fw-bold mb-4 fade-in" style="font-family: 'Pixelify Sans', serif;">Content Management</h1>


    <!-- Content Categories Navigation -->
    <div class="admin-nav mb-4">
      <a href="#task-events" class="active">Task Events</a>
      <a href="#achievements">Achievements</a>
      <a href="#badges">Badges & Rewards</a>
      <a href="#quest-templates">Quest Templates</a>
    </div> <!-- Task Events Section -->
    <div id="task-events" class="mb-4">
      <div class="admin-card">
        <div class="d-flex justify-content-between align-items-center mb-3">
          <div>
            <h2 class="h3" style="font-family: 'Pixelify Sans', serif;">Task Events (Quests/Missions)</h2>
            <p class="text-muted">Create and manage special tasks and mission events for users</p>
          </div>
          <button class="rpg-btn rpg-btn-success" data-bs-toggle="modal" data-bs-target="#addEventModal">
            <i class="bi bi-plus-circle me-1"></i> Add New Event
          </button>
        </div>

        <div id="pagination-content">
          <!-- Search & Filter Controls -->
          <div class="row mb-3">
            <div class="col-md-8 mb-3 mb-md-0">
              <div class="input-group">
                <span class="input-group-text">
                  <i class="bi bi-search"></i>
                </span>
                <input type="text" class="form-control rpg-form-control" placeholder="Search events...">
                <button class="rpg-btn">Search</button>
              </div>
            </div>
            <div class="col-md-4">
              <select class="form-select rpg-form-select">
                <option>All Event Types</option>
                <option>Daily Quest</option>
                <option>Weekly Challenge</option>
                <option>Special Event</option>
                <option>Seasonal Quest</option>
              </select>
            </div>
          </div>

          <!-- Task Events Table -->
          <div class="table-responsive game-table">
            <table class="table rpg-table table-hover">
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
                <?php if (count($taskEvents) > 0): ?>
                  <?php foreach ($taskEvents as $event): ?>
                    <tr class="event-row">
                      <td class="fw-bold">#<?= $event['id'] ?></td>
                      <td class="fw-bold"><?= $event['event_name'] ?></td>
                      <td>
                        <div class="description-cell">
                          <?= (mb_strlen($event['event_description']) > 10) ? mb_substr($event['event_description'], 0, 10) . '...' : $event['event_description'] ?>
                        </div>
                      </td>
                      <td><?= date('m-d-y', strtotime($event['start_date'])) ?></td>
                      <td><?= date('m-d-y', strtotime($event['end_date'])) ?></td>
                      <td class="fw-bold text-success">+<?= $event['reward_xp'] ?></td>
                      <td class="fw-bold text-warning">+<?= $event['reward_coins'] ?></td>
                      <td>
                        <?php if ($event['status'] == 'active'): ?>
                          <span class="badge bg-success pulse-animation">Active</span>
                        <?php else: ?>
                          <span class="badge bg-danger">Inactive</span>
                        <?php endif; ?>
                      </td>
                      <td>
                        <?= isset($event['created_at']) ? \App\Core\Helpers::formatDate($event['created_at']) : '-' ?>
                      </td>
                      <td class="action-buttons">
                        <a href="/taskevents/<?= $event['id'] ?>/edit" class="btn btn-sm btn-outline-dark action-btn"><i
                            class="bi bi-pencil"></i></a>
                        <form action="/taskevents/<?= $event['id'] ?>" method="post" class="d-inline"
                          onsubmit="return confirm('Are you sure you want to delete this quest?')">
                          <input type="hidden" name="_method" value="DELETE">
                          <button type="submit" class="btn btn-sm btn-outline-danger action-btn"><i
                              class="bi bi-trash"></i></button>
                        </form>
                      </td>
                    </tr>
                  <?php endforeach; ?>
                <?php else: ?>
                  <tr>
                    <td colspan="10" class="text-center">
                      <div class="alert alert-info text-center p-4">
                        <div class="mb-3"><i class="bi bi-search fs-3"></i></div>
                        <p class="mb-0">No quests found. New adventures will appear here soon!</p>
                      </div>
                    </td>
                  </tr>
                <?php endif; ?>
              </tbody>
            </table>
          </div>

          <!-- Pagination -->
          <?php if (isset($paginator) && method_exists($paginator, 'links')): ?>
            <div class="mt-4">
              <?= $paginator->setTheme('game')->links() ?>
            </div>
          <?php endif; ?>
        </div>
      </div>
    </div>

    <!-- Achievements Section -->
    <div id="achievements" class="mb-4">
      <div class="admin-card">
        <div class="d-flex justify-content-between align-items-center mb-3">
          <div>
            <h2 class="h3" style="font-family: 'Pixelify Sans', serif;">Achievements</h2>
            <p class="text-muted">Manage user achievements and unlock conditions</p>
          </div>
          <button class="rpg-btn rpg-btn-success" data-bs-toggle="modal" data-bs-target="#addAchievementModal">
            <i class="bi bi-trophy me-1"></i> Add Achievement
          </button>
        </div>

        <div class="row">
          <!-- Achievement Card 1 -->
          <div class="col-md-4 mb-4">
            <div class="admin-card h-100">
              <div class="p-3 bg-light rounded">
                <div class="d-flex justify-content-between align-items-start">
                  <div class="d-flex align-items-center">
                    <div class="p-2 rounded-circle bg-primary-100 me-3">
                      <i class="bi bi-stars text-primary"></i>
                    </div>
                    <h3 class="h5 mb-0" style="font-family: 'Pixelify Sans', serif;">Task Master</h3>
                  </div>
                  <div class="dropdown">
                    <button class="btn btn-sm rpg-btn-outline dropdown-toggle" type="button" data-bs-toggle="dropdown"
                      aria-expanded="false">
                      <i class="bi bi-three-dots-vertical"></i>
                    </button>
                    <ul class="dropdown-menu">
                      <li><a class="dropdown-item" href="#"><i class="bi bi-pencil me-2"></i> Edit</a></li>
                      <li><a class="dropdown-item" href="#"><i class="bi bi-trash me-2"></i> Delete</a></li>
                    </ul>
                  </div>
                </div>
              </div>
              <div class="p-3">
                <p class="mb-3">Complete a specific number of tasks to unlock different tiers</p>
                <div class="d-flex gap-2 flex-wrap mb-3">
                  <span class="rpg-badge rpg-badge-primary">Tasks</span>
                  <span class="rpg-badge rpg-badge-dark">Progression</span>
                </div>
                <div class="border-top pt-3">
                  <small class="text-muted">
                    <span class="fw-medium">Tiers:</span> 10, 50, 100, 500, 1000 tasks
                  </small>
                </div>
              </div>
            </div>
          </div>

          <!-- Achievement Card 2 -->
          <div class="col-md-4 mb-4">
            <div class="admin-card h-100">
              <div class="p-3 bg-light rounded">
                <div class="d-flex justify-content-between align-items-start">
                  <div class="d-flex align-items-center">
                    <div class="p-2 rounded-circle bg-purple-100 me-3">
                      <i class="bi bi-calendar-check text-purple"></i>
                    </div>
                    <h3 class="h5 mb-0" style="font-family: 'Pixelify Sans', serif;">Habit Champion</h3>
                  </div>
                  <div class="dropdown">
                    <button class="btn btn-sm rpg-btn-outline dropdown-toggle" type="button" data-bs-toggle="dropdown"
                      aria-expanded="false">
                      <i class="bi bi-three-dots-vertical"></i>
                    </button>
                    <ul class="dropdown-menu">
                      <li><a class="dropdown-item" href="#"><i class="bi bi-pencil me-2"></i> Edit</a></li>
                      <li><a class="dropdown-item" href="#"><i class="bi bi-trash me-2"></i> Delete</a></li>
                    </ul>
                  </div>
                </div>
              </div>
              <div class="p-3">
                <p class="mb-3">Awarded for maintaining good habits consistently</p>
                <div class="d-flex gap-2 flex-wrap mb-3">
                  <span class="rpg-badge rpg-badge-purple">Good Habits</span>
                  <span class="rpg-badge rpg-badge-primary">Streaks</span>
                </div>
                <div class="border-top pt-3">
                  <small class="text-muted">
                    <span class="fw-medium">Tiers:</span> 7-day, 30-day, 90-day, 365-day streaks
                  </small>
                </div>
              </div>
            </div>
          </div>

          <!-- Achievement Card 3 -->
          <div class="col-md-4 mb-4">
            <div class="admin-card h-100">
              <div class="p-3 bg-light rounded">
                <div class="d-flex justify-content-between align-items-start">
                  <div class="d-flex align-items-center">
                    <div class="p-2 rounded-circle bg-success-100 me-3">
                      <i class="bi bi-lightning-charge text-success"></i>
                    </div>
                    <h3 class="h5 mb-0" style="font-family: 'Pixelify Sans', serif;">Quest Hero</h3>
                  </div>
                  <div class="dropdown">
                    <button class="btn btn-sm rpg-btn-outline dropdown-toggle" type="button" data-bs-toggle="dropdown"
                      aria-expanded="false">
                      <i class="bi bi-three-dots-vertical"></i>
                    </button>
                    <ul class="dropdown-menu">
                      <li><a class="dropdown-item" href="#"><i class="bi bi-pencil me-2"></i> Edit</a></li>
                      <li><a class="dropdown-item" href="#"><i class="bi bi-trash me-2"></i> Delete</a></li>
                    </ul>
                  </div>
                </div>
              </div>
              <div class="p-3">
                <p class="mb-3">Complete special quests and missions</p>
                <div class="d-flex gap-2 flex-wrap mb-3">
                  <span class="rpg-badge rpg-badge-success">Quests</span>
                  <span class="rpg-badge rpg-badge-warning">Special Events</span>
                </div>
                <div class="border-top pt-3">
                  <small class="text-muted">
                    <span class="fw-medium">Tiers:</span> Bronze, Silver, Gold, Platinum
                  </small>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="text-center mt-3">
          <button class="rpg-btn rpg-btn-outline">
            <i class="bi bi-arrow-down me-1"></i> Load More
          </button>
        </div>
      </div>
    </div>

    <!-- Badges & Rewards Section -->
    <div id="badges" class="mb-4">
      <div class="admin-card">
        <div class="d-flex justify-content-between align-items-center mb-3">
          <div>
            <h2 class="h3" style="font-family: 'Pixelify Sans', serif;">Badges & Rewards</h2>
            <p class="text-muted">Manage badges, rewards and virtual items that users can earn</p>
          </div>
          <button class="rpg-btn rpg-btn-success" data-bs-toggle="modal" data-bs-target="#addBadgeModal">
            <i class="bi bi-award me-1"></i> Add Badge/Reward
          </button>
        </div>

        <div class="row">
          <!-- Badge Card 1 -->
          <div class="col-md-3 mb-4">
            <div class="admin-card h-100 text-center">
              <div class="badge-icon mb-3 mx-auto">
                <i class="bi bi-star-fill fs-1 text-warning"></i>
              </div>
              <h4 class="h5 mb-2" style="font-family: 'Pixelify Sans', serif;">Gold Star</h4>
              <p class="small mb-3">Awarded for completing 50 tasks</p>
              <div class="d-flex justify-content-around mb-2">
                <span class="rpg-badge rpg-badge-warning">+50 XP</span>
                <span class="rpg-badge rpg-badge-dark">Uncommon</span>
              </div>
              <div class="mt-auto pt-3 border-top">
                <div class="d-flex justify-content-center gap-2">
                  <button class="btn btn-sm rpg-btn-outline"><i class="bi bi-pencil"></i></button>
                  <button class="btn btn-sm rpg-btn-outline text-danger"><i class="bi bi-trash"></i></button>
                </div>
              </div>
            </div>
          </div>

          <!-- Badge Card 2 -->
          <div class="col-md-3 mb-4">
            <div class="admin-card h-100 text-center">
              <div class="badge-icon mb-3 mx-auto">
                <i class="bi bi-shield-fill-check fs-1 text-primary"></i>
              </div>
              <h4 class="h5 mb-2" style="font-family: 'Pixelify Sans', serif;">Defender</h4>
              <p class="small mb-3">Break 5 bad habits in succession</p>
              <div class="d-flex justify-content-around mb-2">
                <span class="rpg-badge rpg-badge-primary">+75 XP</span>
                <span class="rpg-badge rpg-badge-dark">Rare</span>
              </div>
              <div class="mt-auto pt-3 border-top">
                <div class="d-flex justify-content-center gap-2">
                  <button class="btn btn-sm rpg-btn-outline"><i class="bi bi-pencil"></i></button>
                  <button class="btn btn-sm rpg-btn-outline text-danger"><i class="bi bi-trash"></i></button>
                </div>
              </div>
            </div>
          </div>

          <!-- Badge Card 3 -->
          <div class="col-md-3 mb-4">
            <div class="admin-card h-100 text-center">
              <div class="badge-icon mb-3 mx-auto">
                <i class="bi bi-trophy-fill fs-1 text-success"></i>
              </div>
              <h4 class="h5 mb-2" style="font-family: 'Pixelify Sans', serif;">Champion</h4>
              <p class="small mb-3">Reach level 10 in any skill area</p>
              <div class="d-flex justify-content-around mb-2">
                <span class="rpg-badge rpg-badge-success">+100 XP</span>
                <span class="rpg-badge rpg-badge-dark">Epic</span>
              </div>
              <div class="mt-auto pt-3 border-top">
                <div class="d-flex justify-content-center gap-2">
                  <button class="btn btn-sm rpg-btn-outline"><i class="bi bi-pencil"></i></button>
                  <button class="btn btn-sm rpg-btn-outline text-danger"><i class="bi bi-trash"></i></button>
                </div>
              </div>
            </div>
          </div>

          <!-- Badge Card 4 -->
          <div class="col-md-3 mb-4">
            <div class="admin-card h-100 text-center">
              <div class="badge-icon mb-3 mx-auto">
                <i class="bi bi-gem fs-1 text-purple"></i>
              </div>
              <h4 class="h5 mb-2" style="font-family: 'Pixelify Sans', serif;">Dragon Slayer</h4>
              <p class="small mb-3">Complete the ultimate challenge quest</p>
              <div class="d-flex justify-content-around mb-2">
                <span class="rpg-badge rpg-badge-purple">+500 XP</span>
                <span class="rpg-badge rpg-badge-dark">Legendary</span>
              </div>
              <div class="mt-auto pt-3 border-top">
                <div class="d-flex justify-content-center gap-2">
                  <button class="btn btn-sm rpg-btn-outline"><i class="bi bi-pencil"></i></button>
                  <button class="btn btn-sm rpg-btn-outline text-danger"><i class="bi bi-trash"></i></button>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="text-center mt-3">
          <button class="rpg-btn rpg-btn-outline">
            <i class="bi bi-arrow-down me-1"></i> Load More
          </button>
        </div>
      </div>
    </div>

    <!-- Quest Templates Section -->
    <div id="quest-templates" class="mb-4">
      <div class="admin-card">
        <div class="d-flex justify-content-between align-items-center mb-3">
          <div>
            <h2 class="h3" style="font-family: 'Pixelify Sans', serif;">Quest Templates</h2>
            <p class="text-muted">Create and manage quest templates for easy quest generation</p>
          </div>
          <button class="rpg-btn rpg-btn-success" data-bs-toggle="modal" data-bs-target="#addQuestTemplateModal">
            <i class="bi bi-file-earmark-plus me-1"></i> Add Quest Template
          </button>
        </div>

        <div class="table-responsive">
          <table class="table rpg-table">
            <thead>
              <tr>
                <th>Template Name</th>
                <th>Quest Type</th>
                <th>Difficulty</th>
                <th>XP Range</th>
                <th>Gold Range</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              <!-- Quest Template 1 -->
              <tr>
                <td>
                  <div class="d-flex align-items-center">
                    <div class="p-2 rounded me-2 bg-success-100">
                      <i class="bi bi-book text-success"></i>
                    </div>
                    <div>
                      <div class="fw-medium">Study Session</div>
                      <small class="text-muted">Focus on academic studies</small>
                    </div>
                  </div>
                </td>
                <td><span class="rpg-badge rpg-badge-primary">Daily</span></td>
                <td><span class="rpg-badge rpg-badge-success">Easy</span></td>
                <td>10-20 XP</td>
                <td>5-15 Gold</td>
                <td>
                  <div class="action-cell">
                    <button class="btn btn-sm rpg-btn-outline" title="Edit">
                      <i class="bi bi-pencil-fill"></i>
                    </button>
                    <button class="btn btn-sm rpg-btn-outline" title="Duplicate">
                      <i class="bi bi-files"></i>
                    </button>
                    <button class="btn btn-sm rpg-btn-outline text-danger" title="Delete">
                      <i class="bi bi-trash-fill"></i>
                    </button>
                  </div>
                </td>
              </tr>

              <!-- Quest Template 2 -->
              <tr>
                <td>
                  <div class="d-flex align-items-center">
                    <div class="p-2 rounded me-2 bg-warning-100">
                      <i class="bi bi-person-arms-up text-warning"></i>
                    </div>
                    <div>
                      <div class="fw-medium">Workout Challenge</div>
                      <small class="text-muted">Physical exercise routine</small>
                    </div>
                  </div>
                </td>
                <td><span class="rpg-badge rpg-badge-warning">Challenge</span></td>
                <td><span class="rpg-badge rpg-badge-warning">Medium</span></td>
                <td>30-50 XP</td>
                <td>20-35 Gold</td>
                <td>
                  <div class="action-cell">
                    <button class="btn btn-sm rpg-btn-outline" title="Edit">
                      <i class="bi bi-pencil-fill"></i>
                    </button>
                    <button class="btn btn-sm rpg-btn-outline" title="Duplicate">
                      <i class="bi bi-files"></i>
                    </button>
                    <button class="btn btn-sm rpg-btn-outline text-danger" title="Delete">
                      <i class="bi bi-trash-fill"></i>
                    </button>
                  </div>
                </td>
              </tr>

              <!-- Quest Template 3 -->
              <tr>
                <td>
                  <div class="d-flex align-items-center">
                    <div class="p-2 rounded me-2 bg-danger-100">
                      <i class="bi bi-dragon text-danger"></i>
                    </div>
                    <div>
                      <div class="fw-medium">Epic Project</div>
                      <small class="text-muted">Long-term complex project</small>
                    </div>
                  </div>
                </td>
                <td><span class="rpg-badge rpg-badge-danger">Epic</span></td>
                <td><span class="rpg-badge rpg-badge-danger">Hard</span></td>
                <td>100-200 XP</td>
                <td>75-150 Gold</td>
                <td>
                  <div class="action-cell">
                    <button class="btn btn-sm rpg-btn-outline" title="Edit">
                      <i class="bi bi-pencil-fill"></i>
                    </button>
                    <button class="btn btn-sm rpg-btn-outline" title="Duplicate">
                      <i class="bi bi-files"></i>
                    </button>
                    <button class="btn btn-sm rpg-btn-outline text-danger" title="Delete">
                      <i class="bi bi-trash-fill"></i>
                    </button>
                  </div>
                </td>
              </tr>

              <!-- Quest Template 4 -->
              <tr>
                <td>
                  <div class="d-flex align-items-center">
                    <div class="p-2 rounded me-2 bg-purple-100">
                      <i class="bi bi-stars text-purple"></i>
                    </div>
                    <div>
                      <div class="fw-medium">Seasonal Event</div>
                      <small class="text-muted">Special limited time challenge</small>
                    </div>
                  </div>
                </td>
                <td><span class="rpg-badge rpg-badge-purple">Seasonal</span></td>
                <td><span class="rpg-badge rpg-badge-warning">Medium</span></td>
                <td>50-100 XP</td>
                <td>40-80 Gold</td>
                <td>
                  <div class="action-cell">
                    <button class="btn btn-sm rpg-btn-outline" title="Edit">
                      <i class="bi bi-pencil-fill"></i>
                    </button>
                    <button class="btn btn-sm rpg-btn-outline" title="Duplicate">
                      <i class="bi bi-files"></i>
                    </button>
                    <button class="btn btn-sm rpg-btn-outline text-danger" title="Delete">
                      <i class="bi bi-trash-fill"></i>
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- Add closing divs for container -->
  </div>
</div>

<!-- Modals -->
<!-- Add Achievement Modal -->
<div class="modal rpg-modal fade" id="addAchievementModal" tabindex="-1" aria-labelledby="addAchievementModalLabel"
  aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="addAchievementModalLabel">Add New Achievement</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        <form id="addAchievementForm">
          <div class="mb-3">
            <label for="achievementName" class="rpg-form-label">Achievement Name</label>
            <input type="text" class="form-control rpg-form-control" id="achievementName" required>
          </div>
          <div class="mb-3">
            <label for="achievementDescription" class="rpg-form-label">Description</label>
            <textarea class="form-control rpg-form-control" id="achievementDescription" rows="3" required></textarea>
          </div>
          <div class="mb-3">
            <label for="achievementIcon" class="rpg-form-label">Icon</label>
            <select class="form-select rpg-form-select" id="achievementIcon">
              <option value="bi-stars">Stars</option>
              <option value="bi-trophy">Trophy</option>
              <option value="bi-lightning">Lightning</option>
              <option value="bi-shield">Shield</option>
              <option value="bi-gem">Gem</option>
            </select>
          </div>
          <div class="mb-3">
            <label for="achievementCategories" class="rpg-form-label">Categories</label>
            <input type="text" class="form-control rpg-form-control" id="achievementCategories"
              placeholder="Enter categories separated by commas">
          </div>
          <div class="mb-3">
            <label for="achievementTiers" class="rpg-form-label">Tiers</label>
            <input type="text" class="form-control rpg-form-control" id="achievementTiers"
              placeholder="Enter tiers separated by commas">
          </div>
        </form>
      </div>
      <div class="modal-footer">
        <button type="button" class="rpg-btn rpg-btn-outline" data-bs-dismiss="modal">Cancel</button>
        <button type="button" class="rpg-btn">Save Achievement</button>
      </div>
    </div>
  </div>
</div>

<!-- Add Badge Modal -->
<div class="modal rpg-modal fade" id="addBadgeModal" tabindex="-1" aria-labelledby="addBadgeModalLabel"
  aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="addBadgeModalLabel">Add New Badge/Reward</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        <form id="addBadgeForm">
          <div class="mb-3">
            <label for="badgeName" class="rpg-form-label">Badge Name</label>
            <input type="text" class="form-control rpg-form-control" id="badgeName" required>
          </div>
          <div class="mb-3">
            <label for="badgeDescription" class="rpg-form-label">Description</label>
            <textarea class="form-control rpg-form-control" id="badgeDescription" rows="2" required></textarea>
          </div>
          <div class="mb-3">
            <label for="badgeIcon" class="rpg-form-label">Icon</label>
            <select class="form-select rpg-form-select" id="badgeIcon">
              <option value="bi-star-fill">Star</option>
              <option value="bi-shield-fill-check">Shield</option>
              <option value="bi-trophy-fill">Trophy</option>
              <option value="bi-gem">Gem</option>
              <option value="bi-award">Award</option>
            </select>
          </div>
          <div class="row">
            <div class="col-md-6">
              <div class="mb-3">
                <label for="badgeXP" class="rpg-form-label">XP Reward</label>
                <input type="number" class="form-control rpg-form-control" id="badgeXP" min="0">
              </div>
            </div>
            <div class="col-md-6">
              <div class="mb-3">
                <label for="badgeRarity" class="rpg-form-label">Rarity</label>
                <select class="form-select rpg-form-select" id="badgeRarity">
                  <option value="common">Common</option>
                  <option value="uncommon">Uncommon</option>
                  <option value="rare">Rare</option>
                  <option value="epic">Epic</option>
                  <option value="legendary">Legendary</option>
                </select>
              </div>
            </div>
          </div>
          <div class="mb-3">
            <label for="badgeUnlockCondition" class="rpg-form-label">Unlock Condition</label>
            <textarea class="form-control rpg-form-control" id="badgeUnlockCondition" rows="2"></textarea>
          </div>
        </form>
      </div>
      <div class="modal-footer">
        <button type="button" class="rpg-btn rpg-btn-outline" data-bs-dismiss="modal">Cancel</button>
        <button type="button" class="rpg-btn">Save Badge</button>
      </div>
    </div>
  </div>
</div>

<!-- Add Quest Template Modal -->
<div class="modal rpg-modal fade" id="addQuestTemplateModal" tabindex="-1" aria-labelledby="addQuestTemplateModalLabel"
  aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="addQuestTemplateModalLabel">Add Quest Template</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        <form id="addQuestTemplateForm">
          <div class="mb-3">
            <label for="templateName" class="rpg-form-label">Template Name</label>
            <input type="text" class="form-control rpg-form-control" id="templateName" required>
          </div>
          <div class="mb-3">
            <label for="templateDescription" class="rpg-form-label">Description</label>
            <textarea class="form-control rpg-form-control" id="templateDescription" rows="2" required></textarea>
          </div>
          <div class="row">
            <div class="col-md-6">
              <div class="mb-3">
                <label for="questType" class="rpg-form-label">Quest Type</label>
                <select class="form-select rpg-form-select" id="questType">
                  <option value="daily">Daily</option>
                  <option value="challenge">Challenge</option>
                  <option value="epic">Epic</option>
                  <option value="seasonal">Seasonal</option>
                </select>
              </div>
            </div>
            <div class="col-md-6">
              <div class="mb-3">
                <label for="questDifficulty" class="rpg-form-label">Difficulty</label>
                <select class="form-select rpg-form-select" id="questDifficulty">
                  <option value="easy">Easy</option>
                  <option value="medium">Medium</option>
                  <option value="hard">Hard</option>
                </select>
              </div>
            </div>
          </div>
          <div class="row">
            <div class="col-md-6">
              <div class="mb-3">
                <label for="minXP" class="rpg-form-label">Min XP</label>
                <input type="number" class="form-control rpg-form-control" id="minXP" min="0">
              </div>
            </div>
            <div class="col-md-6">
              <div class="mb-3">
                <label for="maxXP" class="rpg-form-label">Max XP</label>
                <input type="number" class="form-control rpg-form-control" id="maxXP" min="0">
              </div>
            </div>
          </div>
          <div class="row">
            <div class="col-md-6">
              <div class="mb-3">
                <label for="minGold" class="rpg-form-label">Min Gold</label>
                <input type="number" class="form-control rpg-form-control" id="minGold" min="0">
              </div>
            </div>
            <div class="col-md-6">
              <div class="mb-3">
                <label for="maxGold" class="rpg-form-label">Max Gold</label>
                <input type="number" class="form-control rpg-form-control" id="maxGold" min="0">
              </div>
            </div>
          </div>
          <div class="mb-3">
            <label for="questIcon" class="rpg-form-label">Icon</label>
            <select class="form-select rpg-form-select" id="questIcon">
              <option value="bi-book">Book</option>
              <option value="bi-person-arms-up">Exercise</option>
              <option value="bi-dragon">Dragon</option>
              <option value="bi-stars">Seasonal</option>
              <option value="bi-calendar-check">Daily</option>
            </select>
          </div>
        </form>
      </div>
      <div class="modal-footer">
        <button type="button" class="rpg-btn rpg-btn-outline" data-bs-dismiss="modal">Cancel</button>
        <button type="button" class="rpg-btn">Save Template</button>
      </div>
    </div>
  </div>
</div>

<!-- Add Event Modal -->
<div class="modal rpg-modal fade" id="addEventModal" tabindex="-1" aria-labelledby="addEventModalLabel"
  aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="addEventModalLabel">Add New Event</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        <form id="addEventForm" method="post" action="/taskevents" enctype="multipart/form-data">
          <div class="mb-3">
            <label for="eventTitle" class="rpg-form-label">Event Title</label>
            <input type="text" class="form-control rpg-form-control" id="eventTitle" name="eventTitle" required>
          </div>
          <div class="mb-3">
            <label for="eventDescription" class="rpg-form-label">Event Description</label>
            <textarea class="form-control rpg-form-control" id="eventDescription" name="eventDescription" rows="3"
              required></textarea>
          </div>
          <div class="mb-3">
            <label for="startDate" class="rpg-form-label">Start Date</label>
            <input type="date" class="form-control rpg-form-control" id="startDate" name="startDate" required>
          </div>
          <div class="mb-3">
            <label for="endDate" class="rpg-form-label">End Date</label>
            <input type="date" class="form-control rpg-form-control" id="endDate" name="endDate" required>
          </div>
          <div class="row">
            <div class="col-md-6">
              <div class="mb-3">
                <label for="rewardXp" class="rpg-form-label">Reward XP</label>
                <input type="number" class="form-control rpg-form-control" id="rewardXp" name="rewardXp" required
                  min="0">
              </div>
            </div>
            <div class="col-md-6">
              <div class="mb-3">
                <label for="rewardCoins" class="rpg-form-label">Reward Coins</label>
                <input type="number" class="form-control rpg-form-control" id="rewardCoins" name="rewardCoins" required
                  min="0">
              </div>
            </div>
          </div>
          <div class="mb-3">
            <label for="eventStatus" class="rpg-form-label">Status</label>
            <select class="form-select rpg-form-select" id="eventStatus" name="eventStatus">
              <option value="active">Active</option>
              <option value="inactive">Inactive</option>
            </select>
          </div>
        </form>
      </div>
      <div class="modal-footer">
        <button type="button" class="rpg-btn rpg-btn-outline" data-bs-dismiss="modal">Cancel</button>
        <button type="button" class="rpg-btn" onclick="document.getElementById('addEventForm').submit()">Create
          Event</button>
      </div>
    </div>
  </div>
</div>

<script>
  document.addEventListener('DOMContentLoaded', function () {
    const contentContainer = document.getElementById('pagination-content');

    // Handle pagination clicks
    contentContainer.addEventListener('click', function (e) {
      const link = e.target.closest('a');
      if (link && link.getAttribute('href') && link.getAttribute('href').includes('page=')) {
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