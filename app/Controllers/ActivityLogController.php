<?php

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Controller;
use App\Core\Input;
use App\Models\ActivityLog;


class ActivityLogController extends Controller
{
    protected $ActivityLogModel;

    public function __construct()
    {
        $this->ActivityLogModel = new ActivityLog();
    }
    public function index()
    {
        /** @var array $currentUser */
        $currentUser = Auth::user();
        $activities = $this->ActivityLogModel->getRecentActivities($currentUser['id']);

        $currentPage = isset($_GET['page']) ? (int) $_GET['page'] : 1;

        $paginator = $this->ActivityLogModel->paginates(
            $currentUser['id'],
            $currentPage,
            5,
            'log_timestamp',
            'DESC'
        );


        return $this->view('activitylogs/activities', [
            'title' => 'Activity Log',
            'activities' => $paginator->items(),
            'user' => $currentUser,
            'paginator' => $paginator
        ]);
    }

}