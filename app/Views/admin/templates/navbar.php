<?php
// Common admin navigation bar template
?>
<div class="admin-nav mb-4">
  <a href="/admin" <?= strpos($_SERVER['REQUEST_URI'], '/admin') === 0 && strlen($_SERVER['REQUEST_URI']) < 8 ? 'class="active"' : '' ?>>Dashboard</a>
  <a href="/admin/content" <?= strpos($_SERVER['REQUEST_URI'], '/admin/content') === 0 ? 'class="active"' : '' ?>>Content
    Management</a>
  <a href="/admin/marketplace" <?= strpos($_SERVER['REQUEST_URI'], '/admin/marketplace') === 0 ? 'class="active"' : '' ?>>Marketplace</a>
  <a href="/admin/users" <?= strpos($_SERVER['REQUEST_URI'], '/admin/users') === 0 ? 'class="active"' : '' ?>>User
    Management</a>
  <a href="/admin/analytics" <?= strpos($_SERVER['REQUEST_URI'], '/admin/analytics') === 0 ? 'class="active"' : '' ?>>Analytics</a>
</div>