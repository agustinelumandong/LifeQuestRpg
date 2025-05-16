<?php

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Controller;
use App\Core\Input;
use App\Models\Journal;
use App\Models\UserStats;
use App\Models\Streak;
use Exception;

class JournalController extends Controller
{
    protected $JournalModel;
    protected $UserStatsModel;
    protected $streakModel;

    public function __construct()
    {
        $this->JournalModel = new Journal;
        $this->UserStatsModel = new UserStats;
        $this->streakModel = new Streak;
    }


    public function index()
    {
        /** @var array $currentUser */
        $currentUser = Auth::user();
        $journals = $this->JournalModel->getJournalsByUserId($currentUser['id']);

        if (!empty($journals) && $currentUser['id'] !== $journals[0]['user_id']) {
            $_SESSION['error'] = 'Journal entry not found.';
            $this->redirect('/journal');
            return;
        }

        $paginator = $this->JournalModel->paginate(
            page: 1,
            perPage: 6,
            orderBy: 'id',
            direction: 'DESC',
            conditions: [
                'user_id' => $currentUser['id']
            ]
        )->setTheme('game');

        return $this->view('journal/indexs', [
            'title' => 'My Journal',
            'journals' => $paginator->items(),
            'currentUser' => $currentUser,
            'paginator' => $paginator
        ]);
    }

    public function create()
    {
        $today = date('Y-m-d');

        return $this->view('journal/creates', [
            'title' => 'Write Journal Entry',
            'today' => $today
        ]);
    }

    public function store()
    {
        /** @var array $currentUser */
        $currentUser = Auth::user();

        $data = [
            'title' => Input::post('title'),
            'content' => Input::post('content'),
            'date' => Input::post('date') ?: date('Y-m-d'),
            'user_id' => $currentUser['id'],
        ];
        try {
            $created = $this->JournalModel->create($data);

            if ($created) {                // Award XP for creating a journal entry
                $xpAmount = 15; // 15 XP per journal entry as shown in the UI
                $this->UserStatsModel->addXp($currentUser['id'], $xpAmount);

                // Record streak activity for journal writing
                $this->streakModel->recordActivity($currentUser['id'], 'journal_writing');

                $_SESSION['success'] = 'Journal Entry saved successfully! You earned +15 XP';
            } else {
                $_SESSION['error'] = 'Failed to save Journal Entry!';
            }

            $this->redirect('/journal');
        } catch (Exception $e) {
            $_SESSION['error'] = 'Failed to save journal entry: ' . $e->getMessage();
            return $this->redirect('/journal');
        }
    }

    public function peek($id)
    {
        /** 
         * @var array $currentUser 
         * @var array $journal
         */
        $currentUser = Auth::user();
        $journal = $this->JournalModel->find($id);

        if ($currentUser['id'] !== $id && $journal['user_id'] !== $currentUser['id']) {
            $_SESSION['error'] = 'Journal entry not found.';
            $this->redirect('/journal');
            return;
        }

        return $this->view('journal/peeks', [
            'title' => $journal['title'],
            'journal' => $journal,
            'currentUser' => $currentUser
        ]);
    }

    public function edit($id)
    {
        /** @var array $currentUser */
        $currentUser = Auth::user();
        $journal = $this->JournalModel->find($id);

        if ($currentUser['id'] !== $id && $journal['user_id'] !== $currentUser['id']) {
            $_SESSION['error'] = 'Journal entry not found.';
            $this->redirect('/journal');
            return;
        }

        return $this->view('journal/edits', [
            'title' => 'Edit Journal Entry',
            'journal' => $journal
        ]);

    }

    public function update($id)
    {
        /** @var array $currentUser */
        $currentUser = Auth::user();
        $journal = $this->JournalModel->find($id);

        if ($currentUser['id'] !== $id && $journal['user_id'] !== $currentUser['id']) {
            $_SESSION['error'] = 'Journal entry not found.';
            $this->redirect('/journal');
            return;
        }

        // Separate handling of content to avoid HTML encoding
        $title = Input::sanitize(['title' => Input::post('title')])['title'];
        $content = Input::post('content'); // Don't sanitize content to preserve HTML formatting

        $data = [
            'title' => $title,
            'content' => $content,
        ];

        try {
            $updated = $this->JournalModel->update($id, $data);

            if ($updated) {
                $_SESSION['success'] = 'Journal entry updated successfully!';
                $this->redirect('/journal/' . $id . '/peek');
            } else {
                $_SESSION['error'] = 'Failed to update journal entry.';
                $this->redirect('/journal/' . $id . '/peek');
            }
        } catch (Exception $e) {
            $_SESSION['error'] = 'Failed to update journal entry: ' . $e->getMessage();
            return $this->redirect('/journal/' . $id . '/edit');
        }
    }

    public function destroy($id)
    {
        /** @var array $currentUser */
        $currentUser = Auth::user();
        $journal = $this->JournalModel->find($id);

        if ($currentUser['id'] !== $id && $journal['user_id'] !== $currentUser['id']) {
            $_SESSION['error'] = 'Journal entry not found.';
            $this->redirect('/journal');
            return;
        }
        try {

            $deleted = $this->JournalModel->delete($id);

            if ($deleted) {
                $_SESSION['success'] = 'Journal entry deleted successfully!';
                $this->redirect('/journal');
            } else {
                $_SESSION['error'] = 'Failed to delete journal entry.';
                $this->redirect('/journal/' . $id . '/peek');
            }

        } catch (Exception $e) {
            $_SESSION['error'] = 'Failed to delete journal entry: ' . $e->getMessage();
            $this->redirect('/journal');
        }
    }
}