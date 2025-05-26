<?php
namespace App\Models;

use App\Core\Model;

class UserEventCompletion extends Model
{
  protected static $table = 'user_event_completions';

  public function recordCompletion($userId, $taskId)
  {
    // First check if the entry already exists
    if ($this->hasUserCompleted($userId, $taskId)) {
      return ['status' => 'duplicate', 'message' => 'User has already completed this event'];
    }
    
    try {
      $sql = "INSERT INTO " . static::$table . " (taskevent_id, user_id) VALUES (?, ?)";
      $result = self::$db->query($sql)
        ->bind([1 => $taskId, 2 => $userId])
        ->execute()
        ->rowCount();
      
      return ['status' => 'success', 'affected_rows' => $result];
    } catch (\Exception $e) {
      // Check if it's a duplicate entry error (MySQL error code 1062)
      if (strpos($e->getMessage(), '1062') !== false) {
        return ['status' => 'duplicate', 'message' => 'User has already completed this event'];
      }
      
      // Other database error
      return ['status' => 'error', 'message' => $e->getMessage()];
    }
  }

  public function hasUserCompleted($userId, $task_id)
  {
    $sql = "SELECT COUNT(*) FROM " . static::$table . " WHERE user_id = ? AND taskevent_id = ?";
    $result = self::$db->query($sql)
      ->bind([1 => $userId, 2 => $task_id])
      ->execute()
      ->fetchColumn();

    return (bool) $result;
  }

  public function getUserEventCompletions($userId)
  {
    $sql = "SELECT id, user_id, taskevent_id FROM " . static::$table . " WHERE user_id = ?";
    return self::$db->query($sql)
      ->bind([1 => $userId])
      ->execute()
      ->fetchAll();
  }

  public function updateUserExp($userId, $xp)
  {
    $sql = "UPDATE userstats SET xp = xp + ? WHERE id = ?";
    return self::$db->query($sql)
      ->bind([1 => $xp, 2 => $userId])
      ->execute()
      ->rowCount();
  }

  public function updateUserCoins($userId, $coins)
  {
    $sql = "UPDATE users SET coins = coins + ? WHERE id = ?";
    return self::$db->query($sql)
      ->bind([1 => $coins, 2 => $userId])
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