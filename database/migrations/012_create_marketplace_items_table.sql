-- Create marketplace_items table
CREATE TABLE `marketplace_items` (
  `item_id` int NOT NULL AUTO_INCREMENT,
  `item_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `item_description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `item_price` decimal(10, 2) NOT NULL,
  `image_url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `category_id` int DEFAULT NULL,
  `item_type` enum(
    'consumable',
    'equipment',
    'collectible',
    'boost'
  ) COLLATE utf8mb4_unicode_ci DEFAULT 'collectible',
  `effect_type` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `effect_value` int DEFAULT NULL,
  `durability` int DEFAULT NULL,
  `cooldown_period` int DEFAULT NULL,
  PRIMARY KEY (`item_id`),
  KEY `fk_item_category` (`category_id`),
  CONSTRAINT `fk_item_category` FOREIGN KEY (`category_id`) REFERENCES `item_categories` (`category_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;