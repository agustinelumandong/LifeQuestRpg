<?php

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Controller;
use App\Core\Input;
use App\Models\Journal;
use App\Models\UserStats;
use Exception;

class JournalController extends Controller
{
    protected $JournalModel;
    protected $UserStatsModel;

    public function __construct()
    {
        $this->JournalModel = new Journal;
        $this->UserStatsModel = new UserStats;
    }

    public function index()
    {
        /** @var array $currentUser */
        $currentUser = Auth::user();
        $journals = $this->JournalModel->getJournalsByUserId($currentUser['id']);
        if (!$currentUser) {
            $_SESSION['error'] = 'Journal entry not found.';
            $this->redirect('/');
            return;
        }

        return $this->view('journal/indexs', [
            'title' => 'My Journal',
            'journals' => $journals
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

            if ($created) {
                // Award XP for creating a journal entry
                $xpAmount = 15; // 15 XP per journal entry as shown in the UI
                $this->UserStatsModel->addXp($currentUser['id'], $xpAmount);

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
        /** @var array $currentUser */
        $currentUser = Auth::user();
        $journal = $this->JournalModel->find($id);
        if ($currentUser['id'] !== $id && $journal['user_id'] !== $currentUser['id']) {
            $_SESSION['error'] = 'Journal entry not found.';
            $this->redirect('/journal');
            return;
        }

        return $this->view('journal/peeks', [
            'title' => $journal['title'],
            'journal' => $journal
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