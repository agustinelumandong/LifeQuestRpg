<?php

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Controller;
use App\Core\Input;
use App\Models\UserStats;
use App\Models\User;
use App\Models\GoodHabits;

class GoodHabitsController extends Controller 
{

    protected $GoodHabitsM;
    protected $UserStatsM;
    protected $UserM;



    public function __construct(){
        $this->GoodHabitsM = new GoodHabits();
        $this->UserStatsM = new UserStats();
        $this->UserM = new User();
    }

    public function index (){
        $currentUser = Auth::user();
        $GoodHabits = $this->GoodHabitsM->getGoodHabitsByUserId($currentUser['id']);

        return $this->view('goodHabits/index',[
            'title' => 'GoodHabits Task',
            'goodHabits' => $GoodHabits
        ]); 
    }

    public function store () {
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
    
        $this->GoodHabitsM->create($data);
        $this->redirect('/goodHabits/index');
     }

     public function update ($id){
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
            'category' => Input::post('category'),
            'difficulty' => Input::post('difficulty'),
            'coins' => $coins,  
            'xp' => $xp,       
            'user_id' => $currentUser['id']
    
        ]);
    
        $updated = $this->GoodHabitsM->update($id, $data);
        
        if($updated){
            $_SESSION['success'] = 'Task updated successfully!';    
            $this->redirect('/task/index');
        } else{
            $_SESSION['error'] = 'Failed to update task!';
            $this->redirect('/goodHabits/index');
        }
     }

    public function destroy ($id){
        $currentUser = Auth::user();
        $goodHabits = $this->GoodHabitsM->find($id);
    
        // Check if task exists and belongs to current user
        if (!$goodHabits || $goodHabits['user_id'] !== $currentUser['id']) {
            $_SESSION['error'] = 'Unauthorized access!';
            $this->redirect('goodHabits/index');
            return;
        }
    
        $deleted = $this->GoodHabitsM->delete($id);
    
        if ($deleted) {
            $_SESSION['success'] = 'GoodHabits deleted successfully!';
        } else {
            $_SESSION['error'] = 'Failed to GoodHabitsM!';
        }
    
        $this->redirect('/goodHabits/index');
    }

    public function toggle($id) {
        $currentUser = Auth::user();
        $goodHabits = $this->GoodHabitsM->find($id);
   
        if ($goodHabits['status'] === 'completed') {
            // Reset to pending first
            $this->GoodHabitsM->update($id, [
                "status" => 'pending',
                "user_id" => $currentUser['id']
            ]);
        }

        $updated = $this->GoodHabitsM->update($id, [
            "status" => 'completed',
            "user_id" => $currentUser['id']
        ]);

        if($updated){
            $_SESSION['success'] = 'Daily task updated!';     
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
                
                $xpReward = $xpRewards[$goodHabits['difficulty']] ;
                $coinReward = $coinRewards[$goodHabits['difficulty']];
                $user_id = $currentUser['id'];

                $this->UserStatsM->addXp($user_id, $xpReward);
                $this->UserStatsM->addSp($currentUser['id'], $goodHabits['category'], $goodHabits['difficulty']);
                $this->UserM->addCoin($user_id, $coinReward);

        }else{
                $_SESSION['error'] = 'Daily task failed to update!';
            }

             $this->redirect('/goodHabits/index');
        }
    }

?>
