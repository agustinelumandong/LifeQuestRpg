<div id="pagination-content">
  <a href="/" class="back-button">
    <i class="bi bi-arrow-left"></i>
    Back to Dashboard
  </a>

  <div class="container py-4">
    <!-- HEADER SECTION -->
    <div class="card border-dark mb-4 shadow">
      <div class="card-header bg-white">
        <h2 class="my-2"><i class="bi bi-journal-richtext"></i> <?= ucfirst($title) ?></h2>
      </div>
      <div class="card-body">
        <div class="row align-items-center">
          <div class="col-md-2 text-center mb-3 mb-md-0">
            <div class="rounded p-3 d-inline-block">
              <i class="bi bi-journals fs-1"></i>
            </div>
          </div>
          <div class="col-md-10">
            <p class="mb-0">Keep track of your thoughts, adventures, and daily quests here.</p>
            <div class="mt-2">
              <i class="bi bi-info-circle"></i> Writing regularly in your journal earns you XP and unlocks special
              achievements!
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- JOURNAL ENTRIES SECTION -->
    <div class="card border-dark mb-4 shadow">
      <!-- Journal Button To Create New Entry -->
      <div class="card-header bg-white d-flex justify-content-between align-items-center">
        <h3 class="my-2" style="font-family: 'Pixelify Sans', serif;"><i class="bi bi-book"></i> Your Journal Collection
        </h3>
        <a href="/journal/create" class="btn btn-dark">
          <i class="bi bi-plus-circle"></i> New Journal Entry
        </a>
      </div>

      <div class="card-body">
        <?php if (empty($journals)): ?>
          <div class="alert alert-dark text-center" role="alert">
            <i class="bi bi-journal-text display-4 d-block mb-3"></i>
            <p class="mb-0">Your journal shelf is empty! Begin your writing adventure by creating your first entry!</p>
          </div>
        <?php else: ?>
          <div class="row row-cols-1 row-cols-md-3 g-4">
            <?php foreach ($paginator->items() as $journal): ?>
              <div class="col">
                <div class="journal-card card h-100 border-dark shadow-sm clickable-card"
                  onclick="window.location.href='/journal/<?= $journal['id'] ?>/peek' ">
                  <div
                    class="card-header bg-white border-bottom border-dark d-flex justify-content-between align-items-center">
                    <h5 class="card-title mb-0" style="font-family: 'Pixelify Sans', serif;">
                      <?= htmlspecialchars($journal['title']) ?>
                    </h5>
                  </div>
                  <div class="card-body">
                    <h6 class="card-subtitle mb-3 text-muted">
                      <i class="bi bi-calendar-date"></i> <?= date('F j, Y', strtotime($journal['date'])) ?>
                    </h6>
                    <p class="card-text journal-preview">
                      <?php
                      $cleanContent = isset($journal['content']) ?
                        strip_tags(html_entity_decode($journal['content'])) : '';
                      echo mb_substr($cleanContent, 0, 100) .
                        (mb_strlen($cleanContent) > 100 ? '...' : '');
                      ?>
                    </p>
                  </div>
                  <div class="card-footer bg-white border-top border-dark text-center">
                    <div class="small text-muted mb-1">Click to view</div>
                    <div class="card-overlay">
                      <span><i class="bi bi-book-half"></i> Read Journal</span>
                    </div>
                  </div>
                </div>
              </div>
            <?php endforeach; ?>
          </div>
        <?php endif; ?>
        <?= $paginator->links() ?>

      </div>
    </div>

    <!-- Journal Stats Section -->
    <div class="card border-dark mt-4 shadow">
      <div class="card-header bg-white">
        <h3 class="my-2" style="font-family: 'Pixelify Sans', serif;">
          <i class="bi bi-graph-up"></i> Journal Stats
        </h3>
      </div>
      <div class="card-body">
        <div class="row">
          <div class="col-md-4 mb-3">
            <div class="stat-box border border-dark rounded p-3 text-center">
              <h5 style="font-family: 'Pixelify Sans', serif;">Total Entries</h5>
              <div class="stat-value"><?= count($journals) ?></div>
              <div class="progress mt-2">
                <div class="progress-bar bg-dark" role="progressbar"
                  style="width: <?= min(count($journals) * 10, 100) ?>%" aria-valuenow="<?= count($journals) ?>"
                  aria-valuemin="0" aria-valuemax="10"></div>
              </div>
              <small class="text-muted mt-1 d-block">Write more to level up!</small>
            </div>
          </div>
          <div class="col-md-4 mb-3">
            <div class="stat-box border border-dark rounded p-3 text-center">
              <h5 style="font-family: 'Pixelify Sans', serif;">XP Earned</h5>
              <div class="stat-value"><?= count($journals) * 15 ?> XP</div>
              <i class="bi bi-stars fs-3 text-warning"></i>
              <small class="text-muted mt-1 d-block">15 XP per journal entry</small>
            </div>
          </div>
          <div class="col-md-4 mb-3">
            <div class="stat-box border border-dark rounded p-3 text-center">
              <h5 style="font-family: 'Pixelify Sans', serif;">Writing Streak</h5>
              <div class="stat-value">3 Days</div>
              <i class="bi bi-fire fs-3 text-danger"></i>
              <small class="text-muted mt-1 d-block">Keep the streak going!</small>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>

