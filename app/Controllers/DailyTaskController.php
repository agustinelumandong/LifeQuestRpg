<?php

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Controller;
use App\Core\Input;
use App\Models\DailyTasks;
use App\Models\UserStats;
use App\Models\User;
use Exception;


class DailyTaskController extends Controller
{

    protected $DailyTaskModel;
    protected $UserStatsModel;
    protected $UserModel;

    public function __construct()
    {
        $this->DailyTaskModel = new DailyTasks();
        $this->UserStatsModel = new UserStats();
        $this->UserModel = new User();
    }

    public function index()
    {
        /** @var array $currentUser */
        $currentUser = Auth::user();

        $this->DailyTaskModel->resetDailyTasks();
        $dailyTasks = $this->DailyTaskModel->getDailyTasksByUserId($currentUser['id']);

        return $this->view('dailytask/index', [
            'title' => 'Daily Task',
            'dailyTasks' => $dailyTasks
        ]);
    }

    public function store()
    {
        /** @var array $currentUser */
        $currentUser = Auth::user();
        $difficulty = Input::post('difficulty');

        $xpRewards = [
            'easy' => 10,
            'medium' => 20,
            'hard' => 30,
        ];

        $coinRewards = [
            'easy' => 5,
            'medium' => 10,
            'hard' => 15,
        ];

        $xp = $xpRewards[$difficulty] ?? 0;
        $coins = $coinRewards[$difficulty] ?? 0;

        $data = Input::sanitize([
            'title' => Input::post('title'),
            'status' => Input::post('status'),
            'difficulty' => Input::post('difficulty'),
            'category' => Input::post('category'),
            'coins' => $coins,
            'xp' => $xp,
            'user_id' => $currentUser['id']
        ]);

        try {
            $created = $this->DailyTaskModel->create($data);

            if ($created) {
                $_SESSION['success'] = 'Daily Task Created Successfully';
                $this->redirect('/dailytask');
            } else {
                $_SESSION['error'] = 'Failed to Create Daily Task';
                $this->redirect('/dailytask');
            }
        } catch (Exception $e) {
            $_SESSION['error'] = 'Failed to create daily task: ' . $e->getMessage();
            $this->redirect('/dailytask');
        }
    }

    public function update($id)
    {
        /** @var array $currentUser */
        $currentUser = Auth::user();
        $difficulty = Input::post('difficulty');
        $dailyTasks = $this->DailyTaskModel->find($id);

        if ($currentUser !== $id && $dailyTasks['user_id'] !== $currentUser['id']) {
            $_SESSION['error'] = 'Unauthorized access!';
            $this->redirect('/dailytask');
            return;
        }

        $xpRewards = [
            'easy' => 10,
            'medium' => 20,
            'hard' => 30,
        ];

        $coinRewards = [
            'easy' => 5,
            'medium' => 10,
            'hard' => 15,
        ];

        $xp = $xpRewards[$difficulty] ?? 0;
        $coins = $coinRewards[$difficulty] ?? 0;

        $data = Input::sanitize([
            'title' => Input::post('title'),
            'status' => Input::post('status'),
            'difficulty' => Input::post('difficulty'),
            'category' => Input::post('category'),
            'coins' => $coins,
            'xp' => $xp,
            'user_id' => $currentUser['id']

        ]);

        try {
            $updated = $this->DailyTaskModel->update($id, $data);

            if ($updated) {
                $_SESSION['success'] = 'Daily Task Updated Successfully';
            } else {
                $_SESSION['error'] = 'Failed to Update Daily Task';
            }

            $this->redirect('/dailytask');
        } catch (Exception $e) {
            $_SESSION['error'] = 'Failed to update daily task: ' . $e->getMessage();
            $this->redirect('/dailytask');
        }
    }

    public function destroy($id)
    {
        /** @var array $currentUser */
        $currentUser = Auth::user();
        $task = $this->DailyTaskModel->find($id);
        if ($currentUser !== $id && $task['user_id'] !== $currentUser['id']) {
            $_SESSION['error'] = 'Unauthorized access!';
            $this->redirect('dailytask');
            return;
        }

        try {
            $deleted = $this->DailyTaskModel->delete($id);

            if ($deleted) {
                $_SESSION['success'] = 'Daily Task deleted successfully!';
                $this->redirect('/dailytask');
            } else {
                $_SESSION['error'] = 'Failed to delete daily task!';
                $this->redirect('/dailytask');
            }
        } catch (Exception $e) {
            $_SESSION['error'] = 'Failed to delete daily task: ' . $e->getMessage();
            $this->redirect('/dailytask');
        }

    }

    public function toggle($id)
    {
        /** @var array $currentUser */
        $currentUser = Auth::user();
        $dailyTasks = $this->DailyTaskModel->find($id);
        if ($currentUser !== $id && $dailyTasks['user_id'] !== $currentUser['id']) {
            $_SESSION['error'] = 'Unauthorized access!';
            $this->redirect('dailytask');
            return;
        }
        try {
            $newStatus = $dailyTasks['status'] === 'completed' ? 'pending' : 'completed';

            $updated = $this->DailyTaskModel->update($id, [
                "status" => $newStatus,
                "user_id" => $currentUser['id']
            ]);

            if ($updated) {
                if ($newStatus === 'completed') {

                    $xpReward = $dailyTasks['xp'];
                    $coinReward = $dailyTasks['coins'];
                    $user_id = $currentUser['id'];

                    $this->UserStatsModel->addXp($user_id, $xpReward);
                    $this->UserStatsModel->addSkillPoints($currentUser['id'], $dailyTasks['category'], $dailyTasks['difficulty']);
                    $this->UserModel->addCoin($user_id, $coinReward);

                    $_SESSION['success'] = 'Daily task updated!';
                    $this->redirect('/dailytask');
                }
            } else {
                $_SESSION['error'] = 'Daily task failed to update!';
                $this->redirect('/dailytask');
            }
        } catch (Exception $e) {
            $_SESSION['error'] = 'Failed to update daily task: ' . $e->getMessage();
            $this->redirect('/dailytask');
        }

    }
}