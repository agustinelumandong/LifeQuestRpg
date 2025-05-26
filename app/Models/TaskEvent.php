<?php
namespace App\Models;

use App\Core\Model;

class TaskEvent extends Model
{
  protected static $table = 'user_event';

  public function __construct()
  {
    // Empty constructor - no need to set table here
  }


  public function getEventById($event_id)
  {
    return self::$db->query("SELECT * FROM " . static::$table . " WHERE id = ?")
      ->bind([1 => $event_id])
      ->execute()
      ->fetch();
  }

  public function checkEventActive($event_id)
  {
    return self::$db->query("SELECT * FROM " . static::$table . " WHERE id = ? AND status = 'active' AND end_date > NOW()")
      ->bind([1 => $event_id])
      ->execute()
      ->fetch();
  }

  public function getAllActiveEvents()
  {
    return self::$db->query("SELECT * FROM " . static::$table . " WHERE status = 'active' AND end_date > NOW() ORDER BY start_date ASC")
      ->execute()
      ->fetchAll();
  }

  public function update(int $event_id, array $data)
  {
    $fields = '';
    foreach (array_keys($data) as $key) {
      $fields .= "{$key} = :{$key}, ";
    }
    $fields = rtrim($fields, ', ');

    $sql = "UPDATE " . static::$table . " SET {$fields} WHERE id = :id";

    $data['id'] = $event_id;

    return self::$db->query($sql)
      ->bind($data)
      ->execute()
      ->rowCount();
  }

  public function delete(int $id)
  {
    return self::$db->query("DELETE FROM " . static::$table . " WHERE id = ?")
      ->bind([1 => $id])
      ->execute()
      ->rowCount();
  }


  public function getTaskReward($task_id)
  {
    $sql = "SELECT reward_xp, reward_coins FROM " . static::$table . " WHERE id = ?";
    return self::$db->query($sql)
      ->bind([1 => $task_id])
      ->execute()
      ->fetch();
  }

  /**
   * Update all events with end_date in the past to inactive status
   * 
   * @return int Number of updated records
   */
  public function updateExpiredEvents()
  {
    $sql = "UPDATE " . static::$table . " 
    SET status = 'inactive' 
    WHERE status = 'active' AND end_date < NOW()";

    return self::$db->query($sql)
      ->execute()
      ->rowCount();
  }

  /**
   * 
   */
  public function updateActiveEvents()
  {
    $sql = "UPDATE " . static::$table . " 
    SET status = 'active' 
    WHERE status = 'inactive' AND end_date > NOW()";

    return self::$db->query($sql)
      ->execute()
      ->rowCount();
  }
  /**
   * Get a count of all task events
   * @return int
   */
  public function count()
  {
    $result = self::$db->query("SELECT COUNT(*) as count FROM " . static::$table)
      ->execute()
      ->fetch();
    return $result ? (int) ($result['count'] ?? 0) : 0;
  }

  /**
   * Get recent task events
   * @param int $limit
   * @return array
   */
  public function getRecent($limit = 5)
  {
    // Using start_date as the ordering column since it's likely to be present in task_events table
    return self::$db->query("SELECT * FROM " . static::$table . " ORDER BY id DESC LIMIT ?")
      ->bind([1 => $limit])
      ->execute()
      ->fetchAll();
  }
}
