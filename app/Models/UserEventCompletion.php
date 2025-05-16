<?php
namespace App\Models;

use App\Core\Model;

class UserEventCompletion extends Model
{
  protected static $table = 'user_event_completions';



  public function recordCompletion($userId, $taskId)
  {
    $sql = "INSERT IGNORE INTO " . static::$table . " (user_id, id) VALUES (?, ?)";
    return self::$db->query($sql)
      ->bind([1 => $userId, 2 => $taskId])
      ->execute()
      ->rowCount();
  }

  public function hasUserCompleted($userId, $task_id)
  {
    $sql = "SELECT COUNT(*) FROM " . static::$table . " WHERE user_id = ? AND id = ?";
    $result = self::$db->query($sql)
      ->bind([1 => $userId, 2 => $task_id])
      ->execute()
      ->fetchColumn();

    return (bool) $result;
  }

  public function getUserEventCompletions($userId)
  {
    $sql = "SELECT id, user_id, event_name FROM " . static::$table . " WHERE user_id = ?";
    return self::$db->query($sql)
      ->bind([1 => $userId])
      ->execute()
      ->fetchAll();
  }


  public function updateUserStats($userId, $xp, $coins)
  {
    $sql = "UPDATE userstats SET xp = xp + ?, coins = ? + ? WHERE id = ?";
    return self::$db->query($sql)
      ->bind([1 => $xp, 2 => $coins, 3 => $userId])
      ->execute()
      ->rowCount();
  }

  public function getUserEventCompletionsNames($userId)
  {
    $sql = "SELECT task_id FROM " . static::$table . " WHERE user_id = ?";
    return self::$db->query($sql)
      ->bind([1 => $userId])
      ->execute()
      ->fetchAll();
  }
}