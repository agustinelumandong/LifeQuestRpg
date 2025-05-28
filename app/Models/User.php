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
  /**
   * Get paginated users with proper database-level pagination
   * @param int $page Current page number
   * @param int $perPage Number of users per page
   * @param string $orderBy Column to order by
   * @param string $direction Sort direction
   * @param array $conditions Where conditions
   * @param string $search Search term
   * @return \App\Core\Paginator
   */
  public function getPaginatedUsers($page = 1, $perPage = 10, $orderBy = 'created_at', $direction = 'DESC', $conditions = [], $search = '')
  {
    // Build the base SQL
    $sql = "SELECT * FROM " . static::$table;
    $countSql = "SELECT COUNT(*) as count FROM " . static::$table;

    $params = [];
    $whereConditions = [];

    // Add WHERE conditions if any
    if (!empty($conditions)) {
      foreach ($conditions as $key => $value) {
        $whereConditions[] = "{$key} = :{$key}";
        $params[$key] = $value;
      }
    }

    // Add search functionality
    if (!empty($search)) {
      $whereConditions[] = "(name LIKE :search OR email LIKE :search OR username LIKE :search)";
      $params['search'] = "%{$search}%";
    }

    // Apply WHERE clause if we have conditions
    if (!empty($whereConditions)) {
      $whereClause = " WHERE " . implode(' AND ', $whereConditions);
      $sql .= $whereClause;
      $countSql .= $whereClause;
    }

    // Add ordering and pagination
    $sql .= " ORDER BY {$orderBy} {$direction} LIMIT :limit OFFSET :offset";

    $offset = ($page - 1) * $perPage;
    $params['limit'] = $perPage;
    $params['offset'] = $offset;

    // Get the users
    $users = self::$db->query($sql)
      ->bind($params)
      ->execute()
      ->fetchAll();

    // Get total count (without pagination params)
    $countParams = array_filter($params, function ($key) {
      return !in_array($key, ['limit', 'offset']);
    }, ARRAY_FILTER_USE_KEY);

    $totalCount = self::$db->query($countSql)
      ->bind($countParams)
      ->execute()
      ->fetch()['count'];

    // Create and return paginator
    $paginator = new \App\Core\Paginator($perPage);
    return $paginator->setData($users, $totalCount)
      ->setOrderBy($orderBy, $direction)
      ->setPage($page);
  }
}
