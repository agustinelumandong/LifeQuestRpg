<?php
namespace App\Core;

abstract class Model
{
  protected static $db;     // Database connection
  protected static $table;        // Table name

  /**
   * Set the database connection
   */
  public static function setDatabase(Database $database)
  {
    self::$db = $database;
  }

  /**
   * Find a record by ID
   */
  public static function find(int $id)
  {
    return self::$db->query("SELECT * FROM " . static::$table . " WHERE id = ?")
      ->bind([1 => $id])
      ->execute()
      ->fetch();
  }

  /**
   * Find a specific column by ID
   *
   * @param int $id The ID of the record to find
   * @param string $columnName The name of the column to retrieve
   * @return mixed The value of the specified column or false if not found
   */
  public static function findByColumn(int $id, string $columnName)
  {
    // Sanitize the column name slightly to prevent issues if it contains backticks,
    // though proper validation against known column names is recommended for security.
    $safeColumnName = str_replace('`', '', $columnName);

    // Construct the SQL query to select the specific column.
    // Using backticks around the column name is good practice for SQL identifiers.
    $sql = "SELECT `{$safeColumnName}` FROM " . static::$table . " WHERE id = ?";

    return self::$db->query($sql)
      ->bind([1 => $id])
      ->execute()
      ->fetch();
  }

  /**
   * Get all records
   */
  public function all()
  {
    return self::$db->query("SELECT * FROM " . static::$table)
      ->execute()
      ->fetchAll();
  }

  /**
   * Create a new record
   */
  public function create(array $data)
  {
    $columns = implode(', ', array_keys($data));
    $placeholders = ':' . implode(', :', array_keys($data));

    $sql = "INSERT INTO " . static::$table . " ({$columns}) VALUES ({$placeholders})";

    return self::$db->query($sql)
      ->bind($data)
      ->execute()
      ->lastInsertId();

  }

  /**
   * Update a record
   */
  public function update(int $id, array $data)
  {
    $fields = '';
    foreach (array_keys($data) as $key) {
      $fields .= "{$key} = :{$key}, ";
    }
    $fields = rtrim($fields, ', ');

    $sql = "UPDATE " . static::$table . " SET {$fields} WHERE id = :id";

    $data['id'] = $id;

    return self::$db->query($sql)
      ->bind($data)
      ->execute()
      ->rowCount();
  }

  /**
   * Delete a record
   */
  public function delete(int $id)
  {
    return self::$db->query("DELETE FROM " . static::$table . " WHERE id = ?")
      ->bind([1 => $id])
      ->execute()
      ->rowCount();
  }

  /**
   * Find a record by column
   */
  public function findBy(string $column, $value)
  {
    return self::$db->query("SELECT * FROM " . static::$table . " WHERE {$column} = ?")
      ->bind([1 => $value])
      ->execute()
      ->fetch();
  }

  /**
   * Find all records by column
   */
  public function findAllBy(string $column, $value)
  {
    return self::$db->query("SELECT * FROM " . static::$table . " WHERE {$column} = ?")
      ->bind([1 => $value])
      ->execute()
      ->fetchAll();
  }

  /**
   * Get the total number of records
   */
  public function count()
  {
    $result = self::$db->query("SELECT COUNT(*) FROM " . static::$table)
      ->execute()
      ->fetch();
    return is_array($result) ? reset($result) : 0;
  }

  /**
   * Check If record exists
   */
  public function exists(int $id)
  {
    return self::find($id) !== false;
  }


  /**
   * Get the last inserted ID
   */
  public function lastInsertId()
  {
    return self::$db->lastInsertId();
  }

  /**
   * Get the database connection
   */
  public function getDatabase()
  {
    return self::$db;
  }

  /**
   * Get the table name
   */
  public function getTable()
  {
    return $this->table;
  }

  /**
   * Get the primary key
   */
  public function getPrimaryKey()
  {
    return 'id';
  }

  /**
   * Get the timestamp columns
   */
  public function getTimestamps()
  {
    return ['created_at', 'updated_at'];
  }

  /**
   * Get the soft delete column
   */
  public function getSoftDelete()
  {
    return 'deleted_at';
  }

  /**
   * Get the date format
   */
  public function getDateFormat()
  {
    return 'Y-m-d H:i:s';
  }

  /**
   * Validate if the record exists
   */

