<?php

namespace App\Models;

use App\Core\Model;

class DailyTasks extends Model {
    protected static $table = 'dailytasks';

    public function getDailyTasksByUserId($userId) {
        return self::$db->query("SELECT * FROM dailytasks WHERE user_id = ?")
            ->bind([1 => $userId])
            ->execute()
            ->fetchAll();
    }

    public function resetDailyTasks(/*$forceReset = false*/){
        // if ($forceReset) {
        // For testing - resets all tasks regardless of time
        //     return self::$db->query("
        //     UPDATE dailytasks 
        //     SET status = 'pending', last_reset = CURRENT_TIMESTAMP")
        //     ->execute();
        // }

        // Normal production code
    return self::$db->query("
    UPDATE dailytasks 
    SET status = 'pending', last_reset = CURRENT_TIMESTAMP
    WHERE DATE(last_reset) < CURDATE() OR last_reset IS NULL")
    ->execute();
    }
    
}