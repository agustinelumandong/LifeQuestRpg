<?php

namespace App\Controllers;

use App\Core\Controller;
use App\Core\Auth;
use App\Core\Input;
use App\Models\User;
use App\Models\UserStats;

class CharacterController extends Controller
{
  protected $userModel;
  protected $userStats;

  /**
   * Constructor - initialize models
   */
  public function __construct()
  {
    $this->userModel = new User();
    $this->userStats = new UserStats();
  }

  /**
   * Display the character creation stepper
   * 
   * @return void
   */
  public function showStepper()
  {
    $currentUser = Auth::user();
    $userId = Auth::getByUserId();

    if (!$userId) {
      $_SESSION['error'] = 'You must be logged in to create a character.';
      $this->redirect('/login');
      return;
    }

    // Check if user already has character stats set up
    $stats = $this->userStats->getUserStatsByUserId($userId);

    if ($stats && !empty($stats['avatar_id'])) {
      $_SESSION['info'] = 'You have already created your character.';
      $this->redirect('/');
      return;
    }

    // Get the current step from query string or session, default to 1
    $step = (int) (Input::get('step', $_SESSION['character_step'] ?? 1));

    // Validate step is within range
    if ($step < 1 || $step > 4) {
      $step = 1;
    }

    // Store current step in session
    $_SESSION['character_step'] = $step;

    // Pass step to the view
    $this->view('auth/stepper', [
      'currentStep' => $step,
    ]);
  }

  /**
   * Process step-by-step form submission
   * 
   * @return void
   */
  public function processStep()
  {
    $userId = Auth::getByUserId();

    if (!$userId) {
      $_SESSION['error'] = 'You must be logged in to create a character.';
      $this->redirect('/login');
      return;
    }

    $step = (int) Input::post('step', 1);

    switch ($step) {
      case 1: // Introduction 
        break;

      case 2: // Avatar selection
        $_SESSION['character_data']['avatar_id'] = (int) Input::post('avatar_id', 1);
        break;

      case 3: // Profile data
        $username = Input::post('username');
        $objective = Input::post('objective', '');

        // Validate username
        if (empty($username) || strlen($username) < 3) {
          $_SESSION['error'] = 'Please provide a valid username (minimum 3 characters).';
          $this->redirect('/character/stepper?step=3');
          return;
        }

        $_SESSION['character_data']['username'] = $username;
        $_SESSION['character_data']['objective'] = $objective;

        // Save all collected data
        $this->createCharacter();
        return;
    }

    // Advance to next step
    $nextStep = $step + 1;
    $this->redirect("/character/stepper?step={$nextStep}");
  }

  /**
   * Create character from collected data
   * 
   * @return void
   */
  private function createCharacter()
  {
    try {
      $userId = Auth::getByUserId();
      $user = Auth::user();

      if (!$userId || !$user) {
        $_SESSION['error'] = 'You must be logged in to create a character.';
        $this->redirect('/login');
        return;
      }

      $characterData = [
        'user_id' => $userId,
        'username' => $_SESSION['character_data']['username'],
        'objective' => $_SESSION['character_data']['objective'] ?? '',
        'avatar_id' => $_SESSION['character_data']['avatar_id'] ?? 1,
        'xp' => 0,
        'level' => 1,
        'health' => 100
      ];

      // Update user's display name
      if (!$this->userModel->update($userId, ['username' => $characterData['username']])) {
        throw new \Exception('Failed to update username');
      }

      // Create character stats
      if (!$this->userStats->createUserStats($characterData)) {
        throw new \Exception('Failed to create character stats');
      }

      // Clear session data
      unset($_SESSION['character_data']);
      unset($_SESSION['character_step']);

      $_SESSION['success'] = 'Character created successfully! Your adventure begins now.';

      // Advance to final step to show completion
      $this->redirect('/character/stepper?step=4');

    } catch (\Exception $e) {
      error_log("Character creation error: " . $e->getMessage());
      error_log("Stack trace: " . $e->getTraceAsString());

      $_SESSION['error'] = 'Character creation failed: ' . $e->getMessage();
      $this->redirect('/character/stepper?step=3');
    }
  }

  /**
   * Legacy method for backward compatibility
   * Redirects to the step processing method
   */
  public function create()
  {
    $this->processStep();
  }
}