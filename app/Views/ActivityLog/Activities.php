<h1>Activity Log</h1>

<?php foreach ($activities as $activity): ?>
    <div class="activity-entry">
        <br>
        <?= date('M d, Y g:i A', strtotime($activity['log_timestamp'])) ?> <br>
        
        <?php if (isset($activity['coins']) && $activity['xp'] == 0): ?>
            You lost <strong><span class="text-danger"> 10 Health</span></strong>
            for commiting <strong><?= htmlspecialchars($activity['task_title']) ?></strong><br>
        <?php else: ?>      
            You gained <strong><span><?= htmlspecialchars($activity['xp']) ?> XP</span></strong> 
            and <strong><span><?= htmlspecialchars($activity['coins']) ?> coins</span></strong>
            in <strong><?= htmlspecialchars($activity['task_title']) ?></strong><br>
        <?php endif; ?>
        
        <?= htmlspecialchars(ucfirst($activity['difficulty'] ?? 'No Difficulty')) ?>      
        <?= htmlspecialchars($activity['category'] ?? 'No Category') ?>   
    </div>
<?php endforeach; ?>
