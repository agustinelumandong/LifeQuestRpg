<?php

namespace App\Models;

use App\Core\Model;
use App\Core\Auth;

class Tasks Extends Model {

    protected static $table = 'tasks';

    public function getTasksByUserId($userId)
{
    return self::$db->query("SELECT * FROM tasks WHERE user_id = ?")
        ->bind([1 => $userId])
        ->execute()
        ->fetchAll();
}

}

?> 