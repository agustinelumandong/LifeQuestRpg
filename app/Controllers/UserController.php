<?php

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Controller;
use App\Core\Input;
use App\Models\Inventory;
use App\Models\Streak;
use App\Models\User;
use App\Models\UserStats;
use App\Models\ActivityLog;
use Exception;

class UserController extends Controller
{
  protected $userModel;
  protected $userInventoryModel;
  protected $userStatsModel;
  protected $activityLogModel;
  protected $streakModel;

  public function __construct()
  {
    $this->userInventoryModel = new Inventory();
    $this->userModel = new User();
    $this->userStatsModel = new UserStats();
    $this->activityLogModel = new ActivityLog();
    $this->streakModel = new Streak();
  }


  public function index()
  {
    $users = $this->userModel->all();
    $email = $this->userModel->find($users[0]['id']) ?? null;

    return $this->view('users/index', [
      'title' => 'Users',
      'users' => $users,
      'email' => $email
    ]);
  }

  public function create()
  {
    return $this->view('users/create', [
      'title' => 'Create User'
    ]);
  }

  public function store()
  {
    $data = Input::sanitize([
      'name' => Input::post('name'),
      'email' => Input::post('email'),
      'password' => password_hash(Input::post('password'), PASSWORD_DEFAULT)
    ]);

    $userId = $this->userModel->create($data);

    if ($userId) {
      $_SESSION['success'] = 'User created successfully!';
      $this->redirect('/users');
    } else {
      $_SESSION['error'] = 'Failed to create user.';
      $this->redirect('/users/create');
    }
  }

  public function show($id)
  {
    $user = $this->userModel->find($id);
    $userStats = $this->userStatsModel->getUserStatsByUserId($id);

    if (!$user || !$userStats) {
      $_SESSION['error'] = 'User not found';
      header('Location: /leaderboard');
      exit;
    }

    // Format skills data for the chart
    $skills = [
      [
        'name' => 'Physical Health',
        'current' => $userStats['physicalHealth'],
        'max' => 100,
        'level' => ceil($userStats['physicalHealth'] / 20),
        'icon' => 'bi-heart-pulse-fill',
        'chart_value' => $userStats['physicalHealth'] / 33
      ],
      [
        'name' => 'Mental Wellness',
        'current' => $userStats['mentalWellness'],
        'max' => 100,
        'level' => ceil($userStats['mentalWellness'] / 20),
        'icon' => 'bi-brain-fill',
        'chart_value' => $userStats['mentalWellness'] / 33
      ],
      [
        'name' => 'Personal Growth',
        'current' => $userStats['personalGrowth'],
        'max' => 100,
        'level' => ceil($userStats['personalGrowth'] / 20),
        'icon' => 'bi-person-fill-up',
        'chart_value' => $userStats['personalGrowth'] / 33
      ],
      [
        'name' => 'Career / Studies',
        'current' => $userStats['careerStudies'],
        'max' => 100,
        'level' => ceil($userStats['careerStudies'] / 20),
        'icon' => 'bi-briefcase-fill',
        'chart_value' => $userStats['careerStudies'] / 33
      ],
      [
        'name' => 'Finance',
        'current' => $userStats['finance'],
        'max' => 100,
        'level' => ceil($userStats['finance'] / 20),
        'icon' => 'bi-cash-stack-fill',
        'chart_value' => $userStats['finance'] / 33
      ],
      [
        'name' => 'Home Environment',
        'current' => $userStats['homeEnvironment'],
        'max' => 100,
        'level' => ceil($userStats['homeEnvironment'] / 20),
        'icon' => 'bi-house-fill',
        'chart_value' => $userStats['homeEnvironment'] / 33
      ],
      [
        'name' => 'Relationships Social',
        'current' => $userStats['relationshipsSocial'],
        'max' => 100,
        'level' => ceil($userStats['relationshipsSocial'] / 20),
        'icon' => 'bi-people-fill',
        'chart_value' => $userStats['relationshipsSocial'] / 33
      ],
      [
        'name' => 'Passion Hobbies',
        'current' => $userStats['passionHobbies'],
        'max' => 100,
        'level' => ceil($userStats['passionHobbies'] / 20),
        'icon' => 'bi-stars-fill',
        'chart_value' => $userStats['passionHobbies'] / 33
      ]
    ];

    return $this->view('users/show', [
      'user' => $user,
      'userStats' => $userStats,
      'skills' => $skills
    ]);
  }

