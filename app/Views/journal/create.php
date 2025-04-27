<div class="container py-4">
    <div class="mb-4">
        <a href="/journal/index" class="btn btn-outline-secondary">
            <i class="fas fa-arrow-left"></i> Back to Journal
        </a>
    </div>

    <h1 class="mb-4">New Journal Entry</h1>
    
    <form action="/journal" method="post">
        <div class="mb-3">
            <label for="date" class="form-label">Date</label>
            <input type="date" class="form-control" id="date" name="date" value="<?= $today ?>" required>
        </div>
        
        <div class="mb-3">
            <label for="title" class="form-label">Title</label>
            <input type="text" class="form-control" id="title" name="title" placeholder="Title of your journal entry" required>
        </div>
        
           <div class="mb-4">
    <label for="editor-container" class="form-label">Journal Entry</label>
    

    <div id="editor-container" style="height: 300px; border: 1px solid #ccc; border-radius: 4px;"></div>
    

    <input type="hidden" id="content-input" name="content">

    <script>
    document.addEventListener('DOMContentLoaded', function() {
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
        document.querySelector('form').addEventListener('submit', function() {
            document.getElementById('content-input').value = quill.root.innerHTML;
        });
    });
</script>

</div>
        
        <div class="mb-3">
            <button type="submit" class="btn btn-primary">Save Entry</button>
            <a href="/journal/index" class="btn btn-outline-secondary ms-2">Cancel</a>
        </div>
    </form>
</div>