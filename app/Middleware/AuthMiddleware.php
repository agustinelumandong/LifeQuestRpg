<?php

// app/Middleware/AuthMiddleware.php

namespace App\Middleware;

use App\Core\Auth;
use App\Core\Middleware;
use App\Models\UserStats;
use Closure;

class AuthMiddleware extends Middleware
{
  /**
   * Handle the request - check if user is logged in
   * 
   * @param mixed $request Request data
   * @param Closure $next Next middleware
   * @return mixed
   */
  public function handle($request, Closure $next): mixed
  {
    if (!isset($_SESSION['users'])) {
      // Store the intended URL in the session
      $_SESSION['intended_url'] = $_SERVER['REQUEST_URI'];

      // Redirect to login page
      header('Location: /login');
      exit;
    }

    return $next($request);
  }

  /**
   * Optional character creation check
   * Uncomment the call in handle() to enable this functionality
   * 
   * @return void
   */
  private function checkCharacterCreation(): void
  {
    if (!Auth::isLoggedIn()) {
      return;
    }

    $userId = Auth::getByUserId();
    $userStats = (new UserStats())->getUserStatsByUserId($userId);

    if (
      (!$userStats || empty($userStats['avatar_id']))
      && !str_contains($_SERVER['REQUEST_URI'], '/character/stepper')
    ) {
      // Redirect to character creation
      $_SESSION['warning'] = 'Please complete your character setup first!';
      header('Location: /character/stepper');
      exit;
    }
  }
}