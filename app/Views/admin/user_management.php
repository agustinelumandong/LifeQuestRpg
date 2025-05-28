<div class="admin-dashboard">
  <div class="container-fluid">
    <div class="d-flex justify-content-between align-items-center">
      <h1 class="display-5 fw-bold mb-4 fade-in" style="font-family: 'Pixelify Sans', serif;">User Management</h1>

    </div>


    <!-- User Stats Cards -->
    <div class="row mb-4">
      <!-- Total Users -->
      <div class="col-md-3 mb-3">
        <div class="stat-card">
          <div class="d-flex justify-content-between align-items-center">
            <div>
              <p class="stat-title">Total Users</p>
              <h3><?= count($users) ?></h3>
            </div>
            <div class="stat-icon bg-primary">
              <i class="bi bi-people-fill"></i>
            </div>
          </div>
        </div>
      </div>

      <!-- Admins -->
      <div class="col-md-3 mb-3">
        <div class="stat-card">
          <div class="d-flex justify-content-between align-items-center">
            <div>
              <p class="stat-title">Admin Users</p>
              <?php
              $adminCount = 0;
              foreach ($users as $user) {
                if (isset($user['role']) && $user['role'] === 'admin') {
                  $adminCount++;
                }
              }
              ?>
              <h3><?= $adminCount ?></h3>
            </div>
            <div class="stat-icon bg-purple">
              <i class="bi bi-shield-fill-check"></i>
            </div>
          </div>
        </div>
      </div>

      <!-- Active Users -->
      <div class="col-md-3 mb-3">
        <div class="stat-card">
          <div class="d-flex justify-content-between align-items-center">
            <div>
              <p class="stat-title">Active Users</p>
              <?php
              $activeCount = 0;
              foreach ($users as $user) {
                if (!isset($user->is_disabled) || !$user->is_disabled) {
                  $activeCount++;
                }
              }
              ?>
              <h3><?= $activeCount ?></h3>
            </div>
            <div class="stat-icon bg-success">
              <i class="bi bi-check-circle-fill"></i>
            </div>
          </div>
        </div>
      </div>

      <!-- Inactive Users -->
      <div class="col-md-3 mb-3">
        <div class="stat-card">
          <div class="d-flex justify-content-between align-items-center">
            <div>
              <p class="stat-title">Inactive Users</p>
              <?php
              $inactiveCount = 0;
              foreach ($users as $user) {
                if (isset($user->is_disabled) && $user->is_disabled) {
                  $inactiveCount++;
                }
              }
              ?>
              <h3><?= $inactiveCount ?></h3>
            </div>
            <div class="stat-icon bg-danger">
              <i class="bi bi-x-circle-fill"></i>
            </div>
          </div>
        </div>
      </div>
    </div> <!-- Search and Filter Controls -->
    <div class="admin-card mb-4">
      <div class="row">
        <div class="col-md-8 mb-3 mb-md-0">
          <form action="/admin/users" method="GET" class="d-flex align-items-center">
            <div class="input-group me-2">
              <span class="input-group-text">
                <i class="bi bi-search"></i>
              </span>
              <input type="text" name="search"
                value="<?= isset($_GET['search']) ? htmlspecialchars($_GET['search']) : '' ?>"
                placeholder="Search users..." class="form-control rpg-form-control">
            </div>
            <button type="submit" class="rpg-btn rpg-btn-primary">Search</button>
          </form>
        </div>
        <div class="col-md-4">
          <div class="d-flex gap-2 flex-wrap">
            <form action="/admin/users" method="GET" class="me-2">
              <select name="role" onChange="this.form.submit()" class="form-select rpg-form-select">
                <option value="">All Roles</option>
                <option value="admin" <?= isset($_GET['role']) && $_GET['role'] === 'admin' ? 'selected' : '' ?>>Admin
                </option>
                <option value="user" <?= isset($_GET['role']) && $_GET['role'] === 'user' ? 'selected' : '' ?>>User
                </option>
              </select>
            </form>

            <form action="/admin/users" method="GET">
              <select name="status" onChange="this.form.submit()" class="form-select rpg-form-select">
                <option value="">All Status</option>
                <option value="active" <?= isset($_GET['status']) && $_GET['status'] === 'active' ? 'selected' : '' ?>>
                  Active
                </option>
                <option value="inactive" <?= isset($_GET['status']) && $_GET['status'] === 'inactive' ? 'selected' : '' ?>>
                  Inactive</option>
              </select>
            </form>
          </div>
        </div>
      </div>
      <div class="d-flex justify-content-between align-items-center mt-3">
        <div id="bulkActionContainer" class="d-none">
          <div class="d-flex align-items-center">
            <select id="bulkAction" class="form-select rpg-form-select me-2">
              <option value="">Bulk Actions</option>
              <option value="enable">Enable Selected</option>
              <option value="disable">Disable Selected</option>
              <option value="delete">Delete Selected</option>
            </select>
            <button type="button" id="applyBulkAction" class="rpg-btn rpg-btn-primary">Apply</button>
          </div>
        </div>

      </div>
    </div> <!-- Users Table -->
    <div class="card">
      <div class="card-header">
        <div class="d-flex justify-content-between align-items-center">
          <h2 class="mb-0"><?= $title ?? 'User Management' ?></h2>
          <a href="#" class="rpg-btn" data-bs-toggle="modal" data-bs-target="#addUserModal">
            <i class="bi bi-person-plus-fill me-1"></i> Add New User
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
                        <button type="button" class="btn btn-sm btn-info show-user-btn" data-bs-toggle="modal"
                          data-bs-target="#showUserModal" data-user-id="<?= $user['id'] ?>"
                          data-user-name="<?= htmlspecialchars($user['name']) ?>"
                          data-user-username="<?= htmlspecialchars($user['username'] ?? $user['name']) ?>"
                          data-user-email="<?= htmlspecialchars($user['email']) ?>"
                          data-user-role="<?= $user['role'] ?? 'user' ?>"
                          data-user-created="<?= isset($user['created_at']) ? \App\Core\Helpers::formatDate($user['created_at']) : '-' ?>">
                          <i class="bi bi-eye"></i>
                        </button>
                        <button type="button" class="btn btn-sm btn-warning edit-user-btn" data-bs-toggle="modal"
                          data-bs-target="#editUserModal" data-user-id="<?= $user['id'] ?>"
                          data-user-name="<?= htmlspecialchars($user['name']) ?>"
                          data-user-username="<?= htmlspecialchars($user['username'] ?? $user['name']) ?>"
                          data-user-email="<?= htmlspecialchars($user['email']) ?>"
                          data-user-role="<?= $user['role'] ?? 'user' ?>">
                          <i class="bi bi-pencil"></i>
                        </button>
                        <button type="button" class="btn btn-sm btn-danger delete-user-btn" data-bs-toggle="modal"
                          data-bs-target="#deleteUserModal" data-user-id="<?= $user['id'] ?>"
                          data-user-name="<?= htmlspecialchars($user['name']) ?>">
                          <i class="bi bi-trash"></i>
                        </button>
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

    <!-- Pagination -->

  </div>

  <!-- Add User Modal -->
  <div class="modal rpg-modal fade" id="addUserModal" tabindex="-1" aria-labelledby="addUserModalLabel"
    aria-hidden="true">
    <div class="modal-dialog">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title" id="addUserModalLabel">Add New User</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>
        <div class="modal-body">
          <form id="addUserForm" action="/admin/users" method="POST">
            <div class="mb-3">
              <label for="name" class="rpg-form-label">Name</label>
              <input type="text" class="form-control rpg-form-control" id="name" name="name" required>
            </div>
            <div class="mb-3">
              <label for="username" class="rpg-form-label">Username</label>
              <input type="text" class="form-control rpg-form-control" id="username" name="username" required>
            </div>
            <div class="mb-3">
              <label for="email" class="rpg-form-label">Email</label>
              <input type="email" class="form-control rpg-form-control" id="email" name="email" required>
            </div>
            <div class="mb-3">
              <label for="password" class="rpg-form-label">Password</label>
              <input type="password" class="form-control rpg-form-control" id="password" name="password" required>
            </div>
            <div class="mb-3">
              <label for="password_confirmation" class="rpg-form-label">Confirm Password</label>
              <input type="password" class="form-control rpg-form-control" id="password_confirmation"
                name="password_confirmation" required>
            </div>
            <div class="mb-3">
              <label for="role" class="rpg-form-label">Role</label>
              <select class="form-select rpg-form-select" id="role" name="role">
                <option value="user">User</option>
                <option value="admin">Admin</option>
              </select>
            </div>
          </form>
        </div>
        <div class="modal-footer">
          <button type="button" class="rpg-btn rpg-btn-outline" data-bs-dismiss="modal">Cancel</button>
          <button type="button" class="rpg-btn" id="submitUserForm">Add User</button>
        </div>
      </div>
    </div>
  </div>

  <!-- Show User Modal -->
  <div class="modal rpg-modal fade" id="showUserModal" tabindex="-1" aria-labelledby="showUserModalLabel"
    aria-hidden="true">
    <div class="modal-dialog">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title" id="showUserModalLabel">User Details</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>
        <div class="modal-body">
          <div class="row mb-3">
            <div class="col-4"><strong>ID:</strong></div>
            <div class="col-8" id="showUserId"></div>
          </div>
          <div class="row mb-3">
            <div class="col-4"><strong>Name:</strong></div>
            <div class="col-8" id="showUserName"></div>
          </div>
          <div class="row mb-3">
            <div class="col-4"><strong>Username:</strong></div>
            <div class="col-8" id="showUserUsername"></div>
          </div>
          <div class="row mb-3">
            <div class="col-4"><strong>Email:</strong></div>
            <div class="col-8" id="showUserEmail"></div>
          </div>
          <div class="row mb-3">
            <div class="col-4"><strong>Role:</strong></div>
            <div class="col-8">
              <span id="showUserRole" class="badge"></span>
            </div>
          </div>
          <div class="row mb-3">
            <div class="col-4"><strong>Created At:</strong></div>
            <div class="col-8" id="showUserCreated"></div>
          </div>
        </div>
        <div class="modal-footer">
          <button type="button" class="rpg-btn rpg-btn-outline" data-bs-dismiss="modal">Close</button>
        </div>
      </div>
    </div>
  </div>

  <!-- Edit User Modal -->
  <div class="modal rpg-modal fade" id="editUserModal" tabindex="-1" aria-labelledby="editUserModalLabel"
    aria-hidden="true">
    <div class="modal-dialog">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title" id="editUserModalLabel">Edit User</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>
        <div class="modal-body">
          <form id="editUserForm" method="POST">
            <input type="hidden" name="_method" value="PUT">
            <div class="mb-3">
              <label for="edit_name" class="rpg-form-label">Name</label>
              <input type="text" class="form-control rpg-form-control" id="edit_name" name="name" required>
            </div>
            <div class="mb-3">
              <label for="edit_username" class="rpg-form-label">Username</label>
              <input type="text" class="form-control rpg-form-control" id="edit_username" name="username" required>
            </div>
            <div class="mb-3">
              <label for="edit_email" class="rpg-form-label">Email</label>
              <input type="email" class="form-control rpg-form-control" id="edit_email" name="email" required>
            </div>
            <div class="mb-3">
              <label for="edit_password" class="rpg-form-label">Password (leave blank to keep current)</label>
              <input type="password" class="form-control rpg-form-control" id="edit_password" name="password">
            </div>
            <div class="mb-3">
              <label for="edit_password_confirmation" class="rpg-form-label">Confirm Password</label>
              <input type="password" class="form-control rpg-form-control" id="edit_password_confirmation"
                name="password_confirmation">
            </div>
            <div class="mb-3">
              <label for="edit_role" class="rpg-form-label">Role</label>
              <select class="form-select rpg-form-select" id="edit_role" name="role">
                <option value="user">User</option>
                <option value="admin">Admin</option>
              </select>
            </div>
          </form>
        </div>
        <div class="modal-footer">
          <button type="button" class="rpg-btn rpg-btn-outline" data-bs-dismiss="modal">Cancel</button>
          <button type="button" class="rpg-btn" id="submitEditUserForm">Update User</button>
        </div>
      </div>
    </div>
  </div>

  <!-- Delete User Modal -->
  <div class="modal rpg-modal fade" id="deleteUserModal" tabindex="-1" aria-labelledby="deleteUserModalLabel"
    aria-hidden="true">
    <div class="modal-dialog">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title" id="deleteUserModalLabel">Delete User</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>
        <div class="modal-body">
          <div class="alert alert-warning">
            <i class="bi bi-exclamation-triangle-fill me-2"></i>
            <strong>Warning!</strong> This action cannot be undone.
          </div>
          <p>Are you sure you want to delete the user <strong id="deleteUserName"></strong>?</p>
          <p class="text-muted">This will permanently remove all user data including:</p>
          <ul class="text-muted">
            <li>User profile and settings</li>
            <li>Task and habit progress</li>
            <li>Journal entries</li>
            <li>Achievement and streak data</li>
          </ul>
        </div>
        <div class="modal-footer">
          <button type="button" class="rpg-btn rpg-btn-outline" data-bs-dismiss="modal">Cancel</button>
          <form id="deleteUserForm" method="POST" class="d-inline">
            <input type="hidden" name="_method" value="DELETE">
            <button type="submit" class="rpg-btn bg-danger">
              <i class="bi bi-trash me-1"></i> Delete User
            </button>
          </form>
        </div>
      </div>
    </div>
  </div>
