<!-- // app/Views/users/create.php -->
<div class="card">
  <div class="card-header">
    <h1><?= $title ?></h1>
  </div>
  <div class="card-body">
    <form method="post" action="/users">
      <div class="mb-3">
        <label for="name" class="form-label">Name</label>
        <input type="text" class="form-control" id="name" name="name" required>
      </div>
      <div class="mb-3">
        <label for="email" class="form-label">Email</label>
        <input type="email" class="form-control" id="email" name="email" required>
      </div>
      <div class="mb-3">
        <label for="username" class="form-label">Username (optional)</label>
        <input type="text" class="form-control" id="username" name="username">
        <div class="form-text">If not provided, the name will be used as username</div>
      </div>
      <div class="mb-3">
        <label for="role" class="form-label">Role</label>
        <select class="form-select" id="role" name="role">
          <option value="user">Regular User</option>
          <?php if (App\Core\Auth::isAdmin()): ?>
            <option value="admin">Administrator</option>
          <?php endif; ?>
        </select>
      </div>
      <div class="mb-3">
        <label for="password" class="form-label">Password</label>
        <input type="password" class="form-control" id="password" name="password" required>
      </div>
      <div class="mb-3">
        <label for="password_confirmation" class="form-label">Confirm Password</label>
        <input type="password" class="form-control" id="password_confirmation" name="password_confirmation" required>
      </div>
      <button type="submit" class="btn btn-primary">Create User</button>
      <?php
      $isAdmin = strpos($_SERVER['REQUEST_URI'] ?? '', '/admin/') !== false;
      $backUrl = $isAdmin ? '/admin/users' : '/users';
      ?>
      <a href="<?= $backUrl ?>" class="btn btn-secondary">Cancel</a>
    </form>
  </div>
</div>