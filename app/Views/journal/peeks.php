<div class="container py-4">
  <!-- HEADER SECTION -->
  <div class="card border-dark mb-4 shadow">
    <div class="card-header bg-white d-flex justify-content-between align-items-center">
      <h2 class="my-2"><i class="bi bi-journal-richtext"></i> Journal Entry</h2>
      <a href="/journal" class="btn btn-outline-dark">
        <i class="bi bi-arrow-left"></i> Back to Journal
      </a>
    </div>
  </div>

  <!-- JOURNAL ENTRY SECTION -->
  <div class="card border-dark mb-4 shadow">
    <div class="card-header bg-white d-flex justify-content-between align-items-center">
      <h3 class="my-2" style="font-family: 'Pixelify Sans', serif;">
        <?= htmlspecialchars($journal['title']) ?>

      </h3>
      <div class="journal-actions">
        <a href="/journal/<?= $journal['id'] ?>/edit" class="btn btn-outline-dark me-2">
          <i class="bi bi-pencil"></i> Edit
        </a>
        <form action="/journal/<?= $journal['id'] ?>/delete" method="post" class="d-inline">
          <input type="hidden" name="_method" value="DELETE">
          <button type="submit" class="btn btn-outline-danger"
            onclick="return confirm('Are you sure you want to delete this journal entry?')">
            <i class="bi bi-trash"></i> Delete
          </button>
        </form>
      </div>
    </div>

    <div class="card-body">
      <div class="d-flex align-items-center mb-4">
        <div class="journal-date px-3 py-2 bg-light rounded border border-dark">
          <i class="bi bi-calendar-date"></i> <?= date('F j, Y', strtotime($journal['date'])) ?>
        </div>
        <div class="ms-auto">
          <span class="badge bg-dark">
            <i class="bi bi-stars"></i> +15 XP
          </span>
        </div>
      </div>

      <div class="journal-content mt-4">
        <?= html_entity_decode($journal['content']) ?>
      </div>
    </div>

    <div class="card-footer bg-white text-center border-top border-dark">
      <div class="small text-muted">Written on: <?= date('F j, Y \a\t g:i a', strtotime($journal['date'])) ?></div>
    </div>
  </div>

</div>

<style>
  .mood-badge-lg {
    font-size: 1.2rem;
    width: 30px;
    height: 30px;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    border-radius: 50%;
    vertical-align: middle;
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

  .journal-content {
    line-height: 1.8;
    font-size: 1.1rem;
    white-space: pre-line;
  }

  .journal-date {
    font-family: 'Pixelify Sans', serif;
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