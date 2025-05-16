<?php
namespace App\Core;

use PDO;
use PDOException;

class Database
{
  protected $pdo;
  protected $statement;

  public function __construct(array $config)
  {
    $dsn = "mysql:host={$config['host']};dbname={$config['database']};charset={$config['charset']}";

    $options = [
      PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
      PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
      PDO::ATTR_EMULATE_PREPARES => false,
    ];

    try {
      $this->pdo = new PDO($dsn, $config['username'], $config['password'], $options);
    } catch (PDOException $e) {
      throw new PDOException($e->getMessage(), (int) $e->getCode());
    }
  }

  /**
   * Prepare a SQL query
   */
  public function query(string $sql)
  {
    $this->statement = $this->pdo->prepare($sql);
    return $this;
  }

  /**
   * Bind values to prepared statement
   */
  public function bind(array $parameters)
  {
    foreach ($parameters as $key => $value) {
      // Check if $value is an array and handle it appropriately
      if (is_array($value)) {
        // Convert array to JSON string or handle it in some other way
        $value = json_encode($value);
        $paramType = PDO::PARAM_STR;
      } else {
        // Keep the original logic for non-array values
        $paramType = is_int($value) ? PDO::PARAM_INT : PDO::PARAM_STR;
      }

      $this->statement->bindValue(
        is_numeric($key) ? $key : $key,
        $value,
        $paramType
      );
    }

    return $this;
  }

  /**
   * Execute the prepared statement
   */
  public function execute()
  {
    $this->statement->execute();
    return $this;
  }

  /**
   * Fetch all results
   */
  public function fetchAll()
  {
    return $this->statement->fetchAll();
  }

  /**
   * Fetch single result
   */
  public function fetch()
  {
    return $this->statement->fetch();
  }

  /**
   * Fetch single column
   */
  public function fetchColumn()
  {
    return $this->statement->fetchColumn();
  }

  /**
   * Get row count
   */
  public function rowCount()
  {
    return $this->statement->rowCount();
  }

  /**
   * Get Column Count
   */
  public function columnCount()
  {
    return $this->statement->columnCount();
  }


  /**
   * Get last insert ID
   */
  public function lastInsertId()
  {
    return $this->pdo->lastInsertId();
  }
}
?>