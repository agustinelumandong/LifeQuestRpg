<?php

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Controller;
use App\Core\Input;
use App\Models\Tasks;
use App\Models\UserStats;
use App\Models\User;

use Exception;

class TaskController extends Controller
{

    protected $TaskModel;
    protected $UserStatsModel;
    protected $UserModel;


    public function __construct()
    {
        $this->TaskModel = new Tasks();
        $this->UserStatsModel = new UserStats();
        $this->UserModel = new User();

    }

    public function index()
    {
        $currentUser = Auth::user();
        $tasks = $this->TaskModel->getTasksByUserId($currentUser['id']);
        $userStats = $this->UserStatsModel->getByUserId($currentUser['id']);

        return $this->view('task/index', [
            'title' => 'tasks',
            'tasks' => $tasks,
            'userStats' => $userStats,
            'currentUser' => $currentUser,

        ]);

    }

    public function store()
    {
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
            $created = $this->TaskModel->create($data);

            if ($created) {
                $_SESSION['success'] = 'Task created successfully!';
            } else {
                $_SESSION['error'] = 'Failed to create task!';
            }
            $this->redirect('/task');

        } catch (Exception $e) {
            $_SESSION['error'] = 'Failed to create task:' . $e->getMessage();
            $this->redirect('/task');
        }
    }

    public function update($id)
    {
        $currentUser = Auth::user();
        $difficulty = Input::post('difficulty');
        $task = $this->TaskModel->find($id);

        if ($currentUser !== $id && $task['user_id'] !== $currentUser['id']) {
            $_SESSION['error'] = 'Unauthorized access!';
            $this->redirect('/task');
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
            'category' => Input::post('category'),
            'difficulty' => Input::post('difficulty'),
            'coins' => $coins,
            'xp' => $xp,
            'user_id' => $currentUser['id']

        ]);

        try {
            $updated = $this->TaskModel->update($id, $data);

            if ($updated) {
                $_SESSION['success'] = 'Task updated successfully!';
            } else {
                $_SESSION['error'] = 'Failed to update task!';
            }

            $this->redirect('/task');
        } catch (Exception $e) {
            $_SESSION['error'] = 'Failed to update task:' . $e->getMessage();
            $this->redirect('/task');
        }
    }

    public function destroy($id)
    {
        $currentUser = Auth::user();
        $task = $this->TaskModel->find($id);

        if ($currentUser !== $id && $task['user_id'] !== $currentUser['id']) {
            $_SESSION['error'] = 'Unauthorized access!';
            $this->redirect('/task');
            return;
        }

        try {
            $deleted = $this->TaskModel->delete($id);

            if ($deleted) {
                $_SESSION['success'] = 'Task deleted successfully!';
                $this->redirect('/task');
            } else {
                $_SESSION['error'] = 'Failed to delete task!';
                $this->redirect('/task');
            }

        } catch (Exception $e) {
            $_SESSION['error'] = 'Failed to delete task:' . $e->getMessage();
            $this->redirect('/task');
        }
    }

    public function toggle($id)
    {
        $currentUser = Auth::user();
        $task = $this->TaskModel->find($id);
        if ($currentUser !== $id && $task['user_id'] !== $currentUser['id']) {
            $_SESSION['error'] = 'Unauthorized access!';
            $this->redirect('/task');
            return;
        }


        try {
            $newStatus = $task['status'] === 'completed' ? 'pending' : 'completed';

            $updated = $this->TaskModel->update($id, [
                'status' => $newStatus,
                'user_id' => $currentUser['id']
            ]);

            if ($updated) {
                if ($newStatus === 'completed') {

                    $xpReward = $task['xp'];
                    $coinReward = $task['coins'];
                    $user_id = $currentUser['id'];

                    $this->UserStatsModel->addXp($user_id, $xpReward);
                    $this->UserStatsModel->addSkillPoints($currentUser['id'], $task['category'], $task['difficulty']);
                    $this->UserModel->addCoin($user_id, $coinReward);
                }
                $_SESSION['success'] = 'Task status updated!';
                $this->redirect('/task');

            } else {
                $_SESSION['error'] = 'Failed to update task!';
                $this->redirect('/task');
            }
        } catch (Exception $e) {
            $_SESSION['error'] = 'Failed to toggle task status:' . $e->getMessage();
            $this->redirect('/task');
            return;
        }
    }
}