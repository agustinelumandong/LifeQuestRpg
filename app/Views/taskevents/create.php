<div class="card">
  <div class="card-header">
    <h1><?= $title ?></h1>
  </div>
  <div class="card-body">
    <form method="post" action="/taskevents" enctype="multipart/form-data">
      <div class="mb-3">
        <label for="eventTitle" class="form-label">Event Title</label>
        <input type="text" class="form-control" id="eventTitle" name="eventTitle" required>
      </div>
      <div class="mb-3">
        <label for="eventDescription" class="form-label">Event Description</label>
        <input type="text" class="form-control" id="eventDescription" name="eventDescription" required>
      </div>
      <div class="mb-3">
        <label for="startDate" class="form-label">Start Date</label>
        <input type="date" class="form-control" id="startDate" name="startDate" required>
      </div>
      <div class="mb-3">
        <label for="endDate" class="form-label">End Date</label>
        <input type="date" class="form-control" id="endDate" name="endDate" required>
      </div>
      <div class="mb-3">
        <label for="rewardXp" class="form-label">Reward Xp</label>
        <input type="number" class="form-control" id="rewardXp" name="rewardXp" required>
      </div>
      <div class="mb-3">
        <label for="rewardCoins" class="form-label">Reward Coins</label>
        <input type="number" class="form-control" id="rewardCoins" name="rewardCoins" required>
      </div>

      <button type="submit" class="btn btn-primary">Create Event</button>
      <a href="/taskevents" class="btn btn-secondary">Cancel</a>
    </form>
  </div>
</div>