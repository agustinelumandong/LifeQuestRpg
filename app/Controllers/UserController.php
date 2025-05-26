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
    // Get all users from the database
    $users = $this->userModel->all();

    // Simple sorting - newest first
    if (!empty($users)) {
      usort($users, function ($a, $b) {
        return $b['id'] - $a['id']; // Sort by ID descending
      });
    }

    return $this->view('users/index', [
      'title' => 'User Management',
      'users' => $users
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
    // Validate required fields
    if (!Input::post('name') || !Input::post('email') || !Input::post('password') || !Input::post('password_confirmation')) {
      $_SESSION['error'] = 'All fields are required!';
      $this->redirect('/users/create');
      return;
    }

    // Check if the email already exists
    if (Input::post('email') && $this->userModel->findByEmail(Input::post('email'))) {
      $_SESSION['error'] = 'Email already exists!';
      $this->redirect('/users/create');
      return;
    }

    // Check if the password and confirmation match
    if (Input::post('password') !== Input::post('password_confirmation')) {
      $_SESSION['error'] = 'Passwords do not match!';
      $this->redirect('/users/create');
      return;
    }    
    // Get form data
    $username = Input::post('username');
    $role = Input::post('role');

    // Only allow setting admin role if current user is admin
    if ($role === 'admin' && !Auth::isAdmin()) {
      $role = 'user'; // Force to user if not admin
    }

    // Create the user with provided data
    $data = Input::sanitize([
      'name' => Input::post('name'),
      'email' => Input::post('email'),
      'role' => $role ?? 'user',
      'username' => !empty($username) ? $username : Input::post('name'), // Use provided username or default to name
      'password' => password_hash(Input::post('password'), PASSWORD_DEFAULT),
      'coins' => 0, // Initial coins
      'created_at' => date('Y-m-d H:i:s')
    ]);

    $userId = $this->userModel->create($data);

    if ($userId) {
      // Initialize streak records for the new user
      try {
        $this->streakModel->initializeAllStreaks((int) $userId);
      } catch (Exception $e) {
        error_log("Failed to initialize streaks: " . $e->getMessage());
        // Continue anyway, not critical
      }

      // Initialize user stats
      try {
        $this->initializeUserStats($userId);
      } catch (Exception $e) {
        error_log("Failed to initialize stats: " . $e->getMessage());
        // Continue anyway, not critical
      }

      $_SESSION['success'] = 'User created successfully!';

      // Determine if we're in the admin section or regular user management
      $referrer = $_SERVER['HTTP_REFERER'] ?? '';
      if (strpos($referrer, '/admin/') !== false) {
        $this->redirect('/admin/users');
      } else {
        $this->redirect('/users');
      }
    } else {
      $_SESSION['error'] = 'Failed to create user.';
      $this->redirect('/users/create');
    }
  }
  public function show($id)
  {
    $user = $this->userModel->find($id);
    $userStats = $this->userStatsModel->getUserStatsByUserId($id);
    $currentUser = Auth::user();

    if (!$user) {
      $_SESSION['error'] = 'User not found';
      header('Location: /leaderboard');
      exit;
    }

    // Get current user ID safely
    $currentUserId = null;
    if (is_array($currentUser)) {
      $currentUserId = $currentUser['id'] ?? null;
    } elseif (is_object($currentUser)) {
      $currentUserId = $currentUser->id ?? null;
    }

    // Admin view shows a simplified version
    if (Auth::isAdmin() && $currentUserId != $id) {
      return $this->view('users/admin_show', [
        'title' => 'View User',
        'user' => $user,
        'userStats' => $userStats
      ]);
    }

    // If userStats is not found, try to handle it gracefully
    if (!$userStats) {
      $_SESSION['warning'] = 'User stats not found. Some data may be missing.';
      $userStats = [
        'physicalHealth' => 0,
        'mentalWellness' => 0,
        'personalGrowth' => 0,
        'careerStudies' => 0,
        'finance' => 0,
        'homeEnvironment' => 0,
        'relationshipsSocial' => 0,
        'passionHobbies' => 0,
        'level' => 1,
        'xp' => 0,
        'health' => 100
      ];
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

    // Handle password update with confirmation
    if (Input::post('password')) {
      if (Input::post('password') !== Input::post('password_confirmation')) {
        $_SESSION['error'] = 'Password and confirmation do not match.';
        $this->redirect("/users/{$id}/edit");
        return;
      }

      // Only update password if it's not empty and confirmation matches
      if (strlen(Input::post('password')) > 0) {
        $data['password'] = password_hash(Input::post('password'), PASSWORD_DEFAULT);
      }
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
    // Redirect to MarketplaceController inventory
    return $this->redirect('/marketplace/inventory');
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
  }  /**
     * Initialize user stats for a new user
     * 
     * @param int $userId The user ID
     * @return bool True if successful, false otherwise
     */
  private function initializeUserStats($userId)
  {
    $defaultStats = [
      'user_id' => $userId,
      'avatar_id' => 1,
      'objective' => 'Become the best version of myself',
      'level' => 1,
      'xp' => 0,
      'health' => 100,
      'physicalHealth' => 20,
      'mentalWellness' => 20,
      'personalGrowth' => 20,
      'careerStudies' => 20,
      'finance' => 20,
      'homeEnvironment' => 20,
      'relationshipsSocial' => 20,
      'passionHobbies' => 20
    ];

    try {
      return $this->userStatsModel->createUserStats($defaultStats);
    } catch (Exception $e) {
      error_log("Failed to initialize user stats: " . $e->getMessage());
      return false;
    }
  }

  /**
   * Reset a user's password to a random string and email it to them
   * 
   * @param int $id User ID
   * @return void
   */
  public function resetPassword($id)
  {
    // Check if admin
    if (!Auth::isAdmin()) {
      http_response_code(403);
      echo json_encode(['success' => false, 'message' => 'Unauthorized']);
      exit;
    }

    // Find the user
    $user = $this->userModel->find($id);
    if (!$user) {
      http_response_code(404);
      echo json_encode(['success' => false, 'message' => 'User not found']);
      exit;
    }

    // Generate a random password
    $newPassword = bin2hex(random_bytes(4)); // 8 character password

    // Update the user's password
    $updated = $this->userModel->update($id, [
      'password' => password_hash($newPassword, PASSWORD_DEFAULT)
    ]);

    if ($updated) {
      // In a real application, you would email the password to the user
      // For demonstration purposes, we'll just return it in the response
      echo json_encode([
        'success' => true,
        'message' => 'Password reset successfully',
        'newPassword' => $newPassword
      ]);
    } else {
      http_response_code(500);
      echo json_encode(['success' => false, 'message' => 'Failed to reset password']);
    }
    exit;
  }

  /**
   * Toggle a user's active status
   * 
   * @param int $id User ID
   * @return void
   */
  public function toggleStatus($id)
  {
    // Check if admin
    if (!Auth::isAdmin()) {
      http_response_code(403);
      echo json_encode(['success' => false, 'message' => 'Unauthorized']);
      exit;
    }

    // Find the user
    $user = $this->userModel->find($id);
    if (!$user) {
      http_response_code(404);
      echo json_encode(['success' => false, 'message' => 'User not found']);
      exit;
    }

    // Don't allow toggling admin users (except by themselves)
    if (isset($user['role']) && $user['role'] === 'admin') {
      http_response_code(403);
      $message = Auth::user()['id'] == $id ? 'Cannot disable your own admin account' : 'Cannot disable other admin accounts';
      echo json_encode(['success' => false, 'message' => $message]);
      exit;
    }

    // Toggle the status
    $isCurrentlyActive = !isset($user['is_disabled']) || !$user['is_disabled'];
    $updated = $this->userModel->update($id, [
      'is_disabled' => $isCurrentlyActive ? 1 : 0
    ]);

    if ($updated) {
      echo json_encode([
        'success' => true,
        'message' => $isCurrentlyActive ? 'User disabled successfully' : 'User enabled successfully',
        'newStatus' => !$isCurrentlyActive
      ]);
    } else {
      http_response_code(500);
      echo json_encode(['success' => false, 'message' => 'Failed to update user status']);
    }
    exit;
  }

  /**
   * Process bulk actions on users
   * 
   * @return void
   */
  public function bulkAction()
  {
    // Check if admin
    if (!Auth::isAdmin()) {
      http_response_code(403);
      echo json_encode(['success' => false, 'message' => 'Unauthorized']);
      exit;
    }

    $action = Input::post('action');
    $userIds = Input::post('user_ids');

    if (empty($userIds) || !is_array($userIds)) {
      http_response_code(400);
      echo json_encode(['success' => false, 'message' => 'No users selected']);
      exit;
    }

    $successCount = 0;
    $failCount = 0;

    switch ($action) {
      case 'delete':
        foreach ($userIds as $userId) {
          // Skip admin users
          $user = $this->userModel->find($userId);
          if (!$user || (isset($user['role']) && $user['role'] === 'admin')) {
            $failCount++;
            continue;
          }

          $deleted = $this->userModel->delete($userId);
          if ($deleted) {
            $successCount++;
          } else {
            $failCount++;
          }
        }
        break;

      case 'enable':
        foreach ($userIds as $userId) {
          $updated = $this->userModel->update($userId, ['is_disabled' => 0]);
          if ($updated) {
            $successCount++;
          } else {
            $failCount++;
          }
        }
        break;

      case 'disable':
        foreach ($userIds as $userId) {
          // Skip admin users
          $user = $this->userModel->find($userId);
          if (!$user || (isset($user['role']) && $user['role'] === 'admin')) {
            $failCount++;
            continue;
          }

          $updated = $this->userModel->update($userId, ['is_disabled' => 1]);
          if ($updated) {
            $successCount++;
          } else {
            $failCount++;
          }
        }
        break;

      default:
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Invalid action']);
        exit;
    }

    echo json_encode([
      'success' => true,
      'message' => "Action completed: $successCount users processed successfully" . ($failCount > 0 ? ", $failCount failed" : "")
    ]);
    exit;
  }
}
