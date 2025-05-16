<div class="container py-4">
  <!-- HEADER SECTION -->
  <div class="card border-dark mb-4 shadow">
    <div class="card-header bg-white d-flex justify-content-between align-items-center">
      <h2 class="my-2"><i class="bi bi-pencil-square"></i> Edit Journal Entry</h2>
      <a href="/journal/<?= $journal['id'] ?>/peek" class="btn btn-outline-dark">
        <i class="bi bi-arrow-left"></i> Back to Entry
      </a>
    </div>
  </div>

  <!-- EDIT FORM SECTION -->
  <div class="card border-dark mb-4 shadow">
    <div class="card-header bg-white">
      <h3 class="my-2" style="font-family: 'Pixelify Sans', serif;">
        <i class="bi bi-pencil"></i> Update Your Journal
      </h3>
    </div>

    <div class="card-body">
      <form action="/journal/<?= $journal['id'] ?>/update" method="post">
        <input type="hidden" name="_method" value="PUT">

        <div class="row mb-3">
          <div class="col-md-6">
            <label for="date" class="form-label">Date</label>
            <div class="input-group">
              <span class="input-group-text border-dark bg-white"><i class="bi bi-calendar"></i></span>
              <input type="date" class="form-control border-dark" id="date" name="date"
                value="<?= htmlspecialchars($journal['date']) ?>" required>
            </div>
          </div>

          <div class="col-md-6">
            <label for="mood" class="form-label">Mood</label>
            <select class="form-select border-dark" id="mood" name="mood">
              <option value="">Select mood (optional)</option>
              <option value="happy" <?= $journal['mood'] === 'happy' ? 'selected' : '' ?>>
                <i class="bi bi-emoji-smile"></i> Happy
              </option>
              <option value="excited" <?= $journal['mood'] === 'excited' ? 'selected' : '' ?>>
                <i class="bi bi-emoji-laughing"></i> Excited
              </option>
              <option value="neutral" <?= $journal['mood'] === 'neutral' ? 'selected' : '' ?>>
                <i class="bi bi-emoji-neutral"></i> Neutral
              </option>
              <option value="sad" <?= $journal['mood'] === 'sad' ? 'selected' : '' ?>>
                <i class="bi bi-emoji-frown"></i> Sad
              </option>
            </select>
          </div>
        </div>

        <div class="mb-3">
          <label for="title" class="form-label">Title</label>
          <div class="input-group">
            <span class="input-group-text border-dark bg-white"><i class="bi bi-type-h1"></i></span>
            <input type="text" class="form-control border-dark" id="title" name="title"
              value="<?= htmlspecialchars($journal['title']) ?>" placeholder="Title of your journal entry" required>
          </div>
        </div>

        <div class="mb-4">
          <label for="editor-container" class="form-label">Journal Entry</label>
          <div id="editor-container" style="height: 300px; border: 1px solid #212529; border-radius: 4px;"></div>
          <input type="hidden" id="content-input" name="content" value="<?= htmlspecialchars($journal['content']) ?>">
        </div>

        <div class="mb-3 d-flex justify-content-between">
          <div>
            <button type="submit" class="btn btn-dark">
              <i class="bi bi-save"></i> Save Changes
            </button>
            <a href="/journal/<?= $journal['id'] ?>/peek" class="btn btn-outline-dark ms-2">Cancel</a>
          </div>
          <form action="/journal/<?= $journal['id'] ?>/delete" method="post" class="d-inline">
            <input type="hidden" name="_method" value="DELETE">
            <button type="submit" class="btn btn-outline-danger"
              onclick="return confirm('Are you sure you want to delete this journal entry?')">
              <i class="bi bi-trash"></i> Delete Entry
            </button>
          </form>
        </div>
      </form>
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

  function getMoodIcon(mood) {
    switch (mood) {
      case 'happy': return '😊';
      case 'excited': return '😃';
      case 'neutral': return '😐';
      case 'sad': return '😔';
      default: return '';
    }
  }
</script>