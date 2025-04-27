
CREATE DATABASE IF NOT EXISTS `prac_ddbbs`;
USE `prac_ddbbs`;
-- --------------------------------------------------------
-- Core Tables
-- --------------------------------------------------------
-- --------------------------------------------------------
-- User Stats
-- --------------------------------------------------------
CREATE TABLE `users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `email` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `role` enum(' admin ', ' user ') DEFAULT ' user ',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- User Stats
-- --------------------------------------------------------
CREATE TABLE `userstats` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `level` int NOT NULL DEFAULT 1,
  `xp` int NOT NULL DEFAULT 0,
  `coins` int DEFAULT 0,
  `health` int DEFAULT 100,
  PRIMARY KEY (`id`),
  KEY `fk_userstats_user` (`user_id`),
  CONSTRAINT `fk_userstats_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- --------------------------------------------------------
-- Task Event
-- --------------------------------------------------------
CREATE TABLE `user_event` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `event_name` varchar(255) NOT NULL,
  `event_description` text NOT NULL,
  `start_date` timestamp NOT NULL,
  `end_date` timestamp NOT NULL,
  `reward_xp` int NOT NULL DEFAULT 0,
  `reward_coins` int NOT NULL DEFAULT 0,
  `status` enum('active', 'inactive') DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_user_event_user` (`user_id`),
  CONSTRAINT `fk_user_event_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- --------------------------------------------------------
-- user event completions
-- --------------------------------------------------------
CREATE TABLE `user_event_completions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `event_name` varchar(255) NOT NULL,
  `completed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_user_event_completions_user` (`user_id`),
  CONSTRAINT `fk_user_event_completions_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- --------------------------------------------------------
-- Task Management
-- --------------------------------------------------------
CREATE TABLE `tasks` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `title` varchar(255) NOT NULL,
  `status` enum(' pending ', ' completed ') DEFAULT ' pending ',
  `difficulty` enum(' easy ', ' medium ', ' hard ') DEFAULT ' easy ',
  PRIMARY KEY (`id`),
  KEY `fk_tasks_user` (`user_id`),
  CONSTRAINT `fk_tasks_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- --------------------------------------------------------
-- Task Management
-- --------------------------------------------------------
CREATE TABLE `daily_tasks` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `title` varchar(255) NOT NULL,
  `status` enum(' pending ', ' completed ') DEFAULT ' pending ',
  `difficulty` enum(' easy ', ' medium ', ' hard ') NOT NULL,
  `last_reset` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_dailytasks_user` (`user_id`),
  CONSTRAINT `fk_dailytasks_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- --------------------------------------------------------
-- Streaks
-- --------------------------------------------------------
CREATE TABLE `streaks` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `streak_type` enum('check_in', 'task_completion') NOT NULL,
  `current_streak` int NOT NULL DEFAULT 0,
  -- Fixed typo
  `longest_streak` int NOT NULL DEFAULT 0,
  `last_streak_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_streaks_user` (`user_id`),
  CONSTRAINT `fk_streaks_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- --------------------------------------------------------
