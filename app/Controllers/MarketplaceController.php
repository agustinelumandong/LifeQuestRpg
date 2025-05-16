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

    $ownedItemIds = $currentUser ? (new Inventory())->getOwnedItemIds(Auth::getByUserId()) : [];    // Use pagination with dynamic page parameter
    $paginator = $this->marketplaceModel->paginate(
      page: 1,
      perPage: 12,
      orderBy: 'item_id',
      direction: 'DESC',
      conditions: []
    )->setTheme('game');

    return $this->view('marketplace/index', [
      'title' => 'Marketplace',
      'items' => $paginator->items(),
      'paginator' => $paginator,
      'ownedItemIds' => $ownedItemIds,
      'currentUser' => Auth::user(),
    ]);
  }


  public function create()
  {
    return $this->view('marketplace/create', [
      'title' => 'Create Item',
    ]);
  }

  public function store()
  {
    $currentUser = Auth::isAdmin();

    if (!$currentUser) {
      $_SESSION['error'] = 'You do not have permission to create items.';
      $this->redirect('/marketplace');
    }

    $data = Input::sanitize([
      'item_name' => Input::post('productName'),
      'item_description' => Input::post('productDescription'),
      'item_price' => Input::post('productPrice'),
      'image_url' => Input::post('productImage')
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

    if (!$user_id && empty($user_id)) {
      $_SESSION['error'] = 'User not found.';
      $this->redirect('/marketplace');
    }

    if (!$item_id && empty($item_id)) {
      $_SESSION['error'] = 'Invalid item ID.';
      $this->redirect('/marketplace');
    }

    try {
      $message = $this->marketplaceModel->purchaseItem($user_id, $item_id);

      if ($message === 'Purchase successful!') {
        $_SESSION['success'] = 'Item purchased successfully!';
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
      'image_url' => Input::post('productImage')
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

}