<div class="card">
  <div class="card-header">
    <div class="d-flex justify-content-between align-items-center">
      <h2 class="mb-0"><?= $title ?></h2>
      <a href="/users/create" class="btn btn-primary">
        <i class="bi bi-person-plus"></i> Create New User
      </a>
    </div>
  </div>
  <div class="card-body">
    <?php if (empty($users)): ?>
      <div class="alert alert-info">No users found.</div>
    <?php else: ?>
      <div class="table-responsive">
        <table class="table table-striped table-hover">
          <thead>
            <tr>
              <th>ID</th>
              <th>Name</th>
              <th>Username</th>
              <th>Email</th>
              <th>Role</th>
              <th>Created At</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <?php foreach ($users as $user): ?>
              <tr>
                <td><?= $user['id'] ?></td>
                <td><?= htmlspecialchars($user['name']) ?></td>
                <td><?= htmlspecialchars($user['username'] ?? $user['name']) ?></td>
                <td><?= htmlspecialchars($user['email']) ?></td>
                <td>
                  <?php if (isset($user['role']) && $user['role'] === 'admin'): ?>
                    <span class="badge bg-danger">Admin</span>
                  <?php else: ?>
                    <span class="badge bg-info">User</span>
                  <?php endif; ?>
                </td>
                <td><?= isset($user['created_at']) ? \App\Core\Helpers::formatDate($user['created_at']) : '-' ?></td>
                <td>
                  <div class="btn-group" role="group">
                    <a href="/users/<?= $user['id'] ?>" class="btn btn-sm btn-info">
                      <i class="bi bi-eye"></i>
                    </a>
                    <a href="/users/<?= $user['id'] ?>/edit" class="btn btn-sm btn-warning">
                      <i class="bi bi-pencil"></i>
                    </a>
                    <form action="/users/<?= $user['id'] ?>" method="post" class="d-inline"
                      onsubmit="return confirm('Are you sure you want to delete this user? This cannot be undone.')">
                      <input type="hidden" name="_method" value="DELETE">
                      <button type="submit" class="btn btn-sm btn-danger">
                        <i class="bi bi-trash"></i>
                      </button>
                    </form>
                  </div>
                </td>
              </tr>
            <?php endforeach; ?>
          </tbody>
        </table>
      </div>
    <?php endif; ?>
  </div>
</div>