  public function doesRecordAlreadyExist(string $data): bool
  {
    return self::$db->query("SELECT * FROM " . static::$table . " WHERE email = ?")
      ->bind([1 => $data])
      ->execute()
      ->fetch() ? true : false;
  }

  /**
   * Is the email valid
   */
  public function isEmailValid(string $data): bool
  {
    return filter_var($data, FILTER_VALIDATE_EMAIL);
  }

  /**
   * Is the password valid
   */
  public function isPasswordValid(string $password): bool
  {
    return strlen($password) >= 8;
  }
  /**
   * Get paginated items with proper database-level pagination
   * 
   * @param int $page Current page number
   * @param int $perPage Number of items per page
   * @param string|null $orderBy Column to order by
   * @param string $direction Sort direction (ASC or DESC)
   * @param array $conditions Where conditions as associative array
   * @param string $pageName Name of the page parameter in URL 
   * @param array|null $columns Columns to select (default is all)
   * @return Paginator
   */
  public function paginate(
    int $page = 1,
    int $perPage = 10,
    ?string $orderBy = null,
    string $direction = 'DESC',
    array $conditions = [],
    string $pageName = 'page',
    ?array $columns = null
  ) {
    // Create a new Paginator instance
    $paginator = new Paginator($perPage, $pageName);

    // If page was manually specified, set it
    if ($page > 1) {
      $paginator->setPage($page);
    }

    // Set the ordering
    if ($orderBy) {
      $paginator->setOrderBy($orderBy, $direction);
    }

    // Get pagination info
    $paginationInfo = $paginator->getPageInfo();
    $offset = ($paginationInfo['currentPage'] - 1) * $perPage;

    // Get the data
    $items = $this->fetch($conditions, $orderBy, $direction, $perPage, $offset, $columns);

    // Count total items
    $countSql = "SELECT COUNT(*) as count FROM " . static::$table;
    $params = [];

    if (!empty($conditions)) {
      $countSql .= " WHERE ";
      $whereClauses = [];

      foreach ($conditions as $column => $value) {
        $paramName = "{$column}";
        $whereClauses[] = "{$column} = :{$paramName}";
        $params[$paramName] = $value;
      }

      $countSql .= implode(' AND ', $whereClauses);
    }

    $countQuery = self::$db->query($countSql);

    if (!empty($params)) {
      $countQuery->bind($params);
    }

    $totalItems = (int) $countQuery->execute()->fetch()['count'];

    // Set the data and return the paginator
    return $paginator->setData($items, $totalItems);
  }

  /**
   * Fetch records with conditions, sorting, and pagination.
   * 
   * @param array $conditions Conditions for the WHERE clause
   * @param string|null $orderBy Column to order by
   * @param string $direction Sort direction (ASC or DESC)
   * @param int|null $limit Number of records to fetch
   * @param int|null $offset Offset for pagination
   * @param array|null $columns Columns to select (default is all)
   * @return array Fetched records
   */

  public function fetch(
    array $conditions = [],
    ?string $orderBy = null,
    string $direction = 'ASC',
    ?int $limit = null,
    ?int $offset = null,
    ?array $columns = null
  ) {

    $columnsString = $columns ? implode(', ', array_map(fn($col) => "`{$col}`", $columns)) : '*';
    $sql = "SELECT {$columnsString} FROM " . static::$table;
    $params = [];

    if (!empty($conditions)) {
      $sql .= " WHERE ";
      $whereClauses = [];

      foreach ($conditions as $column => $value) {
        $paramName = "{$column}";
        $whereClauses[] = "{$column} = :{$paramName}";
        $params[":{$paramName}"] = $value;
      }
      $sql .= implode(" AND ", $whereClauses);
    }

    if ($orderBy !== null) {
      $direction = strtoupper($direction) === 'DESC' ? 'DESC' : 'ASC';
      $sql .= " ORDER BY `{$orderBy}` {$direction}";
    }

    if ($limit !== null) {
      $sql .= " LIMIT :limit";
      $params[':limit'] = $limit;

      if ($offset !== null) {
        $sql .= " OFFSET :offset";
        $params[':offset'] = $offset;
      }
    }

    $query = self::$db->query($sql);

    if (!empty($params)) {
      $query->bind($params);
    }

    return $query->execute()->fetchAll();
  }
}
