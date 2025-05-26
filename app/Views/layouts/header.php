<!DOCTYPE html>
<html lang="en" data-bs-theme="<?= $currentUser['theme'] ?? 'light' ?>">

<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
  <meta http-equiv="Pragma" content="no-cache">
  <meta http-equiv="Expires" content="0">
  <title><?= $title ?? 'LifeQuestRPG' ?></title>

  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css">

  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css"
    integrity="sha512-z3gLpd7yknf1YoNbCzqRKc4qyor8gaKU1qmn+CShxbuBusANI9QpRohGBreCFkKxLhei6S9CQXFEbbKuqLg0DA=="
    crossorigin="anonymous" referrerpolicy="no-referrer" />

  <link rel="stylesheet" href="<?= \App\Core\Helpers::asset('css/fonts.css') ?>">
  <link rel="stylesheet" href="<?= \App\Core\Helpers::asset('css/bootstrap.min.css') ?>">
  <link rel="stylesheet" href="<?= \App\Core\Helpers::asset('css/bootstrap-icons.css') ?>" />
  <link rel="stylesheet" href="<?= \App\Core\Helpers::asset('css/style.css') ?>">
  <link rel="stylesheet" href="<?= \App\Core\Helpers::asset('css/navbar.css') ?>">
  <link rel="stylesheet" href="<?= \App\Core\Helpers::asset('css/themes.css') ?>">
  <?php if (strpos($_SERVER['REQUEST_URI'], '/admin') === 0): ?>
    <link rel="stylesheet" href="<?= \App\Core\Helpers::asset('css/admin.css') ?>">
    <?php if (strpos($_SERVER['REQUEST_URI'], '/admin/marketplace') !== false): ?>
      <link rel="stylesheet" href="<?= \App\Core\Helpers::asset('css/marketplace.css') ?>">
    <?php endif; ?>
  <?php endif; ?>
  <?php if (strpos($_SERVER['REQUEST_URI'], '/marketplace') === 0): ?>
    <link rel="stylesheet" href="<?= \App\Core\Helpers::asset('css/marketplace.css') ?>">
    <script src="<?= \App\Core\Helpers::asset('js/marketplace.js') ?>" defer></script>
  <?php endif; ?>
</head>

<link rel="stylesheet" href="<?php echo \App\Core\Helpers::asset('css/login.css'); ?>">

<body
  class="theme-<?= $currentUser['theme'] ?? 'light' ?> color-<?= $currentUser['color_scheme'] ?? 'default' ?> <?= \App\Core\Auth::check() ? 'logged-in' : '' ?>">