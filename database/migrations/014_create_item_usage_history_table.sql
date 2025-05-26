-- Create item_usage_history table
CREATE TABLE `item_usage_history` (
  `usage_id` int NOT NULL AUTO_INCREMENT,
  `inventory_id` int NOT NULL,
  `used_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `effect_applied` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`usage_id`),
  KEY `fk_usage_inventory` (`inventory_id`),
  CONSTRAINT `fk_usage_inventory` FOREIGN KEY (`inventory_id`) REFERENCES `user_inventory` (`inventory_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;