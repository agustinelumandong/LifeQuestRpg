<div class="container py-4">
  <!-- HEADER SECTION -->
  <div class="card border-dark mb-4 shadow">
    <div class="card-header bg-white d-flex justify-content-between align-items-center">
      <h2 class="my-2"><i class="bi bi-journal-plus"></i> New Journal Entry</h2>
      <a href="/journal" class="btn btn-outline-dark">
        <i class="bi bi-arrow-left"></i> Back to Journal
      </a>
    </div>
  </div>

  <!-- CREATE FORM SECTION -->
  <div class="card border-dark mb-4 shadow">
    <div class="card-header bg-white d-flex justify-content-between align-items-center">
      <div>
        <h3 class="my-2" style="font-family: 'Pixelify Sans', serif;">
          <i class="bi bi-pen"></i> Write Your Journal
        </h3>

      </div>

      <div class="text-muted" style="font-size: 0.9rem;">
        <span><i class="bi bi-calendar"></i></span>
        <?= date('Y-m-d') ?>
      </div>

    </div>

    <div class="card-body">
      <form action="/journal" method="post">

        <div class="mb-3">
          <label for="title" class="form-label">Title</label>
          <div class="input-group">
            <span class="input-group-text border-dark bg-white"><i class="bi bi-type-h1"></i></span>
            <input type="text" class="form-control border-dark" id="title" name="title"
              placeholder="Title of your journal entry" required>
          </div>
        </div>

        <div class="mb-4">
          <label for="editor-container" class="form-label">Journal Entry</label>
          <div id="editor-container" style="height: 300px; border: 1px solid #212529; border-radius: 4px;"></div>
          <input type="hidden" id="content-input" name="content">
        </div>

        <div class="d-flex justify-content-between">
          <div>
            <button type="submit" class="btn btn-dark">
              <i class="bi bi-save"></i> Save Entry
            </button>
            <a href="/journal" class="btn btn-outline-dark ms-2">Cancel</a>
          </div>
          <div class="d-flex align-items-center">
            <span class="badge bg-dark me-2">
              <i class="bi bi-stars"></i> +15 XP
            </span>
            <span class="text-muted">Earn XP by writing journal entries!</span>
          </div>
        </div>
      </form>
    </div>
  </div>

  <!-- WRITING TIPS SECTION -->
  <div class="card border-dark shadow">
    <div class="card-header bg-white">
      <h3 class="my-2" style="font-family: 'Pixelify Sans', serif;">
        <i class="bi bi-lightbulb"></i> Journal Writing Tips
      </h3>
    </div>
    <div class="card-body">
      <div class="row">
        <div class="col-md-4 mb-3">
          <div class="tip-box border border-dark rounded p-3">
            <h5 style="font-family: 'Pixelify Sans', serif;">Be Honest</h5>
            <p class="small">Your journal is private. Be truthful about your feelings and experiences.</p>
          </div>
        </div>
        <div class="col-md-4 mb-3">
          <div class="tip-box border border-dark rounded p-3">
            <h5 style="font-family: 'Pixelify Sans', serif;">Be Regular</h5>
            <p class="small">Try to write regularly to build the habit and earn more XP!</p>
          </div>
        </div>
        <div class="col-md-4 mb-3">
          <div class="tip-box border border-dark rounded p-3">
            <h5 style="font-family: 'Pixelify Sans', serif;">Be Reflective</h5>
            <p class="small">Don't just record events, reflect on how they affected you.</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>

<!-- Include Quill library -->
<link href="https://cdn.quilljs.com/1.3.6/quill.snow.css" rel="stylesheet">
<script src="https://cdn.quilljs.com/1.3.6/quill.min.js"></script>

<script>
  document.addEventListener('DOMContentLoaded', function () {
    var quill = new Quill('#editor-container', {
      theme: 'snow',
      modules: {
        toolbar: [
          ['bold', 'italic', 'underline', 'strike'],
          ['blockquote', 'code-block'],
          [{ 'header': 1 }, { 'header': 2 }],
          [{ 'list': 'ordered' }, { 'list': 'bullet' }],
          [{ 'indent': '-1' }, { 'indent': '+1' }],
          [{ 'size': ['small', false, 'large', 'huge'] }],
          [{ 'color': [] }, { 'background': [] }],
          ['link', 'image'],
          ['clean']
        ]
      },
      placeholder: 'Write your journal entry...'
    });

    // Set initial content from the hidden input
    if (document.getElementById('content-input').value) {
      quill.clipboard.dangerouslyPasteHTML(document.getElementById('content-input').value);
    }

    // Update hidden input before form submission
    document.querySelector('form').addEventListener('submit', function () {
      document.getElementById('content-input').value = quill.root.innerHTML;
    });

    // Add mood icons to the dropdown
    const moodSelect = document.getElementById('mood');
    Array.from(moodSelect.options).forEach(option => {
      if (option.value) {
        const text = option.textContent;
        option.textContent = getMoodIcon(option.value) + ' ' + text.trim();
      }
    });
  });
</script>

<style>
  .tip-box {
    transition: transform 0.2s;
    height: 100%;
  }

  .tip-box:hover {
    transform: translateY(-3px);
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
  }

  .ql-container {
    font-family: inherit !important;
    font-size: 1rem !important;
  }

  .ql-editor {
    min-height: 250px;
  }
</style>