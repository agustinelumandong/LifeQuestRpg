<div class="card">
  <div class="card-header">
    <h1><?= $title ?></h1>
  </div>
  <div class="card-body">
    <form method="POST" action="/taskevents/<?= $taskEvent['id'] ?>" enctype="multipart/form-data">
      <input type="hidden" name="_method" value="PUT" />
      <div class="mb-3">
        <label for="eventName" class="form-label">Event Title</label>
        <input type="text" class="form-control" id="eventName" name="eventName" value="<?= $taskEvent['event_name'] ?>"
          required>
      </div>
      <div class="mb-3">
        <label for="eventDescription" class="form-label">Event Description</label>
        <input type="text" class="form-control" id="eventDescription" name="eventDescription"
          value="<?= $taskEvent['event_description'] ?>">
      </div>
      <div class="mb-3">
        <label for="startDate" class="form-label">Start Date</label>
        <input type="date" class="form-control" id="startDate" name="startDate"
          value="<?= date('Y-m-d', strtotime($taskEvent['start_date'])) ?>" required>
      </div>
      <div class="mb-3">
        <label for="endDate" class="form-label">End Date</label>
        <input type="date" class="form-control" id="endDate" name="endDate"
          value="<?= date('Y-m-d', strtotime($taskEvent['end_date'])) ?>" required>
      </div>
      <div class="mb-3">
        <label for="rewardXp" class="form-label">Reward Xp</label>
        <input type="number" class="form-control" id="rewardXp" name="rewardXp" value="<?= $taskEvent['reward_xp'] ?>"
          required>
      </div>
      <div class="mb-3">
        <label for="rewardCoins" class="form-label">Reward Coins</label>
        <input type="number" class="form-control" id="rewardCoins" name="rewardCoins"
          value="<?= $taskEvent['reward_coins'] ?>" required>
      </div>

      <div class="mb-3 d-flex flex-row">
        <label class="form-label mx-2">Status</label>
        <div class="form-check mx-2">
          <input class="form-check-input" type="radio" name="status" id="statusActive" value="1"
            <?= $taskEvent['status'] == 'active' ? 'checked' : '' ?> required>
          <label class="form-check-label" for="status">Active</label>
        </div>
        <div class="form-check mx-2">
          <input class="form-check-input" type="radio" name="status" id="statusInactive" value="0"
            <?= $taskEvent['status'] == 'inactive' ? 'checked' : '' ?>>
          <label class="form-check-label" for="status">Inactive</label>
        </div>
      </div>
      <button type="submit" class="btn btn-primary">Update Event</button>
      <a href="/taskevents" class="btn btn-secondary">Cancel</a>
    </form>
  </div>
</div>