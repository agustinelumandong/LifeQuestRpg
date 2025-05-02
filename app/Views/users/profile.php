<!-- <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet"> -->
<!-- <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.3/font/bootstrap-icons.css"> -->
<link rel="stylesheet" href="<?= \App\Core\Helpers::asset('css/profile.css') ?>">

<!-- Main Content -->
<main>
  <div class="container">
    <div class="d-flex justify-content-between align-items-center mb-4">
      <a href="/" class="back-button">
        <i class="bi bi-arrow-left"></i>
        Back to Dashboard
      </a>
      <button type="button" class="edit-profile-btn" data-bs-toggle="modal" data-bs-target="#editProfileModal">
        <i class="bi bi-pencil-square"></i>
        Edit Profile
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
                <p class="mb-0 fw-bold">HeyAlbert • Level 1 • 100 Coins</p>
              </div>

              <!-- Health Bar -->
              <div class="stat-box">
                <div class="d-flex justify-content-between align-items-center mb-1">
                  <span><i class="bi bi-heart-fill"></i> Health</span>
                  <span class="badge bg-dark">80/100</span>
                </div>
                <div class="progress">
                  <div class="progress-bar bg-dark" role="progressbar" style="width: 80%" aria-valuenow="80"
                    aria-valuemin="0" aria-valuemax="100"></div>
                </div>
              </div>
              <!-- Goal Completion -->
              <div class="stat-box">
                <div class="d-flex justify-content-between align-items-center mb-1">
                  <span style="font-family: 'Pixelify Sans', serif;"><i class="bi bi-flag-fill"></i> Goal
                    Completion</span>
                  <span class="badge bg-dark">10%</span>
                </div>
                <div class="progress">
                  <div class="progress-bar bg-dark" role="progressbar" style="width: 10%" aria-valuenow="10"
                    aria-valuemin="0" aria-valuemax="100"></div>
                </div>
              </div>

              <!-- Level Progress -->
              <div class="stat-box">
                <div class="d-flex justify-content-between align-items-center mb-1">
                  <span style="font-family: 'Pixelify Sans', serif;"><i class="bi bi-arrow-up-circle"></i>
                    Level UP</span>
                  <span class="badge bg-dark">10/100</span>
                </div>
                <div class="progress">
                  <div class="progress-bar bg-dark" role="progressbar" style="width: 10%" aria-valuenow="10"
                    aria-valuemin="0" aria-valuemax="100"></div>
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
            <div class="alert alert-info">No skills found! Complete quests to earn skill points.</div>
          <?php endif; ?>
        </div>
      </div>
    </div>
  </div>
</main>


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

  const skillsChart = new Chart(ctx, {
    type: 'radar',
    data: {
      labels: skillLabels,
      datasets: [{
        label: 'Skills',
        data: skillValues,
        backgroundColor: 'rgba(33, 37, 41, 0.2)',
        borderColor: '#212529',
        pointBackgroundColor: '#212529',
        pointBorderColor: '#fff',
        pointHoverBackgroundColor: '#fff',
        pointHoverBorderColor: '#212529'
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      elements: {
        line: {
          borderWidth: 3
        }
      },
      scales: {
        r: {
          angleLines: {
            display: true
          },
          suggestedMin: 0,
          suggestedMax: 3,
          ticks: {
            stepSize: 0.5,
            font: {
              size: 12
            }
          },
          pointLabels: {
            font: {
              size: 14,
              weight: 'bold'
            }
          }
        }
      },
      plugins: {
        legend: {
          display: false
        }
      },
      animation: {
        duration: 1500
      }
    }
  });

  // Add animations for progress bars
  document.addEventListener('DOMContentLoaded', function () {
    const progressBars = document.querySelectorAll('.progress-bar');
    progressBars.forEach(bar => {
      // Save the target width
      const targetWidth = bar.style.width;
      // Reset width to 0
      bar.style.width = '0%';

      // Animate to target width after a delay
      setTimeout(() => {
        bar.style.width = targetWidth;
      }, 300);
    });
  });
</script>