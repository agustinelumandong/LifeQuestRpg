<!-- // app/Views/users/dashboard.php -->
<div class="container">
  <h1 class="mb-4">User Management Dashboard</h1>

  <div class="row mb-4">
    <div class="col-md-12">
      <div class="card bg-light">
        <div class="card-body">
          <div class="d-flex justify-content-between align-items-center">
            <h5 class="mb-0">User Statistics</h5>
            <a href="/users/create" class="btn btn-primary">Add New User</a>
          </div>
          <hr>
          <div class="row text-center">
            <div class="col-md-4">
              <div class="h3"><?= count($users) ?></div>
              <div>Total Users</div>
            </div>
            <div class="col-md-4">
              <div class="h3"><?= array_reduce($users, function ($carry, $user) {
                return $user['role'] === 'admin' ? $carry + 1 : $carry;
              }, 0) ?></div>
              <div>Administrators</div>
            </div>
            <div class="col-md-4">
              <div class="h3"><?= array_reduce($users, function ($carry, $user) {
                return isset($user['last_login']) && strtotime($user['last_login']) > strtotime('-7 days') ? $carry + 1 : $carry;
              }, 0) ?></div>
              <div>Active Last 7 Days</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- User Search and Filters -->
  <div class="card mb-4">
    <div class="card-body">
      <form method="get" class="row g-3 align-items-end">
        <div class="col-md-4">
          <label for="search" class="form-label">Search Users</label>
          <input type="text" class="form-control" id="search" name="search" placeholder="Name, email or username"
            value="<?= htmlspecialchars($_GET['search'] ?? '') ?>">
        </div>
        <div class="col-md-3">
          <label for="role" class="form-label">Role</label>
          <select class="form-select" id="role" name="role">
            <option value="">All Roles</option>
            <option value="admin" <?= isset($_GET['role']) && $_GET['role'] === 'admin' ? 'selected' : '' ?>>Admin</option>
            <option value="user" <?= isset($_GET['role']) && $_GET['role'] === 'user' ? 'selected' : '' ?>>User</option>
          </select>
        </div>
        <div class="col-md-3">
          <label for="sort" class="form-label">Sort By</label>
          <select class="form-select" id="sort" name="sort">
            <option value="newest" <?= (!isset($_GET['sort']) || $_GET['sort'] === 'newest') ? 'selected' : '' ?>>Newest
              First</option>
            <option value="oldest" <?= isset($_GET['sort']) && $_GET['sort'] === 'oldest' ? 'selected' : '' ?>>Oldest First
            </option>
            <option value="name" <?= isset($_GET['sort']) && $_GET['sort'] === 'name' ? 'selected' : '' ?>>Name (A-Z)
            </option>
          </select>
        </div>
        <div class="col-md-2">
          <button type="submit" class="btn btn-primary w-100">Filter</button>
        </div>
      </form>
    </div>
  </div>

  <!-- User Table -->
  <?php if (empty($users)): ?>
    <div class="alert alert-info">No users found.</div>
  <?php else: ?>
    <div class="card">
      <div class="card-body">
        <div class="table-responsive">
          <table class="table table-striped table-hover align-middle">
            <thead>
              <tr>
                <th style="width: 50px;">#</th>
                <th>Name</th>
                <th>Email</th>
                <th>Username</th>
                <th>Role</th>
                <th>Created</th>
                <th>Last Login</th>
                <th style="width: 150px;">Actions</th>
              </tr>
            </thead>
            <tbody>
              <?php foreach ($users as $user): ?>
                <tr>
                  <td><?= $user['id'] ?></td>
                  <td>
                    <?= htmlspecialchars($user['name']) ?>
                  </td>
                  <td><?= htmlspecialchars($user['email']) ?></td>
                  <td><?= htmlspecialchars($user['username'] ?? 'Not set') ?></td>
                  <td>
                    <span class="badge <?= $user['role'] === 'admin' ? 'bg-danger' : 'bg-info' ?>">
                      <?= htmlspecialchars($user['role'] ?? 'user') ?>
                    </span>
                  </td>
                  <td><?= isset($user['created_at']) ? \App\Core\Helpers::formatDate($user['created_at']) : '-' ?></td>
                  <td><?= isset($user['last_login']) ? \App\Core\Helpers::formatDate($user['last_login']) : 'Never' ?></td>
                  <td>
                    <div class="btn-group" role="group">
                      <a href="/users/<?= $user['id'] ?>" class="btn btn-sm btn-info">View</a>
                      <a href="/users/<?= $user['id'] ?>/edit" class="btn btn-sm btn-warning">Edit</a>
                      <form action="/users/<?= $user['id'] ?>" method="post" class="d-inline"
                        onsubmit="return confirm('Are you sure you want to delete this user? This cannot be undone.')">
                        <input type="hidden" name="_method" value="DELETE">
                        <button type="submit" class="btn btn-sm btn-danger">Delete</button>
                      </form>
                    </div>
                  </td>
                </tr>
              <?php endforeach; ?>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  <?php endif; ?>
</div>