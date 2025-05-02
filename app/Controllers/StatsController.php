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

    protected $UserStatsModel;

    public function __construct()
    {
        $this->UserStatsModel = new UserStats();
    }

    public function index()
    {
        /** @var array $currentUser */
        $currentUser = Auth::user();
        $userStats = $this->UserStatsModel->getByUserId($currentUser['id']);

        return $this->view('UserStats/statsBar', [
            'title' => 'StatsBar',
            'userStats' => $userStats
        ]);
    }

}