  public function edit($id)
  {
    $user = $this->userModel->find($id);

    if (!$user) {
      $_SESSION['error'] = 'User not found.';
      $this->redirect('/users');
    }

    return $this->view('users/edit', [
      'title' => 'Edit User',
      'user' => $user
    ]);
  }

  public function update($id)
  {
    $data = Input::sanitize([
      'name' => Input::post('name'),
      'email' => Input::post('email')
    ]);

    if (Input::post('password')) {
      $data['password'] = password_hash(Input::post('password'), PASSWORD_DEFAULT);
    }

    $updated = $this->userModel->update($id, $data);

    if ($updated) {
      $_SESSION['success'] = 'User updated successfully!';
      $this->redirect('/users');
    } else {
      $_SESSION['error'] = 'Failed to update user.';
      $this->redirect("/users/{$id}/edit");
    }
  }

  public function destroy($id): void
  {
    $deleted = $this->userModel->delete($id);

    if ($deleted) {
      $_SESSION['success'] = 'User deleted successfully!';
    } else {
      $_SESSION['error'] = 'Failed to delete user.';
    }

    $this->redirect('/users');
  }

  public function showTaskDailyPage()
  {
    return $this->view('daily-task/task');
  }

  public function inventory()
  {
    // Get the logged-in user
    $user = Auth::user();

    // Check if user exists
    if (!$user) {
      $_SESSION['error'] = 'User not found or not logged in.';
      $this->redirect('/');
      return;
    }
    // Get user ID more reliably
    $userId = $user['id'] ?? $user->id ?? null;


    if (!$userId) {
      $_SESSION['error'] = 'Invalid user data.';
      $this->redirect('/');
      return;
    }

    try {
      $currentPage = isset($_GET['page']) ? (int) $_GET['page'] : 1;
      // Implement pagination for inventory items
      $paginator = $this->userInventoryModel->getPaginatedUserItemNames(
        userId: $userId,
        page: $currentPage,
        perPage: 12,
        orderBy: 'user_id',
        direction: 'DESC'
      );


    } catch (Exception $e) {
      $_SESSION['error'] = 'Failed to fetch user items: ' . $e->getMessage();
      $paginator = null;
    }

    return $this->view('users/inventory', [
      'title' => 'Inventory',
      'items' => $paginator ? $paginator->items() : [],
      'paginator' => $paginator,
    ]);
  }

