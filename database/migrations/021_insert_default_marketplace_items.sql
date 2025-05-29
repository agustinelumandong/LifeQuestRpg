-- Insert default marketplace items
INSERT INTO `marketplace_items` (
    `item_id`,
    `item_name`,
    `item_description`,
    `item_price`,
    `image_url`,
    `category_id`,
    `item_type`,
    `effect_type`,
    `effect_value`,
    `durability`,
    `cooldown_period`
  )
VALUES (
    1,
    'Health Potion',
    'Restores 25 health points',
    10.00,
    'assets/images/items/health_potion.png',
    1,
    'consumable',
    'health',
    25,
    NULL,
    NULL
  ),
  (
    2,
    'XP Booster',
    'Increases XP gain by 50% for 24 hours',
    50.00,
    'assets/images/items/xp_booster.png',
    4,
    'boost',
    'xp',
    50,
    NULL,
    86400
  ),
  (
    3,
    'Focus Crystal',
    'Increases productivity boost by 25% for 24 hours',
    75.00,
    'assets/images/items/focus_crystal.png',
    4,
    'boost',
    'productivity',
    25,
    NULL,
    86400
  ),
  (
    4,
    'Golden Trophy',
    'A prestigious trophy for your collection',
    100.00,
    'assets/images/items/golden_trophy.png',
    3,
    'collectible',
    NULL,
    NULL,
    NULL,
    NULL
  );