/*
 * LifeQuestRPG Database Migration Script
 * 
 * This script will create and populate the database for LifeQuestRPG application.
 * Run this file in your MySQL client or in phpMyAdmin to set up the database.
 *
 * Usage: 
 * - In phpMyAdmin: Import this file
 * - In MySQL command line: source lifequestrpg.sql
 * - In other SQL clients: Execute this file
 */

-- Ensure safe migration by disabling foreign key checks initially
SET FOREIGN_KEY_CHECKS=0;
SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

-- -----------------------------------------------------
-- DATABASE CREATION
-- -----------------------------------------------------
DROP DATABASE IF EXISTS `lifequestrpg`;
CREATE DATABASE IF NOT EXISTS `lifequestrpg` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `lifequestrpg`;

-- -----------------------------------------------------
-- TABLE STRUCTURE
-- -----------------------------------------------------

-- Activity Log table
CREATE TABLE `activity_log` (
  `log_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `activity_type` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `activity_details` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `log_timestamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`log_id`),
  KEY `idx_activity_user` (`user_id`),
  KEY `idx_activity_time` (`log_timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Avatars table
CREATE TABLE `avatars` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `image_path` varchar(255) NOT NULL,
  `category` varchar(50) DEFAULT NULL COMMENT 'e.g., warrior, mage, rogue',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Bad Habits table
CREATE TABLE `badhabits` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `title` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `status` enum('pending','completed') COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'pending',
  `difficulty` enum('easy','medium','hard') COLLATE utf8mb4_general_ci NOT NULL,
  `category` enum('Physical Health','Mental Wellness','Personal Growth','Career / Studies','Finance','Home Environment','Relationships Social','Passion Hobbies') COLLATE utf8mb4_general_ci NOT NULL,
  `coins` int NOT NULL,
  `xp` int NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Daily Tasks table
CREATE TABLE `dailytasks` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `title` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` enum('pending','completed') COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `difficulty` enum('easy','medium','hard') COLLATE utf8mb4_unicode_ci NOT NULL,
  `category` enum('Physical Health','Mental Wellness','Personal Growth','Career / Studies','Finance','Home Environment','Relationships Social','Passion Hobbies') COLLATE utf8mb4_unicode_ci NOT NULL,
  `coins` int DEFAULT '0',
  `xp` int DEFAULT '0',
  `last_reset` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_dailytasks_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Good Habits table
CREATE TABLE `goodhabits` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `title` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `difficulty` enum('easy','medium','hard') COLLATE utf8mb4_general_ci NOT NULL,
  `category` enum('Physical Health','Mental Wellness','Personal Growth','Career / Studies','Finance','Home Environment','Relationships Social','Passion Hobbies') COLLATE utf8mb4_general_ci NOT NULL,
  `status` enum('pending','completed') COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'pending',
  `coins` int DEFAULT '0',
  `xp` int DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Journals table
CREATE TABLE `journals` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `title` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `content` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `date` date NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_journals_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Marketplace Items table
CREATE TABLE `marketplace_items` (
  `item_id` int NOT NULL AUTO_INCREMENT,
  `item_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `item_description` text COLLATE utf8mb4_unicode_ci,
  `item_price` decimal(10,2) NOT NULL,
  `image_url` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Streaks table
CREATE TABLE `streaks` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `streak_type` enum('check_in','task_completion','dailtask_completion','GoodHabits_completion','journal_writing') COLLATE utf8mb4_unicode_ci NOT NULL,
  `current_streak` int NOT NULL DEFAULT '0',
  `longest_streak` int NOT NULL DEFAULT '0',
  `last_streak_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `next_expected_date` date DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_streaks_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tasks table
CREATE TABLE `tasks` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `title` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` enum('pending','completed') COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `difficulty` enum('easy','medium','hard') COLLATE utf8mb4_unicode_ci DEFAULT 'easy',
  `category` enum('Physical Health','Mental Wellness','Personal Growth','Career / Studies','Finance','Home Environment','Relationships Social','Passion Hobbies') COLLATE utf8mb4_unicode_ci NOT NULL,
  `coins` int DEFAULT '0',
  `xp` int DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `fk_tasks_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Test Data table
CREATE TABLE `test_data` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `description` text,
  `category` varchar(50) DEFAULT NULL,
  `price` decimal(10,2) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Users table
CREATE TABLE `users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `username` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `password` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `role` enum('admin','user') COLLATE utf8mb4_unicode_ci DEFAULT 'user',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `coins` int DEFAULT '0',
  `character_created` tinyint(1) DEFAULT '0' COMMENT 'Tracks if character setup is complete',
  `email_notifications` tinyint(1) DEFAULT '1',
  `task_reminders` tinyint(1) DEFAULT '1',
  `achievement_alerts` tinyint(1) DEFAULT '1',
  `theme` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'light',
  `color_scheme` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'default',
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`),
  UNIQUE KEY `username_UNIQUE` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- User Stats table
CREATE TABLE `userstats` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int DEFAULT NULL,
  `level` int NOT NULL,
  `xp` int NOT NULL,
  `health` int DEFAULT '3',
  `avatar_id` int DEFAULT NULL,
  `objective` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `physicalHealth` int DEFAULT '5',
  `mentalWellness` int DEFAULT '5',
  `personalGrowth` int DEFAULT '5',
  `careerStudies` int DEFAULT '5',
  `finance` int DEFAULT '5',
  `homeEnvironment` int DEFAULT '5',
  `relationshipsSocial` int DEFAULT '5',
  `passionHobbies` int DEFAULT '5',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- User Event table
CREATE TABLE `user_event` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `event_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `event_description` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `start_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `end_date` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `reward_xp` int NOT NULL DEFAULT '0',
  `reward_coins` int NOT NULL DEFAULT '0',
  `status` enum('active','inactive') COLLATE utf8mb4_unicode_ci DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_user_event_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- User Event Completions table
CREATE TABLE `user_event_completions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `event_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `completed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_user_event_completions_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- User Inventory table
CREATE TABLE `user_inventory` (
  `inventory_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `item_id` int NOT NULL,
  PRIMARY KEY (`inventory_id`),
  KEY `fk_inventory_user` (`user_id`),
  KEY `fk_inventory_item` (`item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------
-- STORED PROCEDURES
-- -----------------------------------------------------

DELIMITER $$

CREATE PROCEDURE `log_poke` (IN `target_user_id` INT, IN `poker_user_id` INT, IN `poker_username` VARCHAR(255))
BEGIN
    INSERT INTO activity_log (
        user_id,
        activity_type,
        activity_details,
        log_timestamp
    )
    VALUES (
        target_user_id,
        'User Poked',
        JSON_OBJECT(
            'poker_id', poker_user_id,
            'poker_name', poker_username
        ),
        NOW()
    );
    SELECT ROW_COUNT() AS success;
END$$

CREATE PROCEDURE `PurchaseMarketplaceItem` (IN `p_user_id` INT, IN `p_item_id` INT)
proc: BEGIN
    DECLARE v_item_price DECIMAL(10, 2);
    DECLARE v_user_coins INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        SELECT 'Transaction failed' AS message;
    END;
    
    START TRANSACTION;
    
    -- Validate item existence
    IF NOT EXISTS(
        SELECT 1
        FROM `marketplace_items`
        WHERE `item_id` = p_item_id
    ) THEN
        SELECT 'Item not found' AS message;
        ROLLBACK;
        LEAVE proc;
    END IF;
    
    -- Get pricing info
    SELECT `item_price`
    INTO v_item_price
    FROM `marketplace_items`
    WHERE `item_id` = p_item_id;
    
    -- Check user balance
    SELECT `coins`
    INTO v_user_coins
    FROM `users`
    WHERE `id` = p_user_id;
    
    -- Validate funds
    IF v_user_coins < v_item_price THEN
        SELECT 'Insufficient coins' AS message;
        ROLLBACK;
        LEAVE proc;
    END IF;
    
    -- Check existing ownership
    IF EXISTS(
        SELECT 1
        FROM `user_inventory`
        WHERE `user_id` = p_user_id 
        AND `item_id` = p_item_id
    ) THEN
        SELECT 'Item already owned' AS message;
        ROLLBACK;
        LEAVE proc;
    END IF;
    
    -- Execute transaction
    UPDATE `users`
    SET `coins` = `coins` - v_item_price
    WHERE `id` = p_user_id;
    
    INSERT INTO `user_inventory`(`user_id`, `item_id`)
    VALUES(p_user_id, p_item_id);
    
    COMMIT;
    SELECT 'Purchase successful!' AS message;
END$$

DELIMITER ;

-- -----------------------------------------------------
-- TRIGGERS
-- -----------------------------------------------------

DELIMITER $$

CREATE TRIGGER `after_bad_habits_completion` AFTER UPDATE ON `badhabits` FOR EACH ROW
BEGIN
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        INSERT INTO activity_log (
            user_id,
            activity_type,
            activity_details,
            log_timestamp
        )
        VALUES (
            NEW.user_id,
            'Bad Habit Logged',
            JSON_OBJECT(
                'task_id', NEW.id,
                'title', NEW.title,
                'difficulty', NEW.difficulty,
                'category', NEW.category,
                'coins', NEW.coins,
                'xp', NEW.xp
            ),
            NOW()
        );
    END IF;
END$$

CREATE TRIGGER `after_dailytask_completion` AFTER UPDATE ON `dailytasks` FOR EACH ROW
BEGIN
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        INSERT INTO activity_log (user_id, activity_type, activity_details, log_timestamp)
        VALUES (
            NEW.user_id,
            'Daily Task Completed',
            JSON_OBJECT(
                'task_id', NEW.id,
                'title', NEW.title,
                'difficulty', NEW.difficulty,
                'category', NEW.category,
                'coins', NEW.coins,
                'xp', NEW.xp
            ),
            NOW()
        );
    END IF;
END$$

CREATE TRIGGER `after_good_habits_completion` AFTER UPDATE ON `goodhabits` FOR EACH ROW
BEGIN
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        INSERT INTO activity_log (
            user_id,
            activity_type,
            activity_details,
            log_timestamp
        )
        VALUES (
            NEW.user_id,
            'Good Habit Logged',
            JSON_OBJECT(
                'task_id', NEW.id,
                'title', NEW.title,
                'difficulty', NEW.difficulty,
                'category', NEW.category,
                'coins', NEW.coins,
                'xp', NEW.xp
            ),
            NOW()
        );
    END IF;
END$$

CREATE TRIGGER `after_task_completion` AFTER UPDATE ON `tasks` FOR EACH ROW
BEGIN
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        INSERT INTO activity_log (user_id, activity_type, activity_details, log_timestamp)
        VALUES (
            NEW.user_id,
            'Task Completed',
            JSON_OBJECT(
                'task_id', NEW.id,
                'title', NEW.title,
                'difficulty', NEW.difficulty,
                'category', NEW.category,
                'coins', NEW.coins,
                'xp', NEW.xp
            ),
            NOW()
        );
    END IF;
END$$

CREATE TRIGGER `after_inventory_insert` AFTER INSERT ON `user_inventory` FOR EACH ROW
BEGIN
  DECLARE item_name_var VARCHAR(255);
  SELECT item_name INTO item_name_var
  FROM marketplace_items
  WHERE item_id = NEW.item_id;
  
  INSERT INTO activity_log (user_id, activity_type, activity_details)
  VALUES (
    NEW.user_id,
    'ITEM_PURCHASED',
    JSON_OBJECT(
      'item_id',
      NEW.item_id,
      'item_name',
      item_name_var
    )
  );
END$$

DELIMITER ;

-- -----------------------------------------------------
-- VIEWS
-- -----------------------------------------------------

CREATE VIEW `streaks_view` AS 
SELECT 
  `streaks`.`id` AS `id`, 
  `streaks`.`user_id` AS `user_id`, 
  `streaks`.`streak_type` AS `streak_type`, 
  `streaks`.`current_streak` AS `current_streak`, 
  `streaks`.`longest_streak` AS `longest_streak`, 
  `streaks`.`last_streak_date` AS `last_streak_date`, 
  `streaks`.`last_streak_date` AS `last_activity_date`, 
  `streaks`.`next_expected_date` AS `next_expected_date` 
FROM `streaks`;

CREATE VIEW `user_items` AS 
SELECT 
  `u`.`id` AS `user_id`, 
  `mi`.`item_name` AS `item_name` 
FROM (
  `users` `u` 
  JOIN `user_inventory` `ui` ON (`u`.`id` = `ui`.`user_id`)
  JOIN `marketplace_items` `mi` ON (`ui`.`item_id` = `mi`.`item_id`)
);

CREATE VIEW `view_bad_habits_activity` AS 
SELECT 
  `a`.`log_id` AS `log_id`, 
  `a`.`user_id` AS `user_id`, 
  json_unquote(json_extract(`a`.`activity_details`,'$.title')) AS `activity_title`, 
  json_unquote(json_extract(`a`.`activity_details`,'$.difficulty')) AS `difficulty`, 
  json_unquote(json_extract(`a`.`activity_details`,'$.category')) AS `category`, 
  json_unquote(json_extract(`a`.`activity_details`,'$.coins')) AS `coins`, 
  json_unquote(json_extract(`a`.`activity_details`,'$.xp')) AS `xp`, 
  `a`.`log_timestamp` AS `log_timestamp` 
FROM (`activity_log` `a` JOIN `users` `u` ON (`a`.`user_id` = `u`.`id`)) 
WHERE (`a`.`activity_type` = 'Bad Habit Logged');

CREATE VIEW `view_daily_task_activity` AS 
SELECT 
  `a`.`log_id` AS `log_id`, 
  `a`.`user_id` AS `user_id`, 
  json_unquote(json_extract(`a`.`activity_details`,'$.title')) AS `task_title`, 
  json_unquote(json_extract(`a`.`activity_details`,'$.difficulty')) AS `difficulty`, 
  json_unquote(json_extract(`a`.`activity_details`,'$.category')) AS `category`, 
  json_unquote(json_extract(`a`.`activity_details`,'$.coins')) AS `coins`, 
  json_unquote(json_extract(`a`.`activity_details`,'$.xp')) AS `xp`, 
  `a`.`log_timestamp` AS `log_timestamp` 
FROM (`activity_log` `a` JOIN `users` `u` ON (`a`.`user_id` = `u`.`id`)) 
WHERE (`a`.`activity_type` = 'Daily Task Completed');

CREATE VIEW `view_good_habits_activity` AS 
SELECT 
  `a`.`log_id` AS `log_id`, 
  `a`.`user_id` AS `user_id`, 
  json_unquote(json_extract(`a`.`activity_details`,'$.title')) AS `activity_title`, 
  json_unquote(json_extract(`a`.`activity_details`,'$.difficulty')) AS `difficulty`, 
  json_unquote(json_extract(`a`.`activity_details`,'$.category')) AS `category`, 
  json_unquote(json_extract(`a`.`activity_details`,'$.coins')) AS `coins`, 
  json_unquote(json_extract(`a`.`activity_details`,'$.xp')) AS `xp`, 
  `a`.`log_timestamp` AS `log_timestamp` 
FROM (`activity_log` `a` JOIN `users` `u` ON (`a`.`user_id` = `u`.`id`)) 
WHERE (`a`.`activity_type` = 'Good Habit Logged');

CREATE VIEW `view_poke_activity` AS 
SELECT 
  `a`.`log_id` AS `log_id`, 
  `a`.`user_id` AS `target_user_id`, 
  json_unquote(json_extract(`a`.`activity_details`,'$.poker_id')) AS `poker_user_id`, 
  json_unquote(json_extract(`a`.`activity_details`,'$.poker_name')) AS `poker_username`, 
  `a`.`log_timestamp` AS `poke_timestamp`, 
  `u1`.`username` AS `target_username`, 
  `u2`.`username` AS `poker_username_from_users` 
FROM (
  `activity_log` `a` 
  JOIN `users` `u1` ON (`a`.`user_id` = `u1`.`id`)
  LEFT JOIN `users` `u2` ON (json_unquote(json_extract(`a`.`activity_details`,'$.poker_id')) = `u2`.`id`)
) 
WHERE (`a`.`activity_type` = 'User Poked');

CREATE VIEW `view_task_activity` AS 
SELECT 
  `a`.`log_id` AS `log_id`, 
  `a`.`user_id` AS `user_id`, 
  json_unquote(json_extract(`a`.`activity_details`,'$.title')) AS `task_title`, 
  json_unquote(json_extract(`a`.`activity_details`,'$.difficulty')) AS `difficulty`, 
  json_unquote(json_extract(`a`.`activity_details`,'$.category')) AS `category`, 
  json_unquote(json_extract(`a`.`activity_details`,'$.coins')) AS `coins`, 
  json_unquote(json_extract(`a`.`activity_details`,'$.xp')) AS `xp`, 
  `a`.`log_timestamp` AS `log_timestamp` 
FROM (`activity_log` `a` JOIN `users` `u` ON (`a`.`user_id` = `u`.`id`)) 
WHERE (`a`.`activity_type` = 'Task Completed');

-- -----------------------------------------------------
-- SAMPLE DATA
-- -----------------------------------------------------

-- Default avatar data
INSERT INTO `avatars` (`name`, `image_path`, `category`) VALUES
('Warrior', 'assets/images/avatars/warrior1.png', 'warrior'),
('Mage', 'assets/images/avatars/mage1.png', 'mage'),
('Explorer', 'assets/images/avatars/explorer1.png', 'explorer'),
('Scholar', 'assets/images/avatars/scholar1.png', 'scholar');

-- -----------------------------------------------------
-- CONSTRAINTS
-- -----------------------------------------------------

-- Enable foreign key checks before adding constraints
SET FOREIGN_KEY_CHECKS=1;

ALTER TABLE `activity_log`
  ADD CONSTRAINT `fk_log_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

ALTER TABLE `dailytasks`
  ADD CONSTRAINT `fk_dailytasks_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

ALTER TABLE `badhabits`
  ADD CONSTRAINT `fk_badhabits_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
  
ALTER TABLE `goodhabits`
  ADD CONSTRAINT `fk_goodhabits_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

ALTER TABLE `journals`
  ADD CONSTRAINT `fk_journals_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

ALTER TABLE `streaks`
  ADD CONSTRAINT `fk_streaks_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

ALTER TABLE `tasks`
  ADD CONSTRAINT `fk_tasks_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

ALTER TABLE `userstats`
  ADD CONSTRAINT `fk_userstats_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
  
ALTER TABLE `userstats`
  ADD CONSTRAINT `fk_userstats_avatar` FOREIGN KEY (`avatar_id`) REFERENCES `avatars` (`id`);

ALTER TABLE `user_event`
  ADD CONSTRAINT `fk_user_event_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

ALTER TABLE `user_event_completions`
  ADD CONSTRAINT `fk_user_event_completions_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

ALTER TABLE `user_inventory`
  ADD CONSTRAINT `fk_inventory_item` FOREIGN KEY (`item_id`) REFERENCES `marketplace_items` (`item_id`),
  ADD CONSTRAINT `fk_inventory_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

-- -----------------------------------------------------
-- MIGRATION COMPLETE
-- -----------------------------------------------------

-- Print completion message
SELECT 'LifeQuestRPG database setup completed successfully!' AS 'Migration Status';

COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
