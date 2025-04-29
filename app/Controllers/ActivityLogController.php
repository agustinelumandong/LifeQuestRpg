<?php

// app/Controllers/UserController.php

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Controller;
use App\Core\Input;
use App\Models\ActivityLog;


class ActivityLogController extends Controller 
{

    protected $ActivityLogM;

    public function __construct() {
        $this->ActivityLogM = new ActivityLog();
    }

    public function index() {
        $currentUser = Auth::user();

       $activities = $this->ActivityLogM->getRecentActivities($currentUser['id']);

        return $this->view('ActivityLog/Activities', [
            'title' => 'Activity Log',
            'activities' => $activities
        ]);
    }

}