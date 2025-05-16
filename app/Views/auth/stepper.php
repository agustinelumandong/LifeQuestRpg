<?php
use App\Core\Auth;
use App\Models\UserStats;

// Initialize userStats model if needed for step 4
$userStats = new UserStats();
?>
<div class="container">
  <!-- <div class="page-header">
  </div> -->
  <div class="panel panel-default">
    <div class="panel-body">
      <div class="stepper">
        <!-- Progress Bar Navigation -->
        <div class="stepper-progress">
          <div class="stepper-progress-container">
            <!-- Progress Bar -->
            <div class="progress">
              <?php
              // Calculate progress percentage
              $progressPercentage = (($currentStep - 1) / 3) * 100;
              ?>
              <div class="progress-bar" role="progressbar" style="width: <?= $progressPercentage ?>%;"
                aria-valuenow="<?= $progressPercentage ?>" aria-valuemin="0" aria-valuemax="100"></div>
            </div>

            <!-- Step Indicators -->
            <div class="stepper-labels">
              <?php
              $steps = [
                1 => ['label' => 'Welcome', 'icon' => 'bi-1-circle-fill'],
                2 => ['label' => 'Avatar', 'icon' => 'bi-2-circle-fill'],
                3 => ['label' => 'Profile', 'icon' => 'bi-3-circle-fill'],
                4 => ['label' => 'Complete', 'icon' => 'bi-4-circle-fill']
              ];

              foreach ($steps as $step => $data):
                if ($step < $currentStep) {
                  $class = 'completed';
                } elseif ($step === $currentStep) {
                  $class = 'active';
                } else {
                  $class = 'disabled';
                }
                ?>
                <div class="step-indicator <?= $class ?>" data-step="<?= $step ?>">
                  <div class="step-dot <?= $class ?>">
                    <i class="step-icon <?= $data['icon'] ?>"></i>
                  </div>
                  <div class="step-label"><?= $data['label'] ?></div>
                </div>
              <?php endforeach; ?>
            </div>
          </div>
        </div>

        <!-- Step 1: Introduction -->
        <?php if ($currentStep == 1): ?>
          <form action="/character/process-step" method="POST">
            <input type="hidden" name="step" value="1">
            <div class="tab-pane active" role="tabpanel">

              <div class="character-preview text-center">
                <h5 style="font-family: 'Pixelify Sans', sans-serif;">Your Adventure Begins Here</h5>
                <p>Ready to level up your productivity and defeat procrastination?</p>
                <div class="intro-features mt-3">
                  <div class="feature-item">
                    <i class="bi bi-check-circle-fill text-dark"></i> Track daily tasks and habits
                  </div>
                  <div class="feature-item">
                    <i class="bi bi-check-circle-fill text-dark"></i> Earn XP and level up your character
                  </div>
                  <div class="feature-item">
                    <i class="bi bi-check-circle-fill text-dark"></i> Complete quests and unlock achievements
                  </div>
                </div>

                <div class="mt-4">
                  <div class="text-center">
                    <p class="fst-italic">"You may delay, but time will not." — Benjamin Franklin</p>
                  </div>
                </div>
              </div>

              <div class="text-center mt-5">
                <button type="submit" class="btn btn-primary">Start <i class="bi bi-arrow-right"></i></button>
              </div>
            </div>
          </form>
        <?php endif; ?>

        <!-- Step 2: Avatar Selection -->
        <?php if ($currentStep == 2): ?>
          <form action="/character/process-step" method="POST">
            <input type="hidden" name="step" value="2">
            <div class="tab-pane active" role="tabpanel">
              <h3 class="text-center mb-4" style="font-family: 'Pixelify Sans', sans-serif;">
                Choose Your Avatar
              </h3>

              <div class="avatar-selection">
                <?php
                $avatars = [
                  1 => 'fa-user-astronaut',
                  2 => 'fa-user-ninja',
                  3 => 'fa-user-graduate',
                  4 => 'fa-user-secret',
                  5 => 'fa-user-tie',
                  6 => 'fa-user-md'
                ];

                $selectedAvatar = $_SESSION['character_data']['avatar_id'] ?? 1;

                foreach ($avatars as $id => $icon):
                  $class = $id === $selectedAvatar ? 'selected' : '';
                  ?>
                  <div class="avatar-option <?= $class ?>" data-avatar="<?= $id ?>">
                    <i class="fas <?= $icon ?>"></i>
                  </div>
                <?php endforeach; ?>
              </div>

              <div class="avatar-preview text-center mt-4 mb-4">
                <div class="selected-avatar-display" style="font-size: 64px; color: #000000;">
                  <i class="fas <?= $avatars[$selectedAvatar] ?>"></i>
                </div>
                <!-- <div class="mt-2 level-badge">Level 1</div> -->
              </div>

              <input type="hidden" name="avatar_id" id="avatar_id" value="<?= $selectedAvatar ?>">

              <div class="text-center mt-4">
                <a href="/character/stepper?step=1" class="btn btn-secondary me-2"><i class="bi bi-arrow-left"></i>
                  Back</a>
                <button type="submit" class="btn btn-primary">Next <i class="bi bi-arrow-right"></i></button>
              </div>
            </div>
          </form>
        <?php endif; ?>

        <!-- Step 3: Username Form -->
        <?php if ($currentStep == 3): ?>
          <form action="/character/process-step" method="POST">
            <input type="hidden" name="step" value="3">
            <input type="hidden" name="user_id" value="<?= App\Core\Auth::getByUserId() ?>">
            <div class="tab-pane active" role="tabpanel">
              <h3 class="text-center mb-4" style="font-family: 'Pixelify Sans', sans-serif;">
                Create Your Profile
              </h3>

              <div class="row justify-content-center">
                <div class="col-md-8">
                  <div class="form-group">
                    <label for="username" class="form-label">Your Hero Name</label>
                    <div class="input-group mb-3">
                      <span class="input-group-text"><i class="bi bi-person"></i></span>
                      <input type="text" class="form-control" id="username" name="username"
                        placeholder="Enter your hero name" required
                        value="<?= $_SESSION['character_data']['username'] ?? '' ?>">
                    </div>
                    <div class="invalid-feedback">Please enter a username (min 3 characters)</div>
                  </div>

                  <div class="form-group">
                    <label for="objective" class="form-label">Your Main Quest</label>
                    <div class="input-group mb-3">
                      <span class="input-group-text"><i class="bi bi-flag"></i></span>
                      <input type="text" class="form-control" id="objective" name="objective"
                        placeholder="E.g., Learn to code, Get fit, Master a language"
                        value="<?= $_SESSION['character_data']['objective'] ?? '' ?>">
                    </div>
                  </div>
                </div>
              </div>

              <div class="text-center mt-4">
                <a href="/character/stepper?step=2" class="btn btn-secondary me-2"><i class="bi bi-arrow-left"></i>
                  Back</a>
                <button type="submit" class="btn btn-primary">Complete <i class="bi bi-check-lg"></i></button>
              </div>
            </div>
          </form>
        <?php endif; ?>

        <!-- Step 4: Completion -->
        <?php if ($currentStep == 4): ?>
          <div class="tab-pane active" role="tabpanel">
            <div class="completion-message">
              <div class="completion-icon">
                <i class="bi bi-trophy"></i>
              </div>
              <h3 style="font-family: 'Pixelify Sans', sans-serif;">Your Adventure Begins!</h3>
              <p class="lead">Welcome, <span id="hero-name"><?= Auth::user()->username ?? 'Hero' ?></span>!</p>

              <div class="character-preview mt-4">
                <div class="row">
                  <div class="col-md-4 text-center">
                    <?php
                    $avatars = [
                      1 => 'fa-user-astronaut',
                      2 => 'fa-user-ninja',
                      3 => 'fa-user-graduate',
                      4 => 'fa-user-secret',
                      5 => 'fa-user-tie',
                      6 => 'fa-user-md'
                    ];
                    $stats = $userStats->getUserStatsByUserId(Auth::getByUserId());
                    $avatarId = $stats['avatar_id'] ?? 1;
                    $avatarIcon = $avatars[$avatarId] ?? $avatars[1];
                    ?>
                    <div id="final-avatar" style="font-size: 80px; color: #000000;">
                      <i class="fas <?= $avatarIcon ?>"></i>
                    </div>
                    <div class="level-badge mt-2">Level 1</div>
                  </div>
                  <div class="col-md-8">
                    <p id="final-objective">
                      Your quest: <?= htmlspecialchars($stats['objective'] ?? 'Become the best version of yourself') ?>
                    </p>

                    <div class="mt-3">
                      <h6 class="mb-2"><i class="bi bi-heart-fill"></i> Health: 100/100</h6>
                      <div class="stats-bar">
                        <div class="stats-progress" style="width: 100%;"></div>
                      </div>

                      <h6 class="mb-2"><i class="bi bi-star-fill"></i> Experience: 0/100</h6>
                      <div class="stats-bar">
                        <div class="stats-progress" style="width: 0%;"></div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <div class="mt-4">
                <a href="/" class="btn btn-primary btn-lg">
                  <i class="bi bi-controller"></i> Start Playing
                </a>
              </div>
            </div>
          </div>
        <?php endif; ?>
      </div>
    </div>
  </div>
</div>

<!-- Load required styles and scripts -->
<link rel="stylesheet" href="<?= App\Core\Helpers::asset('css/stepper.css') ?>">
<script src="https://cdn.jsdelivr.net/npm/jquery@3.6.0/dist/jquery.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"></script>

<!-- Avatar selection script -->
<?php if ($currentStep == 2): ?>
  <script>
    $(function () {
      // Handle avatar selection
      $('.avatar-option').click(function () {
        $('.avatar-option').removeClass('selected');
        $(this).addClass('selected');

        // Update the preview
        var selectedAvatar = $(this).data('avatar');
        var avatarIcon = $(this).html();
        $('.selected-avatar-display').html(avatarIcon);
        $('#avatar_id').val(selectedAvatar); // Update hidden form field
      });
    });
  </script>
<?php endif; ?>