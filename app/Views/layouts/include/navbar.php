<?php
$currentUser = App\Core\Auth::user();
if ($currentUser) {
  $isLandingPage = false;
} else {
  $isLandingPage = ($_SERVER['REQUEST_URI'] === '/' || $_SERVER['REQUEST_URI'] === '/home');

}
?>

<?php if ($isLandingPage): ?>
  <!-- Landing Page Navigation -->
  <nav class="navbar navbar-expand-lg fixed-top navbar-light pb-3 mb-0 pt-3 mt-0" id="mainNav">
    <div class="container">
      <img id="LifeRpgImage" class="logo-image" src="/assets/images/life%20rpg.png" alt="Life RPG Logo" />
      <a class="navbar-brand rpg-brand" href="#page-top">
        LifeQuest RPG
      </a>
      <!-- <button data-bs-toggle="collapse" data-bs-target="#navbarResponsive" class="navbar-toggler navbar-font"
        type="button" aria-controls="navbarResponsive" aria-expanded="false" aria-label="Toggle navigation">
        <i class="fa fa-bars"></i>
      </button> -->
      <div class="collapse navbar-collapse navbar-font" id="navbarResponsive">
        <ul class="navbar-nav text-uppercase ms-auto py-4 py-lg-0">
          <li class="nav-item"><a class="nav-link fw-bold nav-shadow" href="#services">Services</a></li>
          <li class="nav-item"><a class="nav-link fw-bold nav-shadow" href="#portfolio">Benefits</a></li>
          <li class="nav-item"><a class="nav-link fw-bold nav-shadow" href="#about">About</a></li>
          <li class="nav-item"><a class="nav-link fw-bold nav-shadow" href="#team">Team</a></li>
          <li class="nav-item"><a class="nav-link fw-bold nav-shadow" href="#contact">Contact</a></li>
          <?php if (!App\Core\Auth::check()): ?>
            <li class="nav-item"><a class="nav-link btn btn-primary text-white px-3 ms-lg-3" href="/login">Sign In</a>
            </li>
          <?php else: ?>
            <li class="nav-item"><a class="nav-link btn btn-success text-white px-3 ms-lg-3" href="/dashboard">Dashboard</a>
            </li>
          <?php endif; ?>
        </ul>
      </div>
      <div class="theme-switcher dropdown d-none d-md-block">
        <a class="dropdown-toggle theme-toggle" aria-expanded="false" data-bs-toggle="dropdown" href="#">
          <i class="fa fa-adjust theme-icon"></i>
        </a>
        <div class="dropdown-menu dropdown-menu-end">
          <a class="dropdown-item d-flex align-items-center theme-switch-option" data-theme="light" href="#">
            <i class="fa fa-sun-o me-2"></i>Light
          </a>
          <a class="dropdown-item d-flex align-items-center theme-switch-option" data-theme="dark" href="#">
            <i class="fa fa-moon-o me-2"></i>Dark
          </a>
        </div>
      </div>

      <!-- Mobile Theme Toggle -->
      <div class="d-md-none ms-2">
        <button type="button" class="btn btn-sm theme-toggle-btn" id="mobileThemeToggle">
          <i class="fa fa-adjust"></i>
        </button>
      </div>
    </div>
  </nav>
<?php else: ?>
  <!-- Regular Navigation for other pages -->
  <nav class="navbar navbar-expand-lg navbar-light pb-3 mb-0 pt-3 mt-0" id="mainNav">
    <div class="container">
      <img id="LifeRpgImage" class="logo-image" src="/assets/images/life%20rpg.png" alt="Life RPG Logo" />
      <a class="navbar-brand rpg-brand" href="/">
        <?= \App\Core\Helpers::env('APP_NAME', 'LifeQuest RPG') ?>
      </a>
      <!-- <button data-bs-toggle="collapse" data-bs-target="#navbarNav" class="navbar-toggler navbar-font" type="button"
        aria-controls="navbarNav" aria-expanded="false" aria-label="Toggle navigation">
        <i class="fa fa-bars"></i>
      </button> -->
      <div class="collapse navbar-collapse navbar-font" id="navbarNav">
        <ul class="navbar-nav text-uppercase ms-auto py-4 py-lg-0">
          <?php if (App\Core\Auth::check()): ?>
            <?php if (App\Core\Auth::isAdmin()): ?>
              <li class="nav-item nav-link fw-bold nav-shadow">
                <a href="/admin" <?= strpos($_SERVER['REQUEST_URI'], '/admin') === 0 && strlen($_SERVER['REQUEST_URI']) < 8 ? 'class="active"' : '' ?> style="color: black; text-decoration: none;">
                  Dashboard
                </a>
              </li>
              <li class="nav-item nav-link fw-bold nav-shadow">
                <a href="/admin/content" <?= strpos($_SERVER['REQUEST_URI'], '/admin/content') === 0 ? 'class="active"' : '' ?>
                  style="color: black; text-decoration: none;">Content
                  Management
                </a>
              </li>
              <li class="nav-item nav-link fw-bold nav-shadow">
                <a href="/admin/marketplace" <?= strpos($_SERVER['REQUEST_URI'], '/admin/marketplace') === 0 ? 'class="active"' : '' ?> style="color: black; text-decoration: none;">Marketplace
                </a>
              </li>
              <li class="nav-item nav-link fw-bold nav-shadow">
                <a href="/admin/users" <?= strpos($_SERVER['REQUEST_URI'], '/admin/users') === 0 ? 'class="active"' : '' ?>
                  style="color: black; text-decoration: none;">User
                  Management</a>
              </li>
              <li class="nav-item nav-link fw-bold nav-shadow">
                <a href="/admin/analytics" <?= strpos($_SERVER['REQUEST_URI'], '/admin/analytics') === 0 ? 'class="active"' : '' ?> style="color: black; text-decoration: none;">Analytics</a>
              </li>

            <?php endif; ?>
            <li class="nav-item"><a class="nav-link fw-bold logout-link" href="/logout">
                <i class="bi bi-door-open me-1"></i>Logout</a></li>
          <?php else: ?>
            <!-- <li class="nav-item"><a class="nav-link fw-bold nav-shadow" href="/login">Login</a></li>
            <li class="nav-item"><a class="nav-link btn btn-primary text-white px-3 ms-lg-3" href="/register">Sign Up</a>
            </li> -->
          <?php endif; ?>
        </ul>
      </div>
      <div class="theme-switcher dropdown d-none d-md-block">
        <a class="dropdown-toggle theme-toggle" aria-expanded="false" data-bs-toggle="dropdown" href="#">
          <i class="fa fa-adjust theme-icon"></i>
        </a>
        <div class="dropdown-menu dropdown-menu-end">
          <a class="dropdown-item d-flex align-items-center theme-switch-option" data-theme="light" href="#">
            <i class="fa fa-sun-o me-2"></i>Light
          </a>
          <a class="dropdown-item d-flex align-items-center theme-switch-option" data-theme="dark" href="#">
            <i class="fa fa-moon-o me-2"></i>Dark
          </a>
        </div>
      </div>

      <!-- Mobile Theme Toggle -->
      <div class="d-md-none ms-2">
        <button type="button" class="btn btn-sm theme-toggle-btn" id="mobileThemeToggle">
          <i class="fa fa-adjust"></i>
        </button>
      </div>
    </div>
  </nav>
<?php endif; ?>