<style>
  .journal-card {
    transition: transform 0.3s ease, box-shadow 0.3s ease;
    position: relative;
    cursor: pointer;
  }

  .journal-card:hover {
    transform: translateY(-5px);
    box-shadow: 0 10px 20px rgba(0, 0, 0, 0.1) !important;
  }

  .journal-card:hover::after {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background-color: rgba(0, 0, 0, 0.03);
    border-radius: inherit;
    pointer-events: none;
  }

  .journal-card .card-footer {
    transition: background-color 0.2s ease;
  }

  .journal-card:hover .card-footer {
    background-color: #f8f9fa !important;
  }

  .journal-preview {
    font-style: italic;
    max-height: 80px;
    overflow: hidden;
  }

  .mood-badge {
    font-size: 1.2rem;
    width: 30px;
    height: 30px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 50%;
  }

  .mood-happy {
    background-color: #e3f2fd;
    color: #0d6efd;
  }

  .mood-sad {
    background-color: #e8f4fd;
    color: #0dcaf0;
  }

  .mood-excited {
    background-color: #fff8e1;
    color: #ffc107;
  }

  .mood-neutral {
    background-color: #f5f5f5;
    color: #6c757d;
  }

  .stat-box {
    transition: transform 0.2s;
  }

  .stat-box:hover {
    transform: translateY(-3px);
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
  }

  .stat-value {
    font-size: 24px;
    font-weight: bold;
    font-family: 'Pixelify Sans', serif;
    margin: 10px 0;
  }

  .card-overlay {
    background-color: rgba(33, 37, 41, 0.05);
    border-radius: 4px;
    padding: 5px;
    font-family: 'Pixelify Sans', serif;
  }

  .journal-card:hover .card-overlay {
    background-color: rgba(33, 37, 41, 0.1);
  }
</style>

<script>
  // Initialize tooltips
  document.addEventListener('DOMContentLoaded', function () {
    var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
    var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
      return new bootstrap.Tooltip(tooltipTriggerEl)
    })
  });
</script>

<script>
  document.addEventListener('DOMContentLoaded', function () {
    const contentContainer = document.getElementById('pagination-content');

    // Handle pagination clicks
    contentContainer.addEventListener('click', function (e) {
      const link = e.target.closest('a');
      if (link && link.getAttribute('href').includes('page=')) {
        e.preventDefault();
        const url = link.getAttribute('href');

        // Show loading state
        contentContainer.style.opacity = '0.5';

        // Fetch the new page content
        fetch(url)
          .then(response => response.text())
          .then(html => {
            // Create a temporary element to parse the HTML
            const tempDiv = document.createElement('div');
            tempDiv.innerHTML = html;

            // Extract just the pagination content
            const newContent = tempDiv.querySelector('#pagination-content');

            if (newContent) {
              // Replace only the content inside the container
              contentContainer.innerHTML = newContent.innerHTML;
            } else {
              console.error('Could not find pagination content in response');
            }

            contentContainer.style.opacity = '1';

            // Update browser history
            window.history.pushState({}, '', url);
          })
          .catch(error => {
            console.error('Error:', error);
            contentContainer.style.opacity = '1';
          });
      }
    });

    // Handle browser back/forward buttons
    window.addEventListener('popstate', function () {
      fetch(window.location.href)
        .then(response => response.text())
        .then(html => {
          const tempDiv = document.createElement('div');
          tempDiv.innerHTML = html;

          const newContent = tempDiv.querySelector('#pagination-content');
          if (newContent) {
            contentContainer.innerHTML = newContent.innerHTML;
          }
        });
    });
  });
</script>