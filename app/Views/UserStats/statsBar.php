<div class="container py-4">

<div class="card mb-4">
        <div class="card-body">
            <h2 class="card-title">Welcome, <?= htmlspecialchars($currentUser['name'] ?? 'User') ?></h2>
            
            <?php if ($userStats): ?>
                <div class="progress mb-2" style="height: 20px;">
                    <div class="progress-bar" role="progressbar" 
                         style="width: <?= ($userStats['xp'] / ($userStats['level'] * 100)) * 100 ?>%">
                        <?= $userStats['xp'] ?>/<?= $userStats['level'] * 100 ?> XP
                    </div>
                </div>
                <p class="mb-0">Level: <?= $userStats['level'] ?></p>
                <p class="mb-0">Hearts: <?= $userStats['health'] ?></p>
                <p class="mb-0">Physical Health: <?= $userStats['physicalHealth'] ?></p>
                <p class="mb-0">Mental Wellness: <?= $userStats['mentalWellness'] ?></p>
                <p class="mb-0">Personal Growth: <?= $userStats['personalGrowth'] ?></p>
                <p class="mb-0">Career Studies: <?= $userStats['careerStudies'] ?></p>
                <p class="mb-0">Finance: <?= $userStats['finance'] ?></p>
                <p class="mb-0">Home Environment: <?= $userStats['homeEnvironment'] ?></p>
                <p class="mb-0">Relationships Social: <?= $userStats['relationshipsSocial'] ?></p>
                <p class="mb-0">Passion Hobbies: <?= $userStats['passionHobbies'] ?></p>

            <?php else: ?>
                <p class="text-muted mb-0">No stats available.</p>
            <?php endif; ?>
           
        </div>
    </div>

</div>