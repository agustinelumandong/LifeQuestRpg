<?php

use App\Controllers\HomeController;
use App\Controllers\UserController;
use App\Controllers\AuthController;
use App\Middleware\AdminMiddleware;
use App\Middleware\AuthMiddleware;

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


