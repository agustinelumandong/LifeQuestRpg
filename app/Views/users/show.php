<!-- // app/Views/users/show.php -->
<link rel="stylesheet" href="<?= \App\Core\Helpers::asset('css/profile.css') ?>">

<!-- Main Content -->
<main>
  <div class="container">
    <div class="d-flex justify-content-between align-items-center mb-4">
      <a href="/leaderboard" class="back-button">
        <i class="bi bi-arrow-left"></i>
        Back to Leaderboard
      </a>
      <button type="button" class="btn btn-primary poke-button" onclick="pokeUser(<?= $user['id'] ?>)">
        <i class="bi bi-hand-index-thumb"></i>
        Poke <?= htmlspecialchars($user['username']) ?>
      </button>
    </div>

    <div class="card">
      <div class="card-header">
        <h2 class="mb-0"><i class="bi bi-person-badge"></i> Character Profile</h2>
      </div>
      <div class="card-body">
        <div class="row">
          <div class="col-md-4">
            <div class="character-profile d-flex flex-column align-items-center">
              <img
                src="https://cdn11.bigcommerce.com/s-7va6f0fjxr/images/stencil/1280x1280/products/59261/75500/Details-About-Truck-Car-Video-Games-Super-Mario-1Up-Toadstool-Mushroom-Decal__81968.1506656287.jpg?c=2"
                alt="Character avatar" class="character-avatar" id="character-avatar">

              <div class="character-info">
                <p class="mb-0 fw-bold"><?= $user['username'] ?> • Level <?= $userStats['level'] ?> •
                  <?= $user['coins'] ?? 0 ?>
                  Coins
                </p>
              </div>

              <!-- Health Bar -->
              <div class="stat-box">
                <div class="d-flex justify-content-between align-items-center mb-1">
                  <span><i class="bi bi-heart-fill"></i> Health</span>
                  <span class="badge bg-dark"><?= $userStats['health'] ?>/100</span>
                </div>
                <div class="progress">
                  <div class="progress-bar bg-dark" role="progressbar" style="width: <?= $userStats['health'] ?>%"
                    aria-valuenow="<?= $userStats['health'] ?>" aria-valuemin="0" aria-valuemax="100"></div>
                </div>
              </div>

              <!-- Level Progress -->
              <div class="stat-box">
                <div class="d-flex justify-content-between align-items-center mb-1">
                  <span style="font-family: 'Pixelify Sans', serif;"><i class="bi bi-arrow-up-circle"></i>
                    Level UP</span>
                  <span class="badge bg-dark"><?= $userStats['xp'] ?>/100</span>
                </div>
                <div class="progress">
                  <div class="progress-bar bg-dark" role="progressbar" style="width: <?= $userStats['xp'] ?>%"
                    aria-valuenow="<?= $userStats['xp'] ?>" aria-valuemin="0" aria-valuemax="100"></div>
                </div>
              </div>

              <!-- Badges section -->
              <div class="stat-box mt-2">
                <h5 class="section-title"><i class="bi bi-award"></i> Achievements</h5>
                <div class="badge-container">
                  <div class="badge-item">
                    <div class="badge-icon"><i class="bi bi-trophy-fill text-warning"></i></div>
                    <div class="badge-name">First Quest</div>
                  </div>
                  <div class="badge-item">
                    <div class="badge-icon"><i class="bi bi-star-fill text-warning"></i></div>
                    <div class="badge-name">10 Goals</div>
                  </div>
                  <div class="badge-item">
                    <div class="badge-icon"><i class="bi bi-lightning-fill text-primary"></i></div>
                    <div class="badge-name">Speed Run</div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div class="col-md-8">
            <div class="chart-container">
              <div class="chart-wrapper">
                <canvas id="skillsChart"></canvas>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="card">
      <div class="card-header">
        <h2 class="mb-0"><i class="bi bi-tools"></i> Skill Points</h2>
      </div>
      <div class="card-body">
        <div class="skill-list">
          <?php if (!empty($skills)): ?>
            <?php foreach ($skills as $index => $skill): ?>
              <div class="skill-item animate__animated animate__fadeInUp"
                style="animation-delay: <?= 0.1 + ($index * 0.1) ?>s">
                <div class="skill-header">
                  <div class="skill-name">
                    <i class="bi <?= $skill['icon'] ?> skill-icon"></i>
                    <?= htmlspecialchars($skill['name']) ?>
                  </div>
                  <div class="skill-level">• LV <?= $skill['level'] ?></div>
                </div>
                <div class="skill-progress-container">
                  <div class="skill-progress">
                    <div class="skill-progress-fill" style="width: <?= ($skill['current'] / $skill['max']) * 100 ?>%;">
                    </div>
                  </div>
                  <div class="skill-value"><?= $skill['current'] ?> / <?= $skill['max'] ?></div>
                </div>
              </div>
            <?php endforeach; ?>
          <?php else: ?>
            <div class="alert alert-info">No skills found!</div>
          <?php endif; ?>
        </div>
      </div>
    </div>
  </div>
