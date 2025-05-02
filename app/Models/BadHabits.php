<?php

namespace App\Models;

use App\Core\Model;
use App\Core\Auth;

class BadHabits extends Model
{

    protected static $table = 'badhabits';

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

}