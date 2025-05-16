<div class="login-page">
  <!-- RPG decorative elements -->
  <!-- <img src="< ?php echo \App\Core\Helpers::asset('images/reppolo.png'); ?>" alt="" class="rpg-icon icon-shield">
  <img src="< ?php echo \App\Core\Helpers::asset('images/sword.png'); ?>" alt="" class="rpg-icon icon-sword"> -->

  <div class="login-container">
    <div class="login-card register-card">
      <div class="login-header">
        <h1>Join the Adventure</h1>
      </div>
      <div class="login-body">
        <form method="post" action="/register">
          <div class="mb-4">
            <label for="name" class="form-label">
              <i class="fas fa-user me-2"></i>Full Name
            </label>
            <input type="text" class="form-control" id="name" name="name" required>
          </div>
          <div class="mb-4">
            <label for="email" class="form-label">
              <i class="fas fa-envelope me-2"></i>Email
            </label>
            <input type="email" class="form-control" id="email" name="email" required>
          </div>
          <div class="mb-4">
            <label for="password" class="form-label">
              <i class="fas fa-lock me-2"></i>Password
            </label>
            <input type="password" class="form-control" id="password" name="password" required>
          </div>
          <div class="mb-4">
            <label for="confirm_password" class="form-label">
              <i class="fas fa-check-circle me-2"></i>Confirm Password
            </label>
            <input type="password" class="form-control" id="confirm_password" name="password_confirmation" required>
          </div>
          <div class="d-flex align-items-center flex-wrap mt-4">
            <button type="submit" class="btn btn-login">
              <i class="fas fa-user-plus me-2"></i>Create Account
            </button>
            <a href="/login" class="register-link ms-3">Already a player? Login</a>
          </div>
        </form>
      </div>
    </div>
    <div class="login-footer mt-4">
      <p>Begin your heroic journey and level up your life!</p>
    </div>
  </div>
</div>