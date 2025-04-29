<!-- //Create Task Modal -->
<div class="modal fade" id="createTaskModal" tabindex="-1" aria-labelledby="createTaskModalLabel" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="createTaskModalLabel">Create New Task</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        <form method="post" action="/tasks" id="createTaskForm">
          <div class="mb-3">
            <label for="title" class="form-label">Title</label>
            <input type="text" class="form-control" id="title" name="title" required>
          </div>
          <div class="mb-3">
            <label for="category" class="form-label">Category</label>
            <input type="hidden" name="status" value="pending">
            <select name="category" class="form-select">
              <option value="Physical Health">Physical Health</option>
              <option value="Mental Wellness">Mental Wellness</option>
              <option value="Personal Growth">Personal Growth</option>
              <option value="Career / Studies">Career / Studies</option>
              <option value="Finance">Finance</option>
              <option value="Home Environment">Home & Environment</option>
              <option value="Relationships Social">Relationships & Social</option>
              <option value="Passion Hobbies">Passion & Hobbies</option>
            </select>
          </div>
          <div class="mb-3">
            <label for="difficulty" class="form-label">Difficulty</label>
            <select name="difficulty" class="form-select">
              <option value="easy" selected>Easy</option>
              <option value="medium">Medium</option>
              <option value="hard">Hard</option>
            </select>
          </div>
        </form>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
        <button type="submit" form="createTaskForm" class="btn btn-primary">Create Task</button>
      </div>
    </div>
  </div>
</div>