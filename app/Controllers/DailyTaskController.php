<?php

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Controller;
use App\Core\Input;
use App\Models\DailyTasks;
use App\Models\UserStats;
use App\Models\User;
use App\Models\Streak;
use Exception;


class DailyTaskController extends Controller
{
    protected $DailyTaskModel;
    protected $UserStatsModel;
    protected $UserModel;
    protected $streakModel;

    public function __construct()
    {
        $this->DailyTaskModel = new DailyTasks();
        $this->UserStatsModel = new UserStats();
        $this->UserModel = new User();
        $this->streakModel = new Streak();
    }

    public function index()
    {
        /** @var array $currentUser */
        $currentUser = Auth::user();

        $this->DailyTaskModel->resetDailyTasks();
        $dailyTasks = $this->DailyTaskModel->getDailyTasksByUserId($currentUser['id']);

        $paginator = $this->DailyTaskModel->paginate(
            page: 1,
            perPage: 5,
            orderBy: 'id',
            direction: 'DESC',
            conditions: [
                'user_id' => $currentUser['id']
            ]
        )->setTheme('game');

        return $this->view('dailytask/index', [
            'title' => 'Daily Task',
            'dailyTasks' => $paginator->items(),
            'paginator' => $paginator,
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
        if (!$currentUser) {
            $_SESSION['error'] = 'You must be logged in to perform this action!';
            $this->redirect('/dailytask');
            return;
        }

        $task = $this->DailyTaskModel->find($id);

        if (!$task || $task['user_id'] !== $currentUser['id']) {
            $_SESSION['error'] = 'Task not found or unauthorized!';
            $this->redirect('/dailytask');
            return;
        }

        try {
            $newStatus = $task['completed'] == 'completed' ? 'pending' : 'completed';

            $updated = $this->DailyTaskModel->update(
                $id,
                [
                    "status" => $newStatus,
                    "user_id" => $currentUser['id']
                ]
            );

            if ($updated) {
                if ($newStatus == 'completed') {
                    // Calculate rewards based on difficulty
                    $xpReward = 0;
                    $coinReward = 0;

                    switch ($task['difficulty']) {
                        case 'easy':
                            $xpReward = 10;
                            $coinReward = 5;
                            break;
                        case 'medium':
                            $xpReward = 20;
                            $coinReward = 10;
                            break;
                        case 'hard':
                            $xpReward = 30;
                            $coinReward = 15;
                            break;
                        default:
                            $xpReward = 10;
                            $coinReward = 5;
                    }

                    $userId = $currentUser['id'];                    // Add XP reward consistently using the correct method
                    $this->UserStatsModel->addXp($userId, $xpReward);

                    $this->UserStatsModel->addSkillPoints($userId, $task['category'], $task['difficulty']);
                    $this->UserModel->addCoin($userId, $coinReward);

                    // Record streak activity for daily task completion
                    $this->streakModel->recordActivity($userId, 'dailtask_completion');

                    $_SESSION['success'] = "Daily task marked as completed! You earned {$xpReward} XP and {$coinReward} coins!";
                } else {
                    $_SESSION['success'] = "Daily task marked as pending.";
                }
                $this->redirect('/dailytask');
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