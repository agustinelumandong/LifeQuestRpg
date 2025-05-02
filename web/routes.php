<?php

use App\Controllers\ActivityLogController;
use App\Controllers\ApiController;
use App\Controllers\HomeController;
use App\Controllers\LeaderboardController;
use App\Controllers\MarketplaceController;
use App\Controllers\TaskEventController;
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
$router->get('/task', [TaskController::class, 'index'], [AuthMiddleware::class]);
$router->post('/task', [TaskController::class, 'store'], [AuthMiddleware::class]);
$router->put('/task/{id}', [TaskController::class, 'update'], [AuthMiddleware::class]);
$router->delete('/task/{id}/delete', [TaskController::class, 'destroy'], [AuthMiddleware::class]);
$router->post('/task/{id}/toggle', [TaskController::class, 'toggle'], [AuthMiddleware::class]);

//Daily task routes (done)
$router->get('/dailytask', [DailyTaskController::class, 'index'], [AuthMiddleware::class]);
$router->post('/dailytask', [DailyTaskController::class, 'store'], [AuthMiddleware::class]);
$router->put('/dailytask/{id}', [DailyTaskController::class, 'update'], [AuthMiddleware::class]);
$router->delete('/dailytask/{id}/delete', [DailyTaskController::class, 'destroy'], [AuthMiddleware::class]);
$router->post('/dailytask/{id}/toggle', [DailyTaskController::class, 'toggle'], [AuthMiddleware::class]);

// Task Event routes
$router->get('/taskevents', [TaskEventController::class, 'index'], [AuthMiddleware::class]);
$router->get('/taskevents/create', [TaskEventController::class, 'create'], [AdminMiddleware::class]);
$router->post('/taskevents', [TaskEventController::class, 'store'], [AdminMiddleware::class]);
$router->get('/taskevents/{event_id}/edit', [TaskEventController::class, 'edit'], [AdminMiddleware::class]);
$router->put('/taskevents/{event_id}', [TaskEventController::class, 'update'], [AdminMiddleware::class]);
$router->delete('/taskevents/{event_id}', [TaskEventController::class, 'delete'], [AdminMiddleware::class]);
$router->get('/taskevents/{event_id}', [TaskEventController::class, 'show'], [AuthMiddleware::class]);
$router->post('/taskevents/complete/{event_id}', [TaskEventController::class, 'completeTask'], [AuthMiddleware::class]);

//Good Habits (done)
$router->get('/goodhabit', [GoodHabitsController::class, 'index'], [AuthMiddleware::class]);
$router->get('/goodhabit/create', [GoodHabitsController::class, 'create'], [AuthMiddleware::class]);
$router->post('/goodhabit', [GoodHabitsController::class, 'store'], [AuthMiddleware::class]);
$router->get('/goodhabit/{id}/edit', [GoodHabitsController::class, 'edit'], [AuthMiddleware::class]);
$router->put('/goodhabit/{id}', [GoodHabitsController::class, 'update'], [AuthMiddleware::class]);
$router->delete('/goodhabit/{id}/delete', [GoodHabitsController::class, 'destroy'], [AuthMiddleware::class]);
$router->post('/goodhabit/{id}/toggle', [GoodHabitsController::class, 'toggle'], [AuthMiddleware::class]);

//Bad Habits (done)
$router->get('/badhabit', [BadHabitsController::class, 'index'], [AuthMiddleware::class]);
$router->get('/badhabit/create', [BadHabitsController::class, 'create'], [AuthMiddleware::class]);
$router->post('/badhabit', [BadHabitsController::class, 'store'], [AuthMiddleware::class]);
$router->put('/badhabit/{id}', [BadHabitsController::class, 'update'], [AuthMiddleware::class]);
$router->delete('/badhabit/{id}/delete', [BadHabitsController::class, 'destroy'], [AuthMiddleware::class]);
$router->post('/badhabit/{id}/toggle', [BadHabitsController::class, 'toggle'], [AuthMiddleware::class]);

// Journal routes
$router->get('/journal', [JournalController::class, 'index'], [AuthMiddleware::class]);
$router->get('/journal/create', [JournalController::class, 'create'], [AuthMiddleware::class]);
$router->post('/journal', [JournalController::class, 'store'], [AuthMiddleware::class]);
$router->get('/journal/{id}/peek', [JournalController::class, 'peek'], [AuthMiddleware::class]);
$router->get('/journal/{id}/edit', [JournalController::class, 'edit'], [AuthMiddleware::class]);
$router->put('/journal/{id}', [JournalController::class, 'update'], [AuthMiddleware::class]);
$router->delete('/journal/{id}/delete', [JournalController::class, 'destroy'], [AuthMiddleware::class]);
$router->post('/journal/{id}/toggle', [JournalController::class, 'toggle'], [AuthMiddleware::class]);

// Activity Log routes
$router->get('/activityLog/index', [ActivityLogController::class, 'index'], [AuthMiddleware::class]);

// Inventroy routes
$router->get('/inventory', [UserController::class, 'inventory'], [AuthMiddleware::class]);

// Profile routes
$router->get('/profile', [UserController::class, 'profile'], [AuthMiddleware::class]);

// Leaderboard routes
$router->get('/leaderboard', [LeaderboardController::class, 'index'], [AuthMiddleware::class]);

// Marketplace routes
$router->get('/marketplace', [MarketplaceController::class, 'index'], [AuthMiddleware::class]);
$router->get('/marketplace/create', [MarketplaceController::class, 'create'], [AdminMiddleware::class]);
$router->post('/marketplace/store', [MarketplaceController::class, 'store'], [AdminMiddleware::class]);
$router->get('/marketplace/edit/{id}', [MarketplaceController::class, 'edit'], [AdminMiddleware::class]);
$router->put('/marketplace/{id}', [MarketplaceController::class, 'update'], [AdminMiddleware::class]);
$router->put('/marketplace/purchase/{user_id}/{item_id}', [MarketplaceController::class, 'purchase'], [AuthMiddleware::class]);
