<?php

declare(strict_types=1);

namespace App\Controllers;

use App\Core\Controller;
use App\Models\UserStats;

class LeaderboardController extends Controller
{
  private UserStats $userStats;

  public function __construct()
  {
    $this->userStats = new UserStats();
  }

  public function index()
  {
    // Get all users with their stats, ordered by level and XP
    $rankings = $this->userStats->getAllUsersAndStats();

    return $this->view('leaderboard/index', [
      'title' => 'Leaderboard',
      'rankings' => $rankings
    ]);
  }
}