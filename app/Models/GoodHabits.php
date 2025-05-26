<?php

namespace App\Models;

use App\Core\Model;
use App\Core\Auth;

class GoodHabits extends Model
{

    protected static $table = 'goodhabits';

    public function getGoodHabitsByUserId($userId)
    {
        return self::$db->query("SELECT * FROM goodhabits WHERE user_id = ?")
            ->bind([1 => $userId])
            ->execute()
            ->fetchAll();
    }

    /**
     * Get a count of all good habits
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
     * Get count of completed good habits
     * @return int
     */
    public function getCompletedCount()
    {
        $result = self::$db->query("SELECT COUNT(*) as count FROM " . static::$table . " WHERE status = 'completed'")
            ->execute()
            ->fetch();

        if ($result && (int) ($result['count'] ?? 0) > 0) {
            // There is at least one completed habit
            return true;
        }
        // No completed habits
        return false;
        // return $result ? (int) ($result['count'] ?? 0) : 0;
    }

}