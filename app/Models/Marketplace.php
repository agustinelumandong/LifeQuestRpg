<?php
namespace App\Models;

use App\Core\Model;

class Marketplace extends Model
{
  protected static $table = 'marketplace_items';

  public function __construct()
  {
    // Empty constructor - no need to set table here
  }

  public function GetItemById($id)
  {
    return self::$db->query("
      SELECT *
      FROM marketplace_items
      WHERE item_id = :item_id
    ")->bind(['item_id' => $id])
      ->execute()
      ->fetchAll();

  }

  public function purchaseItem($userId, $itemId)
  {
    $statement = self::$db->query("CALL PurchaseMarketplaceItem(:user_id, :item_id)")
      ->bind(['user_id' => $userId, 'item_id' => $itemId])
      ->execute();

    if ($statement) {
      $result = $statement->fetchAll();
      if (!empty($result) && isset($result[0]['message'])) {
        return $result[0]['message'];
      }
    }
    return false; // Or some other indicator of failure to execute the procedure
  }

  public function getItemDetails($itemId)
  {
    return self::$db->query("
      SELECT item_name, item_description, item_price
      FROM marketplace_items
      WHERE item_id = :item_id
    ")->bind(['item_id' => $itemId])
      ->execute()
      ->fetchAll();
  }



  public function update(int $item_id, array $data)
  {
    $fields = '';
    foreach (array_keys($data) as $key) {
      $fields .= "{$key} = :{$key}, ";
    }
    $fields = rtrim($fields, characters: ', ');

    $sql = "UPDATE " . static::$table . " SET {$fields} WHERE item_id = :item_id";

    $data['item_id'] = $item_id;

    return self::$db->query($sql)
      ->bind($data)
      ->execute()
      ->rowCount();
  }

}
