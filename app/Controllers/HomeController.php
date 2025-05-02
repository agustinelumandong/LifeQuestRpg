<?php

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Controller;
use App\Models\User;
use Exception;
use Vtiful\Kernel\Excel;

class HomeController extends Controller
{

  protected $userModel;

  public function __construct()
  {
    $this->userModel = new User();
  }

  /**
   * Display the home page
   */
  public function index()
  {
    $currentUser = Auth::user();
    $view = !$currentUser ? 'home' : 'dashboard';

    return $this->view($view, [
      'title' => 'LifeQuestRPG',
      'message' => 'Mag LifeQuestRPG na!!',
      'currentUser' => $currentUser
    ]);
  }

  /**
   * Display the profile page
   */
  public function profile()
  {
    try {
      $currentUser = Auth::user();

      if (!$currentUser) {
        return $this->redirect('/login');
      }

      return $this->view('profile', [
        'title' => 'Profile',
        'content' => 'Welcome to your profile page!',
        'currentUser' => $currentUser,
      ]);
    } catch (Exception $e) {
      $_SESSION['error'] = 'An error occurred while loading your profile.';
      return $this->redirect('/');
    }
  }
}