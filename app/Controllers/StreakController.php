<?php

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Controller;
use App\Core\Input;
use App\Models\Streak;
use App\Models\User;
use App\Models\UserStats;
use App\Models\ActivityLog;
use Exception;

class StreakController extends Controller
{
  protected $streakModel;
  protected $userModel;
  protected $userStatsModel;
  protected $activityLogModel;

  public function __construct()
  {
    $this->streakModel = new Streak();
    $this->userModel = new User();
    $this->userStatsModel = new UserStats();
    $this->activityLogModel = new ActivityLog();
  }

  /**
   * Display user streaks
   */
  public function index()
  {
    // Check if user is logged in
    if (!Auth::check()) {
      $this->redirect('/login');
      return;
    }

    $userId = Auth::getByUserId();
    $userStreaks = $this->streakModel->getUserStreaks($userId);

    // If no streaks found, initialize them
    if (empty($userStreaks)) {
      $this->streakModel->initializeAllStreaks($userId);
      $userStreaks = $this->streakModel->getUserStreaks($userId);
    }

    // Format streak types for display
    $streakLabels = [
      'check_in' => 'Daily Login',
      'task_completion' => 'Task Completion',
      'dailtask_completion' => 'Daily Tasks',
      'GoodHabits_completion' => 'Good Habits',
      'journal_writing' => 'Journal Writing'
    ];

    return $this->view('streaks/index', [
      'title' => 'Your Activity Streaks',
      'userStreaks' => $userStreaks,
      'streakLabels' => $streakLabels
    ]);
  }

  /**
   * Manually record activity (can be called via API)
   */
  public function recordActivity()
  {
    if (!Auth::check()) {
      return $this->jsonResponse(['success' => false, 'message' => 'Authentication required']);
    }

    $userId = Auth::getByUserId();
    $streakType = Input::post('streak_type');

    // Validate streak type
    $validTypes = ['check_in', 'task_completion', 'dailtask_completion', 'GoodHabits_completion', 'journal_writing'];
    if (!in_array($streakType, $validTypes)) {
      return $this->jsonResponse(['success' => false, 'message' => 'Invalid streak type']);
    }

    try {
      $result = $this->streakModel->recordActivity($userId, $streakType);

      if ($result) {
        // Get updated streak info
        $streak = $this->streakModel->getStreak($userId, $streakType);

        // Check if it's a milestone
        $isMilestone = ($streak['current_streak'] > 0 &&
          ($streak['current_streak'] % 7 === 0 || $streak['current_streak'] % 30 === 0));

        // If it's a milestone, grant rewards
        $rewards = null;
        if ($isMilestone) {
          $rewards = $this->streakModel->grantStreakRewards($userId, $streakType, $streak['current_streak']);
        }

        return $this->jsonResponse([
          'success' => true,
          'message' => 'Streak updated successfully',
          'streak' => $streak,
          'isMilestone' => $isMilestone,
          'rewards' => $rewards
        ]);
      } else {
        return $this->jsonResponse(['success' => false, 'message' => 'Failed to update streak']);
      }
    } catch (Exception $e) {
      return $this->jsonResponse(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
    }
  }

  /**
   * Grant rewards for streak milestones (can be called via API)
   */
  public function grantRewards($streakType, $streakCount)
  {
    if (!Auth::check()) {
      return $this->jsonResponse(['success' => false, 'message' => 'Authentication required']);
    }

    $userId = Auth::getByUserId();

    // Validate streak type
    $validTypes = ['check_in', 'task_completion', 'dailtask_completion', 'GoodHabits_completion', 'journal_writing'];
    if (!in_array($streakType, $validTypes)) {
      return $this->jsonResponse(['success' => false, 'message' => 'Invalid streak type']);
    }

    // Validate streak count is a milestone
    $streakCount = (int) $streakCount;
    if ($streakCount <= 0 || ($streakCount % 7 !== 0 && $streakCount % 30 !== 0)) {
      return $this->jsonResponse(['success' => false, 'message' => 'Invalid milestone']);
    }

    try {
      // Verify streak count matches user's actual streak
      $streak = $this->streakModel->getStreak($userId, $streakType);
      if (!$streak || $streak['current_streak'] != $streakCount) {
        return $this->jsonResponse(['success' => false, 'message' => 'Streak count mismatch']);
      }

      // Grant rewards
      $rewards = $this->streakModel->grantStreakRewards($userId, $streakType, $streak['current_streak']);

      return $this->jsonResponse([
        'success' => true,
        'message' => 'Rewards granted successfully',
        'rewards' => $rewards
      ]);
    } catch (Exception $e) {
      return $this->jsonResponse(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
    }
  }

  /**
   * Helper function to return JSON responses
   */
  private function jsonResponse($data)
  {
    header('Content-Type: application/json');
    echo json_encode($data);
    exit;
  }
}
