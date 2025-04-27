<div class="card">
  <div class="card-header">
    <h1><?= $title ?></h1>
  </div>
  <div class="card-body">
    <form method="post" action="/dailyTask/<?= $dailyTasks['id']?>">
    <input type="hidden" name="_method" value="PUT">
      <div class="mb-3">
        <label for="name" class="form-label">Title</label>
        <input type="text" class="form-control" id="title" name="title" value="<?= $dailyTasks['title'] ?>"  required>
      </div>
      <div class="mb-3">
      <label for="name" class="form-label">Category</label>
      <input type="hidden" name="status" value="pending">
      <select name="category">
    <option value="Physical Health">Physical Health</option>
    <option value="Mental Wellness">Mental Wellness</option>
    <option value="Personal Growth">Personal Growth</option>
    <option value="Career / Studies">Career / Studies</option>
    <option value="Finance">Finance</option>
    <option value="Home Environment">Home & Environment</option>
    <option value="Relationships Social">Relationships & Social</option>
    <option value="Passion Hobbies">Passion & Hobbies</option>
      </select>
      <select name = "difficulty">
        <option value="easy" selected >Easy</option>
        <option value="medium">Medium</option>
        <option value="hard">Hard</option>
      </select>
      </div>
      <button type="submit" class="btn btn-primary">update Task</button>
    </form>
  </div>
</div>