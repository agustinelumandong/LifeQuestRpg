-- Insert default item categories
INSERT INTO `item_categories` (
    `category_id`,
    `category_name`,
    `category_description`,
    `icon`
  )
VALUES (
    1,
    'Consumables',
    'Items that can be consumed for temporary benefits',
    'fa-flask'
  ),
  (
    2,
    'Equipment',
    'Permanent items that enhance character abilities',
    'fa-shield'
  ),
  (
    3,
    'Collectibles',
    'Special items for collection and display',
    'fa-gem'
  ),
  (
    4,
    'Boosts',
    'Temporary enhancement items',
    'fa-bolt'
  );