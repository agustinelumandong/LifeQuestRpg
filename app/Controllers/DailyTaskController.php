<?php

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Controller;
use App\Core\Input;
use App\Models\DailyTasks;
use App\Models\UserStats;
use App\Models\User;
use App\Models\Activities;


class DailyTaskController extends Controller 
{

    protected $DailyTaskM;
    protected $UserStatsM;
    protected $UserM;



    public function __construct(){
        $this->DailyTaskM = new DailyTasks();
        $this->UserStatsM = new UserStats();
        $this->UserM = new User();
    }

    public function index (){
        $currentUser = Auth::user();

        $this->DailyTaskM->resetDailyTasks(); 
        $dailyTasks = $this->DailyTaskM->getDailyTasksByUserId($currentUser['id']);
        return $this->view('dailyTask/index',[
            'title' => 'Daily Task',
            'dailyTasks' => $dailyTasks
        ]); 
    }

    public function store () {
            $currentUser = Auth::user();

            $data = Input::sanitize([
                'title' => Input::post('title'),
                'status' => Input::post('status'),
                'difficulty' => Input::post('difficulty'),
                'category' => Input::post('category'),
                'user_id' => $currentUser['id']

            ]);

            $this->DailyTaskM->create($data);
            $this->redirect('/dailyTask/index');
    }

    public function update ($id){
        $currentUser = Auth::user();

        $data = Input::sanitize([
            'title' => Input::post('title'),
            'category' => Input::post('category'),
            'difficulty' => Input::post('difficulty'),
            'user_id' => $currentUser['id']

        ]);

        $updated = $this->DailyTaskM->update($id, $data);

        if($updated){
            $_SESSION['success'] = 'Daily Task Updated Successfully';
            $this->redirect('/dailyTask/index');
        }else {
            $_SESSION['error'] = 'Failed to Update Daily Task';
            $this->redirect('/dailyTask/index');
        }
    }

    public function destroy ($id){
        $currentUser = Auth::user();
        $task = $this->DailyTaskM->find($id);
    
        // Check if task exists and belongs to current user
        if (!$task || $task['user_id'] !== $currentUser['id']) {
            $_SESSION['error'] = 'Unauthorized access!';
            $this->redirect('dailyTask/index');
            return;
        }
    
        $deleted = $this->DailyTaskM->delete($id);
    
        if ($deleted) {
            $_SESSION['success'] = 'Task deleted successfully!';
        } else {
            $_SESSION['error'] = 'Failed to delete task!';
        }
    
        $this->redirect('/dailyTask/index');
    }

    public function toggle($id) {
        $currentUser = Auth::user();
        $dailyTasks = $this->DailyTaskM->find($id);

        $newStatus = $dailyTasks['status'] === 'completed' ? 'pending' : 'completed';
        
        $updated = $this->DailyTaskM->update($id, [
            "status" => $newStatus,
            "user_id" => $currentUser['id']
        ]);

        if($updated){
            $_SESSION['success'] = 'Daily task updated!';
            if($newStatus === 'completed'){
                
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

                $xpReward = $xpRewards[$dailyTasks['difficulty']] ;
                $coinReward = $coinRewards[$dailyTasks['difficulty']];
                $user_id = $currentUser['id'];

                $this->UserStatsM->addXp($user_id, $xpReward);
                $this->UserStatsM->addSp($currentUser['id'], $dailyTasks['category'], $dailyTasks['difficulty']);
                $this->UserM->addCoin($user_id, $coinReward);


            }
        }else{
                $_SESSION['error'] = 'Daily task failed to update!';
            }


             $this->redirect('/dailyTask/index');
        }
    }

?>
