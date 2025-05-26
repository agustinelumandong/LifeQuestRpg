<?php

namespace App\Models;

use App\Core\Model;
use App\Core\Auth;

class BadHabits extends Model
{

    protected static $table = 'badhabits';

    /**
     * Get all bad habits for a specific user
     *
     * @param int $userId The user ID to retrieve bad habits for
     * @return array|null Bad habits or null if not found
     */
    public function getBadHabitsByUserId($userId)
    {
        return self::$db->query("SELECT * FROM badhabits WHERE user_id = ?")
            ->bind([1 => $userId])
            ->execute()
            ->fetchAll();
    }

    public function cleanDay($user_id, $date = null)
    {
        $date = $date ?: date('Y-m-d');

        $result = self::$db->query("
            SELECT COUNT (*) as count
            FROM badHabits
            WHERE user_id = ?
            AND status = 'completed'
            AND DATE(updated_at)  = ?
        ")
            ->bind([1 => $user_id, $date])
            ->execute()
            ->fetch();

        return $result['count'] == 0;
    }

    /**
     * Get a count of all bad habits
     * @return int
     */
    public function count()
    {
        $result = self::$db->query("SELECT COUNT(*) as count FROM " . static::$table)
            ->execute()
            ->fetch();
        return $result ? (int) ($result['count'] ?? 0) : 0;
    }

    /**
     * Get count of avoided bad habits
     * @return int
     */
    public function getAvoidedCount()
    {
        $result = self::$db->query("SELECT COUNT(*) as count FROM " . static::$table . " WHERE avoided > 0")
            ->execute()
            ->fetch();
        return $result ? (int) ($result['count'] ?? 0) : 0;
    }
}