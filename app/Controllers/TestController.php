<?php

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Controller;

class TestController extends Controller
{
  public function testAuth()
  {
    $userIsLoggedIn = Auth::check();
    $currentUser = Auth::user();
    $isAdmin = Auth::isAdmin();

    return $this->view('tests/auth', [
      'title' => 'Auth Test',
      'isLoggedIn' => $userIsLoggedIn,
      'user' => $currentUser,
      'isAdmin' => $isAdmin
    ]);
  }
}
