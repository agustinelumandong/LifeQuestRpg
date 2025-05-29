<?php

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Controller;
use App\Core\Input;
use App\Models\Marketplace;
use App\Models\Inventory;
use Exception;

class MarketplaceController extends Controller
{

  protected $marketplaceModel;

  public function __construct()
  {
    $this->marketplaceModel = new Marketplace();

  }
  public function index()
  {
    $currentUser = Auth::user();
    if (!$currentUser) {
      $_SESSION['error'] = 'You must be logged in to view the marketplace.';
      $this->redirect('/login');
    }

    $ownedItemIds = $currentUser ? (new Inventory())->getOwnedItemIds(Auth::getByUserId()) : [];

    // Get categories for filtering
    $categories = $this->marketplaceModel->getAllCategories();
    $selectedCategory = Input::get('category', 'all');

    // Set conditions based on category filter
    $conditions = [];
    if ($selectedCategory !== 'all' && is_numeric($selectedCategory)) {
      $conditions['category_id'] = $selectedCategory;
    }

    // Use custom pagination method with proper JOIN for category information
    $paginator = $this->marketplaceModel->getPaginatedItems(
      page: Input::get('page', 1),
      perPage: 12,
      orderBy: 'item_id',
      direction: 'DESC',
      conditions: $conditions
    );

    return $this->view('marketplace/index', [
      'title' => 'Marketplace',
      'items' => $paginator->items(),
      'paginator' => $paginator,
      'ownedItemIds' => $ownedItemIds,
      'currentUser' => Auth::user(),
      'userCoins' => $currentUser['coins'] ?? 0,
      'categories' => $categories,
      'selectedCategory' => $selectedCategory
    ]);
  }

  public function create()
  {
    if (!Auth::isAdmin()) {
      $_SESSION['error'] = 'You do not have permission to create items.';
      return $this->redirect('/marketplace');
    }

    $categories = $this->marketplaceModel->getAllCategories();

    return $this->view('marketplace/create', [
      'title' => 'Create Item',
      'categories' => $categories,
      'itemTypes' => ['consumable', 'equipment', 'collectible', 'boost']
    ]);
  }
  public function store()
  {
    $currentUser = Auth::isAdmin();

    if (!$currentUser) {
      $_SESSION['error'] = 'You do not have permission to create items.';
      $this->redirect('/marketplace');
    }

    // Validate required fields
    if (
      !Input::post('productName') ||
      !Input::post('productPrice')
    ) {
      $_SESSION['error'] = 'Product name and price are required!';
      return $this->redirect('/marketplace/create');
    }

    $data = Input::sanitize([
      'item_name' => Input::post('productName'),
      'item_description' => Input::post('productDescription'),
      'item_price' => Input::post('productPrice'),
      'image_url' => Input::post('productImage'),
      'category_id' => Input::post('category'),
      'item_type' => Input::post('itemType'),
      'effect_type' => Input::post('effectType'),
      'effect_value' => Input::post('effectValue')
    ]);

    $create = $this->marketplaceModel->create($data);
    if ($create) {
      $_SESSION['success'] = 'Item created successfully!';
      $this->redirect('/marketplace');
    } else {
      $_SESSION['error'] = 'Failed to create item.';
      $this->redirect('/marketplace/create');
    }
  }


  public function purchase($user_id, $item_id)
  {
    if (!Auth::check()) {
      $_SESSION['error'] = 'You must be logged in to purchase items.';
      $this->redirect('/login');
    }

    if (!$user_id || empty($user_id)) {
      $_SESSION['error'] = 'User not found.';
      $this->redirect('/marketplace');
    }

    if (!$item_id || empty($item_id)) {
      $_SESSION['error'] = 'Invalid item ID.';
      $this->redirect('/marketplace');
    }

    try {
      // Get quantity from POST if available, otherwise default to 1
      $quantity = Input::post('quantity', 1);
      $quantity = max(1, min(10, (int) $quantity)); // Limit between 1 and 10

      $message = $this->marketplaceModel->purchaseItem($user_id, $item_id, $quantity);

      if (strpos($message, 'Purchase successful!') === 0) {
        $_SESSION['success'] = $message;
      } else {
        $_SESSION['error'] = $message;
      }

    } catch (Exception $e) {
      $_SESSION['error'] = 'Failed to purchase item: ' . $e->getMessage();
    }

    $this->redirect('/marketplace');
  }

