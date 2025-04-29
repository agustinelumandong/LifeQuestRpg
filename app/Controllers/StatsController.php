<?php

// app/Controllers/UserController.php

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Controller;
use App\Core\Input;
use App\Models\Tasks;
use App\Models\UserStats;
use App\Models\Activities;

use function PHPUnit\Framework\isEmpty;

class StatsController extends Controller 
{

    protected $UserStatsM;

    public function __construct() {
        $this->UserStatsM = new UserStats();
    }

    public function index() {
        $currentUser = Auth::user();

       $userStats = $this->UserStatsM->getByUserId($currentUser['id']);

        return $this->view('UserStats/statsBar', [
            'title' => 'StatsBar',
            'userStats' => $userStats
        ]);
    }

}