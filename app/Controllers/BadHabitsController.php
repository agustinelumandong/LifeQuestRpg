<?php

// declare(strict_types=1);

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Controller;
use App\Core\Input;
use App\Models\BadHabits;
use App\Models\User;
use App\Models\UserStats;
use Exception;
use Throwable;

class BadHabitsController extends Controller
{
  protected $BadHabitModel;
  protected $UserModel;
  protected $UserStatsModel;

  public function __construct()
  {
    $this->BadHabitModel = new BadHabits();
    $this->UserModel = new User();
    $this->UserStatsModel = new UserStats();
  }

  public function index()
  {
    /** @var array $currentUser */
    $currentUser = Auth::user();
    // $userId = Auth::getByUserId();

    $badHabits = $this->BadHabitModel->getBadHabitsByUserId($currentUser['id']);

    return $this->view('badhabit/index', [
      'title' => 'Bad Habit',
      'badHabits' => $badHabits
    ]);
  }

  // This method is no longer needed since we're using modals
  // But we'll keep it for backward compatibility
  public function create()
  {
    return $this->redirect('/badhabit');
  }

  public function store()
  {
    /** @var array $currentUser */
    $currentUser = Auth::user();

    // Map the input fields to match database column names
    $data = Input::sanitize([
      'title' => Input::post('title'),
      'status' => Input::post('status') ?? 'pending',
      'difficulty' => Input::post('difficulty'),
      'category' => Input::post('category'),
      'coins' => Input::post('coins') ?? 0,
      'xp' => Input::post('xp') ?? 0,
      'user_id' => $currentUser['id'],
    ]);

    try {
      $habitId = $this->BadHabitModel->create($data);

      if ($habitId) {
        $_SESSION['success'] = 'Bad habit created successfully!';
      } else {
        $_SESSION['error'] = 'Failed to create bad habit!';
      }

    } catch (Exception $e) {
      $_SESSION['error'] = 'Failed to create bad habit: ' . $e->getMessage();
    }

    $this->redirect('/badhabit');
  }

  // This method is no longer needed since we're using modals
  // But we'll keep it for backward compatibility
  public function edit($id)
  {
    return $this->redirect('/badhabit');
  }

  public function update($id)
  {
    /** @var array $currentUser */
    $currentUser = Auth::user();
    $badHabit = $this->BadHabitModel->find($id);

    if (!$badHabit || $badHabit['user_id'] !== $currentUser['id']) {
      $_SESSION['error'] = 'You are not authorized to edit this habit!';
      $this->redirect('/badhabit');
      return;
    }

    // Map the input fields to match database column names
    $data = Input::sanitize([
      'title' => Input::post('title'),
      'category' => Input::post('category'),
      'difficulty' => Input::post('difficulty'),
      'status' => Input::post('status'),
      'coins' => Input::post('coins') ?? 0,
      'xp' => Input::post('xp') ?? 0,
      'user_id' => $currentUser['id'],
    ]);

    try {
      $updated = $this->BadHabitModel->update($id, $data);

      if ($updated) {
        $_SESSION['success'] = 'Bad habit updated successfully!';
      } else {
        $_SESSION['error'] = 'Failed to update bad habit!';
      }
    } catch (Exception $e) {
      $_SESSION['error'] = 'Failed to update bad habit: ' . $e->getMessage();
    }

    $this->redirect('/badhabit');
  }

  public function destroy($id)
  {
    /** @var array $currentUser */
    $currentUser = Auth::user();
    $badhabit = $this->BadHabitModel->find($id);

    if (!$badhabit || $badhabit['user_id'] !== $currentUser['id']) {
      $_SESSION['error'] = 'You are not authorized to delete this habit!';
      $this->redirect('/badhabit');
      return;
    }

    try {
      $deleted = $this->BadHabitModel->delete($id);

      if ($deleted) {
        $_SESSION['success'] = 'Bad habit deleted successfully!';
      } else {
        $_SESSION['error'] = 'Failed to delete bad habit!';
      }

    } catch (Exception $e) {
      $_SESSION['error'] = 'Failed to delete bad habit: ' . $e->getMessage();
    }

    $this->redirect('/badhabit');
  }

  public function toggle($id)
  {
    /** @var array $currentUser */
    $currentUser = Auth::user();
    $badhabit = $this->BadHabitModel->find($id);

    if (!$badhabit || $badhabit['user_id'] !== $currentUser['id']) {
      $_SESSION['error'] = 'You are not authorized to update this habit!';
      $this->redirect('/badhabit');
      return;
    }

    try {
      $newStatus = $badhabit['status'] === 'completed' ? 'pending' : 'completed';

      $updated = $this->BadHabitModel->update(
        $id,
        [
          'status' => $newStatus,
          'user_id' => $currentUser['id']
        ]
      );

      if ($updated) {
        // Update User Stats if a bad habit is marked as completed
        if ($newStatus === 'completed') {
          $hpLoss = 0;
          switch ($badhabit['difficulty']) {
            case 'easy':
              $hpLoss = -5;
              break;
            case 'medium':
              $hpLoss = -10;
              break;
            case 'hard':
              $hpLoss = -15;
              break;
          }

          // Update health points
          if ($hpLoss !== 0) {
            $this->UserStatsModel->minusHealth($currentUser['id']);
          }
        }

        $_SESSION['success'] = 'Bad habit updated successfully!';
      } else {
        $_SESSION['error'] = 'Failed to update bad habit!';
      }

    } catch (Exception $e) {
      $_SESSION['error'] = 'Failed to toggle bad habit: ' . $e->getMessage();
    }

    $this->redirect('/badhabit');
  }

  public function checkCleanDay()
  {
    /** @var array $currentUser */
    $currentUser = Auth::user();
    $user_id = $currentUser['id'];

    $badHabits = $this->BadHabitModel->getBadHabitsByUserId($user_id);

    $checkHabits = $this->BadHabitModel->cleanDay($user_id);

    if ($checkHabits) {
      $categoryHabits = [];
      foreach ($badHabits as $badHabit) {
        $category = $badHabit['category'];
        $difficulty = $badHabit['difficulty'];

        if (!isset($categoryHabits[$category])) {
          $categoryHabits[$category] = [];
        }

        $categoryHabits[$category][] = $difficulty;
      }

      foreach ($categoryHabits as $category => $difficulties) {
        foreach ($difficulties as $difficulty) {
          $this->UserStatsModel->addSkillPoints($user_id, $category, $difficulty);
        }
      }
    }
  }
}