  public function profile()
  {
    /**
     * @var array $currentUser
     */
    $currentUser = Auth::user();
    $user = $this->userModel->find($currentUser['id']);
    $userStats = $this->userStatsModel->getUserStatsByUserId(Auth::getByUserId());
    $userStreaks = $this->streakModel->getUserStreaks($currentUser['id']);

    $streakLabels = [
      'check_in' => 'Daily Login',
      'task_completion' => 'Task Completion',
      'dailtask_completion' => 'Daily Tasks',
      'GoodHabits_completion' => 'Good Habits',
      'journal_writing' => 'Journal Writing'
    ];

    $skills =
      [
        [
          'name' => 'Physical Health',
          'value' => $userStats['physicalHealth'],
          'icon' => 'bi-heart',
          'level' => floor($userStats['physicalHealth'] / 20) + 1,
          'current' => $userStats['physicalHealth'] % 20,
          'max' => 20,
          'chart_value' => $userStats['physicalHealth'] / 33
        ],
        [
          'name' => 'Mental Wellness',
          'value' => $userStats['mentalWellness'],
          'icon' => 'bi-brain',
          'level' => floor($userStats['mentalWellness'] / 20) + 1,
          'current' => $userStats['mentalWellness'] % 20,
          'max' => 20,
          'chart_value' => $userStats['mentalWellness'] / 33
        ],
        [
          'name' => 'Personal Growth',
          'value' => $userStats['personalGrowth'],
          'icon' => 'bi-graph-up',
          'level' => floor($userStats['personalGrowth'] / 20) + 1,
          'current' => $userStats['personalGrowth'] % 20,
          'max' => 20,
          'chart_value' => $userStats['personalGrowth'] / 33
        ],
        [
          'name' => 'Career & Studies',
          'value' => $userStats['careerStudies'],
          'icon' => 'bi-briefcase',
          'level' => floor($userStats['careerStudies'] / 20) + 1,
          'current' => $userStats['careerStudies'] % 20,
          'max' => 20,
          'chart_value' => $userStats['careerStudies'] / 33
        ],
        [
          'name' => 'Finance',
          'value' => $userStats['finance'],
          'icon' => 'bi-cash-coin',
          'level' => floor($userStats['finance'] / 20) + 1,
          'current' => $userStats['finance'] % 20,
          'max' => 20,
          'chart_value' => $userStats['finance'] / 33
        ],
        [
          'name' => 'Relationships & Social',
          'value' => $userStats['relationshipsSocial'],
          'icon' => 'bi-people',
          'level' => floor($userStats['relationshipsSocial'] / 20) + 1,
          'current' => $userStats['relationshipsSocial'] % 20,
          'max' => 20,
          'chart_value' => $userStats['relationshipsSocial'] / 33
        ],
        [
          'name' => 'Passion & Hobbies',
          'value' => $userStats['passionHobbies'],
          'icon' => 'bi-palette',
          'level' => floor($userStats['passionHobbies'] / 20) + 1,
          'current' => $userStats['passionHobbies'] % 20,
          'max' => 20,
          'chart_value' => $userStats['passionHobbies'] / 33
        ],
      ];

    if (!$user) {
      $_SESSION['error'] = 'User not found.';
      $this->redirect('/users');
    }

    return $this->view('users/profile', [
      'title' => 'Profile',
      'user' => $user,
      'userStats' => $userStats,
      'skills' => $skills,
      'userStreaks' => $userStreaks,
      'streakLabels' => $streakLabels
    ]);
  }

  public function poke($id)
  {
    // Check if user exists
    $user = $this->userModel->find($id);
    if (!$user) {
      http_response_code(404);
      echo json_encode(['success' => false, 'message' => 'User not found']);
      return;
    }

    // Check if user is poking themselves
    if ($id == $_SESSION['users']['id']) {
      http_response_code(400);
      echo json_encode(['success' => false, 'message' => 'You cannot poke yourself!']);
      return;
    }

    // Get current user's info
    $currentUser = $this->userModel->find($_SESSION['users']['id']);

    try {
      // Log the poke action using ActivityLog model
      $logged = $this->activityLogModel->logPoke($id, $_SESSION['users']['id'], $currentUser['username']);

      if ($logged) {
        echo json_encode(['success' => true, 'message' => 'You poked ' . $user['username'] . '!']);
      } else {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Failed to poke user']);
      }
    } catch (Exception $e) {
      http_response_code(500);
      echo json_encode(['success' => false, 'message' => 'An error occurred while poking user']);
    }
  }

  public function settings()
  {
    /** @var array $currentUser */
    $currentUser = Auth::user();
    $userStats = $this->userStatsModel->getUserStatsByUserId($currentUser['id']);

    return $this->view('users/settings', [
      'title' => 'Settings',
      'currentUser' => $currentUser,
      'userStats' => $userStats
    ]);
  }

