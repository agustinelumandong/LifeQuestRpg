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

}