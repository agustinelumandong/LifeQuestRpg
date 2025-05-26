<!-- // app/Views/users/admin_show.php -->
<div class="card">
  <div class="card-header">
    <h2 class="mb-0">User Details: <?= htmlspecialchars($user['name']) ?></h2>
  </div>
  <div class="card-body">
    <div class="row">
      <div class="col-md-6">
        <table class="table">
          <tr>
            <th>ID</th>
            <td><?= $user['id'] ?></td>
          </tr>
          <tr>
            <th>Name</th>
            <td><?= htmlspecialchars($user['name']) ?></td>
          </tr>
          <tr>
            <th>Email</th>
            <td><?= htmlspecialchars($user['email']) ?></td>
          </tr>
          <tr>
            <th>Username</th>
            <td><?= htmlspecialchars($user['username'] ?? 'Not set') ?></td>
          </tr>
          <tr>
            <th>Role</th>
            <td><span
                class="badge <?= $user['role'] === 'admin' ? 'bg-danger' : 'bg-info' ?>"><?= htmlspecialchars($user['role'] ?? 'user') ?></span>
            </td>
          </tr>
          <tr>
            <th>Coins</th>
            <td><?= htmlspecialchars($user['coins'] ?? 0) ?></td>
          </tr>
          <tr>
            <th>Created At</th>
            <td><?= isset($user['created_at']) ? \App\Core\Helpers::formatDate($user['created_at']) : '-' ?></td>
          </tr>
          <tr>
            <th>Last Login</th>
            <td><?= isset($user['last_login']) ? \App\Core\Helpers::formatDate($user['last_login']) : 'Never' ?></td>
          </tr>
        </table>
      </div>

      <div class="col-md-6">
        <h4>User Stats</h4>
        <?php if ($userStats): ?>
          <table class="table">
            <tr>
              <th>Level</th>
              <td><?= htmlspecialchars($userStats['level']) ?></td>

            </tr>
            <tr>
              <th>XP</th>
              <td><?= htmlspecialchars($userStats['xp']) ?>/100</td>
            </tr>
            <tr>
              <th>Health</th>
              <td><?= htmlspecialchars($userStats['health']) ?>/100</td>
            </tr>
          </table>
        <?php else: ?>
          <div class="alert alert-warning">No stats found for this user.</div>
        <?php endif; ?>
      </div>
    </div>

    <div class="mt-4">
      <a href="/users" class="btn btn-secondary">Back to Users</a>
      <a href="/users/<?= $user['id'] ?>/edit" class="btn btn-warning">Edit User</a>
      <form action="/users/<?= $user['id'] ?>" method="post" class="d-inline ms-2"
        onsubmit="return confirm('Are you sure you want to delete this user? This action cannot be undone.')">
        <input type="hidden" name="_method" value="DELETE">
        <button type="submit" class="btn btn-danger">Delete User</button>
      </form>
    </div>
  </div>
</div>