</main>

<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

<script>
  // Radar Chart
  const ctx = document.getElementById('skillsChart').getContext('2d');

  // Make the chart responsive
  function resizeChart() {
    const containerWidth = document.querySelector('.chart-container').clientWidth;
    const containerHeight = document.querySelector('.chart-container').clientHeight;

    // Set canvas dimensions to match container
    const canvas = document.getElementById('skillsChart');
    canvas.style.width = '100%';
    canvas.style.height = '100%';
    canvas.width = containerWidth;
    canvas.height = containerHeight;
  }

  // Call resize on load and window resize
  window.addEventListener('load', resizeChart);
  window.addEventListener('resize', resizeChart);

  // Define skill data from PHP variables
  const skillLabels = <?= json_encode(array_column($skills ?? [], 'name')) ?>;
  const skillValues = <?= json_encode(array_column($skills ?? [], 'chart_value')) ?>;

  // Create the radar chart with custom styling
  const skillsChart = new Chart(ctx, {
    type: 'radar',
    data: {
      labels: skillLabels,
      datasets: [{
        label: 'Skills',
        data: skillValues,
        backgroundColor: 'rgba(33, 37, 41, 0.3)',
        borderColor: '#212529',
        borderWidth: 2,
        pointBackgroundColor: '#212529',
        pointBorderColor: '#fff',
        pointHoverBackgroundColor: '#fff',
        pointHoverBorderColor: '#212529',
        pointRadius: 4,
        pointHoverRadius: 6
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      elements: {
        line: {
          borderWidth: 2,
          tension: 0.1
        }
      },
      scales: {
        r: {
          backgroundColor: 'rgba(255, 255, 255, 0.8)',
          angleLines: {
            display: true,
            color: 'rgba(33, 37, 41, 0.2)'
          },
          grid: {
            color: 'rgba(33, 37, 41, 0.1)'
          },
          suggestedMin: 0,
          suggestedMax: 3,
          ticks: {
            stepSize: 1,
            backdropColor: 'transparent',
            font: {
              size: 10,
              family: "'Pixelify Sans', serif"
            },
            color: '#6b7280'
          },
          pointLabels: {
            font: {
              size: 13,
              weight: 'bold',
              family: "'Pixelify Sans', serif"
            },
            color: '#212529',
            padding: 10
          }
        }
      },
      plugins: {
        legend: {
          display: false
        },
        tooltip: {
          backgroundColor: 'rgba(33, 37, 41, 0.8)',
          titleFont: {
            family: "'Pixelify Sans', serif",
            size: 14
          },
          bodyFont: {
            family: "'Pixelify Sans', serif",
            size: 12
          },
          padding: 10,
          cornerRadius: 8,
          displayColors: false,
          callbacks: {
            label: function (context) {
              const label = context.dataset.label || '';
              const value = context.raw || 0;
              const levelValue = value * 33;
              const level = Math.floor(levelValue / 20) + 1;
              return `Level ${level} (${Math.round(levelValue)} points)`;
            }
          }
        }
      },
      animation: {
        duration: 1800,
        easing: 'easeOutQuart'
      }
    }
  });

  // Add animations for progress bars
  document.addEventListener('DOMContentLoaded', function () {
    const progressBars = document.querySelectorAll('.progress-bar');
    progressBars.forEach(bar => {
      const targetWidth = bar.style.width;
      bar.style.width = '0%';
      setTimeout(() => {
        bar.style.width = targetWidth;
      }, 300);
    });
  });

  function pokeUser(userId) {
    fetch(`/users/${userId}/poke`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      }
    })
      .then(response => response.json())
      .then(data => {
        // Add a fun animation to the button
        const button = document.querySelector('.poke-button');
        button.classList.add('poked');
        setTimeout(() => {
          button.classList.remove('poked');
        }, 1000);

        // Disable the button temporarily to prevent spam
        if (data.success) {
          button.disabled = true;
          setTimeout(() => {
            button.disabled = false;
          }, 5000); // Re-enable after 5 seconds
        }
      })
      .catch(error => {
        console.error('Error:', error);
      });
  }
</script>

<link rel="stylesheet" href="<?= app\core\helpers::asset('css/showProfile.css') ?>" />