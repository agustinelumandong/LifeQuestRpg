<div class="container">
  <div class="row">
    <div class="col-12">
      <h1 class="mb-4">Your Activity Streaks</h1>
      <p class="lead">Keep your streaks alive to earn extra rewards!</p>
    </div>
  </div>

  <div class="streak-container">
    <div class="streak-grid">
      <?php foreach ($streakLabels as $key => $title): ?>
        <?php
        $streakData = $userStreaks[$key] ?? null;
        $streakCount = $streakData ? $streakData['current_streak'] : 0;
        $longestStreak = $streakData ? $streakData['longest_streak'] : 0;

        // Determine flame class based on streak count
        $flameClass = 'flame-small';
        if ($streakCount > 30) {
          $flameClass = 'flame-intense';
        } else if ($streakCount > 7) {
          $flameClass = 'flame-medium';
        }

        // Determine if this is a milestone (weekly or monthly)
        $isMilestone = ($streakCount > 0 && ($streakCount % 7 === 0 || $streakCount % 30 === 0));
        ?>

        <div class="streak-card <?= $streakData ? 'active' : 'inactive' ?>">
          <div class="streak-title"><?= $title ?></div>
          <div class="streak-flame <?= $flameClass ?>"></div>
          <div class="streak-count"><?= $streakCount ?> days</div>
          <div class="streak-best">Best: <?= $longestStreak ?> days</div>

          <?php if ($isMilestone): ?>
            <div class="streak-milestone">
              <span class="badge bg-warning">Milestone!</span>
            </div>
          <?php endif; ?>
        </div>
      <?php endforeach; ?>
    </div>

    <div class="streak-info mt-4">
      <div class="card">
        <div class="card-header">
          <h5>About Streaks</h5>
        </div>
        <div class="card-body">
          <ul>
            <li><strong>Daily Login</strong> - Log in every day to maintain this streak</li>
            <li><strong>Task Completion</strong> - Complete at least one task daily</li>
            <li><strong>Daily Tasks</strong> - Complete your daily tasks</li>
            <li><strong>Good Habits</strong> - Practice your good habits daily</li>
            <li><strong>Journal Writing</strong> - Write in your journal every day</li>
          </ul>
          <p>Streaks reset if you miss a day. Special rewards are granted for 7-day and 30-day milestones!</p>
        </div>
      </div>
    </div>
  </div>
</div>

<!-- CSS for streaks -->
<style>
  /* Streak Styling */
  .streak-container {
    padding: 20px;
    background: linear-gradient(to right, #2b5876, #4e4376);
    border-radius: 10px;
    margin: 20px 0;
    box-shadow: 0 4px 15px rgba(0, 0, 0, 0.2);
    color: #fff;
  }

  .streak-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 15px;
  }

  .streak-card {
    background: rgba(255, 255, 255, 0.1);
    border-radius: 8px;
    padding: 15px;
    display: flex;
    flex-direction: column;
    align-items: center;
    transition: all 0.3s ease;
  }

  .streak-card:hover {
    transform: translateY(-5px);
    box-shadow: 0 5px 15px rgba(0, 0, 0, 0.3);
  }

  .streak-card.active {
    border: 2px solid rgba(255, 215, 0, 0.7);
  }

  .streak-card.inactive {
    opacity: 0.7;
  }

  .streak-title {
    font-weight: 600;
    margin-bottom: 10px;
    text-align: center;
  }

  .streak-flame {
    width: 40px;
    height: 40px;
    background-image: url('/public/assets/images/flame.svg');
    background-size: contain;
    background-repeat: no-repeat;
    margin: 10px 0;
    /* Default flame if image not available */
    background-color: #ff7e5f;
    border-radius: 50%;
  }

  .flame-small {
    filter: brightness(0.8);
    transform: scale(0.9);
  }

  .flame-medium {
    filter: brightness(1.2);
    transform: scale(1.0);
  }

  .flame-intense {
    filter: brightness(1.4) saturate(1.5);
    animation: pulse 2s infinite;
  }

  @keyframes pulse {
    0% {
      transform: scale(1);
      filter: brightness(1.4) saturate(1.5);
    }

    50% {
      transform: scale(1.1);
      filter: brightness(1.6) saturate(1.8);
    }

    100% {
      transform: scale(1);
      filter: brightness(1.4) saturate(1.5);
    }
  }

  .streak-count {
    font-size: 1.2em;
    font-weight: bold;
    margin: 5px 0;
  }

  .streak-best {
    font-size: 0.9em;
    opacity: 0.8;
  }

  .streak-milestone {
    margin-top: 10px;
  }

  .streak-info {
    color: #333;
  }
</style>