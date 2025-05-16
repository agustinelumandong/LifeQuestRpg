<div class="container mt-4">
  <h1 class="mb-4" style="font-family: 'Pixelify Sans', serif;">Settings</h1>

  <?php if (isset($_SESSION['success'])): ?>
    <div class="alert alert-success">
      <?= $_SESSION['success']; ?>
      <?php unset($_SESSION['success']); ?>
    </div>
  <?php endif; ?>

  <?php if (isset($_SESSION['error'])): ?>
    <div class="alert alert-danger">
      <?= $_SESSION['error']; ?>
      <?php unset($_SESSION['error']); ?>
    </div>
  <?php endif; ?>

  <!-- Nav tabs for different settings sections -->
  <ul class="nav nav-tabs mb-4" id="settingsTabs" role="tablist">
    <li class="nav-item" role="presentation">
      <button class="nav-link active" id="profile-tab" data-bs-toggle="tab" data-bs-target="#profile" type="button"
        role="tab" aria-controls="profile" aria-selected="true">Profile</button>
    </li>
    <li class="nav-item" role="presentation">
      <button class="nav-link" id="avatar-tab" data-bs-toggle="tab" data-bs-target="#avatar" type="button" role="tab"
        aria-controls="avatar" aria-selected="false">Avatar</button>
    </li>
    <li class="nav-item" role="presentation">
      <button class="nav-link" id="notifications-tab" data-bs-toggle="tab" data-bs-target="#notifications" type="button"
        role="tab" aria-controls="notifications" aria-selected="false">Notifications</button>
    </li>
    <li class="nav-item" role="presentation">
      <button class="nav-link" id="theme-tab" data-bs-toggle="tab" data-bs-target="#theme" type="button" role="tab"
        aria-controls="theme" aria-selected="false">Theme</button>
    </li>
    <li class="nav-item" role="presentation">
      <button class="nav-link" id="account-tab" data-bs-toggle="tab" data-bs-target="#account" type="button" role="tab"
        aria-controls="account" aria-selected="false">Account</button>
    </li>
  </ul>

  <!-- Tab content -->
  <div class="tab-content" id="settingsTabContent">
    <!-- Profile Settings -->
    <div class="tab-pane fade show active" id="profile" role="tabpanel" aria-labelledby="profile-tab">
      <div class="card">
        <div class="card-body">
          <h3 class="card-title" style="font-family: 'Pixelify Sans', serif;">Profile Settings</h3>
          <form action="/settings/update" method="POST">
            <input type="hidden" name="update_type" value="profile">

            <div class="mb-3">
              <label for="username" class="form-label">Username</label>
              <input type="text" class="form-control" id="username" name="username"
                value="<?= $currentUser['username'] ?>">
            </div>

            <div class="mb-3">
              <label for="email" class="form-label">Email</label>
              <input type="email" class="form-control" id="email" name="email" value="<?= $currentUser['email'] ?>">
            </div>

            <div class="mb-3">
              <label for="password" class="form-label">New Password</label>
              <input type="password" class="form-control" id="password" name="password">
              <div class="form-text">Leave blank if you don't want to change your password</div>
            </div>

            <div class="mb-3">
              <label for="password_confirmation" class="form-label">Confirm New Password</label>
              <input type="password" class="form-control" id="password_confirmation" name="password_confirmation">
            </div>

            <button type="submit" class="btn btn-dark">Save Profile Settings</button>
          </form>
        </div>
      </div>
    </div>

    <!-- Avatar Settings -->
    <div class="tab-pane fade" id="avatar" role="tabpanel" aria-labelledby="avatar-tab">
      <div class="card">
        <div class="card-body">
          <h3 class="card-title" style="font-family: 'Pixelify Sans', serif;">Avatar Settings</h3>
          <form action="/settings/update" method="POST">
            <input type="hidden" name="update_type" value="avatar">

            <div class="row avatar-selection">
              <!-- Avatar options -->
              <div class="col-md-12 mb-4">
                <p>Select your character avatar:</p>
              </div>

              <div class="col-3 mb-3">
                <div class="avatar-option <?= ($userStats['avatar_id'] == 1) ? 'selected' : '' ?>" data-avatar="1">
                  <img src="/assets/images/avatars/avatar1.svg" alt="Avatar 1" class="img-fluid avatar-preview">
                </div>
              </div>
              <div class="col-3 mb-3">
                <div class="avatar-option <?= ($userStats['avatar_id'] == 2) ? 'selected' : '' ?>" data-avatar="2">
                  <img src="/assets/images/avatars/avatar2.svg" alt="Avatar 2" class="img-fluid avatar-preview">
                </div>
              </div>
              <div class="col-3 mb-3">
                <div class="avatar-option <?= ($userStats['avatar_id'] == 3) ? 'selected' : '' ?>" data-avatar="3">
                  <img src="/assets/images/avatars/avatar3.svg" alt="Avatar 3" class="img-fluid avatar-preview">
                </div>
              </div>
              <div class="col-3 mb-3">
                <div class="avatar-option <?= ($userStats['avatar_id'] == 4) ? 'selected' : '' ?>" data-avatar="4">
                  <img src="/assets/images/avatars/avatar4.svg" alt="Avatar 4" class="img-fluid avatar-preview">
                </div>
              </div>
              <div class="col-3 mb-3">
                <div class="avatar-option <?= ($userStats['avatar_id'] == 5) ? 'selected' : '' ?>" data-avatar="5">
                  <img src="/assets/images/avatars/avatar5.svg" alt="Avatar 5" class="img-fluid avatar-preview">
                </div>
              </div>
              <div class="col-3 mb-3">
                <div class="avatar-option <?= ($userStats['avatar_id'] == 6) ? 'selected' : '' ?>" data-avatar="6">
                  <img src="/assets/images/avatars/avatar6.svg" alt="Avatar 6" class="img-fluid avatar-preview">
                </div>
              </div>


              <input type="hidden" id="avatar_id" name="avatar_id" value="<?= $userStats['avatar_id'] ?? 1 ?>">
            </div>

            <button type="submit" class="btn btn-dark">Save Avatar</button>
          </form>
        </div>
      </div>
    </div>

    <!-- Notification Settings -->
    <div class="tab-pane fade" id="notifications" role="tabpanel" aria-labelledby="notifications-tab">
      <div class="card">
        <div class="card-body">
          <h3 class="card-title" style="font-family: 'Pixelify Sans', serif;">Notification Settings</h3>
          <form action="/settings/update" method="POST">
            <input type="hidden" name="update_type" value="notifications">

            <div class="form-check form-switch mb-3">
              <input class="form-check-input" type="checkbox" role="switch" id="emailNotifications"
                name="email_notifications" <?= ($currentUser['email_notifications'] ?? false) ? 'checked' : '' ?>>
              <label class="form-check-label" for="emailNotifications">Email Notifications</label>
            </div>

            <div class="form-check form-switch mb-3">
              <input class="form-check-input" type="checkbox" role="switch" id="taskReminders" name="task_reminders"
                <?= ($currentUser['task_reminders'] ?? false) ? 'checked' : '' ?>>
              <label class="form-check-label" for="taskReminders">Task Reminders</label>
            </div>

            <div class="form-check form-switch mb-3">
              <input class="form-check-input" type="checkbox" role="switch" id="achievementAlerts"
                name="achievement_alerts" <?= ($currentUser['achievement_alerts'] ?? true) ? 'checked' : '' ?>>
              <label class="form-check-label" for="achievementAlerts">Achievement Alerts</label>
            </div>

            <button type="submit" class="btn btn-dark">Save Notification Settings</button>
          </form>
        </div>
      </div>
    </div>

    <!-- Theme Settings -->
    <div class="tab-pane fade" id="theme" role="tabpanel" aria-labelledby="theme-tab">
      <div class="card">
        <div class="card-body">
          <h3 class="card-title" style="font-family: 'Pixelify Sans', serif;">Theme Settings</h3>
          <form action="/settings/update" method="POST">
            <input type="hidden" name="update_type" value="theme">

            <div class="mb-4">
              <label class="form-label">Theme Mode</label>
              <div class="row mt-3">
                <!-- Light Theme Option -->
                <div class="col-md-6 mb-3">
                  <div
                    class="theme-option p-3 border rounded <?= ($currentUser['theme'] ?? 'dark') == 'light' ? 'border-primary' : '' ?>"
                    data-theme="light">
                    <div class="theme-preview light-theme-preview mb-3">
                      <div class="preview-navbar"></div>
                      <div class="preview-content">
                        <div class="preview-sidebar"></div>
                        <div class="preview-main"></div>
                      </div>
                    </div>
                    <div class="form-check">
                      <input class="form-check-input" type="radio" name="theme" id="lightTheme" value="light"
                        <?= ($currentUser['theme'] ?? 'dark') == 'light' ? 'checked' : '' ?>>
                      <label class="form-check-label" for="lightTheme">
                        Light Mode
                      </label>
                    </div>
                    <p class="small text-muted mt-2">Bright theme with light backgrounds and dark text.</p>
                  </div>
                </div>

                <!-- Dark Theme Option -->
                <div class="col-md-6 mb-3">
                  <div
                    class="theme-option p-3 border rounded <?= ($currentUser['theme'] ?? 'dark') == 'dark' ? 'border-primary' : '' ?>"
                    data-theme="dark">
                    <div class="theme-preview dark-theme-preview mb-3">
                      <div class="preview-navbar"></div>
                      <div class="preview-content">
                        <div class="preview-sidebar"></div>
                        <div class="preview-main"></div>
                      </div>
                    </div>
                    <div class="form-check">
                      <input class="form-check-input" type="radio" name="theme" id="darkTheme" value="dark"
                        <?= ($currentUser['theme'] ?? 'dark') == 'dark' ? 'checked' : '' ?>>
                      <label class="form-check-label" for="darkTheme">
                        Dark Mode
                      </label>
                    </div>
                    <p class="small text-muted mt-2">Dark theme with reduced brightness for low-light environments.</p>
                  </div>
                </div>
              </div>
            </div>

            <div class="mb-4">
              <label for="colorScheme" class="form-label">Color Accent</label>

              <!-- Color scheme preview row -->
              <div class="row mb-3">
                <div class="col-3">
                  <div class="color-preview color-default-preview color-preview-element">Default</div>
                </div>
                <div class="col-3">
                  <div class="color-preview color-forest-preview color-preview-element">Forest</div>
                </div>
                <div class="col-3">
                  <div class="color-preview color-ocean-preview color-preview-element">Ocean</div>
                </div>
                <div class="col-3">
                  <div class="color-preview color-sunset-preview color-preview-element">Sunset</div>
                </div>
              </div>

              <select class="form-select" id="colorScheme" name="color_scheme">
                <option value="default" <?= ($currentUser['color_scheme'] ?? 'default') == 'default' ? 'selected' : '' ?>>
                  Default</option>
                <option value="forest" <?= ($currentUser['color_scheme'] ?? 'default') == 'forest' ? 'selected' : '' ?>>
                  Forest</option>
                <option value="ocean" <?= ($currentUser['color_scheme'] ?? 'default') == 'ocean' ? 'selected' : '' ?>>Ocean
                </option>
                <option value="sunset" <?= ($currentUser['color_scheme'] ?? 'default') == 'sunset' ? 'selected' : '' ?>>
                  Sunset</option>
              </select>
              <div class="form-text">Choose a color accent for buttons and highlights.</div>
            </div>

            <button type="submit" class="btn btn-dark">Save Theme Settings</button>
          </form>
        </div>
      </div>
    </div>

    <style>
      .theme-option {
        cursor: pointer;
        transition: all 0.2s ease;
      }

      .theme-option:hover {
        transform: translateY(-5px);
        box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
      }

      .theme-option.border-primary {
        border-width: 2px !important;
        box-shadow: 0 5px 15px rgba(13, 110, 253, 0.2);
      }

      .theme-preview {
        height: 160px;
        border-radius: 8px;
        overflow: hidden;
        border: 1px solid #dee2e6;
      }

      .light-theme-preview {
        background-color: #ffffff;
        color: #212529;
      }

      .dark-theme-preview {
        background-color: #212529;
        color: #f8f9fa;
      }

      .preview-navbar {
        height: 30px;
        background-color: inherit;
        border-bottom: 1px solid;
        border-color: inherit;
        opacity: 0.8;
      }

      .preview-content {
        display: flex;
        height: calc(100% - 30px);
      }

      .preview-sidebar {
        width: 25%;
        height: 100%;
        border-right: 1px solid;
        border-color: inherit;
        opacity: 0.7;
      }

      .preview-main {
        width: 75%;
        height: 100%;
        position: relative;
      }

      .preview-main::after {
        content: "";
        position: absolute;
        top: 15px;
        left: 15px;
        width: 70%;
        height: 10px;
        background-color: currentColor;
        opacity: 0.2;
        border-radius: 5px;
      }

      .preview-main::before {
        content: "";
        position: absolute;
        top: 35px;
        left: 15px;
        width: 40%;
        height: 60px;
        background-color: currentColor;
        opacity: 0.1;
        border-radius: 5px;
      }

      /* Make theme options clickable to select radio */
      .theme-option {
        position: relative;
      }

      .theme-option input[type="radio"] {
        position: relative;
        z-index: 2;
      }

      /* Make color previews clickable */
      .color-preview {
        cursor: pointer;
        transition: all 0.2s ease;
      }

      .color-preview:hover {
        transform: translateY(-2px);
        box-shadow: 0 3px 10px rgba(0, 0, 0, 0.1);
      }
    </style>

    <!-- Account Settings -->
    <div class="tab-pane fade" id="account" role="tabpanel" aria-labelledby="account-tab">
      <div class="card">
        <div class="card-body">
          <h3 class="card-title" style="font-family: 'Pixelify Sans', serif;">Account Settings</h3>

          <div class="mb-4">
            <h5>Export Your Data</h5>
            <p>Download all your LifeQuestRPG data including tasks, habits, and achievements.</p>
            <a href="/settings/export" class="btn btn-outline-dark">Export Data</a>
          </div>

          <div class="mb-4 border-top pt-4">
            <h5 class="text-danger">Danger Zone</h5>
            <p>Once you delete your account, there is no going back. Please be certain.</p>
            <button type="button" class="btn btn-outline-danger" data-bs-toggle="modal"
              data-bs-target="#deleteAccountModal">
              Delete Account
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>