  public function edit($id)
  {
    if (!Auth::isAdmin()) {
      $_SESSION['error'] = 'You do not have permission to delete items.';
      $this->redirect('/marketplace');
    }

    $item = $this->marketplaceModel->GetItemById($id);
    $items = $this->marketplaceModel->findBy('item_id', $id);
    if (!$item) {
      $_SESSION['error'] = 'Item not found!';
      $this->redirect('/marketplace');
    }

    return $this->view('marketplace/edit', [
      'title' => 'Edit Product',
      'content' => 'Edit product details',
      'item' => $item,
      'items' => $items
    ]);
  }
  public function update($id)
  {
    if (!Auth::isAdmin()) {
      $_SESSION['error'] = 'You do not have permission to delete items.';
      $this->redirect('/marketplace');
    }
    // Validate the form
    if (
      !Input::post('productName') ||
      !Input::post('productPrice')
    ) {
      $_SESSION['error'] = 'Product Name and Product Price fields are required!';
      $this->redirect('/marketplace/edit/' . $id);
    }

    $item = Input::sanitize([
      'item_name' => Input::post('productName'),
      'item_description' => Input::post('productDescription'),
      'item_price' => Input::post('productPrice'),
      'image_url' => Input::post('productImage'),
      'category_id' => Input::post('category'),
      'item_type' => Input::post('itemType'),
      'effect_type' => Input::post('effectType'),
      'effect_value' => Input::post('effectValue'),
      'durability' => Input::post('durability'),
      'cooldown_period' => Input::post('cooldownPeriod')
    ]);


    $updated = $this->marketplaceModel->update($id, $item);


    if ($updated) {
      $_SESSION['success'] = 'Item updated successfully!';
      $this->redirect('/marketplace');
    } else {
      $_SESSION['error'] = 'Failed to update item!';
      $this->redirect('/marketplace/edit/' . $id);
    }
  }

  public function delete($id)
  {
    if (!Auth::isAdmin()) {
      $_SESSION['error'] = 'You do not have permission to delete items.';
      $this->redirect('/marketplace');
    }


    $item = $this->marketplaceModel->find($id);
    if (!$item) {
      $_SESSION['error'] = 'Item not found!';
      $this->redirect('/marketplace');
    }


    $deleted = $this->marketplaceModel->delete($id);


    if ($deleted) {
      $_SESSION['success'] = 'Item deleted successfully!';
    } else {
      $_SESSION['error'] = 'Failed to delete item!';
    }


    $this->redirect('/marketplace');
  }

  public function inventory()
  {
    if (!Auth::check()) {
      $_SESSION['error'] = 'You must be logged in to view your inventory.';
      return $this->redirect('/login');
    }

    $userId = Auth::getByUserId();
    $inventoryModel = new Inventory();

    $paginator = $inventoryModel->getPaginatedUserItems(
      $userId,
      page: Input::get('page', 1),
      perPage: 12
    );

    // Get usage history for display in inventory
    $usageHistory = $inventoryModel->getItemUsageHistory($userId, 5);

    // Get inventory summary and total value
    $inventorySummary = $inventoryModel->getInventorySummary($userId);
    $totalInventoryValue = $inventoryModel->getTotalInventoryValue($userId);
    $totalItemCount = $inventoryModel->getUserItemCount($userId);

    return $this->view('marketplace/inventory', [
      'title' => 'My Inventory',
      'items' => $paginator->items(),
      'paginator' => $paginator,
      'usageHistory' => $usageHistory,
      'currentUser' => Auth::user(),
      'inventorySummary' => $inventorySummary,
      'totalInventoryValue' => $totalInventoryValue,
      'totalItemCount' => $totalItemCount
    ]);
  }
  public function useItem($inventory_id)
  {
    if (!Auth::check()) {
      $_SESSION['error'] = 'You must be logged in to use items.';
      return $this->json(['success' => false, 'message' => 'Authentication required']);
    }

    try {
      // Get inventory item details first to validate ownership
      $inventoryModel = new Inventory();
      $item = $inventoryModel->getItemByInventoryId($inventory_id);

      if (!$item || $item['user_id'] != Auth::getByUserId()) {
        return $this->json(['success' => false, 'message' => 'Item not found in your inventory']);
      }

      // Check if the item is usable
      $usableTypes = ['consumable', 'boost', 'equipment'];
      if (!in_array($item['item_type'], $usableTypes)) {
        return $this->json([
          'success' => false,
          'message' => 'This item type cannot be used directly',
          'itemType' => $item['item_type']
        ]);
      }

      // Use the item through the stored procedure
      $result = $this->marketplaceModel->useInventoryItem(Auth::getByUserId(), $inventory_id);

      // Record activity if item was used successfully
      if ($result['message'] === 'Item used successfully') {
        $activityLog = new \App\Models\ActivityLog();
        $activityLog->logActivity(
          Auth::getByUserId(),
          'item_use',
          "Used item: " . $item['item_name'],
          json_encode([
            'item_id' => $item['item_id'],
            'item_type' => $item['item_type'],
            'effect' => $result['effect']
          ])
        );
      }

      return $this->json([
        'success' => $result['message'] === 'Item used successfully',
        'message' => $result['message'],
        'effect' => $result['effect'] ?? null,
        'itemType' => $item['item_type'] ?? null,
        'itemName' => $item['item_name'] ?? null
      ]);
    } catch (Exception $e) {
      return $this->json(['success' => false, 'message' => $e->getMessage()]);
    }
  }
}