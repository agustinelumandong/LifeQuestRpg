<?php

namespace App\Models;

use App\Core\Model;

class Journal extends Model
{
    protected static $table = 'journals';

    public function getJournalsByUserId($userId)
    {
        return self::$db->query("SELECT * FROM journals WHERE user_id = ? ORDER BY created_at DESC")
            ->bind([1 => $userId])
            ->execute()
            ->fetchAll();
    }


    public function getJournalByDate($userId, $date)
    {
        return self::$db->query("SELECT * FROM journals WHERE user_id = ? AND date = ?")
            ->bind([1 => $userId, 2 => $date])
            ->execute()
            ->fetch();
    }
}