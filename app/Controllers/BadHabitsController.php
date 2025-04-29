<?php

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Controller;
use App\Core\Input;
use App\Models\BadHabits;
use App\Models\User;
use App\Models\UserStats;


class BadHabitsController extends Controller 
{

    protected $BadHabitsM;
    protected $UserM;
    protected $UserStatsM;



    public function __construct(){
        $this->BadHabitsM = new BadHabits();
        $this->UserM = new User();
        $this->UserStatsM = new UserStats();

    }

    public function index (){
        $currentUser = Auth::user();
        $badHabits = $this->BadHabitsM->getBadHabitsByUserId($currentUser['id']);

        return $this->view('badHabits/index',[
            'title' => 'BadHabits',
            'badHabits' => $badHabits
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

            $this->BadHabitsM->create($data);
            $this->redirect('/badHabits/index');
    }

    public function update ($id){
        $currentUser = Auth::user();

        $data = Input::sanitize([
            'title' => Input::post('title'),
            'category' => Input::post('category'),
            'difficulty' => Input::post('difficulty'),
            'user_id' => $currentUser['id']

        ]);

        $updated = $this->BadHabitsM->update($id, $data);

        if($updated){
            $_SESSION['success'] = 'badHabits  Updated Successfully';
            $this->redirect('/badHabits/index');
        }else {
            $_SESSION['error'] = 'Failed to Update Daily Task';
            $this->redirect('/badHabits/index');
        }
    }

    public function destroy ($id){
        $currentUser = Auth::user();
        $badHabits = $this->BadHabitsM->find($id);
    
        // Check if task exists and belongs to current user
        if (!$badHabits || $badHabits['user_id'] !== $currentUser['id']) {
            $_SESSION['error'] = 'Unauthorized access!';
            $this->redirect('badHabits/index');
            return;
        }
    
        $deleted = $this->BadHabitsM->delete($id);
    
        if ($deleted) {
            $_SESSION['success'] = 'badHabits deleted successfully!';
        } else {
            $_SESSION['error'] = 'Failed to delete badHabits!';
        }
    
        $this->redirect('/badHabits/index');
    }

    public function toggle($id) {
        $currentUser = Auth::user();
        $badHabits = $this->BadHabitsM->find($id);

        $newStatus = $badHabits['status'] === 'completed' ? 'pending' : 'completed';
        
        $updated = $this->BadHabitsM->update($id, [
            "status" => $newStatus,
            "user_id" => $currentUser['id']
        ]);

        if($updated){
            $_SESSION['success'] = 'Bad Habits task updated!';
            if($newStatus === 'completed'){
            
               $user_id = $currentUser['id'];

               $this->UserStatsM->minusHealth($user_id);

            }
        }else{
                $_SESSION['error'] = 'Bad Habits failed to update!';
            }

             $this->redirect('/badHabits/index');
        }

        public function checkCleanDay (){
            $currentUser = Auth::user();
            $user_id = $currentUser['id'];

            $badHabits = $this->BadHabitsM->getBadHabitsByUserId($user_id);

            $checkHabits = $this->BadHabitsM->cleanDay($user_id);

            if($checkHabits){

                $categoryHabits = [];

                foreach($badHabits as $badHabit) {
                    $category = $badHabit['category'];
                    $difficulty = $badHabit['difficulty'];
                }

                if (!isset($categoryHabits[$category])) {
                    $categoryHabits[$category] = [];
                }
                
                $categoryHabits[$category][] = $difficulty;
            }

            foreach ($categoryHabits as $category => $difficulties) {
   
                foreach ($difficulties as $difficulty) {
            
                    $this->UserStatsM->addSp($user_id, $category, $difficulty);
                }
            }

            }

        }
    

?>
