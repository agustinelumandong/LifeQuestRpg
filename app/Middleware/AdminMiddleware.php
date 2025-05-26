<?php

namespace App\Middleware;

use App\Core\Auth;
use App\Core\Middleware;
use App\Models\Profile;
use App\Models\User;
use Closure;

class AdminMiddleware extends Middleware
{
  public function handle($request, Closure $next)
  {
    // Check if user is logged in
    if (!Auth::check()) {
      $_SESSION['error'] = 'You must be logged in to access this page';
      header('Location: /login');
      exit;
    }

    // Get the user data
    $user = Auth::user();

    if (!$user) {
      $_SESSION['error'] = 'User session data is invalid.';
      header('Location: /login');
      exit;
    }

    if (Auth::check() && Auth::isAdmin()) {
      // If admin is trying to access regular dashboard, redirect to admin
      if ($request === '/' || $request === 'dashboard') {
        header('Location: /admin');
      }
    }

    // Check if user is admin
    if (!Auth::isAdmin()) {
      $_SESSION['error'] = 'You do not have permission to access this page';
      header('Location: /');
      exit;
    }

    return $next($request);
  }
}
