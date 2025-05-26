<?php

use App\Controllers\ActivityLogController;
use App\Controllers\AdminController;
use App\Controllers\CharacterController;
use App\Controllers\HomeController;
use App\Controllers\LeaderboardController;
use App\Controllers\MarketplaceController;
use App\Controllers\TaskEventController;
use App\Controllers\UserController;
use App\Controllers\AuthController;
use App\Controllers\BadHabitsController;
use App\Controllers\StreakController;
use App\Middleware\AuthMiddleware;
use App\Middleware\AdminMiddleware;
use App\Controllers\TaskController;
use App\Controllers\DailyTaskController;
use App\Controllers\GoodHabitsController;
use App\Controllers\JournalController;
use App\Controllers\ExamplePaginationController;
use App\Controllers\PomodoroController;

// Define routes
$router->get('/', [HomeController::class, 'index']);

// Auth routes
$router->get('/login', [AuthController::class, 'index']);
$router->post('/login', [AuthController::class, 'login']);
$router->get('/logout', [AuthController::class, 'logout'], [AuthMiddleware::class]);
$router->get('/register', [AuthController::class, 'register']);
$router->post('/register', [AuthController::class, 'store']);

// Character creation stepper routes
$router->get('/character/stepper', [CharacterController::class, 'showStepper'], [AuthMiddleware::class]);
$router->post('/character/create', [CharacterController::class, 'create'], [AuthMiddleware::class]);
$router->post('/character/process-step', [CharacterController::class, 'processStep'], [AuthMiddleware::class]);

// User routes
$router->get('/users', [UserController::class, 'index'], [AuthMiddleware::class]);
$router->get('/users/create', [UserController::class, 'create'], [AdminMiddleware::class]);
$router->post('/users', [UserController::class, 'store'], [AdminMiddleware::class]);
$router->get('/users/{id}', [UserController::class, 'show'], [AuthMiddleware::class]);
$router->post('/users/{id}/poke', [UserController::class, 'poke'], [AuthMiddleware::class]);
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

// Inventory routes - redirects to marketplace inventory
$router->get('/inventory', [MarketplaceController::class, 'inventory'], [AuthMiddleware::class]);

// Profile routes
$router->get('/profile', [UserController::class, 'profile'], [AuthMiddleware::class]);

// Settings routes
$router->get('/settings', [UserController::class, 'settings'], [AuthMiddleware::class]);
$router->post('/settings/update', [UserController::class, 'updateSettings'], [AuthMiddleware::class]);
$router->get('/settings/export', [UserController::class, 'exportData'], [AuthMiddleware::class]);
$router->post('/settings/delete', [UserController::class, 'deleteAccount'], [AuthMiddleware::class]);

// Example Pagination routes
$router->get('/examples/pagination', [ExamplePaginationController::class, 'index']);
$router->get('/examples/pagination/bootstrap', [ExamplePaginationController::class, 'bootstrap']);
$router->get('/examples/pagination/tailwind', [ExamplePaginationController::class, 'tailwind']);
$router->get('/examples/pagination/ajax', [ExamplePaginationController::class, 'ajax']);
$router->get('/examples/pagination/generate', [ExamplePaginationController::class, 'generate']);

// Leaderboard routes
$router->get('/leaderboard', [LeaderboardController::class, 'index'], [AuthMiddleware::class]);

// Marketplace routes
$router->get('/marketplace', [MarketplaceController::class, 'index'], [AuthMiddleware::class]);
$router->get('/marketplace/create', [MarketplaceController::class, 'create'], [AdminMiddleware::class]);
$router->post('/marketplace/store', [MarketplaceController::class, 'store'], [AdminMiddleware::class]);
$router->get('/marketplace/edit/{id}', [MarketplaceController::class, 'edit'], [AdminMiddleware::class]);
$router->put('/marketplace/{id}', [MarketplaceController::class, 'update'], [AdminMiddleware::class]);
$router->delete('/marketplace/{id}/delete', [MarketplaceController::class, 'delete'], [AdminMiddleware::class]);
$router->get('/marketplace/purchase/{user_id}/{item_id}', [MarketplaceController::class, 'purchase'], [AuthMiddleware::class]);
$router->post('/marketplace/purchase/{user_id}/{item_id}', [MarketplaceController::class, 'purchase'], [AuthMiddleware::class]);
$router->put('/marketplace/purchase/{user_id}/{item_id}', [MarketplaceController::class, 'purchase'], [AuthMiddleware::class]);
$router->get('/marketplace/inventory', [MarketplaceController::class, 'inventory'], [AuthMiddleware::class]);
$router->post('/marketplace/use-item/{inventory_id}', [MarketplaceController::class, 'useItem'], [AuthMiddleware::class]);

// Streak routes
$router->get('/streaks', [StreakController::class, 'index'], [AuthMiddleware::class]);
$router->post('/streaks/record', [StreakController::class, 'recordActivity'], [AuthMiddleware::class]);
$router->get('/streaks/{streakType}/{streakCount}/rewards', [StreakController::class, 'grantRewards'], [AuthMiddleware::class]);


// Admin routes
$router->get('/admin', [AdminController::class, 'index'], [AdminMiddleware::class]);
$router->get('/admin/content', [AdminController::class, 'contentManagement'], [AdminMiddleware::class]);
$router->get('/admin/marketplace', [AdminController::class, 'marketplaceManagement'], [AdminMiddleware::class]);
$router->get('/admin/users', [AdminController::class, 'userManagement'], [AdminMiddleware::class]);
$router->get('/admin/analytics', [AdminController::class, 'analytics'], [AdminMiddleware::class]);

// Admin user management routes
$router->get('/admin/users/create', [UserController::class, 'create'], [AdminMiddleware::class]);
$router->post('/admin/users', [UserController::class, 'store'], [AdminMiddleware::class]);
$router->post('/admin/users/{id}/reset-password', [UserController::class, 'resetPassword'], [AdminMiddleware::class]);
$router->post('/admin/users/{id}/toggle-status', [UserController::class, 'toggleStatus'], [AdminMiddleware::class]);
$router->post('/admin/users/bulk-action', [UserController::class, 'bulkAction'], [AdminMiddleware::class]);