</div>

<!-- Alpine.js for dropdowns -->
<script src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js" defer></script>
<!-- JavaScript for form submission and table functionality -->
<script>
  document.addEventListener('DOMContentLoaded', function () {    // Handle form submission for Add User modal
    const submitUserFormBtn = document.getElementById('submitUserForm');
    const addUserForm = document.getElementById('addUserForm');

    if (submitUserFormBtn && addUserForm) {
      submitUserFormBtn.addEventListener('click', function () {
        // Validate the form
        if (addUserForm.checkValidity()) {
          // Check if passwords match
          const password = document.getElementById('password').value;
          const passwordConfirmation = document.getElementById('password_confirmation').value;

          if (password !== passwordConfirmation) {
            alert('Passwords do not match!');
            return;
          }

          // Submit the form
          addUserForm.submit();
        } else {
          // Trigger HTML5 validation
          addUserForm.reportValidity();
        }
      });
    }

    // Handle Show User Modal
    const showUserButtons = document.querySelectorAll('.show-user-btn');
    showUserButtons.forEach(button => {
      button.addEventListener('click', function () {
        const userId = this.getAttribute('data-user-id');
        const userName = this.getAttribute('data-user-name');
        const userUsername = this.getAttribute('data-user-username');
        const userEmail = this.getAttribute('data-user-email');
        const userRole = this.getAttribute('data-user-role');
        const userCreated = this.getAttribute('data-user-created');

        // Populate the show modal
        document.getElementById('showUserId').textContent = userId;
        document.getElementById('showUserName').textContent = userName;
        document.getElementById('showUserUsername').textContent = userUsername;
        document.getElementById('showUserEmail').textContent = userEmail;
        document.getElementById('showUserCreated').textContent = userCreated;

        // Set role badge
        const roleSpan = document.getElementById('showUserRole');
        if (userRole === 'admin') {
          roleSpan.textContent = 'Admin';
          roleSpan.className = 'badge bg-danger';
        } else {
          roleSpan.textContent = 'User';
          roleSpan.className = 'badge bg-info';
        }
      });
    });

    // Handle Edit User Modal
    const editUserButtons = document.querySelectorAll('.edit-user-btn');
    editUserButtons.forEach(button => {
      button.addEventListener('click', function () {
        const userId = this.getAttribute('data-user-id');
        const userName = this.getAttribute('data-user-name');
        const userUsername = this.getAttribute('data-user-username');
        const userEmail = this.getAttribute('data-user-email');
        const userRole = this.getAttribute('data-user-role');

        // Set form action
        document.getElementById('editUserForm').action = `/users/${userId}`;

        // Populate the edit form
        document.getElementById('edit_name').value = userName;
        document.getElementById('edit_username').value = userUsername;
        document.getElementById('edit_email').value = userEmail;
        document.getElementById('edit_role').value = userRole;

        // Clear password fields
        document.getElementById('edit_password').value = '';
        document.getElementById('edit_password_confirmation').value = '';
      });
    });

    // Handle Edit User Form Submission
    const submitEditUserFormBtn = document.getElementById('submitEditUserForm');
    const editUserForm = document.getElementById('editUserForm');

    if (submitEditUserFormBtn && editUserForm) {
      submitEditUserFormBtn.addEventListener('click', function () {
        // Validate the form
        if (editUserForm.checkValidity()) {
          // Check if passwords match (only if password is provided)
          const password = document.getElementById('edit_password').value;
          const passwordConfirmation = document.getElementById('edit_password_confirmation').value;

          if (password && password !== passwordConfirmation) {
            alert('Passwords do not match!');
            return;
          }

          // Submit the form
          editUserForm.submit();
        } else {
          // Trigger HTML5 validation
          editUserForm.reportValidity();
        }
      });
    }

    // Handle Delete User Modal
    const deleteUserButtons = document.querySelectorAll('.delete-user-btn');
    deleteUserButtons.forEach(button => {
      button.addEventListener('click', function () {
        const userId = this.getAttribute('data-user-id');
        const userName = this.getAttribute('data-user-name');

        // Set form action
        document.getElementById('deleteUserForm').action = `/admin/users/${userId}`;

        // Set user name in modal
        document.getElementById('deleteUserName').textContent = userName;
      });
    });

    // Toggle user status functionality
    const toggleStatusButtons = document.querySelectorAll('.toggle-status-btn');
    toggleStatusButtons.forEach(button => {
      button.addEventListener('click', function () {
        const userId = this.getAttribute('data-user-id');
        const username = this.getAttribute('data-username');
        const currentStatus = this.getAttribute('data-current-status');
        const newStatus = currentStatus === 'active' ? 'disable' : 'enable';

        if (!confirm(`${newStatus.charAt(0).toUpperCase() + newStatus.slice(1)} account for ${username}?`)) return;

        fetch(`/admin/users/${userId}/toggle-status`, {
          method: 'POST'
        })
          .then(response => response.json())
          .then(data => {
            if (data.success) {
              alert(data.message);
              // Reload the page to reflect changes
              window.location.reload();
            } else {
              alert('Error: ' + data.message);
            }
          })
          .catch(error => {
            console.error('Error:', error);
            alert('An error occurred while updating user status');
          });
      });
    });
  });
</script>