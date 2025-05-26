<?php

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Controller;
use App\Models\TaskEvent;
use App\Models\User;
use Exception;
use App\Middleware\AuthMiddleware;
use App\Models\UserStats;
use App\Models\ActivityLog;
use App\Models\Streak;

class HomeController extends Controller
{

  protected $userModel;
  protected $taskEventModel;
  protected $userStatsModel;
  protected $activityLogModel;
  protected $streakModel;

  public function __construct()
  {
    $this->userModel = new User();
    $this->taskEventModel = new TaskEvent();
    $this->userStatsModel = new UserStats();
    $this->activityLogModel = new ActivityLog();
    $this->streakModel = new Streak();
  }

  /**
   * Display the home page
   * 
   * @var array $currentUser
   */
  public function index()
  {
    $currentUser = Auth::user();
    $events = $this->taskEventModel->getAllActiveEvents();
    $view = !$currentUser ? 'home' : 'dashboard';

    if ($currentUser && Auth::isAdmin()) {
      // If admin, redirect to admin dashboard
      $this->redirect('/admin');
    }

    // Only load user-specific data if logged in
    $userStats = null;
    $activities = [];
    $userStreaks = [];

    if ($currentUser) {
      $userId = Auth::getByUserId();
      $userStats = $this->userStatsModel->getUserStatsByUserId($userId);
      $activities = $this->activityLogModel->getRecentActivities($userId);

      // Get user streaks
      $userStreaks = $this->streakModel->getUserStreaks($userId);

      // If no streaks found, initialize them
      if (empty($userStreaks)) {
        $this->streakModel->initializeAllStreaks($userId);
        $userStreaks = $this->streakModel->getUserStreaks($userId);
      }
      // Record check-in streak if needed
      $checkInStreak = $userStreaks['check_in'] ?? null;
      $today = date('Y-m-d');

      if ($checkInStreak) {      // Get last streak date in Y-m-d format for comparison
        $lastStreakDate = null;
        if (!empty($checkInStreak['last_streak_date'])) {
          $lastStreakDate = date('Y-m-d', strtotime($checkInStreak['last_streak_date']));
        }

        if ($lastStreakDate !== $today) {
          // Update check-in streak with JSON formatted details
          $loginDetails = json_encode(['message' => 'Daily login', 'timestamp' => date('Y-m-d H:i:s')]);
          $this->activityLogModel->logActivity($userId, 'User Login', $loginDetails);
        }
      }
    }

    return $this->view($view, [
      'title' => 'LifeQuestRPG',
      'message' => 'Mag LifeQuestRPG na!!',
      'currentUser' => $currentUser,
      'userStats' => $userStats,
      'events' => $events,
      'activities' => $activities,
      'userStreaks' => $userStreaks
    ]);
  }

}