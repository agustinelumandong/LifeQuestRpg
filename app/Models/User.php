<?php
namespace App\Models;

use App\Core\Model;

class User extends Model
{
  protected static $table = 'users';

  public function __construct()
  {
  }

  public function getUserById($userId)
  {
    return self::$db->query("SELECT * FROM " . static::$table . " WHERE id = ?")
      ->bind([1 => $userId])
      ->execute()
      ->fetch();
  }

  public function getAllUserIds(): array
  {
    $results = self::$db->query("SELECT id FROM " . static::$table)
      ->execute()
      ->fetchAll();
    return $results ? $results : [];
  }

  /**
   * Find a user by email
   */
  public static function findByEmail(string $email)
  {
    return self::$db->query("SELECT * FROM " . static::$table . " WHERE LOWER(email) = LOWER(?)")
      ->bind([1 => $email])
      ->execute()
      ->fetch();
  }

  /**
   * Authenticate a user
   */
  public static function authenticate(string $email, string $password)
  {
    $user = self::findByEmail($email);

    if (!$user) {
      return false;
    }

    return password_verify($password, $user['password']) ? $user : false;
  }

  /**
   * Summary of getUserStats
   * @param mixed $userId
   */
  public function getUserStats($userId)
  {
    return self::$db->query("SELECT * FROM userstats WHERE id = ?")
      ->bind([1 => $userId])
      ->execute()
      ->fetch();
  }

  /**
   * Special update method that can handle both user array and user ID
   * for backward compatibility
   */
  public function update($user, array $data)
  {
    // Handle case where $user is an array (the whole user object)
    $userId = is_array($user) ? ($user['id'] ?? null) : $user;

    if (!$userId) {
      error_log("User::update - Invalid user ID: " . var_export($user, true));
      return false;
    }

    error_log("User::update - Using ID: " . var_export($userId, true) . " with data: " . var_export($data, true));

    // Call the parent update method
    return parent::update($userId, $data);
  }

  /**
   * Summary of addCoin
   * @param mixed $user_id
   * @param mixed $coinRewards
   * @return bool|int
   */
  public function addCoin($user_id, $coinRewards)
  {
    $user = $this->find($user_id);

    if (!$user) {
      return false;
    }

    $newCoins = $user['coins'] + $coinRewards;

    return $this->update($user['id'], [
      'coins' => $newCoins
    ]);
  }

  /**
   * Get a count of all users
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
   * Get recent users
   * @param int $limit
   * @return array
   */
  public function getRecent($limit = 5)
  {
    return self::$db->query("SELECT * FROM " . static::$table . " ORDER BY created_at DESC LIMIT ?")
      ->bind([1 => $limit])
      ->execute()
      ->fetchAll();
  }

  /**
   * Get count of users created before a specific date
   * @param string $date
   * @return int
   */
  public function getCountBefore($date)
  {
    $result = self::$db->query("SELECT COUNT(*) as count FROM " . static::$table . " WHERE created_at < ?")
      ->bind([1 => $date])
      ->execute()
      ->fetch();
    return $result ? (int) ($result['count'] ?? 0) : 0;
  }

  /**
   * Get count of users created since a specific date
   * @param string $date
   * @return int
   */
  public function getCountSince($date)
  {
    $result = self::$db->query("SELECT COUNT(*) as count FROM " . static::$table . " WHERE created_at >= ?")
      ->bind([1 => $date])
      ->execute()
      ->fetch();
    return $result ? (int) ($result['count'] ?? 0) : 0;
  }

  /**
   * Get count of users created between two dates
   * @param string $startDate
   * @param string $endDate
   * @return int
   */
  public function getCountBetween($startDate, $endDate)
  {
    $result = self::$db->query("SELECT COUNT(*) as count FROM " . static::$table . " WHERE created_at >= ? AND created_at <= ?")
      ->bind([1 => $startDate, 2 => $endDate])
      ->execute()
      ->fetch();
    return $result ? (int) ($result['count'] ?? 0) : 0;
  }
  /**
   * Paginate users
   * @param int $page
   * @param int $perPage
   * @param string|null $orderBy
   * @param string $direction
   * @param array $conditions
   * @param string $pageName
   * @param array|null $columns
   * @return array
   */
  public function paginate(
    int $page = 1,
    int $perPage = 10,
    ?string $orderBy = 'created_at',
    string $direction = 'DESC',
    array $conditions = [],
    string $pageName = 'page',
    ?array $columns = null
  ) {
    $offset = ($page - 1) * $perPage;

    $totalResult = self::$db->query("SELECT COUNT(*) as count FROM " . static::$table)
      ->execute()
      ->fetch();

    $total = $totalResult ? (int) ($totalResult['count'] ?? 0) : 0;

    $items = self::$db->query("SELECT * FROM " . static::$table . " ORDER BY {$orderBy} {$direction} LIMIT ? OFFSET ?")
      ->bind([1 => $perPage, 2 => $offset])
      ->execute()
      ->fetchAll();

    return [
      'items' => $items,
      'total' => $total,
      'per_page' => $perPage,
      'current_page' => $page,
      'last_page' => ceil($total / $perPage)
    ];
  }
}
