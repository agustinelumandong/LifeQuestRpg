<?php

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Controller;
use App\Core\Input;
use App\Models\User;
use App\Models\TaskEvent;
use App\Models\Tasks;
use App\Models\DailyTasks;
use App\Models\GoodHabits;
use App\Models\BadHabits;
use App\Models\ActivityLog;
use App\Models\Marketplace;
use App\Models\UserStats;

class AdminController extends Controller
{
  protected $userModel;
  protected $taskModel;
  protected $dailyTaskModel;
  protected $goodHabitsModel;
  protected $badHabitsModel;
  protected $taskEventModel;
  protected $marketplaceModel;
  protected $activityLogModel;
  protected $userStatsModel;

  public function __construct()
  {
    $this->userModel = new User();
    $this->taskModel = new Tasks();
    $this->dailyTaskModel = new DailyTasks();
    $this->goodHabitsModel = new GoodHabits();
    $this->badHabitsModel = new BadHabits();
    $this->taskEventModel = new TaskEvent();
    $this->marketplaceModel = new Marketplace();
    $this->activityLogModel = new ActivityLog();
    $this->userStatsModel = new UserStats();
  }

  /**
   * Display the admin dashboard
   */
  public function index()
  {
    // Get summary statistics for the dashboard
    $stats = [
      'total_users' => $this->userModel->count(),
      'total_tasks' => $this->taskModel->count(),
      'daily_tasks' => $this->dailyTaskModel->count(),
      'good_habits' => $this->goodHabitsModel->count(),
      'bad_habits' => $this->badHabitsModel->count(),
      'task_events' => $this->taskEventModel->count(),
      'marketplace_items' => $this->marketplaceModel->count(),
    ];
    // Calculate user growth (30-day comparison)
    $thirtyDaysAgo = date('Y-m-d H:i:s', strtotime('-30 days'));
    $usersLastMonth = $this->userModel->getCountBefore($thirtyDaysAgo);
    $userGrowth = $usersLastMonth > 0
      ? round((($stats['total_users'] - $usersLastMonth) / $usersLastMonth) * 100, 1)
      : 100; // If no users last month, then 100% growth
    $stats['user_growth'] = $userGrowth;

    // Get recent user registrations
    $recentUsers = $this->userModel->getRecent(5);

    // Get recent activity logs
    $recentActivity = $this->activityLogModel->getRecent(10);

    // Get task completion rate
    $completedTasks = $this->taskModel->getCompletedCount();
    $stats['task_completion_rate'] = $stats['total_tasks'] > 0
      ? round(($completedTasks / $stats['total_tasks']) * 100, 1)
      : 0;

    // Get daily active users (users with activity in the last 24 hours)
    $oneDayAgo = date('Y-m-d H:i:s', strtotime('-24 hours'));
    $stats['daily_active_users'] = $this->activityLogModel->getActiveUserCountSince($oneDayAgo);

    return $this->view('admin/dashboard', [
      'stats' => $stats,
      'recentUsers' => $recentUsers,
      'recentActivity' => $recentActivity,
      'title' => 'Admin Dashboard'
    ]);
  }  /**
     * Display the content management page
     */
  public function contentManagement()
  {
    // Get paginated task events (quests/missions)
    $paginator = $this->taskEventModel->paginate(
      page: \App\Core\Input::get('page', 1),
      perPage: 10,
      orderBy: 'id',
      direction: 'DESC'
    );

    return $this->view('admin/content_management', [
      'taskEvents' => $paginator->items(),
      'paginator' => $paginator,
      'title' => 'Content Management'
    ]);
  }

  /**
   * Display the marketplace management page
   */
  public function marketplaceManagement()
  {
    // Get all marketplace items
    $items = $this->marketplaceModel->all();

    return $this->view('admin/marketplace_management', [
      'items' => $items,
      'title' => 'Marketplace Management'
    ]);
  }  /**
     * Display the user management page
     */
  public function userManagement()
  {
    // Get current page from query parameter
    $currentPage = Input::get('page', 1);

    // Get search and filter parameters
    $search = Input::get('search', '');
    $roleFilter = Input::get('role', '');
    $statusFilter = Input::get('status', '');

    // Build conditions array for filtering
    $conditions = [];

    // Add role filter
    if ($roleFilter && in_array($roleFilter, ['admin', 'user'])) {
      $conditions['role'] = $roleFilter;
    }

    // Add status filter
    if ($statusFilter === 'active') {
      $conditions['is_disabled'] = 0;
    } elseif ($statusFilter === 'inactive') {
      $conditions['is_disabled'] = 1;
    }

    // Get paginated users with search and filters
    $paginator = $this->userModel->getPaginatedUsers(
      page: $currentPage,
      perPage: 10,
      orderBy: 'created_at',
      direction: 'DESC',
      conditions: $conditions,
      search: $search
    );

    return $this->view('admin/user_management', [
      'users' => $paginator->items(),
      'paginator' => $paginator,
      'title' => 'User Management'
    ]);
  }

