<?php

namespace App\Models;

use App\Core\Model;

class UserStats extends Model
{
    /**
     * Database table name
     */
    protected static $table = 'userstats';



    public function getAllUsersAndStats()
    {
        $sql = "
    SELECT 
        users.id as user_id,
        users.username,
        userstats.level,
        userstats.xp,
        userstats.avatar_id
    FROM users
    JOIN userstats ON users.id = userstats.user_id
    WHERE users.role = 'user'
    ORDER BY userstats.level DESC, userstats.xp DESC
    LIMIT 50
    ";

        return self::$db->query($sql)
            ->execute()
            ->fetchAll();
    }

    /**
     * Get user statistics by user ID
     * 
     * @param int $user_id The user ID to retrieve stats for
     * @return array|null User stats or null if not found
     */
    public function getUserStatsByUserId($user_id)
    {
        $sql = "
        SELECT  userstats.id, userstats.xp, userstats.level, userstats.health,
        userstats.physicalHealth, userstats.mentalWellness, userstats.personalGrowth, userstats.careerStudies,
        userstats.finance, userstats.homeEnvironment, userstats.relationshipsSocial, userstats.passionHobbies, userstats.avatar_id, userstats.objective, users.username
        FROM userstats
        LEFT JOIN users ON users.id = userstats.user_id
        WHERE userstats.user_id = ? ";

        return self::$db->query($sql)
            ->bind([1 => $user_id])
            ->execute()->fetch();
    }

    /**
     * Add experience points to user and level up if threshold is reached
     * 
     * @param int $user_id The user ID to add XP to
     * @param int $xpReward The amount of XP to add
     * @return bool Success or failure of the update
     */
    public function addXp($user_id, $xpReward)
    {
        $userStats = $this->getUserStatsByUserId($user_id);

        if (!$userStats) {
            return false;
        }

        $newXp = $userStats['xp'] + $xpReward;
        $level = $userStats['level'];
        $xpThreshold = $level * 100;

        // Level up if XP threshold is reached
        if ($newXp >= $xpThreshold) {
            $level++;
            $newXp -= $xpThreshold;
        }

        return $this->update($userStats['id'], [
            'xp' => $newXp,
            'level' => $level
        ]);
    }

    /**
     * Add skill points to a specific category based on difficulty
     * 
     * @param int $user_id The user ID
     * @param string $category The skill category to increase
     * @param string $difficulty The difficulty level (easy, medium, hard)
     * @return bool Success or failure of the update
     */
    public function addSkillPoints($user_id, $category, $difficulty)
    {
        $userStats = $this->getUserStatsByUserId($user_id);

        if (!$userStats) {
            return false;
        }

        $categoryColumns = [
            'Physical Health' => 'physicalHealth',
            'Mental Wellness' => 'mentalWellness',
            'Personal Growth' => 'personalGrowth',
            'Career / Studies' => 'careerStudies',
            'Finance' => 'finance',
            'Home Environment' => 'homeEnvironment',
            'Relationships Social' => 'relationshipsSocial',
            'Passion Hobbies' => 'passionHobbies',
        ];

        $difficultyPoints = [
            'easy' => 1,
            'medium' => 2,
            'hard' => 3,
        ];

        $columnName = $categoryColumns[$category] ?? null;

        if (!$columnName) {
            return false;
        }

        $points = $difficultyPoints[$difficulty] ?? 1;
        $newStats = ($userStats[$columnName] ?? 0) + $points;

        return $this->update($userStats['id'], [
            $columnName => $newStats
        ]);
    }

    /**
     * Reduce user health points and reset stats if health reaches zero
     * 
     * @param int $user_id The user ID
     * @return bool Success or failure of the update
     */
    public function minusHealth($user_id)
    {
        $userStats = $this->getUserStatsByUserId($user_id);

        if (!$userStats) {
            return false;
        }

        $healthDeduction = 10;
        $newHealth = $userStats['health'] - $healthDeduction;

        $updated = $this->update($userStats['id'], [
            'health' => $newHealth
        ]);

        // If health reaches zero, reset stats
        if ($updated && $newHealth <= 0) {
            $this->resetStatsPunishment($user_id);
            $_SESSION['warning'] = 'Your health reached zero! All stats have been reset to 5.';
        }

        return $updated;
    }

    /**
     * Reset user stats when health reaches zero
     * 
     * @param int $user_id The user ID
     * @return bool Success or failure of the update
     */
    public function resetStatsPunishment($user_id)
    {
        $userStats = $this->getUserStatsByUserId($user_id);

        if (!$userStats) {
            return false;
        }

        if ($userStats['health'] <= 0) {
            $defaultValue = 5;

            return $this->update($userStats['id'], [
                'physicalHealth' => $defaultValue,
                'mentalWellness' => $defaultValue,
                'personalGrowth' => $defaultValue,
                'careerStudies' => $defaultValue,
                'finance' => $defaultValue,
                'homeEnvironment' => $defaultValue,
                'relationshipsSocial' => $defaultValue,
                'passionHobbies' => $defaultValue,
                'health' => 10,
                'level' => 1,
                'xp' => 0
            ]);
        }

        return false;
    }

    /**
     * Creates initial stats for a new user character
     * 
     * @param array $data User data containing required fields (user_id, avatar_id, objective)
     * Success or failure of the insertion
     */
    public function createUserStats(array $data)
    {
        // Validate required data
        if (empty($data['user_id'])) {
            return false;
        }

        // Default starting skill values
        $defaultSkillValue = 5;

        // Prepare query parameters with defaults for optional fields
        $params = [
            'user_id' => $data['user_id'],
            'avatar_id' => $data['avatar_id'] ?? 1,
            'objective' => $data['objective'] ?? '',
            'xp' => $data['xp'] ?? 0,
            'level' => $data['level'] ?? 1,
            'health' => $data['health'] ?? 3,
            'physicalHealth' => $defaultSkillValue,
            'mentalWellness' => $defaultSkillValue,
            'personalGrowth' => $defaultSkillValue,
            'careerStudies' => $defaultSkillValue,
            'finance' => $defaultSkillValue,
            'homeEnvironment' => $defaultSkillValue,
            'relationshipsSocial' => $defaultSkillValue,
            'passionHobbies' => $defaultSkillValue
        ];

        // Execute the insert query
        return self::$db->query("INSERT INTO userstats (
            user_id, 
            avatar_id, 
            objective, 
            xp, 
            level, 
            health,
            physicalHealth,
            mentalWellness,
            personalGrowth,
            careerStudies,
            finance,
            homeEnvironment,
            relationshipsSocial,
            passionHobbies
        ) VALUES (
            :user_id, 
            :avatar_id, 
            :objective, 
            :xp, 
            :level, 
            :health,
            :physicalHealth,
            :mentalWellness,
            :personalGrowth,
            :careerStudies,
            :finance,
            :homeEnvironment,
            :relationshipsSocial,
            :passionHobbies
        )")
            ->bind($params)
            ->execute();
    }
}
