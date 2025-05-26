<?php
namespace App\Core;

use App\Models\User;
use Exception;

abstract class Auth
{
  protected static $user = null;
  /**
   * Check if a user is logged in
   * 
   * @return bool
   */
  public static function check()
  {
    return isset($_SESSION['users']) && !empty($_SESSION['users']);
  }
  /**
   * Get the currently logged-in user
   * 
   * @return mixed User object or null
   */
  public static function user()
  {
    if (self::$user === null && self::check()) {
      $sessionUser = $_SESSION['users'];
      $userId = null;

      // Handle both array and object formats
      if (is_array($sessionUser)) {
        $userId = $sessionUser['id'] ?? null;
      } elseif (is_object($sessionUser)) {
        $userId = $sessionUser->id ?? null;
      } elseif (is_numeric($sessionUser)) {
        $userId = $sessionUser;
      }

      if ($userId) {
        self::$user = User::find($userId);
      }
    }
    return self::$user;
  }

  /**
   * Get user ID of the current user or specified user
   * 
   * @param mixed $user User object/array or null to use current user
   * @return int|null
   */
  public static function getByUserId($user = null)
  {
    $user = $user ?? self::user();
    if (!$user)
      return null;

    return is_array($user) ? ($user['id'] ?? null) : ($user->id ?? null);
  }
  /**
   * Check if the current user is an admin
   * 
   * @return bool
   */
  public static function isAdmin()
  {
    $user = self::user();
    if (!$user)
      return false;

    $role = null;

    // Handle different user data formats
    if (is_array($user)) {
      $role = $user['role'] ?? '';
    } elseif (is_object($user)) {
      $role = $user->role ?? '';
    }

    return $role === 'admin';
  }

  /**
   * Login a user
   * 
   * @param mixed $user User object/array
   * @return void
   * @throws Exception If user is invalid
   */
  public static function login($user)
  {
    if (!$user) {
      throw new Exception('User not found or invalid');
    }

    // Ensure theme settings are available
    if (!isset($user['theme'])) {
      $user['theme'] = 'light'; // Set default theme to light
    }

    if (!isset($user['color_scheme'])) {
      $user['color_scheme'] = 'default'; // Set default color scheme
    }

    $_SESSION['users'] = $user;
    self::$user = $user; // Cache the user
    session_regenerate_id(true);
  }

  /**
   * Logout the current user
   * 
   * @return void
   */
  public static function logout()
  {
    self::$user = null;
    session_unset();     // Remove all session variables
    session_destroy();   // Destroy the session
    session_regenerate_id(true);
  }

  /**
   * Check if the user is logged in (alias for check())
   * 
   * @return bool
   */
  public static function isLoggedIn(): bool
  {
    return self::check();
  }

  
}
