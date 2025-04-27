<?php

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Controller;
use App\Core\Input;
use App\Models\Journal;
use App\Models\UserStats;

class JournalController extends Controller {
    protected $JournalM;
    protected $UserStatsM;
    
    public function __construct(){
        $this->JournalM = new Journal;
        $this->UserStatsM = new UserStats;
    }

     public function index(){
        $currentUser = Auth::user();
        $journals = $this->JournalM->getJournalsByUserId($currentUser['id']);

        return $this->view('journal/index', [
            'title' => 'My Journal',
            'journals' => $journals
        ]);
     }

     public function create(){
        $today = date('Y-m-d');

        return $this->view('journal/create', [
            'title' => 'Write Journal Entry',
            'today' => $today
        ]);
     }

     public function store(){
        $currentUser = Auth::user();

        $data = Input::sanitize([
            'title' => input::post('title'),
            'content' => input::post('title'),
            'date' => input::post('date') ?: date('Y-m-d'),
            'user_id' => $currentUser['id'],
        ]);

        $created = $this->JournalM->create($data);

        if($created){
            $_SESSION['success'] = 'Journal Entry saved successdully!';
        } else{
            $_SESSION['error'] = 'Failed to saved Journal Entry!';
        }

        $this->redirect('/journal/index');

     }

     public function peek($id) {
        $currentUser = Auth::user();
        $journal = $this->JournalM->find($id);
        
        if (!$journal || $journal['user_id'] !== $currentUser['id']) {
            $_SESSION['error'] = 'Journal entry not found.';
            $this->redirect('/journal/index');
            return;
        }
        
        return $this->view('journal/peek', [
            'title' => $journal['title'],
            'journal' => $journal
        ]);
    }

     public function edit($id){
        $currentUser  = Auth::user();
        $journal = $this->JournalM->find($id);

        if(!$journal || $journal['user_id'] !== $currentUser['id']) {
            $_SESSION['error'] = 'Journal Entry not found.';
            $this->redirect('/journal/index');
            return;
        }

        return $this->view('journal/edit', [
            'title' => 'Edit Journal Entry',
            'journal' => $journal
        ]);

     }

     public function update($id){
        $currentUser  = Auth::user();
        $journal = $this->JournalM->find($id);

        if (!$journal || $journal['user_id'] !== $currentUser['id']) {
            $_SESSION['error'] = 'Journal entry not found.';
            $this->redirect('/journal/index');
            return;
        }
        
        $data = [
            'title' => ($_POST['title']),
            'content' => $_POST['content'] 
        ];

        $updated = $this->JournalM->update($id, $data);

        if ($updated) {
            $_SESSION['success'] = 'Journal entry updated successfully!';
        } else {
            $_SESSION['error'] = 'Failed to update journal entry.';
        }
        
        $this->redirect('/journal/'. $id .'/peek');

     }

     public function destroy($id) {
        $currentUser = Auth::user();
        $journal = $this->JournalM->find($id);
        
        if (!$journal || $journal['user_id'] !== $currentUser['id']) {
            $_SESSION['error'] = 'Journal entry not found.';
            $this->redirect('/journal/index');
            return;
        }
        
        $deleted = $this->JournalM->delete($id);
        
        if ($deleted) {
            $_SESSION['success'] = 'Journal entry deleted successfully!';
        } else {
            $_SESSION['error'] = 'Failed to delete journal entry.';
        }
        
        $this->redirect('/journal/index');
    }

}