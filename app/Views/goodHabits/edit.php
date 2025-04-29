<!-- Edit Task Modal -->
<div class="modal fade" id="editTaskModal" tabindex="-1" aria-labelledby="editTaskModalLabel" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="editTaskModalLabel">Edit Bad Habits</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        <form method="post" id="editTaskForm">
          <input type="hidden" name="_method" value="PUT">
          <input type="hidden" id="edit-task-id" name="task_id">
          
          <div class="mb-3">
            <label for="edit-title" class="form-label">Title</label>
            <input type="text" class="form-control" id="edit-title" name="title" required>
          </div>
          
          <div class="mb-3">
            <label for="edit-category" class="form-label">Category</label>
            <select name="category" id="edit-category" class="form-select">
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
            <label for="edit-difficulty" class="form-label">Difficulty</label>
            <select name="difficulty" id="edit-difficulty" class="form-select">
              <option value="easy">Easy</option>
              <option value="medium">Medium</option>
              <option value="hard">Hard</option>
            </select>
          </div>
          <input type="hidden" name="status" value="pending">
        </form>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
        <button type="submit" form="editTaskForm" class="btn btn-primary">Update Bad Habits</button>
      </div>
    </div>
  </div>
</div>
