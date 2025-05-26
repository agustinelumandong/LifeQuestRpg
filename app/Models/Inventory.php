<?php
namespace App\Models;

use App\Core\Model;
use App\Core\Paginator;

class Inventory extends Model
{
  protected static $table = 'user_inventory';

  public function getOwnedItemIds($userId)
  {
    $ownedItems = $this->findAllBy('user_id', $userId);
    return array_column($ownedItems, 'item_id');
  }
  public function getPaginatedUserItems($userId, $page = 1, $perPage = 12, $orderBy = 'inventory_id', $direction = 'DESC')
  {
    $sql = "SELECT ui.inventory_id, ui.user_id, ui.quantity, ui.acquired_at, mi.item_id, mi.item_name, mi.item_description, mi.item_price, 
            mi.image_url, mi.item_type, mi.effect_type, mi.effect_value, 
            ic.category_name, ic.icon
            FROM user_inventory ui
            JOIN marketplace_items mi ON ui.item_id = mi.item_id
            LEFT JOIN item_categories ic ON mi.category_id = ic.category_id
            WHERE ui.user_id = :user_id 
            ORDER BY {$orderBy} {$direction} 
            LIMIT :limit OFFSET :offset";

    $offset = ($page - 1) * $perPage;

    $items = self::$db->query($sql)
      ->bind([
        ':user_id' => $userId,
        ':limit' => $perPage,
        ':offset' => $offset
      ])
      ->execute()
      ->fetchAll();

    // Get total count for pagination
    $countSql = "SELECT COUNT(*) as count FROM user_inventory WHERE user_id = :user_id";
    $totalCount = self::$db->query($countSql)
      ->bind([':user_id' => $userId])
      ->execute()
      ->fetch()['count'];

    // Create and return paginator
    $paginator = new Paginator($perPage);
    return $paginator->setData($items, $totalCount)
      ->setOrderBy($orderBy, $direction)
      ->setPage($page)
      ->setTheme('game');
  }
  public function getUserItemCount($userId)
  {
    $sql = "SELECT COUNT(*) as item_count FROM user_inventory WHERE user_id = :user_id";

    return self::$db->query($sql)
      ->bind([':user_id' => $userId])
      ->execute()
      ->fetch()['item_count'] ?? 0;
  }

  /**
   * Get item usage history for a user
   * @param int $userId The user ID
   * @param int $limit Optional limit of records to return
   * @return array Usage history records
   */
  public function getItemUsageHistory($userId, $limit = 10)
  {
    $sql = "SELECT h.usage_id, h.used_at, h.effect_applied, 
            m.item_name, m.image_url, m.item_type
            FROM item_usage_history h
            JOIN user_inventory i ON h.inventory_id = i.inventory_id
            JOIN marketplace_items m ON i.item_id = m.item_id
            WHERE i.user_id = :user_id
            ORDER BY h.used_at DESC
            LIMIT :limit";

    return self::$db->query($sql)
      ->bind([':user_id' => $userId, ':limit' => $limit])
      ->execute()
      ->fetchAll();
  }

  /**
   * Get item by inventory ID
   * @param int $inventoryId The inventory ID
   * @return array|false The item details or false if not found
   */
  public function getItemByInventoryId($inventoryId)
  {
    $sql = "SELECT ui.inventory_id, ui.user_id, ui.quantity, ui.acquired_at, mi.item_id, mi.item_name, 
            mi.item_description, mi.item_price, mi.image_url, mi.item_type, 
            mi.effect_type, mi.effect_value, ic.category_name
            FROM user_inventory ui
            JOIN marketplace_items mi ON ui.item_id = mi.item_id
            LEFT JOIN item_categories ic ON mi.category_id = ic.category_id
            WHERE ui.inventory_id = :inventory_id";

    return self::$db->query($sql)
      ->bind([':inventory_id' => $inventoryId])
      ->execute()
      ->fetch();
  }

  public function getUserStats($userId)
  {
    return self::$db->query("
      SELECT * FROM userstats 
      WHERE user_id = :user_id
    ")->bind(['user_id' => $userId])
      ->execute()
      ->fetch();
  }

  /**
   * Get inventory summary with total quantities by item type
   * @param int $userId The user ID
   * @return array Summary of items grouped by type with total quantities
   */
  public function getInventorySummary($userId)
  {
    $sql = "SELECT mi.item_type, 
            COUNT(DISTINCT ui.item_id) as unique_items,
            SUM(ui.quantity) as total_quantity
            FROM user_inventory ui
            JOIN marketplace_items mi ON ui.item_id = mi.item_id
            WHERE ui.user_id = :user_id
            GROUP BY mi.item_type
            ORDER BY mi.item_type";

    return self::$db->query($sql)
      ->bind([':user_id' => $userId])
      ->execute()
      ->fetchAll();
  }

  /**
   * Get total value of user's inventory
   * @param int $userId The user ID
   * @return int Total gold value of all items in inventory
   */
  public function getTotalInventoryValue($userId)
  {
    $sql = "SELECT SUM(mi.item_price * ui.quantity) as total_value
            FROM user_inventory ui
            JOIN marketplace_items mi ON ui.item_id = mi.item_id
            WHERE ui.user_id = :user_id";

    $result = self::$db->query($sql)
      ->bind([':user_id' => $userId])
      ->execute()
      ->fetch();

    return $result['total_value'] ?? 0;
  }
}