  /**
   * Display the analytics and reports page
   */
  public function analytics()
  {
    // Get user engagement metrics
    $userStats = $this->userStatsModel->all();

    // Task completion statistics
    $completedTasks = $this->taskModel->getCompletedCount();
    $totalTasks = $this->taskModel->count();
    $completionRate = $totalTasks > 0 ? round(($completedTasks / $totalTasks) * 100, 2) : 0;

    // Daily tasks completion 
    $dailyTasksCompleted = $this->dailyTaskModel->getCompletedCount(); // We'll need to add this method
    $dailyTasksTotal = $this->dailyTaskModel->count();
    $dailyCompletionRate = $dailyTasksTotal > 0 ? round(($dailyTasksCompleted / $dailyTasksTotal) * 100, 2) : 0;

    // Good habits tracking
    $goodHabitsCompleted = $this->goodHabitsModel->getCompletedCount(); // We'll need to add this method
    $goodHabitsTotal = $this->goodHabitsModel->count();
    $goodHabitsCompletionRate = $goodHabitsTotal > 0 ? round(($goodHabitsCompleted / $goodHabitsTotal) * 100, 2) : 0;

    // Bad habits tracking
    $badHabitsAvoided = $this->badHabitsModel->getAvoidedCount(); // We'll need to add this method
    $badHabitsTotal = $this->badHabitsModel->count();
    $badHabitsAvoidanceRate = $badHabitsTotal > 0 ? round(($badHabitsAvoided / $badHabitsTotal) * 100, 2) : 0;

    // User activity trends (last 7 days)
    $lastSevenDays = date('Y-m-d H:i:s', strtotime('-7 days'));
    $activeUsersLastWeek = $this->activityLogModel->getActiveUserCountSince($lastSevenDays);
    $totalUsers = $this->userModel->count();
    $weeklyActiveRate = $totalUsers > 0 ? round(($activeUsersLastWeek / $totalUsers) * 100, 2) : 0;

    // Monthly active users
    $lastThirtyDays = date('Y-m-d H:i:s', strtotime('-30 days'));
    $activeUsersLastMonth = $this->activityLogModel->getActiveUserCountSince($lastThirtyDays);
    $monthlyActiveRate = $totalUsers > 0 ? round(($activeUsersLastMonth / $totalUsers) * 100, 2) : 0;

    // User growth data
    $newUsersToday = $this->userModel->getCountSince(date('Y-m-d 00:00:00')); // We'll need to add this method
    $newUsersYesterday = $this->userModel->getCountBetween(
      date('Y-m-d 00:00:00', strtotime('-1 day')),
      date('Y-m-d 23:59:59', strtotime('-1 day'))
    ); // We'll need to add this method
    $userGrowthDaily = $newUsersYesterday > 0 ? round((($newUsersToday - $newUsersYesterday) / $newUsersYesterday) * 100, 2) : 0;

    // Get popular events (based on completion)
    $popularEvents = $this->taskEventModel->getRecent(5);

    // For the user engagement chart
    $dailyUserData = $this->activityLogModel->getDailyUserCountLast30Days(); // We'll need to add this method

    // Category distribution data
    $categoryData = $this->taskModel->getCategoryDistribution(); // We'll need to add this method

    return $this->view('admin/analytics', [
      'userStats' => $userStats,
      'completionRate' => $completionRate,
      'completedTasks' => $completedTasks,
      'totalTasks' => $totalTasks,
      'dailyCompletionRate' => $dailyCompletionRate,
      'goodHabitsCompletionRate' => $goodHabitsCompletionRate,
      'badHabitsAvoidanceRate' => $badHabitsAvoidanceRate,
      'weeklyActiveRate' => $weeklyActiveRate,
      'monthlyActiveRate' => $monthlyActiveRate,
      'activeUsersLastWeek' => $activeUsersLastWeek,
      'activeUsersLastMonth' => $activeUsersLastMonth,
      'totalUsers' => $totalUsers,
      'newUsersToday' => $newUsersToday,
      'newUsersYesterday' => $newUsersYesterday,
      'userGrowthDaily' => $userGrowthDaily,
      'popularEvents' => $popularEvents,
      'dailyUserData' => $dailyUserData,
      'categoryData' => $categoryData,
      'title' => 'Analytics & Reports'
    ]);
  }
}
