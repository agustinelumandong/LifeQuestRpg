<?php

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Controller;
use App\Core\Input;
use App\Models\Inventory;
use App\Models\User;
use Exception;

class UserController extends Controller
{
  protected $userModel;
  protected $userInventoryModel;

  public function __construct()
  {
    $this->userInventoryModel = new Inventory();
    $this->userModel = new User();
  }


  public function index()
  {
    $users = $this->userModel->all();
    $email = $this->userModel->find($users[0]['id'])['email'] ?? null;

    return $this->view('users/index', [
      'title' => 'Users',
      'users' => $users,
      'email' => $email
    ]);
  }

  public function create()
  {
    return $this->view('users/create', [
      'title' => 'Create User'
    ]);
  }


  public function store()
  {
    $data = Input::sanitize([
      'name' => Input::post('name'),
      'email' => Input::post('email'),
      'password' => password_hash(Input::post('password'), PASSWORD_DEFAULT)
    ]);

    $userId = $this->userModel->create($data);

    if ($userId) {
      $_SESSION['success'] = 'User created successfully!';
      $this->redirect('/users');
    } else {
      $_SESSION['error'] = 'Failed to create user.';
      $this->redirect('/users/create');
    }
  }

  public function show($id)
  {
    $user = $this->userModel->find($id);

    if (!$user) {
      $_SESSION['error'] = 'User not found.';
      $this->redirect('/users');
    }

    return $this->view('users/show', [
      'title' => 'User Details',
      'user' => $user
    ]);
  }


  public function edit($id)
  {
    $user = $this->userModel->find($id);

    if (!$user) {
      $_SESSION['error'] = 'User not found.';
      $this->redirect('/users');
    }

    return $this->view('users/edit', [
      'title' => 'Edit User',
      'user' => $user
    ]);
  }


  public function update($id)
  {
    $data = Input::sanitize([
      'name' => Input::post('name'),
      'email' => Input::post('email')
    ]);

    if (Input::post('password')) {
      $data['password'] = password_hash(Input::post('password'), PASSWORD_DEFAULT);
    }

    $updated = $this->userModel->update($id, $data);

    if ($updated) {
      $_SESSION['success'] = 'User updated successfully!';
      $this->redirect('/users');
    } else {
      $_SESSION['error'] = 'Failed to update user.';
      $this->redirect("/users/{$id}/edit");
    }
  }

  public function destroy($id): void
  {
    $deleted = $this->userModel->delete($id);

    if ($deleted) {
      $_SESSION['success'] = 'User deleted successfully!';
    } else {
      $_SESSION['error'] = 'Failed to delete user.';
    }

    $this->redirect('/users');
  }

  public function showTaskDailyPage()
  {
    return $this->view('daily-task/task');
  }

  public function inventory()
  {
    // Get the logged-in user
    $user = Auth::user();

    // Check if user exists
    if (!$user) {
      $_SESSION['error'] = 'User not found or not logged in.';
      $this->redirect('/');
      return;
    }

    // Get user ID more reliably
    $userId = $user['id'] ?? $user->id ?? null;

    if (!$userId) {
      $_SESSION['error'] = 'Invalid user data.';
      $this->redirect('/');
      return;
    }

    try {
      // Get user inventory items
      $items = $this->userInventoryModel->getUserItemNames($userId);
    } catch (Exception $e) {
      $_SESSION['error'] = 'Failed to fetch user items: ' . $e->getMessage();
      $items = [];
    }

    return $this->view('users/inventory', [
      'title' => 'Inventory',
      'items' => $items,
    ]);
  }



  public function profile()
  {
    $currentUser = Auth::user();
    $user = $this->userModel->find($currentUser['id']);

    if (!$user) {
      $_SESSION['error'] = 'User not found.';
      $this->redirect('/users');
    }

    return $this->view('users/profile', [
      'title' => 'Profile',
      'user' => $user
    ]);
  }
}
