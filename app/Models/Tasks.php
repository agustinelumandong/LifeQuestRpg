<?php

namespace App\Models;

use App\Core\Model;
use App\Core\Auth;

class Tasks extends Model
{

    protected static $table = 'tasks';

    public function getTasksByUserId($userId)
    {
        return self::$db->query("SELECT * FROM tasks WHERE user_id = ?")
            ->bind([1 => $userId])
            ->execute()
            ->fetchAll();
    }

    public function getTasks()
    {
        /** @var array $currentUser */
        $currentUser = Auth::user();

        if ($currentUser) {
            return $this->getTasksByUserId($currentUser['id']);
        } else {
            return self::$db->query("SELECT * FROM " . self::$table)
                ->execute()
                ->fetchAll();
        }
    }
}

