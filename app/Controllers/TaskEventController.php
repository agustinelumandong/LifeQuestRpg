<?php

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Controller;
use App\Core\Input;
use App\Models\TaskEvent;
use App\Models\UserEventCompletion;
use Exception;

class TaskEventController extends Controller
{

  protected $TaskEventModel;
  protected $UserEventCompletionModel;

  public function __construct()
  {
    $this->TaskEventModel = new TaskEvent();
    $this->UserEventCompletionModel = new UserEventCompletion();
    $this->updateStatusEvents();
  }

  /**
   * Updates status of expired events to inactive
   * 
   * @return void
   */
  private function updateStatusEvents()
  {
    try {
      $updatedExpired = $this->TaskEventModel->updateExpiredEvents();
      $updatedActive = $this->TaskEventModel->updateActiveEvents();
      if ($updatedExpired && $updatedActive > 0) {
        $_SESSION['success'] = 'Events updated successfully!';
      }
    } catch (Exception $e) {
      $_SESSION['error'] = 'Failed to update status events: ' . $e->getMessage();
    }
  }

  public function index()
  {
    /** @var array $currentUser */
    $currentUser = Auth::user();

    $taskEventsId = $this->TaskEventModel->getEventById($currentUser['id']);

    $taskEvents = $this->TaskEventModel->all();
    $userTaskEventCompleted = $this->UserEventCompletionModel->getUserEventCompletions($currentUser['id']);

    $userHasCompleted = $this->UserEventCompletionModel->hasUserCompleted($currentUser['id'], $taskEventsId);

    $paginator = $this->TaskEventModel->paginate(
      page: 1,
      perPage: 5,
      orderBy: 'id',
      direction: 'DESC',
    )->setTheme('game');

    return $this->view('taskevents/index', [
      'title' => 'Task Events',
      'taskEvents' => $paginator->items(),
      'paginator' => $paginator,
      'userTaskEventCompleted' => $userTaskEventCompleted,
      'userHasCompleted' => $userHasCompleted,
    ]);
  }

  public function create()
  {
    if (!Auth::isAdmin()) {
      return $this->redirect('/');
    }

    return $this->view('taskevents/create', [
      'title' => 'Create Task Event',
    ]);
  }


  public function store()
  {
    if (!Auth::isAdmin()) {
      return $this->redirect('/');
    }

    $data = Input::sanitize([
      'event_name' => Input::post('eventTitle'),
      'event_description' => Input::post('eventDescription'),
      'start_date' => Input::post('startDate'),
      'end_date' => Input::post('endDate'),
      'reward_xp' => Input::post('rewardXp'),
      'reward_coins' => Input::post('rewardCoins'),
    ]);
    $data['user_id'] = Auth::getByUserId();

    $data['start_date'] = date('Y-m-d H:i:s', strtotime($data['start_date']));
    $data['end_date'] = date('Y-m-d H:i:s', strtotime($data['end_date']));

    try {
      $taskEventId = $this->TaskEventModel->create($data);

      if ($taskEventId) {
        $_SESSION['success'] = 'Task Event created successfully!';
        return $this->redirect('/taskevents');
      } else {
        throw new Exception('Failed to create Task Event.');
      }
    } catch (Exception $e) {
      $_SESSION['error'] = $e->getMessage();
      return $this->redirect('/taskevents/create');
    }
  }

  public function edit($event_id)
  {
    if (!Auth::isAdmin()) {
      return $this->redirect('/');
    }
    $taskEvent = $this->TaskEventModel->findBy('id', $event_id);
    if (!$taskEvent) {
      $_SESSION['error'] = 'Task Event not found.';
      return $this->redirect('/taskevents');
    }

    return $this->view('taskevents/edit', [
      'title' => 'Edit Task Event',
      'taskEvent' => $taskEvent,
    ]);
  }

