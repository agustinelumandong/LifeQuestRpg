<?php
namespace App\Models;

use App\Core\Model;

class Streak extends Model
{
  protected static $table = 'streaks_view';

  /**
   * Get streak info for a user and streak type
   * @param int $userId
   * @param string $streakType
   * @return array|null
   */
  public function getStreak($userId, $streakType = 'check_in')
  {
    return self::$db->query("SELECT * FROM " . static::$table . " WHERE user_id = ? AND streak_type = ?")
      ->bind([1 => $userId, 2 => $streakType])
      ->execute()
      ->fetch();
  }

  /**
   * Get all streak types for a user
   * @param int $userId
   * @return array
   */
  public function getUserStreaks($userId)
  {
    $streaks = self::$db->query("SELECT * FROM " . static::$table . " WHERE user_id = ?")
      ->bind([1 => $userId])
      ->execute()
      ->fetchAll();

    if (!$streaks) {
      return [];
    }

    // Transform to associative array by streak_type for easier access
    $result = [];
    foreach ($streaks as $streak) {
      $result[$streak['streak_type']] = $streak;
    }

    return $result;
  }

  /**
   * Initialize a streak for a new user
   * @param int $userId
   * @param string $streakType
   * @ return bool|int
   */
  public function initializeStreak($userId, $streakType = 'check_in')
  {
    return self::$db->query("INSERT INTO streaks (user_id, streak_type, current_streak, longest_streak, last_streak_date) 
                               VALUES (?, ?, 0, 0, NOW())")
      ->bind([1 => $userId, 2 => $streakType])
      ->execute();
  }

  /**
   * Record user activity and update streak manually (when not using triggers)
   * @param int $userId
   * @param string $streakType
   * @ return bool|int
   */
  public function recordActivity($userId, $streakType = 'check_in')
  {
    $streak = $this->getStreak($userId, $streakType);
    $today = date('Y-m-d');

    if (!$streak) {
      // Initialize new streak record - use base table, not the view
      return self::$db->query("INSERT INTO streaks (user_id, streak_type, current_streak, longest_streak, last_streak_date) 
                                  VALUES (?, ?, 1, 1, NOW())")
        ->bind([
          1 => $userId,
          2 => $streakType
        ])
        ->execute();
    }

    // Get streak date in Y-m-d format for comparison
    $lastStreakDate = null;
    if (!empty($streak['last_streak_date'])) {
      $lastStreakDate = date('Y-m-d', strtotime($streak['last_streak_date']));
    }

    // Calculate streak based on date comparison
    if ($lastStreakDate === null) {
      // First activity
      $newStreak = 1;
    } else if ($today === $lastStreakDate) {
      // Already logged in today, no change to streak
      return true;
    } else if ($today === date('Y-m-d', strtotime($lastStreakDate . ' +1 day'))) {
      // Consecutive day
      $newStreak = $streak['current_streak'] + 1;
    } else if (strtotime($today) > strtotime($lastStreakDate)) {
      // It's a future date but not consecutive - streak broken
      $newStreak = 1;
    } else {
      // Something's wrong with dates (possibly server time issue)
      $newStreak = 1;
    }


    $longestStreak = max($streak['longest_streak'], $newStreak);

    return self::$db->query("UPDATE streaks SET 
                              current_streak = ?, 
                              longest_streak = ?, 
                              last_streak_date = NOW()
                              WHERE user_id = ? AND streak_type = ?")
      ->bind([
        1 => $newStreak,
        2 => $longestStreak,
        3 => $userId,
        4 => $streakType
      ])
      ->execute();
  }

  /**
   * Calculate and grant rewards based on streak milestones
   * @param int $userId
   * @param string $streakType
   * @param int $streakCount
   * @ return void
   */
  public function grantStreakRewards($userId, $streakType, $streakCount)
  {
    $userStatsModel = new UserStats();
    $userModel = new User();

    // Base rewards
    $coinsReward = 0;
    $xpReward = 0;

    // Customize rewards based on streak type
    switch ($streakType) {
      case 'check_in':
        $coinsReward = 5;
        $xpReward = 10;
        break;

      case 'task_completion':
        $coinsReward = 10;
        $xpReward = 15;
        break;

      case 'dailtask_completion':
        $coinsReward = 15;
        $xpReward = 20;
        break;

      case 'GoodHabits_completion':
        $coinsReward = 20;
        $xpReward = 25;
        break;

      case 'journal_writing':
        $coinsReward = 10;
        $xpReward = 20;
        break;
    }

    // Apply milestone bonuses
    if ($streakCount % 7 === 0) {
      // Weekly milestone bonus
      $coinsReward += 20;
      $xpReward += 30;
    }

    if ($streakCount % 30 === 0) {
      // Monthly milestone bonus
      $coinsReward += 100;
      $xpReward += 100;

      // Log significant achievement
      $activityLogger = new ActivityLog();
      $activityLogger->logActivity(
        $userId,
        'Achievement Unlocked',
        json_encode([
          'achievement' => $streakCount . '-day ' . str_replace('_', ' ', $streakType) . ' streak',
          'reward_coins' => $coinsReward,
          'reward_xp' => $xpReward
        ])
      );
    }

    // Grant rewards using the correct methods
    $userModel->addCoin($userId, $coinsReward);
    $userStatsModel->addXp($userId, $xpReward);

    return [
      'coins' => $coinsReward,
      'xp' => $xpReward
    ];
  }

  /**
   * Initialize all streak types for a new user
   * @param int $userId
   * @return void
   */
  public function initializeAllStreaks($userId)
  {
    $streakTypes = [
      'check_in',
      'task_completion',
      'dailtask_completion',
      'GoodHabits_completion',
      'journal_writing'
    ];

    foreach ($streakTypes as $type) {
      $this->initializeStreak($userId, $type);
    }
  }
}
