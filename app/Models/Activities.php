<?php

namespace App\Models;

use App\Core\Model;

class Activities extends Model
{
    protected static $table = 'activities';

    public function getRecentActivities($userId, $limit = 10)
    {
        return self::$db->query(
            "SELECT * FROM activities 
             WHERE user_id = ? 
             ORDER BY created_at DESC 
             LIMIT ?"
        )
        ->bind([1 => $userId, 2 => $limit])
        ->execute()
        ->fetchAll();
    }
}