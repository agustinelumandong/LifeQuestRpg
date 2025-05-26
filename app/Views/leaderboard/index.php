<div class="container py-4">
  <!-- Header -->
  <a href="/" class="back-button">
    <i class="bi bi-arrow-left"></i>
    Back to Dashboard
  </a>
  <header class="text-center my-5">
    <h1 class="display-4 fw-bold mb-3" style="font-family: 'Pixelify Sans', serif;">
      <i class="bi bi-trophy-fill"></i>
      Leaderboard
    </h1>
    <p class="lead text-muted">Discover the top performers in LifeQuest RPG</p>
  </header>

  <!-- Leaderboard Table -->
  <div class="card border-dark shadow-sm mb-4">
    <div class="card-header bg-white py-3">
      <div class="d-flex justify-content-between align-items-center">
        <h5 class="card-title mb-0 fw-bold" style="font-family: 'Pixelify Sans', serif;">
          <i class="bi bi-list-ol"></i>
          Top Players
        </h5>
        <span class="badge bg-dark rounded-pill px-3 py-2">
          <?= count($rankings) ?> Players
        </span>
      </div>
    </div>
    <div class="card-body p-0">
      <div class="table-responsive">
        <table class="table table-hover leaderboard-table mb-0">
          <thead class="bg-dark text-white">
            <tr>
              <th class="ps-4">Rank</th>
              <th>User</th>
              <th>Level</th>
              <th class="pe-4">Experience</th>
            </tr>
          </thead>
          <tbody>
            <?php foreach ($rankings as $index => $player): ?>
              <?php
              $currentUserId = \App\Core\Auth::getByUserId();
              $isCurrentUser = $currentUserId && $currentUserId == $player['user_id'];
              ?>
              <tr
                class="<?= $index < 3 ? 'top-rank ' . ['first-place', 'second-place', 'third-place'][$index] : '' ?> <?= $isCurrentUser ? 'current-user-row' : '' ?>"
                <?= !$isCurrentUser ? "onclick=\"window.location.href='/users/{$player['user_id']}'\"" : '' ?>
                style="cursor: <?= $isCurrentUser ? 'default' : 'pointer' ?>;">
                <td class="ps-4 <?= $index < 3 ? ['first-row', 'second-row', 'third-row'][$index] : '' ?>">
                  <?php if ($index < 3): ?>
                    <div
                      class="rank-medal <?= ['gold', 'silver', 'bronze'][$index] ?> <?= ['first', 'second', 'third'][$index] ?>">
                      <?= $index + 1 ?>
                    </div>
                  <?php else: ?>
                    <span class="rank-number"><?= $index + 1 ?></span>
                  <?php endif; ?>
                </td>
                <td class="<?= $index < 3 ? ['first-row', 'second-row', 'third-row'][$index] : '' ?>">
                  <div class="d-flex align-items-center">
                    <div
                      class="avatar me-3 <?= $index < 3 ? ['first-avatar', 'second-avatar', 'third-avatar'][$index] : '' ?>">
                      <img
                        src="https://ui-avatars.com/api/?name=<?= urlencode($player['username'] ?? '') ?>&background=random"
                        alt="User Avatar" class="rounded-circle">
                    </div>
                    <div>
                      <h6
                        class="mb-0 fw-bold <?= $index < 3 ? ['first-name', 'second-name', 'third-name'][$index] : '' ?>"
                        style="font-family: 'Pixelify Sans', serif;">
                        <?= htmlspecialchars($player['username'] ?? '') ?>
                        <?= $isCurrentUser ? '<span class="text-muted ms-2">(You)</span>' : '' ?>
                      </h6>
                    </div>
                  </div>
                </td>
                <td class="<?= $index < 3 ? ['first-row', 'second-row', 'third-row'][$index] : '' ?>">
                  <span
                    class="level-badge <?= $index < 3 ? ['first-badge', 'second-badge', 'third-badge'][$index] : '' ?>">Level
                    <?= $player['level'] ?></span>
                </td>
                <td class="pe-4 <?= $index < 3 ? ['first-row', 'second-row', 'third-row'][$index] : '' ?>">
                  <span
                    class="xp-text <?= $index < 3 ? ['first-xp', 'second-xp', 'third-xp'][$index] : '' ?>"><?= number_format($player['xp']) ?>
                    XP</span>
                </td>
              </tr>
            <?php endforeach; ?>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</div>

<link rel="stylesheet" href="<?= \App\Core\Helpers::asset('css/leaderboard.css') ?>">