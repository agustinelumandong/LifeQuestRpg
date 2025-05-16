<div class="login-page">
  <!-- RPG decorative elements -->

  <!-- <img src="< ?php echo \App\Core\Helpers::asset('images/reppolo.png'); ?>" alt="" class="rpg-icon icon-shield">
  <img src="< ?php echo \App\Core\Helpers::asset('images/sword.png'); ?>" alt="" class="rpg-icon icon-sword"> -->

  <div class="login-container">
    <div class="login-card">
      <div class="login-header">
        <h1><?= $title ?></h1>
      </div>
      <div class="login-body">
        <form method="post" action="/login">
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
          <div class="d-flex align-items-center mt-4">
            <button type="submit" class="btn btn-login">
              <i class="fas fa-sign-in-alt me-2"></i>Login
            </button>
            <a href="/register" class="register-link ms-3">New Player? Register</a>
          </div>
        </form>
      </div>
    </div>
    <div class="login-footer mt-4">
      <p>Your adventure awaits. Login to continue your quest!</p>
    </div>
  </div>
</div>