  public function updateSettings()
  {
    /** @var array $currentUser */
    $currentUser = Auth::user();

    // Process different types of settings updates based on form data
    $updateType = Input::post('update_type');
    $updated = false;

    switch ($updateType) {
      case 'profile':
        // Handle profile updates (username, email)
        $data = Input::sanitize([
          'username' => Input::post('username'),
          'email' => Input::post('email')
        ]);

        // Only update password if provided
        if (Input::post('password')) {
          $data['password'] = password_hash(Input::post('password'), PASSWORD_DEFAULT);
        }

        $updated = $this->userModel->update($currentUser['id'], $data);
        break;
      case 'avatar':
        // Handle avatar changes
        $avatarId = (int) Input::post('avatar_id');
        $userStats = $this->userStatsModel->getUserStatsByUserId($currentUser['id']);
        $updated = $this->userStatsModel->update($userStats['id'], [
          'avatar_id' => $avatarId
        ]);
        break;

      case 'notifications':
        // Handle notification settings
        $data = [
          'email_notifications' => Input::post('email_notifications') ? 1 : 0,
          'task_reminders' => Input::post('task_reminders') ? 1 : 0,
          'achievement_alerts' => Input::post('achievement_alerts') ? 1 : 0,
        ];

        $updated = $this->userModel->update($currentUser['id'], $data);
        break;
      case 'theme':
        // Handle theme settings
        $data = [
          'theme' => Input::post('theme'),
          'color_scheme' => Input::post('color_scheme'),
        ];

        $updated = $this->userModel->update($currentUser['id'], $data);

        // Update session with new theme settings for immediate effect
        if ($updated) {
          $_SESSION['users']['theme'] = $data['theme'];
          $_SESSION['users']['color_scheme'] = $data['color_scheme'];
        }
        break;
    }

    if ($updated) {
      $_SESSION['success'] = 'Settings updated successfully!';

      // Check if this is an AJAX request and respond accordingly
      if (isset($_SERVER['HTTP_X_REQUESTED_WITH']) && strtolower($_SERVER['HTTP_X_REQUESTED_WITH']) === 'xmlhttprequest') {
        header('Content-Type: application/json');
        echo json_encode(['success' => true, 'message' => 'Settings updated successfully!']);
        exit;
      }

      return $this->redirect('/settings');
    } else {
      $_SESSION['error'] = 'There was a problem updating your settings.';

      // Check if this is an AJAX request and respond accordingly
      if (isset($_SERVER['HTTP_X_REQUESTED_WITH']) && strtolower($_SERVER['HTTP_X_REQUESTED_WITH']) === 'xmlhttprequest') {
        header('Content-Type: application/json');
        echo json_encode(['success' => false, 'message' => 'There was a problem updating your settings.']);
        exit;
      }

      return $this->redirect('/settings');
    }
  }

  public function exportData()
  {
    /** @var array $currentUser */
    $currentUser = Auth::user();

    // Get all user data
    $userData = $this->userModel->find($currentUser['id']);
    $userStats = $this->userStatsModel->getUserStatsByUserId($currentUser['id']);

    // Get other user-related data (tasks, habits, etc.)
    // This would depend on your specific models and data structure

    // Create export data array
    $exportData = [
      'user' => $userData,
      'stats' => $userStats,
      // Add other data as needed
    ];

    // Set headers for download
    header('Content-Type: application/json');
    header('Content-Disposition: attachment; filename="lifequest_data_' . $currentUser['username'] . '.json"');

    // Output JSON data
    echo json_encode($exportData, JSON_PRETTY_PRINT);
    exit;
  }

  public function deleteAccount()
  {
    /** @var array $currentUser */
    $currentUser = Auth::user();
    $password = Input::post('password');

    // Verify password
    if (!password_verify($password, $currentUser['password'])) {
      $_SESSION['error'] = 'Incorrect password. Account not deleted.';
      $this->redirect('/settings');
      return;
    }

    // Delete user account and related data
    $deleted = $this->userModel->delete($currentUser['id']);

    if ($deleted) {
      // Log the user out
      Auth::logout();
      $_SESSION['success'] = 'Your account has been deleted successfully.';
      $this->redirect('/login');
    } else {
      $_SESSION['error'] = 'Failed to delete account. Please try again.';
      $this->redirect('/settings');
    }
  }
}
