<div class="container">
  <div class="row">
    <!-- Left Panel - Character Profile -->
    <div class="col-md-3 col-lg-3 mb-4">
      <div class="profile-panel p-3 mb-4">

        <!-- Character Avatar -->
        <div class="text-center mb-3">
          <div class="profile-avatar bg-white text-dark mb-2">
            <?php $avatarId = isset($userStats['avatar_id']) ? $userStats['avatar_id'] : 1; ?>
            <img src="/assets/images/avatars/avatar<?= $avatarId ?>.svg" alt="Character Avatar"
              class="img-fluid rounded-circle " id="profile-avatar">
          </div>
          <h4 class="mb-0" style="font-family: 'Pixelify Sans', serif;"><?= $userStats['username'] ?></h4>
          <div>
            <?php foreach ($userStreaks as $type => $streak): ?>
              <?php
              $label = '';
              switch ($type) {
                case 'check_in':
                  $label = 'Login';
                  break;
              }

              // Determine flame class based on streak count
              $flameClass = '';
              if ($streak['current_streak'] >= 30) {
                $flameClass = 'text-danger';
              } else if ($streak['current_streak'] >= 7) {
                $flameClass = 'text-warning';
              } else {
                $flameClass = 'text-white';
              }
              ?>
              <?php if ($label == 'Login'): ?>
                <div class="">
                  <span class="streak-count">
                    <div class="badge bg-dark">Level: <?= $userStats['level'] ?></div>

                    <span class="badge bg-dark"> <i style="color: #fff ;" class="bi bi-fire <?= $flameClass ?>"></i>
                      <?= $streak['current_streak'] ?> Streaks</span>
                  </span>
                </div>
              <?php endif; ?>
            <?php endforeach; ?>

          </div>
        </div>

        <!-- Health Bar -->
        <div class="stat-box">
          <div class="d-flex justify-content-between align-items-center mb-1">
            <span><i class="bi bi-heart-fill"></i> Health</span>
            <span class="badge bg-dark"><?= $userStats['health'] ?>/100</span>
          </div>
          <div class="progress">
            <div class="progress-bar bg-dark" role="progressbar" style="width: <?= $userStats['health'] ?>%"
              aria-valuenow="<?= $userStats['health'] ?>" aria-valuemin="0" aria-valuemax="100"></div>
          </div>
        </div> <!-- Level Progress -->
        <div class="stat-box">
          <div class="d-flex justify-content-between align-items-center mb-1">
            <span style="font-family: 'Pixelify Sans', serif;"><i class="bi bi-arrow-up-circle"></i>
              Level UP</span>
            <?php $xpThreshold = $userStats['level'] * 100; ?>
            <span class="badge bg-dark"><?= $userStats['xp'] ?>/<?= $xpThreshold ?></span>
          </div>
          <div class="progress">
            <?php $xpProgress = ($xpThreshold > 0) ? ($userStats['xp'] / $xpThreshold * 100) : 0; ?>
            <div class="progress-bar bg-dark" role="progressbar" style="width: <?= $xpProgress ?>%"
              aria-valuenow="<?= $userStats['xp'] ?>" aria-valuemin="0" aria-valuemax="<?= $xpThreshold ?>"></div>
          </div>
        </div> <!-- Goal Information -->
        <div class="stat-box">
          <div class="d-flex justify-content-between align-items-center mb-1">
            <span style="font-family: 'Pixelify Sans', serif;"><i class="bi bi-flag-fill"></i> My Goal</span>
          </div>
          <h6 class="mb-0"><?= $userStats['objective'] ?></h6>
          <small class="text-muted">Your personal objective</small>
        </div>


      </div>

      <!-- POMODORO TIMER -->
      <div class="pomodoro-panel mb-4">
        <h5 class="border-bottom pb-2 mb-3 " style="font-family: 'Pixelify Sans', serif;">
          <i class="bi bi-alarm me-2"></i> Pomodoro Timer
        </h5>
        <div class="d-flex flex-column align-items-center justify-content-center mb-3">
          <h1 class="fw-bold text-center" style="font-family: 'Pixelify Sans', serif;" id="ph-time">
            <?php
            date_default_timezone_set('Asia/Manila');
            echo date('H:i');
            ?>
          </h1>
          <small class="text-muted mb-2">Philippine Time</small>
          <!-- <a href="#" class="focus-btn text-white ">FOCUS MODE</a> -->
          <button type="button" type="button" class="btn focus-btn text-white" data-bs-toggle="modal"
            data-bs-target="#exampleModalFullscreen"> FOCUS
            MODE</button>

        </div>
      </div>

      <!-- SPOTIFY -->
      <div class="spotify-panel">
        <iframe class="spotify" id="spotify"
          src="https://open.spotify.com/embed/playlist/4Zjli1P13J5mmSCD5iKAXK?theme=0" width="100%" height="80"
          frameborder="0" allowtransparency="true"
          allow="autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture" loading="lazy">
        </iframe>
      </div>
    </div>

    <!-- Middle Panel - RPG Content -->
    <div class="col-md-6 col-lg-6 mb-4">
      <div class="card mb-4">
        <div class="card-header bg-white">
          <h2 class="text-center my-2" style="font-family: 'Pixelify Sans', serif;">
            <i class="bi bi-controller"></i> Welcome To Life RPG
          </h2>
        </div>

        <div class="card-body">
          <!-- Habit Grid -->
          <div class="row g-4 justify-content-center">
            <!-- Row 1: Good Habits -->
            <div class="box col-md-4 d-flex justify-content-center">
              <a href="/task" class="habit-box">
                <i class="fas fa-cross mb-3" style="font-size: 116px;color: var(--bs-dark);"></i>
                <p class="habit-label">Task/DailyTask</p>
              </a>
            </div>
            <div class="box col-md-4 d-flex justify-content-center">
              <a href="/goodhabit" class="habit-box">
                <i class="fas fa-skull-crossbones mb-3" style="font-size: 116px;color: var(--bs-dark);"></i>
                <p class="habit-label">Good Habits</p>
              </a>
            </div>
            <div class="box col-md-4 d-flex justify-content-center">
              <a href="/badhabit" class="habit-box">
                <i class="fas fa-trophy mb-3" style="font-size: 116px;color: var(--bs-dark);"></i>
                <p class="habit-label">Bad Habits</p>
              </a>
            </div>

            <!-- Row 2: Good Habits -->
            <div class="box col-md-4 d-flex justify-content-center">
              <a href="/inventory" class="habit-box">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -64 640 640" width="1em" height="1em"
                  fill="currentColor" style="font-size: 116px;color: var(--bs-dark);" class="mb-3">
                  <!--! Font Awesome Free 6.4.2 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license/free (Icons: CC BY 4.0, Fonts: SIL OFL 1.1, Code: MIT License) Copyright 2023 Fonticons, Inc. -->
                  <path
                    d="M560 160A80 80 0 1 0 560 0a80 80 0 1 0 0 160zM55.9 512H381.1h75H578.9c33.8 0 61.1-27.4 61.1-61.1c0-11.2-3.1-22.2-8.9-31.8l-132-216.3C495 196.1 487.8 192 480 192s-15 4.1-19.1 10.7l-48.2 79L286.8 81c-6.6-10.6-18.3-17-30.8-17s-24.1 6.4-30.8 17L8.6 426.4C3 435.3 0 445.6 0 456.1C0 487 25 512 55.9 512z">
                  </path>
                </svg>
                <p class="habit-label">Inventory</p>
              </a>
            </div>            <div class="box col-md-4 d-flex justify-content-center">
              <a href="/marketplace" class="habit-box">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -32 576 576" width="1em" height="1em"
                  fill="currentColor" style="font-size: 116px;color: var(--bs-dark);" class="mb-3">
                  <!--! Font Awesome Free 6.4.2 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license/free (Icons: CC BY 4.0, Fonts: SIL OFL 1.1, Code: MIT License) Copyright 2023 Fonticons, Inc. -->
                  <path
                    d="M547.6 103.8L490.3 13.1C485.2 5 476.1 0 466.4 0H109.6C99.9 0 90.8 5 85.7 13.1L28.3 103.8c-29.6 46.8-3.4 111.9 51.9 119.4c4 .5 8.1 .8 12.1 .8c26.1 0 49.3-11.4 65.2-29c15.9 17.6 39.1 29 65.2 29c26.1 0 49.3-11.4 65.2-29c15.9 17.6 39.1 29 65.2 29c26.2 0 49.3-11.4 65.2-29c16 17.6 39.1 29 65.2 29c4.1 0 8.1-.3 12.1-.8c55.5-7.4 81.8-72.5 52.1-119.4zM499.7 254.9l-.1 0c-5.3 .7-10.7 1.1-16.2 1.1c-12.4 0-24.3-1.9-35.4-5.3V384H128V250.6c-11.2 3.5-23.2 5.4-35.6 5.4c-5.5 0-11-.4-16.3-1.1l-.1 0c-4.1-.6-8.1-1.3-12-2.3V384v64c0 35.3 28.7 64 64 64H448c35.3 0 64-28.7 64-64V384 252.6c-4 1-8 1.8-12.3 2.3z">
                  </path>
                </svg>
                <p class="habit-label">Marketplace</p>
              </a>
            </div>
            <div class="box col-md-4 d-flex justify-content-center">
              <a href="/journal" class="habit-box">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="-32 0 512 512" width="1em" height="1em"
                  fill="currentColor" style="font-size: 116px;color: var(--bs-dark);" class="mb-3">
                  <!--! Font Awesome Free 6.4.2 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license/free (Icons: CC BY 4.0, Fonts: SIL OFL 1.1, Code: MIT License) Copyright 2023 Fonticons, Inc. -->
                  <path
                    d="M0 96C0 43 43 0 96 0H384h32c17.7 0 32 14.3 32 32V352c0 17.7-14.3 32-32 32v64c17.7 0 32 14.3 32 32s-14.3 32-32 32H384 96c-53 0-96-43-96-96V96zM64 416c0 17.7 14.3 32 32 32H352V384H96c-17.7 0-32 14.3-32 32zm90.4-234.4l-21.2-21.2c-3 10.1-5.1 20.6-5.1 31.6c0 .2 0 .5 .1 .8s.1 .5 .1 .8L165.2 226c2.5 2.1 3.4 5.8 2.3 8.9c-1.3 3-4.1 5.1-7.5 5.1c-1.9-.1-3.8-.8-5.2-2l-23.6-20.6C142.8 267 186.9 304 240 304s97.3-37 108.9-86.6L325.3 238c-1.4 1.2-3.3 2-5.3 2c-2.2-.1-4.4-1.1-6-2.8c-1.2-1.5-1.9-3.4-2-5.2c.1-2.2 1.1-4.4 2.8-6l37.1-32.5c0-.3 0-.5 .1-.8s.1-.5 .1-.8c0-11-2.1-21.5-5.1-31.6l-21.2 21.2c-3.1 3.1-8.1 3.1-11.3 0s-3.1-8.1 0-11.2l26.4-26.5c-8.2-17-20.5-31.7-35.9-42.6c-2.7-1.9-6.2 1.4-5 4.5c8.5 22.4 3.6 48-13 65.6c-3.2 3.4-3.6 8.9-.9 12.7c9.8 14 12.7 31.9 7.5 48.5c-5.9 19.4-22 34.1-41.9 38.3l-1.4-34.3 12.6 8.6c.6 .4 1.5 .6 2.3 .6c1.5 0 2.7-.8 3.5-2s.6-2.8-.1-4L260 225.4l18-3.6c1.8-.4 3.1-2.1 3.1-4s-1.4-3.5-3.1-3.9l-18-3.7 8.5-14.3c.8-1.2 .9-2.9 .1-4.1s-2-2-3.5-2l-.1 0c-.7 .1-1.5 .3-2.1 .7l-14.1 9.6L244 87.9c-.1-2.2-1.9-3.9-4-3.9s-3.9 1.6-4 3.9l-4.6 110.8-12-8.1c-1.5-1.1-3.6-.9-5 .4s-1.6 3.4-.8 5l8.6 14.3-18 3.7c-1.8 .4-3.1 2-3.1 3.9s1.4 3.6 3.1 4l18 3.8-8.6 14.2c-.2 .6-.5 1.4-.5 2c0 1.1 .5 2.1 1.2 3c.8 .6 1.8 1 2.8 1c.7 0 1.6-.2 2.2-.6l10.4-7.1-1.4 32.8c-19.9-4.1-36-18.9-41.9-38.3c-5.1-16.6-2.2-34.4 7.6-48.5c2.7-3.9 2.3-9.3-.9-12.7c-16.6-17.5-21.6-43.1-13.1-65.5c1.2-3.1-2.3-6.4-5-4.5c-15.3 10.9-27.6 25.6-35.8 42.6l26.4 26.5c3.1 3.1 3.1 8.1 0 11.2s-8.1 3.1-11.2 0z">
                  </path>
                </svg>
                <p class="habit-label">Journal</p>
              </a>
            </div>

            <!-- Row 3: AMBOT -->
            <div class="box col-md-4 d-flex justify-content-center">
              <a href="/settings" class="habit-box">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="-32 0 512 512" width="1em" height="1em"
                  fill="currentColor" style="font-size: 116px;color: var(--bs-dark);" class="mb-3">
                  <!--! Font Awesome Free 6.4.2 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license/free (Icons: CC BY 4.0, Fonts: SIL OFL 1.1, Code: MIT License) Copyright 2023 Fonticons, Inc. -->
                  <path
                    d="M152 88a72 72 0 1 1 144 0A72 72 0 1 1 152 88zM39.7 144.5c13-17.9 38-21.8 55.9-8.8L131.8 162c26.8 19.5 59.1 30 92.2 30s65.4-10.5 92.2-30l36.2-26.4c17.9-13 42.9-9 55.9 8.8s9 42.9-8.8 55.9l-36.2 26.4c-13.6 9.9-28.1 18.2-43.3 25V288H128V251.7c-15.2-6.7-29.7-15.1-43.3-25L48.5 200.3c-17.9-13-21.8-38-8.8-55.9zm89.8 184.8l60.6 53-26 37.2 24.3 24.3c15.6 15.6 15.6 40.9 0 56.6s-40.9 15.6-56.6 0l-48-48C70 438.6 68.1 417 79.2 401.1l50.2-71.8zm128.5 53l60.6-53 50.2 71.8c11.1 15.9 9.2 37.5-4.5 51.2l-48 48c-15.6 15.6-40.9 15.6-56.6 0s-15.6-40.9 0-56.6L284 419.4l-26-37.2z">
                  </path>
                </svg>
                <p class="habit-label">Settings</p>
              </a>
            </div>
            <div class="box col-md-4 d-flex justify-content-center">
              <a href="/profile" class="habit-box">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="-32 0 512 512" width="1em" height="1em"
                  fill="currentColor" style="font-size: 116px;color: var(--bs-dark);" class="mb-3">
                  <!--! Font Awesome Free 6.4.2 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license/free (Icons: CC BY 4.0, Fonts: SIL OFL 1.1, Code: MIT License) Copyright 2023 Fonticons, Inc. -->
                  <path
                    d="M352 0c53 0 96 43 96 96V416c0 53-43 96-96 96H64 32c-17.7 0-32-14.3-32-32s14.3-32 32-32V384c-17.7 0-32-14.3-32-32V32C0 14.3 14.3 0 32 0H64 352zm0 384H96v64H352c17.7 0 32-14.3 32-32s-14.3-32-32-32zM138.7 208l13.9 24H124.9l13.9-24zm-13.9-24L97.1 232c-6.2 10.7 1.5 24 13.9 24h55.4l27.7 48c6.2 10.7 21.6 10.7 27.7 0l27.7-48H305c12.3 0 20-13.3 13.9-24l-27.7-48 27.7-48c6.2-10.7-1.5-24-13.9-24H249.6L221.9 64c-6.2-10.7-21.6-10.7-27.7 0l-27.7 48H111c-12.3 0-20 13.3-13.9 24l27.7 48zm27.7 0l27.7-48h55.4l27.7 48-27.7 48H180.3l-27.7-48zm0-48l-13.9 24-13.9-24h27.7zm41.6-24L208 88l13.9 24H194.1zm69.3 24h27.7l-13.9 24-13.9-24zm13.9 72l13.9 24H263.4l13.9-24zm-55.4 48L208 280l-13.9-24h27.7z">
                  </path>
                </svg>
                <p class="habit-label">Profile</p>
              </a>
            </div>
            <div class="box col-md-4 d-flex justify-content-center">
              <a href="/leaderboard" class="habit-box">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="-32 0 512 512" width="1em" height="1em"
                  fill="currentColor" style="font-size: 116px;color: var(--bs-dark);" class="mb-3">
                  <!--! Font Awesome Free 6.4.2 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license/free (Icons: CC BY 4.0, Fonts: SIL OFL 1.1, Code: MIT License) Copyright 2023 Fonticons, Inc. -->
                  <path
                    d="M352 0c53 0 96 43 96 96V416c0 53-43 96-96 96H64 32c-17.7 0-32-14.3-32-32s14.3-32 32-32V384c-17.7 0-32-14.3-32-32V32C0 14.3 14.3 0 32 0H64 352zm0 384H96v64H352c17.7 0 32-14.3 32-32s-14.3-32-32-32zM274.1 150.2l-8.9 21.4-23.1 1.9c-5.7 .5-8 7.5-3.7 11.2L256 199.8l-5.4 22.6c-1.3 5.5 4.7 9.9 9.6 6.9L280 217.2l19.8 12.1c4.9 3 10.9-1.4 9.6-6.9L304 199.8l17.6-15.1c4.3-3.7 2-10.8-3.7-11.2l-23.1-1.9-8.9-21.4c-2.2-5.3-9.6-5.3-11.8 0zM96 192c0 70.7 57.3 128 128 128c25.6 0 49.5-7.5 69.5-20.5c3.2-2.1 4.5-6.2 3.1-9.7s-5.2-5.6-9-4.8c-6.1 1.2-12.5 1.9-19 1.9c-52.4 0-94.9-42.5-94.9-94.9s42.5-94.9 94.9-94.9c6.5 0 12.8 .7 19 1.9c3.8 .8 7.5-1.3 9-4.8s.2-7.6-3.1-9.7C273.5 71.5 249.6 64 224 64C153.3 64 96 121.3 96 192z">
                  </path>
                </svg>
                <p class="habit-label">Leaderboards</p>
              </a>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Right Panel - Activities & Quests -->
    <div class="col-md-3 col-lg-3">
      <!-- Activity Logs -->
      <!-- <div class="activity-panel mb-4">
        <h5 class="d-flex align-items-center border-bottom pb-2 mb-3" style="font-family: 'Pixelify Sans', serif;">
          <i class="bi bi-activity me-2"></i> Activities
        </h5>

        <div class="activity-item">
          <div class="activity-dot"></div>
          <div class="small text-muted mb-1">Today 10:45 PM</div>
          <div class="activity-details small">
            <div>You gained <strong>100 EXP</strong> and <strong>100 Coins</strong> in Taking a course!
            </div>
            <div class="text-success mt-1">+ 100 EXP & 100 Coins!</div>
          </div>
        </div>

        <div class="activity-item">
          <div class="activity-dot"></div>
          <div class="small text-muted mb-1">Today 09:30 PM</div>
          <div class="activity-details small">
            <div>You gained <strong>100 EXP</strong> and <strong>100 Coins</strong> in Taking a course!
            </div>
            <div class="text-success mt-1">+ 100 EXP & 100 Coins!</div>
          </div>
        </div>
      </div> -->

      <div class="activity-panel mb-4">
        <h5 class="d-flex align-items-center border-bottom pb-2 mb-3" style="font-family: 'Pixelify Sans', serif;">
          <i class="bi bi-activity me-2"></i> <a href="/activityLog/index" class="text-decoration-none text-dark">Recent
            Activities</a>
        </h5>

        <div class="activity-timeline" style="max-height: 280px; overflow-y: auto;">
          <?php
          $count = 0;
          foreach ($activities as $activity):
            if ($count >= 2)
              break; // Limit to 2 most recent activities
            $count++;
            ?>
            <div class="activity-item">
              <div class="activity-dot"></div>
              <div class="small text-muted mb-1">
                <?= date('M d, Y g:i A', strtotime($activity['log_timestamp'])) ?>
              </div>
              <div class="activity-details small">
                <?php if (isset($activity['coins']) && $activity['xp'] == 0): ?>
                  <div>You got <strong><span class="text-danger">N/A</span></strong> for committing
                    <strong><?= htmlspecialchars($activity['task_title'] ?? $activity['activity_title']) ?></strong>
                  </div>
                <?php else: ?>
                  <div>You gained <strong><span class="text-success"><?= htmlspecialchars($activity['xp']) ?>
                        XP</span></strong> and <strong><span
                        class="text-warning"><?= htmlspecialchars($activity['coins']) ?> Coins</span></strong> in
                    <strong><?= htmlspecialchars($activity['task_title'] ?? $activity['activity_title']) ?></strong>
                  </div>
                <?php endif; ?>
                <div class="text-muted mt-1">
                  <?= htmlspecialchars(ucfirst($activity['difficulty'] ?? 'No Difficulty')) ?> -
                  <?= htmlspecialchars($activity['category'] ?? 'No Category') ?>
                </div>
              </div>
            </div>
          <?php endforeach; ?>
        </div>
      </div>

      <!-- Community Quests -->
      <div class="quest-panel">
        <a href="/taskevents" class="text-decoration-none text-dark">
          <h5 class="border-bottom pb-2 mb-3" style="font-family: 'Pixelify Sans', serif;">
            <i class="bi bi-map me-2"></i> Community Quests
          </h5>
        </a>
        <?php foreach ($events as $event): ?>
          <a href="/taskevents/<?= $event['id'] ?>" class="event-card-btn">
            <div class="event-card">
              <div class="fw-bold mb-1" style="font-family: 'Pixelify Sans', serif;">
                <i class="bi bi-joystick"></i> <?= $event['event_name'] ?>
              </div>
              <div class="small text-muted">
                <div>Apr 10 - Apr 15, 2023</div>
              </div>
              <div class="d-flex mt-2">
                <div class="me-3 small">
                  <i class="bi bi-stars"></i> <?= $event['reward_xp'] ?>
                </div>
                <div class="small">
                  <i class="bi bi-coin"></i> <?= $event['reward_coins'] ?>
                </div>
              </div>
            </div>
          </a>
        <?php endforeach; ?>

      </div>
    </div>
  </div>
</div>


<link rel="stylesheet" href="<?= \App\Core\Helpers::asset('css/dashboard.css') ?>">

<!-- Modal -->
<?php include __DIR__ . '/pomodoro/pomodoro.php'; ?>
<!-- Modal -->

<script>
  // Update Philippine time every second
  function updatePhilippineTime() {
    const now = new Date();
    // Convert to Philippine time (UTC+8)
    const phTime = new Date(now.toLocaleString("en-US", { timeZone: "Asia/Manila" }));
    const hours = phTime.getHours().toString().padStart(2, '0');
    const minutes = phTime.getMinutes().toString().padStart(2, '0');

    const timeElement = document.getElementById('ph-time');
    if (timeElement) {
      timeElement.textContent = `${hours}:${minutes}`;
    }
  }

  // Update time immediately and then every second
  updatePhilippineTime();
  setInterval(updatePhilippineTime, 1000);
</script>

<script src="<?= \App\Core\Helpers::asset('js/pomodoro.js') ?>"></script>

<link rel="stylesheet" href="<?= \App\Core\Helpers::asset('css/pomodoro.css') ?>">