  public function update($event_id)
  {
    if (!Auth::isAdmin()) {
      return $this->redirect('/');
    }

    $data = Input::sanitize([
      'event_name' => Input::post('eventName'),
      'event_description' => Input::post('eventDescription'),
      'start_date' => Input::post('startDate'),
      'end_date' => Input::post('endDate'),
      'reward_xp' => Input::post('rewardXp'),
      'reward_coins' => Input::post('rewardCoins'),
      'status' => Input::post('status') ? 'active' : 'inactive',
    ]);

    $data['user_id'] = Auth::getByUserId();
    $data['start_date'] = date('Y-m-d H:i:s', strtotime($data['start_date']));
    $data['end_date'] = date('Y-m-d H:i:s', strtotime($data['end_date']));

    try {
      $updated = $this->TaskEventModel->update($event_id, $data);

      if ($updated) {
        $_SESSION['success'] = 'Task Event updated successfully!';
        return $this->redirect('/taskevents');
      } else {
        $_SESSION['error'] = 'Failed to Update Task Event.';
        return $this->redirect("/taskevents/{$event_id}/edit");
      }

    } catch (Exception $e) {
      $_SESSION['error'] = $e->getMessage();
      return $this->redirect("/taskevents/{$event_id}/edit");
    }
  }

  public function delete($event_id)
  {
    if (!Auth::isAdmin()) {
      return $this->redirect('/');
    }

    try {
      $deleted = $this->TaskEventModel->delete($event_id);

      if ($deleted) {
        $_SESSION['success'] = 'Task Event deleted successfully!';
        return $this->redirect('/taskevents');
      } else {
        $_SESSION['error'] = 'Failed to delete Task Event.';
        return $this->redirect('/taskevents');
      }
    } catch (Exception $e) {
      $_SESSION['error'] = $e->getMessage();
      return $this->redirect('/taskevents');
    }
  }

  public function completeTask($task_id)
  {
    $userId = Auth::getByUserId();

    $task = $this->TaskEventModel->getEventById($task_id);
    if (!$task) {
      $_SESSION['error'] = 'Task not found.';
      return $this->redirect('/');
    }

    if (!$this->TaskEventModel->checkEventActive($task_id)) {
      $_SESSION['error'] = 'This task is not currently active.';
      return $this->redirect('/');
    }

    if ($this->UserEventCompletionModel->hasUserCompleted($userId, $task_id)) {
      $_SESSION['error'] = 'You have already completed this event.';
      return $this->redirect("/");
    }

    $taskReward = $this->TaskEventModel->getTaskReward($task_id);
    if (!isset($taskReward['reward_xp'], $taskReward['reward_coins'])) {
      $_SESSION['error'] = 'Task reward data is incomplete.';
      return $this->redirect('/');
    }

    $completeTask = $this->UserEventCompletionModel->recordCompletion($userId, $task_id);
    if ($completeTask) {

      $this->UserEventCompletionModel->updateUserExp(
        $userId,
        $taskReward['reward_xp']
      );

      $this->UserEventCompletionModel->updateUserCoins(
        $userId,
        $taskReward['reward_coins']
      );

      $_SESSION['success'] = 'Congratulations! You have completed the task and claimed your rewards!';
    } else {
      $_SESSION['error'] = 'Failed to complete the task event.';
    }

    return $this->redirect("/");
  }

  public function show($event_id)
  {
    /** @var array $currentUser */
    $currentUser = Auth::user();
    $taskEventsId = $this->TaskEventModel->getEventById($currentUser['id']);
    $event = $this->TaskEventModel->getEventById($event_id);
    $userHasCompleted = $this->UserEventCompletionModel->hasUserCompleted($currentUser['id'], $taskEventsId);
    if (!$this->TaskEventModel->checkEventActive($event_id)) {
      $_SESSION['error'] = 'This event is not active.';
      return $this->redirect('/profile');
    }

    if ($event) {
      return $this->view('taskevents/show', [
        'title' => 'Task Event Details',
        'event' => $event,
        'userHasCompleted' => $userHasCompleted,
      ]);
    } else {
      $_SESSION['error'] = 'Task Event not found.';
      return $this->redirect('/taskevents');
    }

  }
}
