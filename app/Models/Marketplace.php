<?php
namespace App\Models;

use App\Core\Model;
use Exception;

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
      SELECT m.*, c.category_name
      FROM marketplace_items m
      LEFT JOIN item_categories c ON m.category_id = c.category_id
      WHERE m.item_id = :item_id
    ")->bind(['item_id' => $id])
      ->execute()
      ->fetchAll();

  }

  public function getAllCategories()
  {
    return self::$db->query("
      SELECT *
      FROM item_categories
      ORDER BY category_name
    ")
      ->execute()
      ->fetchAll();
  }

  /**
   * Get paginated marketplace items with category information
   * @param int $page Current page number
   * @param int $perPage Number of items per page
   * @param string $orderBy Column to order by
   * @param string $direction Sort direction
   * @param array $conditions Where conditions
   * @return \App\Core\Paginator
   */
  public function getPaginatedItems($page = 1, $perPage = 12, $orderBy = 'item_id', $direction = 'DESC', $conditions = [])
  {
    // Build the base SQL with proper JOIN for category information
    $sql = "SELECT m.*, c.category_name
            FROM marketplace_items m
            LEFT JOIN item_categories c ON m.category_id = c.category_id";

    $countSql = "SELECT COUNT(*) as count 
                 FROM marketplace_items m
                 LEFT JOIN item_categories c ON m.category_id = c.category_id";

    $params = [];

    // Add WHERE conditions if any
    if (!empty($conditions)) {
      $whereClauses = [];

      foreach ($conditions as $column => $value) {
        $paramName = "condition_{$column}";
        $whereClauses[] = "m.{$column} = :{$paramName}";
        $params[$paramName] = $value;
      }

      $whereClause = " WHERE " . implode(' AND ', $whereClauses);
      $sql .= $whereClause;
      $countSql .= $whereClause;
    }

    // Add ordering and pagination
    $sql .= " ORDER BY m.{$orderBy} {$direction} LIMIT :limit OFFSET :offset";

    $offset = ($page - 1) * $perPage;
    $params['limit'] = $perPage;
    $params['offset'] = $offset;

    // Get the items
    $items = self::$db->query($sql)
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
    return $paginator->setData($items, $totalCount)
      ->setOrderBy($orderBy, $direction)
      ->setPage($page)
      ->setTheme('game');
  }

  public function purchaseItem($userId, $itemId, $quantity = 1)
  {
    // First check if item is available
    $item = $this->GetItemById($itemId);
    if (!$item || (isset($item[0]['status']) && $item[0]['status'] === 'disabled')) {
      return 'Item is not available for purchase.';
    }

    $itemType = $item[0]['item_type'];

    // Check if this is a one-time purchase item (collectibles and equipment)
    $oneTimePurchaseTypes = ['collectible', 'equipment'];
    if (in_array($itemType, $oneTimePurchaseTypes)) {
      // Check if user already owns this item
      $existingItem = self::$db->query("SELECT inventory_id FROM user_inventory WHERE user_id = :user_id AND item_id = :item_id")
        ->bind(['user_id' => $userId, 'item_id' => $itemId])
        ->execute()
        ->fetch();

      if ($existingItem) {
        return 'You already own this ' . $itemType . '. This item can only be purchased once.';
      }

      // Force quantity to 1 for one-time purchase items
      $quantity = 1;
    }

    $totalCost = $item[0]['item_price'] * $quantity;

    // Check if user has enough coins
    $userCoins = self::$db->query("SELECT coins FROM users WHERE id = :user_id")
      ->bind(['user_id' => $userId])
      ->execute()
      ->fetch();

    if (!$userCoins || $userCoins['coins'] < $totalCost) {
      return 'Insufficient coins for this purchase.';
    }

    try {
      // Start transaction
      self::$db->query("START TRANSACTION")->execute();

      // Deduct coins
      self::$db->query("UPDATE users SET coins = coins - :cost WHERE id = :user_id")
        ->bind(['cost' => $totalCost, 'user_id' => $userId])
        ->execute();

      // Check if item already exists in user inventory
      $existingItem = self::$db->query("SELECT inventory_id, quantity FROM user_inventory WHERE user_id = :user_id AND item_id = :item_id")
        ->bind(['user_id' => $userId, 'item_id' => $itemId])
        ->execute()
        ->fetch();

      if ($existingItem) {
        // For multi-purchase items (boosts, consumables), update quantity
        if (in_array($itemType, ['boost', 'consumable'])) {
          self::$db->query("UPDATE user_inventory SET quantity = quantity + :quantity WHERE inventory_id = :inventory_id")
            ->bind(['quantity' => $quantity, 'inventory_id' => $existingItem['inventory_id']])
            ->execute();
        }
        // Note: One-time purchase items won't reach this point due to earlier check
      } else {
        // Insert new item
        self::$db->query("INSERT INTO user_inventory (user_id, item_id, quantity, acquired_at) VALUES (:user_id, :item_id, :quantity, NOW())")
          ->bind(['user_id' => $userId, 'item_id' => $itemId, 'quantity' => $quantity])
          ->execute();
      }

      // Commit transaction
      self::$db->query("COMMIT")->execute();

      if (in_array($itemType, $oneTimePurchaseTypes)) {
        return "Purchase successful! You acquired this {$itemType} for {$totalCost} coins.";
      } else {
        return "Purchase successful! You bought {$quantity} item(s) for {$totalCost} coins.";
      }

    } catch (Exception $e) {
      // Rollback on error
      self::$db->query("ROLLBACK")->execute();
      return 'Purchase failed: ' . $e->getMessage();
    }
  }

  /**
   * Purchase item using stored procedure
   * @param int $userId
   * @param int $itemId  
   * @param int $quantity
   * @return string
   */
  public function purchaseItemUsingStoredProcedure($userId, $itemId, $quantity = 1)
  {
    try {
      // Ensure quantity is at least 1
      $quantity = max(1, (int) $quantity);

      // Call the stored procedure
      $result = self::$db->query("CALL PurchaseMarketplaceItem(:user_id, :item_id, :quantity)")
        ->bind([
          'user_id' => $userId,
          'item_id' => $itemId,
          'quantity' => $quantity
        ])
        ->execute()
        ->fetch();

      // Close cursor to prevent "Commands out of sync" error
      self::$db->closeCursor();

      // Return the message from stored procedure
      return $result['message'] ?? 'Unknown error occurred';

    } catch (Exception $e) {
      return 'Purchase failed: ' . $e->getMessage();
    }
  }

  public function getItemDetails($itemId)
  {
    return self::$db->query("
      SELECT m.*, c.category_name
      FROM marketplace_items m
      LEFT JOIN item_categories c ON m.category_id = c.category_id
      WHERE m.item_id = :item_id
    ")->bind(['item_id' => $itemId])
      ->execute()
      ->fetchAll();
  }

  public function getItemsByCategory($categoryId)
  {
    return self::$db->query("
      SELECT m.*, c.category_name
      FROM marketplace_items m
      LEFT JOIN item_categories c ON m.category_id = c.category_id
      WHERE m.category_id = :category_id
      ORDER BY m.item_price ASC
    ")->bind(['category_id' => $categoryId])
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

  /**
   * Get a count of all marketplace items
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
   * Create a consistent error response
   */
  private function createErrorResponse($message, $effect = null, $itemType = null, $itemName = null)
  {
    return [
      'success' => false,
      'message' => $message,
      'effect' => $effect,
      'itemType' => $itemType,
      'itemName' => $itemName
    ];
  }

  /**
   * Create a consistent success response
   */
  private function createSuccessResponse($message, $effect, $itemType, $itemName)
  {
    return [
      'success' => true,
      'message' => $message,
      'effect' => $effect,
      'itemType' => $itemType,
      'itemName' => $itemName
    ];
  }

  /**
   * Use an inventory item
   * @param int $userId 
   * @param int $inventoryId
   * @return array Result from the stored procedure
   */
  public function useInventoryItem($userId, $inventoryId)
  {
    try {
      // Enhanced validation
      if (!$userId || !$inventoryId || !is_numeric($userId) || !is_numeric($inventoryId)) {
        return $this->createErrorResponse('Invalid user ID or inventory ID');
      }

      // First verify the user has a userstats row
      $userStats = self::$db->query("SELECT id, health FROM userstats WHERE user_id = :user_id")
        ->bind(['user_id' => $userId])
        ->execute()
        ->fetch();

      if (!$userStats) {
        // Create a userstats row if it doesn't exist
        self::$db->query("
          INSERT INTO userstats (user_id, level, xp, health, avatar_id, objective, 
            physicalHealth, mentalWellness, personalGrowth, careerStudies, 
            finance, homeEnvironment, relationshipsSocial, passionHobbies)
          VALUES (:user_id, 1, 0, 100, 1, 'Auto-created', 5, 5, 5, 5, 5, 5, 5, 5)
        ")->bind(['user_id' => $userId])->execute();

        // Fetch the newly created stats
        $userStats = self::$db->query("SELECT id, health FROM userstats WHERE user_id = :user_id")
          ->bind(['user_id' => $userId])
          ->execute()
          ->fetch();
      }

      // Verify the item exists and belongs to the user
      $itemCheck = self::$db->query("
        SELECT i.inventory_id, m.item_type, m.effect_type, m.effect_value, m.item_name
        FROM user_inventory i
        JOIN marketplace_items m ON i.item_id = m.item_id
        WHERE i.inventory_id = :inventory_id AND i.user_id = :user_id
      ")->bind([
            'inventory_id' => $inventoryId,
            'user_id' => $userId
          ])->execute()->fetch();

      if (!$itemCheck) {
        error_log("Item not found or doesn't belong to user. User ID: $userId, Inventory ID: $inventoryId");
        return $this->createErrorResponse(
          'Item not found in your inventory',
          null,
          null,
          null
        );
      }

      // For health items, check if health is already at max
      if ($itemCheck['effect_type'] === 'health' && $userStats['health'] >= 100) {
        return $this->createErrorResponse(
          'Your health is already at maximum',
          'Health is already at maximum',
          $itemCheck['item_type'],
          $itemCheck['item_name']
        );
      }

      // For boost items, check if boost is already active
      if ($itemCheck['item_type'] === 'boost') {
        // Clean up expired boosts first (user-specific for better performance)
        self::$db->query("DELETE FROM user_active_boosts WHERE user_id = :user_id AND expires_at < NOW()")
          ->bind(['user_id' => $userId])
          ->execute();

        $activeBoost = self::$db->query("
          SELECT 1 FROM user_active_boosts 
          WHERE user_id = :user_id 
          AND boost_type = :boost_type 
          AND expires_at > NOW()
        ")->bind([
              'user_id' => $userId,
              'boost_type' => $itemCheck['effect_type']
            ])
          ->execute()
          ->fetch();

        if ($activeBoost) {
          return $this->createErrorResponse(
            'This type of boost is already active',
            'Boost already active',
            $itemCheck['item_type'],
            $itemCheck['item_name']
          );
        }
      }

      // Execute the stored procedure
      $result = self::$db->query("CALL UseInventoryItem(:inventory_id, :user_id)")
        ->bind([
          'inventory_id' => $inventoryId,
          'user_id' => $userId
        ])
        ->execute()
        ->fetchAll();

      // Close the cursor
      self::$db->closeCursor();

      // Debug logging
      error_log("Stored procedure result: " . json_encode($result));

      if (!empty($result)) {
        // Check if the result contains an error message
        if (isset($result[0]['message'])) {
          if (strpos($result[0]['message'], 'SQL Error:') === 0) {
            error_log("SQL Error in UseInventoryItem: " . $result[0]['message']);
            return $this->createErrorResponse(
              'An error occurred while processing the item',
              $result[0]['message'],
              $itemCheck['item_type'],
              $itemCheck['item_name']
            );
          }

          // Check for success message
          if ($result[0]['message'] === 'Item used successfully') {
            $effect = $result[0]['effect'] ?? 'Item used successfully';
            error_log("Item used successfully - User: $userId, Item: {$itemCheck['item_name']}, Effect: $effect");

            return $this->createSuccessResponse(
              $result[0]['message'],
              $effect,
              $itemCheck['item_type'],
              $itemCheck['item_name']
            );
          } else {
            // Any other message is treated as an error
            return $this->createErrorResponse(
              $result[0]['message'],
              null,
              $itemCheck['item_type'],
              $itemCheck['item_name']
            );
          }
        }
      }

      // Log the error for debugging
      error_log("Failed to use item. User ID: $userId, Inventory ID: $inventoryId, Item: {$itemCheck['item_name']}");
      return $this->createErrorResponse(
        'Error processing item',
        'Failed to process item effect',
        $itemCheck['item_type'],
        $itemCheck['item_name']
      );
    } catch (\PDOException $e) {
      // Log the detailed error
      error_log("Error using item: " . $e->getMessage() . "\nStack trace: " . $e->getTraceAsString());
      return $this->createErrorResponse(
        'Database error occurred',
        $e->getMessage(),
        null,
        null
      );
    }
  }
}
