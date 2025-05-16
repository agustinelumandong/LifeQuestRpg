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

  public function getPaginatedUserItemNames($userId, $page = 1, $perPage = 12, $orderBy = 'user_id', $direction = 'DESC')
  {
    $sql = "SELECT item_name FROM user_items WHERE user_id = :user_id ORDER BY {$orderBy} {$direction} LIMIT :limit OFFSET :offset";

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
    $countSql = "SELECT COUNT(*) as count FROM user_items WHERE user_id = :user_id";
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
    $sql = "SELECT COUNT(*) as item_count FROM user_items WHERE user_id = ?";

    return self::$db->query($sql)
      ->bind(['user_id' => $userId])
      ->execute()
      ->fetchColumn();
  }
}
