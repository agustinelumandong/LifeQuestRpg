<!-- Create Good Habit Modal -->
<div class="modal fade" id="createTaskModal" tabindex="-1" aria-labelledby="createTaskModalLabel" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="createTaskModalLabel">Create New Good Habit</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        <form method="post" action="/goodhabit" id="createTaskForm">
          <div class="mb-3">
            <label for="title" class="form-label fw-bold">Habit Name</label>
            <input type="text" class="form-control" id="title" name="title" required
              placeholder="e.g. Daily Meditation">
          </div>

          <div class="row mb-3">
            <div class="col-md-6">
              <label for="difficulty" class="form-label fw-bold">Difficulty</label>
              <select class="form-select" id="difficulty" name="difficulty" required>
                <option value="">Select difficulty...</option>
                <option value="easy">Easy (5 XP, 5 Coins)</option>
                <option value="medium">Medium (10 XP, 10 Coins)</option>
                <option value="hard">Hard (15 XP, 15 Coins)</option>
              </select>
            </div>
            <div class="col-md-6">
              <label for="category" class="form-label fw-bold">Category</label>
              <select class="form-select" id="category" name="category" required>
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

          <input type="hidden" name="status" value="pending">
        </form>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-outline-dark" data-bs-dismiss="modal">Cancel</button>
        <button type="submit" form="createTaskForm" class="btn btn-dark">Create Habit</button>
      </div>
    </div>
  </div>
</div>