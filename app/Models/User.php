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
    return self::$db->query("SELECT * FROM " . static::$table . " WHERE email = ?")
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
}
