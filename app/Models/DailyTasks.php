<?php

namespace App\Models;

use App\Core\Auth;
use App\Core\Model;

class DailyTasks extends Model
{
    protected static $table = 'dailytasks';

    public function getDailyTasksByUserId($userId)
    {
        return self::$db->query("SELECT * FROM dailytasks WHERE user_id = ?")
            ->bind([1 => $userId])
            ->execute()
            ->fetchAll();
    }

    public function resetDailyTasks()
    {
        return self::$db->query(
            "UPDATE dailytasks 
            SET status = 'pending', last_reset = CURRENT_TIMESTAMP 
            WHERE DATE(last_reset) < CURDATE() OR last_reset IS NULL"
        )
            ->execute();
    }

    public function getDailyTasks()
    {
        /** @var array $currentUser */
        $currentUser = Auth::user();

        if ($currentUser) {
            return $this->getDailyTasksByUserId($currentUser['id']);
        } else {
            return self::$db->query("SELECT * FROM " . self::$table)
                ->execute()
                ->fetchAll();
        }
    }

}