-- Marketplace System
-- --------------------------------------------------------
CREATE TABLE `marketplace_items` (
  `item_id` int NOT NULL AUTO_INCREMENT,
  `item_name` varchar(255) NOT NULL,
  `item_description` text,
  `item_price` decimal(10, 2) NOT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`item_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
CREATE TABLE `user_inventory` (
  `inventory_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `item_id` int NOT NULL,
  PRIMARY KEY (`inventory_id`),
  KEY `fk_inventory_user` (`user_id`),
  KEY `fk_inventory_item` (`item_id`),
  CONSTRAINT `fk_inventory_item` FOREIGN KEY (`item_id`) REFERENCES `marketplace_items` (`item_id`),
  CONSTRAINT `fk_inventory_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- --------------------------------------------------------
-- Activity Tracking
-- --------------------------------------------------------
CREATE TABLE `activity_log` (
  `log_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `activity_type` varchar(50) NOT NULL,
  `activity_details` json DEFAULT NULL,
  `log_timestamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`log_id`),
  KEY `idx_activity_user` (`user_id`),
  KEY `idx_activity_time` (`log_timestamp`),
  CONSTRAINT `fk_log_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- --------------------------------------------------------
-- Triggers & Procedures
-- --------------------------------------------------------
DELIMITER $$ CREATE TRIGGER `after_task_complete`
AFTER
UPDATE ON `tasks` FOR EACH ROW BEGIN IF NEW.status = 'completed'
  AND OLD.status != 'completed' THEN
INSERT INTO `activity_log` (
    `user_id`,
    `activity_type`,
    `activity_details`,
    `log_timestamp`
  )
VALUES (
    NEW.user_id,
    'Task Completed',
    JSON_OBJECT(
      'task_id',
      NEW.id,
      'title',
      NEW.title,
      'difficulty',
      NEW.difficulty
    ),
    NOW()
  );
END IF;
END $$
DELIMITER ;

DELIMITER $$ 
CREATE TRIGGER `after_level_up`
AFTER
UPDATE ON `userstats` FOR EACH ROW BEGIN IF NEW.level > OLD.level THEN
INSERT INTO `activity_log` (
    `user_id`,
    `activity_type`,
    `activity_details`,
    `log_timestamp`
  )
VALUES (
    NEW.user_id,
    'Level Up',
    JSON_OBJECT('new_level', NEW.level),
    NOW()
  );
END IF;
END $$ 
DELIMITER ;
DELIMITER $$

CREATE TRIGGER `after_inventory_insert`
AFTER
INSERT ON `user_inventory` FOR EACH ROW BEGIN
DECLARE item_name_var VARCHAR(255);
SELECT item_name INTO item_name_var
FROM marketplace_items
WHERE item_id = NEW.item_id;
INSERT INTO activity_log (user_id, activity_type, activity_details)
VALUES (
    NEW.user_id,
    ' ITEM_PURCHASED ',
    JSON_OBJECT(
      ' item_id ',
      NEW.item_id,
      ' item_name ',
      item_name_var
    )
  );
END $$ 
DELIMITER ;
-- Trigger to log user creation
DELIMITER $$ CREATE TRIGGER `after_user_insert`
AFTER
INSERT ON `users` FOR EACH ROW BEGIN
INSERT INTO `userstats` (`user_id`, `level`, `xp`, `coins`, `health`)
VALUES (NEW.id, 1, 0, 0, 100);
END $$ 
DELIMITER ;
-- Purchase Procedure
DELIMITER $$ CREATE PROCEDURE `PurchaseMarketplaceItem` (IN `p_user_id` INT, IN `p_item_id` INT) proc: BEGIN
DECLARE v_item_price DECIMAL(10, 2);
DECLARE v_user_coins INT;
-- Changed to INT to match userstats.coins
DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK;
SELECT 'Transaction failed' AS message;
END;
START TRANSACTION;
-- Validate item existence
IF NOT EXISTS (
  SELECT 1
  FROM `marketplace_items`
  WHERE `item_id` = p_item_id
) THEN ROLLBACK;
SELECT 'Item not found' AS message;
LEAVE proc;
END IF;
-- Get pricing info
SELECT `item_price` INTO v_item_price
FROM `marketplace_items`
WHERE `item_id` = p_item_id;
-- Check user balance
SELECT `coins` INTO v_user_coins
FROM `userstats`
WHERE `user_id` = p_user_id;
-- Validate funds
IF v_user_coins < v_item_price THEN ROLLBACK;
SELECT 'Insufficient coins' AS message;
LEAVE proc;
END IF;
-- Check existing ownership
IF EXISTS (
  SELECT 1
  FROM `user_inventory`
  WHERE `user_id` = p_user_id
    AND `item_id` = p_item_id
) THEN ROLLBACK;
SELECT 'Item already owned' AS message;
LEAVE proc;
END IF;
-- Execute transaction
UPDATE `userstats`
SET `coins` = `coins` - v_item_price
WHERE `user_id` = p_user_id;
INSERT INTO `user_inventory` (`user_id`, `item_id`)
VALUES (p_user_id, p_item_id);
COMMIT;
SELECT 'Purchase successful!' AS message;
END $$ 
DELIMITER ;