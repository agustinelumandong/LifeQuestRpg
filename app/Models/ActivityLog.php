<?php

namespace App\Models;

use App\Core\Model;

class ActivityLog extends Model
{

    public function getRecentActivities($userId)
    {
        return self::$db->query(
            " SELECT * FROM view_task_activity WHERE user_id = ?
            UNION ALL
            SELECT * FROM view_daily_task_activity WHERE user_id = ?
            UNION ALL
            SELECT * FROM view_good_habits_activity WHERE user_id = ?
            UNION ALL
            SELECT * FROM view_bad_habits_activity WHERE user_id = ?
            ORDER BY log_timestamp DESC"
        )
        ->bind([1 => $userId, 2 => $userId, 3 => $userId, 4 => $userId])
        ->execute()
        ->fetchAll(); 
    }

}