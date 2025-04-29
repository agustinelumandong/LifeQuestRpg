<nav class="navbar navbar-expand-lg bg-white border-bottom py-3">
  <div class="container">
    <a class="navbar-brand fw-bold" href="/"><?= \App\Core\Helpers::env('APP_NAME', 'MVC Framework') ?></a>
    <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav"
      aria-controls="navbarNav" aria-expanded="false" aria-label="Toggle navigation">
      <span class="navbar-toggler-icon"></span>
    </button>
    <div class="collapse navbar-collapse" id="navbarNav">
      <ul class="navbar-nav ms-auto">

        <?php if (App\Core\Auth::check()): ?>
          <?php if (App\Core\Auth::isAdmin()): ?>
            <li class="nav-item">
              <a class="nav-link" href="/">Home</a>
            </li>
            <li class="nav-item">
              <a class="nav-link" href="/users">Users</a>
            </li>
            <li class="nav-item">
              <a class="nav-link" href="#">nothing</a>
            </li>
          <?php endif; ?>
          <li class="nav-item">
            <a class="nav-link " style="font-size: 21px; color: red;" href="/logout"> <i class="bi bi-door-open me-1"></i>
            </a>
          </li>
        <?php else: ?>
          <li class="nav-item">
            <a class="nav-link" href="/login">LogIn</a>
          </li>
          <li class="nav-item">
            <a class="nav-link" href="/register">Register</a>
          </li>
        <?php endif; ?>

      </ul>
    </div>
  </div>
</nav>