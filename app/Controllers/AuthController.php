<?php

declare(strict_types=1);

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Controller;
use App\Core\Input;
use App\Models\User;
use App\Models\UserStats;
use App\Models\Streak;
use App\Models\ActivityLog;

class AuthController extends Controller
{

  protected $userModel;
  protected $userStats;
  protected $streakModel;
  protected $activityLogModel;

  public function __construct()
  {
    $this->userModel = new User();
    $this->userStats = new UserStats();
    $this->streakModel = new Streak();
    $this->activityLogModel = new ActivityLog();
  }


  /**
   * Display the login page
   */
  public function index()
  {
    return $this->view('auth/login', [
      'title' => 'Login'
    ]);
  }


  /**
   * Login & Authenticate the user
   */
  public function login()
  {
    // Validate the form
    $data = Input::sanitize([
      'email' => Input::post('email'),
      'password' => Input::post('password')
    ]);

    // Check if the user exists
    $user = User::authenticate($data['email'], $data['password']);

    if (!$user) {
      $_SESSION['error'] = 'Invalid email or password!';
      $this->redirect('/login');
    }

    if ($user && isset($user['password']) && password_verify($data['password'], $user['password'])) {
      // Create session
      Auth::login($user);
      // Log login activity for check-in streak with JSON formatted details

      $userId = $user['id'];

      $loginDetails = json_encode(['message' => 'User logged in', 'timestamp' => date('Y-m-d H:i:s')]);

      $this->activityLogModel->logActivity($userId, 'User Login', $loginDetails);

      $this->processLoginStreak($userId);

      $_SESSION['success'] = 'Welcome back, ' . $user['name'] . '!';

      // Check if user has completed character creation
      $userStats = $this->userStats->getUserStatsByUserId($userId);
      if (!$userStats || empty($userStats['avatar_id'])) {
        // If not, redirect to character creation stepper
        $this->redirect('/character/stepper');
      } else {
        // Check if the user is an admin
        if (Auth::isAdmin()) {
          // If admin, redirect to admin dashboard
          $this->redirect('/admin');
        } else {
          // Otherwise, redirect to regular dashboard
          $this->redirect('/');
        }
      }
    } else {
      $_SESSION['error'] = 'Invalid email or password!';
      $this->redirect('/login');
    }
  }


  /**
   * Display the registration page
   */
  public function register()
  {
    return $this->view('auth/register', [
      'title' => 'Register'
    ]);
  }


  /**
   * Store the user in the database
   */
  public function store()
  {
    // Validate the form
    if (!Input::post('name') || !Input::post('email') || !Input::post('password') || !Input::post('password_confirmation')) {
      $_SESSION['error'] = 'All fields are required!';
      $this->redirect('/register');
    }

    // Check if the email already exists
    if (Input::post('email') && $this->userModel->findByEmail(Input::post('email'))) {
      $_SESSION['error'] = 'Email already exists!';
      $this->redirect('/register');
    }

    // Check if the password and confirmation match
    if (Input::post('password') !== Input::post('password_confirmation')) {
      $_SESSION['error'] = 'Passwords do not match!';
      $this->redirect('/register');
    }

    // Create the user
    $user = Input::sanitize([
      'name' => Input::post('name'),
      'email' => Input::post('email'),
      'password' => password_hash(Input::post('password'), PASSWORD_DEFAULT),
    ]);

    $userId = $this->userModel->create($user);

    if ($userId) {
      // Initialize streak records for the new user
      $this->streakModel->initializeAllStreaks((int) $userId);

      // Log the user in automatically
      $createdUser = $this->userModel->getUserById($userId);
      if ($createdUser) {
        Auth::login($createdUser);
        // Log login activity for check-in streak with JSON formatted details
        $loginDetails = json_encode(['message' => 'New user registration and first login', 'timestamp' => date('Y-m-d H:i:s')]);

        // Log the activity
        $this->activityLogModel->logActivity((int) $userId, 'User Login', $loginDetails);

        $this->streakModel->recordActivity((int) $userId, 'check_in');
        $this->processLoginStreak((int) $userId);

        $_SESSION['success'] = 'Account created successfully! Let\'s setup your character.';

        $this->redirect('/character/stepper');

      } else {
        $_SESSION['success'] = 'User created successfully! Please login.';
        $this->redirect('/login');
      }
    } else {
      $_SESSION['error'] = 'Failed to create user!';
      $this->redirect('/register');
    }
  }


  /**
   * Logout the user
   */
  public function logout()
  {
    Auth::logout();
    header('Location: /login');
    exit;
  }


  public function processLoginStreak($userId)
  {

    try {
      $streakData = $this->streakModel->getStreak($userId, 'check_in');
      $today = date('Y-m-d');

      // If no streak found, initialize one
      if (!$streakData) {
        $this->streakModel->initializeStreak($userId, 'check_in');
        $streakData = $this->streakModel->getStreak($userId, 'check_in');
      }

      // If streak exists, check if we need to update it
      if ($streakData) {
        // Format last activity date for comparison
        $lastActivityDate = $streakData['last_streak_date'] ? date('Y-m-d', strtotime($streakData['last_streak_date'])) : null;

        // Only process if not already logged in today
        if ($lastActivityDate !== $today) {
          // Record the streak activity
          $this->streakModel->recordActivity($userId, 'check_in');

          // Get updated streak data to determine rewards
          $updatedStreakData = $this->streakModel->getStreak($userId, 'check_in');
          $currentStreak = $updatedStreakData['current_streak'] ?? 1;

          // Check for milestone rewards
          // Weekly milestone (7 days) or monthly milestone (30 days)
          if ($currentStreak % 7 === 0 || $currentStreak % 30 === 0) {
            $rewards = $this->streakModel->grantStreakRewards($userId, 'check_in', $currentStreak);

            // Add a session message about milestone rewards
            if ($currentStreak % 30 === 0) {
              $_SESSION['success'] .= " 🏆 Amazing! You've maintained a {$currentStreak}-day login streak! Earned: {$rewards['coins']} coins, {$rewards['xp']} XP.";
            } elseif ($currentStreak % 7 === 0) {
              $_SESSION['success'] .= " 🔥 Awesome! {$currentStreak}-day login streak! Earned: {$rewards['coins']} coins, {$rewards['xp']} XP.";
            }
          } else {
            // Regular daily reward
            $rewards = $this->streakModel->grantStreakRewards($userId, 'check_in', $currentStreak);

            // Add a subtle note about the streak
            if ($currentStreak > 1) {
              $_SESSION['success'] .= " ({$currentStreak}-day streak! +{$rewards['coins']} coins, +{$rewards['xp']} XP)";
            }
          }

          // Log streak milestone achievements
          if ($currentStreak % 30 === 0) {
            $this->activityLogModel->logActivity(
              $userId,
              'Achievement Unlocked',
              json_encode([
                'achievement' => "{$currentStreak}-day Login Streak",
                'reward_coins' => $rewards['coins'],
                'reward_xp' => $rewards['xp'],
                'timestamp' => date('Y-m-d H:i:s')
              ])
            );
          }
        }
      }

    } catch (\Exception $e) {
      // Handle any exceptions that may occur
      $_SESSION['error'] = 'Error processing streak: ' . $e->getMessage();
      $this->redirect('/login');
    }
  }

}
