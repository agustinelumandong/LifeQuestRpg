<?php

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Controller;
use App\Core\Input;
use App\Models\UserStats;
use App\Models\User;
use App\Models\GoodHabits;
use Exception;

class GoodHabitsController extends Controller
{

    protected $GoodHabitsModel;
    protected $UserStatsModel;
    protected $UserModel;

    public function __construct()
    {
        $this->GoodHabitsModel = new GoodHabits();
        $this->UserStatsModel = new UserStats();
        $this->UserModel = new User();
    }

    public function index()
    {
        /** @var array $currentUser */
        $currentUser = Auth::user();
        $GoodHabits = $this->GoodHabitsModel->getGoodHabitsByUserId($currentUser['id']);

        return $this->view('goodhabit/index', [
            'title' => 'Good Habits',
            'goodHabits' => $GoodHabits
        ]);
    }

    public function create()
    {
        // This method now redirects to index where modals are used
        return $this->redirect('/goodhabit');
    }

    public function edit($id)
    {
        // This method now redirects to index where modals are used
        return $this->redirect('/goodhabit');
    }

    public function store()
    {
        /** @var array $currentUser */
        $currentUser = Auth::user();
        $difficulty = Input::post('difficulty');

        $xpRewards = [
            'easy' => 5,
            'medium' => 10,
            'hard' => 15,
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
            'status' => Input::post('status') ?? 'pending',
            'difficulty' => $difficulty,
            'category' => Input::post('category'),
            'coins' => $coins,
            'xp' => $xp,
            'user_id' => $currentUser['id']
        ]);

        try {
            $created = $this->GoodHabitsModel->create($data);

            if ($created) {
                $_SESSION['success'] = 'Good habit created successfully!';
            } else {
                $_SESSION['error'] = 'Failed to create good habit!';
            }

            $this->redirect('/goodhabit');

        } catch (Exception $e) {
            $_SESSION['error'] = 'Failed to create good habit: ' . $e->getMessage();
            $this->redirect('/goodhabit');
            return;
        }
    }

    public function update($id)
    {
        /** @var array $currentUser */
        $currentUser = Auth::user();
        $goodHabit = $this->GoodHabitsModel->find($id);

        if (!$goodHabit || $goodHabit['user_id'] !== $currentUser['id']) {
            $_SESSION['error'] = 'You are not authorized to edit this good habit!';
            $this->redirect('/goodhabit');
            return;
        }

        $difficulty = Input::post('difficulty');

        $xpRewards = [
            'easy' => 5,
            'medium' => 10,
            'hard' => 15,
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
            'difficulty' => $difficulty,
            'status' => Input::post('status'),
            'coins' => $coins,
            'xp' => $xp,
            'user_id' => $currentUser['id']
        ]);

        try {
            $updated = $this->GoodHabitsModel->update($id, $data);

            if ($updated) {
                $_SESSION['success'] = 'Good habit updated successfully!';
            } else {
                $_SESSION['error'] = 'Failed to update good habit!';
            }

            $this->redirect('/goodhabit');

        } catch (Exception $e) {
            $_SESSION['error'] = 'Failed to update good habit: ' . $e->getMessage();
            $this->redirect('/goodhabit');
            return;
        }
    }

    public function destroy($id)
    {
        /** @var array $currentUser */
        $currentUser = Auth::user();
        $goodHabits = $this->GoodHabitsModel->find($id);

        if (!$goodHabits || $goodHabits['user_id'] !== $currentUser['id']) {
            $_SESSION['error'] = 'You are not authorized to delete this habit!';
            $this->redirect('/goodhabit');
            return;
        }

        try {
            $deleted = $this->GoodHabitsModel->delete($id);

            if ($deleted) {
                $_SESSION['success'] = 'Good habit deleted successfully!';
            } else {
                $_SESSION['error'] = 'Failed to delete good habit!';
            }

            $this->redirect('/goodhabit');

        } catch (Exception $e) {
            $_SESSION['error'] = 'Failed to delete good habit: ' . $e->getMessage();
            $this->redirect('/goodhabit');
        }
    }

    public function toggle($id)
    {
        /** @var array $currentUser */
        $currentUser = Auth::user();
        $goodHabits = $this->GoodHabitsModel->find($id);

        if (!$goodHabits || $goodHabits['user_id'] !== $currentUser['id']) {
            $_SESSION['error'] = 'You are not authorized to update this habit!';
            $this->redirect('/goodhabit');
            return;
        }

        // Skip if already completed
        if ($goodHabits['status'] === 'completed') {
            $_SESSION['info'] = 'This habit has already been completed!';
            $this->redirect('/goodhabit');
            return;
        }

        try {
            $updated = $this->GoodHabitsModel->update($id, [
                "status" => 'completed',
                "user_id" => $currentUser['id']
            ]);

            if ($updated) {
                // Add XP and coins based on difficulty
                $xpReward = $goodHabits['xp'];
                $coinReward = $goodHabits['coins'];
                $user_id = $currentUser['id'];

                $this->UserStatsModel->addXP($user_id, $xpReward);
                $this->UserStatsModel->addSkillPoints($user_id, $goodHabits['category'], $goodHabits['difficulty']);
                $this->UserModel->addCoin($user_id, $coinReward);

                $_SESSION['success'] = "Habit completed! You earned {$xpReward} XP and {$coinReward} coins!";
            } else {
                $_SESSION['error'] = 'Good habit failed to update!';
            }

            $this->redirect('/goodhabit');

        } catch (Exception $e) {
            $_SESSION['error'] = 'Failed to update good habit: ' . $e->getMessage();
            $this->redirect('/goodhabit');
        }
    }
}