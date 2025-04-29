<?php

use App\Controllers\ActivityLogController;
use App\Controllers\HomeController;
use App\Controllers\UserController;
use App\Controllers\AuthController;
use App\Controllers\BadHabitsController;
use App\Middleware\AuthMiddleware;
use App\Middleware\AdminMiddleware;
use App\Controllers\TaskController;
use App\Controllers\DailyTaskController;
use App\Controllers\GoodHabitsController;
use App\Controllers\JournalController;

// Define routes
$router->get('/', [HomeController::class, 'index']);

// Auth routes
$router->get('/login', [AuthController::class, 'index']);
$router->post('/login', [AuthController::class, 'login']);
$router->get('/logout', [AuthController::class, 'logout'], [AuthMiddleware::class]);
$router->get('/register', [AuthController::class, 'register']);
$router->post('/register', [AuthController::class, 'store']);


// User routes
$router->get('/users', [UserController::class, 'index'], [AdminMiddleware::class]);
$router->get('/users/create', [UserController::class, 'create'], [AdminMiddleware::class]);
$router->post('/users', [UserController::class, 'store'], [AdminMiddleware::class]);
$router->get('/users/{id}', [UserController::class, 'show'], [AdminMiddleware::class]);
$router->get('/users/{id}/edit', [UserController::class, 'edit'], [AdminMiddleware::class]);
$router->put('/users/{id}', [UserController::class, 'update'], [AdminMiddleware::class]);
$router->delete('/users/{id}', [UserController::class, 'destroy'], [AdminMiddleware::class]);


  //task routes (done)
  $router->get('/task/index',[TaskController::class, 'index'], [AuthMiddleware::class]);
  $router->post('/tasks', [TaskController::class, 'store'], [AuthMiddleware::class]);
  $router->put('/task/{id}', [TaskController::class, 'update'], [AuthMiddleware::class]);
  $router->delete('/task/{id}/delete', [TaskController::class, 'destroy'], [AuthMiddleware::class]);
  $router->post('/task/{id}/toggle', [TaskController::class, 'toggle'], [AuthMiddleware::class]);

   //Daily task routes (done)
   $router->get('/dailyTask/index',[DailyTaskController::class, 'index'], [AuthMiddleware::class]);
   $router->post('/dailyTask', [DailyTaskController::class, 'store'], [AuthMiddleware::class]);
   $router->put('/dailyTask/{id}', [DailyTaskController::class, 'update'], [AuthMiddleware::class]);
   $router->delete('/dailyTask/{id}/delete', [DailyTaskController::class, 'destroy'], [AuthMiddleware::class]);
   $router->post('/dailyTask/{id}/toggle', [DailyTaskController::class, 'toggle'], [AuthMiddleware::class]);
   
   //Good Habits (done)
   $router->get('/goodHabits/index',[GoodHabitsController::class, 'index'], [AuthMiddleware::class]);
   $router->post('/goodHabits', [GoodHabitsController::class, 'store'], [AuthMiddleware::class]);
   $router->put('/goodHabits/{id}', [GoodHabitsController::class, 'update'], [AuthMiddleware::class]);
   $router->delete('/goodHabits/{id}/delete', [GoodHabitsController::class, 'destroy'], [AuthMiddleware::class]);
   $router->post('/goodHabits/{id}/toggle', [GoodHabitsController::class, 'toggle'], [AuthMiddleware::class]);

  //Bad Habits (done)
   $router->get('/badHabits/index',[BadHabitsController::class, 'index'], [AuthMiddleware::class]);
   $router->post('/badHabits', [BadHabitsController::class, 'store'], [AuthMiddleware::class]);
   $router->put('/badHabits/{id}', [BadHabitsController::class, 'update'], [AuthMiddleware::class]);
   $router->delete('/badHabits/{id}/delete', [BadHabitsController::class, 'destroy'], [AuthMiddleware::class]);
   $router->post('/badHabits/{id}/toggle', [BadHabitsController::class, 'toggle'], [AuthMiddleware::class]);

   //journal
   $router->get('/journal/index',[JournalController::class, 'index'], [AuthMiddleware::class]);
   $router->get('/journal/create', [JournalController::class, 'create'], [AuthMiddleware::class]);
   $router->post('/journal', [JournalController::class, 'store'], [AuthMiddleware::class]); 
   $router->get('/journal/{id}/peek', [JournalController::class, 'peek'], [AuthMiddleware::class]);
   $router->get('/journal/{id}/edit', [JournalController::class, 'edit'], [AuthMiddleware::class]);
   $router->put('/journal/{id}', [JournalController::class, 'update'], [AuthMiddleware::class]);
   $router->delete('/journal/{id}/delete', [JournalController::class, 'destroy'], [AuthMiddleware::class]);
   $router->post('/journal/{id}/toggle', [JournalController::class, 'toggle'], [AuthMiddleware::class]);

   $router->get('/activityLog/index',[ActivityLogController::class, 'index'], [AuthMiddleware::class]);

   