<!-- Delete Account Modal -->
<div class="modal fade" id="deleteAccountModal" tabindex="-1" aria-labelledby="deleteAccountModalLabel"
  aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="deleteAccountModalLabel">Delete Account</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        <p>Are you sure you want to delete your account? This action cannot be undone.</p>
        <form action="/settings/delete" method="POST">
          <div class="mb-3">
            <label for="confirmPassword" class="form-label">Enter your password to confirm</label>
            <input type="password" class="form-control" id="confirmPassword" name="password" required>
          </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
        <button type="submit" class="btn btn-danger">Delete Account</button>
        </form>
      </div>
    </div>
  </div>
</div>

<style>
  .avatar-selection {
    margin-bottom: 20px;
  }

  .avatar-option {
    border: 3px solid #dee2e6;
    border-radius: 8px;
    padding: 10px;
    cursor: pointer;
    transition: all 0.3s ease;
    display: flex;
    justify-content: center;
  }

  .avatar-option:hover {
    border-color: #adb5bd;
    transform: translateY(-5px);
  }

  .avatar-option.selected {
    border-color: #212529;
    box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
  }

  .avatar-preview {
    width: 100%;
    height: auto;
    max-width: 80px;
    border-radius: 50%;
  }
</style>

<script>
  document.addEventListener('DOMContentLoaded', function () {
    // Handle avatar selection
    const avatarOptions = document.querySelectorAll('.avatar-option');
    const avatarIdInput = document.getElementById('avatar_id');

    avatarOptions.forEach(option => {
      option.addEventListener('click', function () {
        // Remove selected class from all options
        avatarOptions.forEach(o => o.classList.remove('selected'));
        // Add selected class to clicked option
        this.classList.add('selected');
        // Update hidden input value
        avatarIdInput.value = this.getAttribute('data-avatar');
      });
    });

    // Form validation for password
    const profileForm = document.querySelector('#profile form');
    if (profileForm) {
      profileForm.addEventListener('submit', function (e) {
        const password = document.getElementById('password').value;
        const confirmation = document.getElementById('password_confirmation').value;

        if (password && password !== confirmation) {
          e.preventDefault();
          alert('Passwords do not match!');
        }
      });
    }

    // Make color preview elements clickable
    document.querySelectorAll('.color-preview').forEach(preview => {
      preview.addEventListener('click', function () {
        // Extract color scheme from class name
        const classNames = this.classList;
        let colorScheme = '';

        for (let className of classNames) {
          if (className.startsWith('color-') && className.endsWith('-preview')) {
            colorScheme = className.replace('color-', '').replace('-preview', '');
            break;
          }
        }

        if (colorScheme) {
          // Update select element
          const colorSelect = document.getElementById('colorScheme');
          colorSelect.value = colorScheme;

          // Trigger change event to apply preview
          const event = new Event('change');
          colorSelect.dispatchEvent(event);
        }
      });
    });
  });
</script>