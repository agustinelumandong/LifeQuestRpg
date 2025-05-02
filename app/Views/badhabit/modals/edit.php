<!-- Edit Bad Habit Modal -->
<div class="modal fade" id="editTaskModal" tabindex="-1" aria-labelledby="editTaskModalLabel" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="editTaskModalLabel">Edit Bad Habit</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        <form method="post" id="editTaskForm">
          <input type="hidden" name="_method" value="PUT">

          <div class="mb-3">
            <label for="edit-title" class="form-label fw-bold">Habit Name</label>
            <input type="text" class="form-control" id="edit-title" name="title" required>
          </div>

          <div class="row mb-3">
            <div class="col-md-6">
              <label for="edit-difficulty" class="form-label fw-bold">Difficulty (HP Loss)</label>
              <select class="form-select" id="edit-difficulty" name="difficulty" required>
                <option value="">Select difficulty...</option>
                <option value="easy">Easy (-5 HP)</option>
                <option value="medium">Medium (-10 HP)</option>
                <option value="hard">Hard (-15 HP)</option>
              </select>
            </div>
            <div class="col-md-6">
              <label for="edit-category" class="form-label fw-bold">Category</label>
              <select class="form-select" id="edit-category" name="category" required>
                <option value="">Select category...</option>
                <option value="Physical Health">Physical Health</option>
                <option value="Mental Wellness">Mental Wellness</option>
                <option value="Personal Growth">Personal Growth</option>
                <option value="Career / Studies">Career / Studies</option>
                <option value="Finance">Finance</option>
                <option value="Home Environment">Home Environment</option>
                <option value="Relationships Social">Relationships Social</option>
                <option value="Passion Hobbies">Passion Hobbies</option>
              </select>
            </div>
          </div>

          <input type="hidden" name="status" id="edit-status" value="">
          <input type="hidden" name="coins" value="0">
          <input type="hidden" name="xp" value="0">
        </form>
      </div>
      <div class="modal-footer d-flex justify-content-between">
        <button type="button" class="btn btn-danger delete-habit-btn" data-bs-toggle="modal"
          data-bs-target="#deleteConfirmModal">
          <i class="bi bi-trash"></i> Delete
        </button>
        <div>
          <button type="button" class="btn btn-outline-dark" data-bs-dismiss="modal">Cancel</button>
          <button type="submit" form="editTaskForm" class="btn btn-dark">Update Habit</button>
        </div>
      </div>
    </div>
  </div>
</div>

<!-- Delete Confirmation Modal -->
<div class="modal fade" id="deleteConfirmModal" tabindex="-1" aria-labelledby="deleteConfirmModalLabel"
  aria-hidden="true">
  <div class="modal-dialog modal-sm">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="deleteConfirmModalLabel">Confirm Delete</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        Are you sure you want to delete this habit?
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-outline-dark" data-bs-dismiss="modal">Cancel</button>
        <form method="post" id="deleteHabitForm">
          <input type="hidden" name="_method" value="DELETE">
          <button type="submit" class="btn btn-danger">Delete</button>
        </form>
      </div>
    </div>
  </div>
</div>