-- phpMyAdmin SQL Dump
-- version 6.0.0-dev+20250328.9291a9ff8f
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: May 24, 2025 at 02:19 PM
-- Server version: 8.4.3
-- PHP Version: 8.4.3
SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";
/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */
;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */
;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */
;
/*!40101 SET NAMES utf8mb4 */
;
--
-- Database: `lifequestrpg`
--

DELIMITER $$ --
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `log_poke` (IN `target_user_id` INT, IN `poker_user_id` INT, IN `poker_username` VARCHAR(255))   BEGIN
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
      'poker_id',
      poker_user_id,
      'poker_name',
      poker_username
    ),
    NOW()
  );
SELECT ROW_COUNT() AS success;
END $$ CREATE DEFINER = `root` @`localhost` PROCEDURE `PurchaseMarketplaceItem` (IN `p_user_id` INT, IN `p_item_id` INT) proc: BEGIN
DECLARE v_item_price DECIMAL(10, 2);
DECLARE v_user_coins INT;
DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK;
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
SELECT `item_price` INTO v_item_price
FROM `marketplace_items`
WHERE `item_id` = p_item_id;
-- Check user balance
SELECT `coins` INTO v_user_coins
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
END $$ CREATE DEFINER = `root` @`localhost` PROCEDURE `UseInventoryItem` (IN `p_inventory_id` INT, IN `p_user_id` INT) proc_label: BEGIN
DECLARE v_item_id INT;
DECLARE v_item_type VARCHAR(50);
DECLARE v_effect_type VARCHAR(50);
DECLARE v_effect_value INT;
DECLARE v_effect_message VARCHAR(255);
DECLARE v_userstats_count INT;
DECLARE v_item_name VARCHAR(255);
DECLARE v_current_health INT;
DECLARE v_error_message VARCHAR(255);
DECLARE v_new_health INT;
DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN GET DIAGNOSTICS CONDITION 1 v_error_message = MESSAGE_TEXT;
ROLLBACK;
SELECT CONCAT('SQL Error: ', v_error_message) AS message;
END;
START TRANSACTION;
-- Check if userstats exists for the user
SELECT COUNT(*) INTO v_userstats_count
FROM userstats
WHERE user_id = p_user_id;
IF v_userstats_count = 0 THEN
SELECT 'No userstats row found for this user' AS message;
ROLLBACK;
LEAVE proc_label;
END IF;
-- Get current health for health-related items
SELECT health INTO v_current_health
FROM userstats
WHERE user_id = p_user_id;
-- Verify inventory item exists and belongs to the user
SELECT i.item_id,
  m.item_type,
  m.effect_type,
  m.effect_value,
  m.item_name INTO v_item_id,
  v_item_type,
  v_effect_type,
  v_effect_value,
  v_item_name
FROM user_inventory i
  JOIN marketplace_items m ON i.item_id = m.item_id
WHERE i.inventory_id = p_inventory_id
  AND i.user_id = p_user_id;
IF v_item_id IS NULL THEN
SELECT 'Item not found in your inventory' AS message;
ROLLBACK;
LEAVE proc_label;
END IF;
-- Process based on item type
CASE
  v_item_type
  WHEN 'consumable' THEN CASE
    v_effect_type
    WHEN 'health' THEN -- Check if health is already at max
    IF v_current_health >= 100 THEN
    SELECT 'Your health is already at maximum' AS message;
ROLLBACK;
LEAVE proc_label;
END IF;
-- Calculate new health value
SET v_new_health = LEAST(v_current_health + v_effect_value, 100);
-- Update health
UPDATE userstats
SET health = v_new_health
WHERE user_id = p_user_id;
SET v_effect_message = CONCAT(
    'Restored ',
    (v_new_health - v_current_health),
    ' health points'
  );
WHEN 'xp' THEN
UPDATE userstats
SET xp = xp + v_effect_value
WHERE user_id = p_user_id;
SET v_effect_message = CONCAT('Gained ', v_effect_value, ' experience points');
ELSE
SET v_effect_message = CONCAT(
    'Consumable used with unknown effect type: ',
    v_effect_type
  );
END CASE
;
-- Remove consumable item after use
DELETE FROM user_inventory
WHERE inventory_id = p_inventory_id;
WHEN 'boost' THEN -- Check if boost is already active
IF EXISTS (
  SELECT 1
  FROM user_active_boosts
  WHERE user_id = p_user_id
    AND boost_type = v_effect_type
    AND expires_at > NOW()
) THEN
SELECT 'This type of boost is already active' AS message;
ROLLBACK;
LEAVE proc_label;
END IF;
-- Add boost to active boosts
INSERT INTO user_active_boosts (
    user_id,
    boost_type,
    boost_value,
    activated_at,
    expires_at
  )
VALUES (
    p_user_id,
    v_effect_type,
    v_effect_value,
    NOW(),
    DATE_ADD(NOW(), INTERVAL 24 HOUR)
  );
SET v_effect_message = CONCAT(
    'Activated a ',
    v_effect_value,
    '% boost for 24 hours'
  );
WHEN 'equipment' THEN
SET v_effect_message = 'Item equipped successfully';
ELSE
SET v_effect_message = CONCAT('Unknown item type: ', v_item_type);
END CASE
;
-- Log the usage
INSERT INTO item_usage_history (inventory_id, effect_applied)
VALUES (p_inventory_id, v_effect_message);
-- Return success message
SELECT 'Item used successfully' AS message,
  v_effect_message AS effect;
COMMIT;
END $$ DELIMITER;
-- --------------------------------------------------------
--
-- Table structure for table `activity_log`
--

CREATE TABLE `activity_log` (
  `log_id` int NOT NULL,
  `user_id` int NOT NULL,
  `activity_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `activity_details` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `log_timestamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
--
-- Dumping data for table `activity_log`
--

INSERT INTO `activity_log` (
    `log_id`,
    `user_id`,
    `activity_type`,
    `activity_details`,
    `log_timestamp`
  )
VALUES (
    1,
    1,
    'User Login',
    '{\"message\":\"New user registration and first login\",\"timestamp\":\"2025-05-16 04:34:10\"}',
    '2025-05-16 04:34:10'
  ),
  (
    2,
    2,
    'User Login',
    '{\"message\":\"New user registration and first login\",\"timestamp\":\"2025-05-16 19:33:17\"}',
    '2025-05-16 19:33:17'
  ),
  (
    3,
    2,
    'User Login',
    '{\"message\":\"User logged in\",\"timestamp\":\"2025-05-16 19:33:58\"}',
    '2025-05-16 19:33:58'
  ),
  (
    4,
    2,
    'User Login',
    '{\"message\":\"Daily login\",\"timestamp\":\"2025-05-16 19:35:16\"}',
    '2025-05-16 19:35:16'
  ),
  (
    5,
    2,
    'User Login',
    '{\"message\":\"Daily login\",\"timestamp\":\"2025-05-16 19:35:20\"}',
    '2025-05-16 19:35:20'
  ),
  (
    6,
    2,
    'User Login',
    '{\"message\":\"Daily login\",\"timestamp\":\"2025-05-16 19:35:40\"}',
    '2025-05-16 19:35:40'
  ),
  (
    7,
    3,
    'User Login',
    '{\"message\":\"New user registration and first login\",\"timestamp\":\"2025-05-16 19:36:07\"}',
    '2025-05-16 19:36:07'
  ),
  (
    8,
    3,
    'User Login',
    '{\"message\":\"Daily login\",\"timestamp\":\"2025-05-16 19:36:29\"}',
    '2025-05-16 19:36:29'
  ),
  (
    9,
    2,
    'User Login',
    '{\"message\":\"User logged in\",\"timestamp\":\"2025-05-16 19:37:53\"}',
    '2025-05-16 19:37:53'
  ),
  (
    10,
    2,
    'User Login',
    '{\"message\":\"Daily login\",\"timestamp\":\"2025-05-16 19:38:17\"}',
    '2025-05-16 19:38:17'
  ),
  (
    11,
    2,
    'User Login',
    '{\"message\":\"Daily login\",\"timestamp\":\"2025-05-16 19:38:30\"}',
    '2025-05-16 19:38:30'
  ),
  (
    12,
    2,
    'User Login',
    '{\"message\":\"Daily login\",\"timestamp\":\"2025-05-16 19:38:32\"}',
    '2025-05-16 19:38:32'
  ),
  (
    13,
    2,
    'User Login',
    '{\"message\":\"Daily login\",\"timestamp\":\"2025-05-16 19:38:35\"}',
    '2025-05-16 19:38:35'
  ),
  (
    14,
    2,
    'User Login',
    '{\"message\":\"Daily login\",\"timestamp\":\"2025-05-16 19:38:40\"}',
    '2025-05-16 19:38:40'
  ),
  (
    15,
    2,
    'User Login',
    '{\"message\":\"Daily login\",\"timestamp\":\"2025-05-16 19:39:25\"}',
    '2025-05-16 19:39:25'
  ),
  (
    16,
    3,
    'User Login',
    '{\"message\":\"User logged in\",\"timestamp\":\"2025-05-16 19:40:48\"}',
    '2025-05-16 19:40:48'
  ),
  (
    17,
    3,
    'User Login',
    '{\"message\":\"Daily login\",\"timestamp\":\"2025-05-16 19:40:48\"}',
    '2025-05-16 19:40:48'
  ),
  (
    18,
    3,
    'User Login',
    '{\"message\":\"Daily login\",\"timestamp\":\"2025-05-16 19:41:06\"}',
    '2025-05-16 19:41:06'
  ),
  (
    19,
    3,
    'User Login',
    '{\"message\":\"Daily login\",\"timestamp\":\"2025-05-16 19:41:45\"}',
    '2025-05-16 19:41:45'
  ),
  (
    20,
    3,
    'User Login',
    '{\"message\":\"Daily login\",\"timestamp\":\"2025-05-16 19:41:53\"}',
    '2025-05-16 19:41:53'
  ),
  (
    21,
    3,
    'User Login',
    '{\"message\":\"Daily login\",\"timestamp\":\"2025-05-16 19:42:00\"}',
    '2025-05-16 19:42:00'
  ),
  (
    22,
    3,
    'User Login',
    '{\"message\":\"Daily login\",\"timestamp\":\"2025-05-16 19:45:00\"}',
    '2025-05-16 19:45:00'
  ),
  (
    23,
    3,
    'User Login',
    '{\"message\":\"Daily login\",\"timestamp\":\"2025-05-16 19:45:11\"}',
    '2025-05-16 19:45:11'
  ),
  (
    24,
    3,
    'User Login',
    '{\"message\":\"Daily login\",\"timestamp\":\"2025-05-16 19:47:08\"}',
    '2025-05-16 19:47:08'
  ),
  (
    25,
    3,
    'User Login',
    '{\"message\":\"Daily login\",\"timestamp\":\"2025-05-16 19:47:16\"}',
    '2025-05-16 19:47:16'
  ),
  (
    26,
    3,
    'User Login',
    '{\"message\":\"Daily login\",\"timestamp\":\"2025-05-16 19:47:25\"}',
    '2025-05-16 19:47:25'
  ),
  (
    27,
    3,
    'User Login',
    '{\"message\":\"Daily login\",\"timestamp\":\"2025-05-16 19:54:51\"}',
    '2025-05-16 19:54:51'
  ),
  (
    28,
    3,
    'User Login',
    '{\"message\":\"Daily login\",\"timestamp\":\"2025-05-16 20:06:02\"}',
    '2025-05-16 20:06:02'
  ),
  (
    29,
    3,
    'User Login',
    '{\"message\":\"Daily login\",\"timestamp\":\"2025-05-16 20:12:25\"}',
    '2025-05-16 20:12:25'
  ),
  (
    30,
    3,
    'User Login',
    '{\"message\":\"Daily login\",\"timestamp\":\"2025-05-16 20:12:30\"}',
    '2025-05-16 20:12:30'
  ),
  (
    31,
    3,
    'User Login',
    '{\"message\":\"Daily login\",\"timestamp\":\"2025-05-16 20:13:17\"}',
    '2025-05-16 20:13:17'
  ),
  (
    32,
    3,
    'User Login',
    '{\"message\":\"Daily login\",\"timestamp\":\"2025-05-16 20:13:26\"}',
    '2025-05-16 20:13:26'
  ),
  (
    33,
    1,
    'User Login',
    '{\"message\":\"User logged in\",\"timestamp\":\"2025-05-17 04:42:18\"}',
    '2025-05-17 04:42:18'
  ),
  (
    34,
    1,
    'User Login',
    '{\"message\":\"User logged in\",\"timestamp\":\"2025-05-17 05:32:11\"}',
    '2025-05-17 05:32:11'
  ),
  (
    35,
    1,
    'User Login',
    '{\"message\":\"User logged in\",\"timestamp\":\"2025-05-17 08:12:24\"}',
    '2025-05-17 08:12:24'
  ),
  (
    36,
    1,
    'User Login',
    '{\"message\":\"User logged in\",\"timestamp\":\"2025-05-17 09:29:03\"}',
    '2025-05-17 09:29:03'
  ),
  (
    37,
    4,
    'User Login',
    '{\"message\":\"New user registration and first login\",\"timestamp\":\"2025-05-17 10:04:51\"}',
    '2025-05-17 10:04:51'
  ),
  (
    38,
    4,
    'Event Completed',
    '{\"event_id\": 1, \"reward_xp\": 12, \"event_name\": \"OPLAN TULI\", \"completed_at\": \"2025-05-17 18:05:25.000000\", \"reward_coins\": 12, \"event_description\": \"mag pa tuli\"}',
    '2025-05-17 10:05:25'
  ),
  (
    39,
    2,
    'User Login',
    '{\"message\":\"User logged in\",\"timestamp\":\"2025-05-17 23:18:58\"}',
    '2025-05-17 23:18:58'
  ),
  (
    40,
    2,
    'User Login',
    '{\"message\":\"Daily login\",\"timestamp\":\"2025-05-18 00:52:50\"}',
    '2025-05-18 00:52:50'
  ),
  (
    41,
    2,
    'User Login',
    '{\"message\":\"Daily login\",\"timestamp\":\"2025-05-18 02:34:45\"}',
    '2025-05-18 02:34:45'
  ),
  (
    42,
    2,
    'User Login',
    '{\"message\":\"Daily login\",\"timestamp\":\"2025-05-18 02:49:33\"}',
    '2025-05-18 02:49:33'
  ),
  (
    43,
    2,
    'User Login',
    '{\"message\":\"User logged in\",\"timestamp\":\"2025-05-18 02:57:31\"}',
    '2025-05-18 02:57:31'
  ),
  (
    44,
    2,
    'User Login',
    '{\"message\":\"User logged in\",\"timestamp\":\"2025-05-18 02:58:28\"}',
    '2025-05-18 02:58:28'
  ),
  (
    45,
    2,
    'User Login',
    '{\"message\":\"User logged in\",\"timestamp\":\"2025-05-18 05:22:45\"}',
    '2025-05-18 05:22:45'
  ),
  (
    46,
    2,
    'User Login',
    '{\"message\":\"User logged in\",\"timestamp\":\"2025-05-18 10:37:39\"}',
    '2025-05-18 10:37:39'
  ),
  (
    47,
    2,
    'User Login',
    '{\"message\":\"User logged in\",\"timestamp\":\"2025-05-18 13:25:53\"}',
    '2025-05-18 13:25:53'
  ),
  (
    48,
    3,
    'User Login',
    '{\"message\":\"User logged in\",\"timestamp\":\"2025-05-19 08:54:18\"}',
    '2025-05-19 08:54:18'
  ),
  (
    49,
    4,
    'User Poked',
    '{\"poker_id\": 3, \"poker_name\": \"marvin\"}',
    '2025-05-19 08:57:13'
  ),
  (
    50,
    4,
    'User Login',
    '{\"message\":\"User logged in\",\"timestamp\":\"2025-05-19 08:57:39\"}',
    '2025-05-19 08:57:39'
  ),
  (
    51,
    2,
    'User Login',
    '{\"message\":\"User logged in\",\"timestamp\":\"2025-05-19 09:06:14\"}',
    '2025-05-19 09:06:14'
  ),
  (
    52,
    3,
    'User Login',
    '{\"message\":\"User logged in\",\"timestamp\":\"2025-05-19 09:07:53\"}',
    '2025-05-19 09:07:53'
  ),
  (
    53,
    2,
    'User Login',
    '{\"message\":\"User logged in\",\"timestamp\":\"2025-05-20 09:35:48\"}',
    '2025-05-20 09:35:48'
  ),
  (
    54,
    1,
    'User Login',
    '{\"message\":\"User logged in\",\"timestamp\":\"2025-05-20 09:38:00\"}',
    '2025-05-20 09:38:00'
  ),
  (
    55,
    1,
    'User Login',
    '{\"message\":\"User logged in\",\"timestamp\":\"2025-05-20 09:38:01\"}',
    '2025-05-20 09:38:01'
  ),
  (
    56,
    1,
    'User Login',
    '{\"message\":\"User logged in\",\"timestamp\":\"2025-05-20 10:25:44\"}',
    '2025-05-20 10:25:44'
  ),
  (
    57,
    1,
    'User Login',
    '{\"message\":\"User logged in\",\"timestamp\":\"2025-05-20 11:14:55\"}',
    '2025-05-20 11:14:55'
  ),
  (
    58,
    1,
    'ITEM_PURCHASED',
    '{\"item_id\": 1, \"item_name\": \"test2\"}',
    '2025-05-20 11:24:24'
  ),
  (
    59,
    1,
    'User Login',
    '{\"message\":\"User logged in\",\"timestamp\":\"2025-05-20 12:06:17\"}',
    '2025-05-20 12:06:17'
  ),
  (
    60,
    1,
    'User Login',
    '{\"message\":\"User logged in\",\"timestamp\":\"2025-05-20 13:23:51\"}',
    '2025-05-20 13:23:51'
  ),
  (
    61,
    1,
    'ITEM_PURCHASED',
    '{\"item_id\": 2, \"item_name\": \"hahah\"}',
    '2025-05-20 13:37:57'
  ),
  (
    62,
    1,
    'Task Completed',
    '{\"xp\": 10, \"coins\": 5, \"title\": \"hahaha\", \"task_id\": 1, \"category\": \"Physical Health\", \"difficulty\": \"easy\"}',
    '2025-05-20 13:38:47'
  ),
  (
    63,
    1,
    'Task Completed',
    '{\"xp\": 10, \"coins\": 5, \"title\": \"saasa\", \"task_id\": 2, \"category\": \"Physical Health\", \"difficulty\": \"easy\"}',
    '2025-05-20 13:38:53'
  ),
  (
    64,
    1,
    'Task Completed',
    '{\"xp\": 10, \"coins\": 5, \"title\": \"hahaha\", \"task_id\": 1, \"category\": \"Physical Health\", \"difficulty\": \"easy\"}',
    '2025-05-20 13:38:53'
  ),
  (
    65,
    1,
    'ITEM_PURCHASED',
    '{\"item_id\": 5, \"item_name\": \"XP Booster\"}',
    '2025-05-20 13:40:51'
  ),
  (
    66,
    1,
    'User Login',
    '{\"message\":\"User logged in\",\"timestamp\":\"2025-05-20 14:17:04\"}',
    '2025-05-20 14:17:04'
  ),
  (
    67,
    1,
    'User Login',
    '{\"message\":\"User logged in\",\"timestamp\":\"2025-05-20 15:50:53\"}',
    '2025-05-20 15:50:53'
  ),
  (
    68,
    1,
    'User Login',
    '{\"message\":\"User logged in\",\"timestamp\":\"2025-05-24 08:18:08\"}',
    '2025-05-24 08:18:08'
  ),
  (
    69,
    1,
    'ITEM_PURCHASED',
    '{\"item_id\": 6, \"item_name\": \"Focus Crystal\"}',
    '2025-05-24 08:21:00'
  ),
  (
    70,
    1,
    'ITEM_PURCHASED',
    '{\"item_id\": 7, \"item_name\": \"Golden Trophy\"}',
    '2025-05-24 08:21:02'
  ),
  (
    71,
    1,
    'ITEM_PURCHASED',
    '{\"item_id\": 3, \"item_name\": \"gaga\"}',
    '2025-05-24 08:21:03'
  ),
  (
    72,
    1,
    'ITEM_PURCHASED',
    '{\"item_id\": 4, \"item_name\": \"Health Potion\"}',
    '2025-05-24 08:21:04'
  ),
  (
    73,
    1,
    'User Login',
    '{\"message\":\"User logged in\",\"timestamp\":\"2025-05-24 09:01:52\"}',
    '2025-05-24 09:01:52'
  ),
  (
    74,
    1,
    'User Login',
    '{\"message\":\"User logged in\",\"timestamp\":\"2025-05-24 10:02:40\"}',
    '2025-05-24 10:02:40'
  ),
  (
    75,
    1,
    'item_use',
    '{\"message\":\"Used item: XP Booster\"}',
    '2025-05-24 10:08:16'
  ),
  (
    76,
    1,
    'item_use',
    '{\"message\":\"Used item: XP Booster\"}',
    '2025-05-24 10:09:12'
  ),
  (
    77,
    1,
    'item_use',
    '{\"message\":\"Used item: Focus Crystal\"}',
    '2025-05-24 10:09:21'
  ),
  (
    78,
    1,
    'User Login',
    '{\"message\":\"User logged in\",\"timestamp\":\"2025-05-24 10:49:30\"}',
    '2025-05-24 10:49:30'
  ),
  (
    79,
    1,
    'item_use',
    '{\"message\":\"Used item: XP Booster\"}',
    '2025-05-24 10:49:37'
  ),
  (
    80,
    1,
    'User Login',
    '{\"message\":\"User logged in\",\"timestamp\":\"2025-05-24 12:35:01\"}',
    '2025-05-24 12:35:01'
  ),
  (
    81,
    1,
    'item_use',
    '{\"message\":\"Used item: Focus Crystal\"}',
    '2025-05-24 12:36:28'
  ),
  (
    82,
    1,
    'item_use',
    '{\"message\":\"Used item: XP Booster\"}',
    '2025-05-24 12:36:32'
  ),
  (
    83,
    1,
    'User Login',
    '{\"message\":\"User logged in\",\"timestamp\":\"2025-05-24 14:05:17\"}',
    '2025-05-24 14:05:17'
  );
-- --------------------------------------------------------
--
-- Table structure for table `avatars`
--

CREATE TABLE `avatars` (
  `id` int NOT NULL,
  `name` varchar(50) NOT NULL,
  `image_path` varchar(255) NOT NULL,
  `category` varchar(50) DEFAULT NULL COMMENT 'e.g., warrior, mage, rogue',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;
--
-- Dumping data for table `avatars`
--

INSERT INTO `avatars` (
    `id`,
    `name`,
    `image_path`,
    `category`,
    `created_at`
  )
VALUES (
    1,
    'Warrior',
    'assets/images/avatars/warrior1.png',
    'warrior',
    '2025-05-16 04:29:15'
  ),
  (
    2,
    'Mage',
    'assets/images/avatars/mage1.png',
    'mage',
    '2025-05-16 04:29:15'
  ),
  (
    3,
    'Explorer',
    'assets/images/avatars/explorer1.png',
    'explorer',
    '2025-05-16 04:29:15'
  ),
  (
    4,
    'Scholar',
    'assets/images/avatars/scholar1.png',
    'scholar',
    '2025-05-16 04:29:15'
  );
-- --------------------------------------------------------
--
-- Table structure for table `badhabits`
--

CREATE TABLE `badhabits` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `status` enum('pending', 'completed') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'pending',
  `difficulty` enum('easy', 'medium', 'hard') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `category` enum(
    'Physical Health',
    'Mental Wellness',
    'Personal Growth',
    'Career / Studies',
    'Finance',
    'Home Environment',
    'Relationships Social',
    'Passion Hobbies'
  ) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `coins` int NOT NULL,
  `xp` int NOT NULL,
  `avoided` int NOT NULL DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;
--
-- Triggers `badhabits`
--
DELIMITER $$
CREATE TRIGGER `after_bad_habits_completion`
AFTER
UPDATE ON `badhabits` FOR EACH ROW BEGIN IF NEW.status = 'completed'
  AND OLD.status != 'completed' THEN
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
      'task_id',
      NEW.id,
      'title',
      NEW.title,
      'difficulty',
      NEW.difficulty,
      'category',
      NEW.category,
      'coins',
      NEW.coins,
      'xp',
      NEW.xp
    ),
    NOW()
  );
END IF;
END $$ DELIMITER;
-- --------------------------------------------------------
--
-- Table structure for table `dailytasks`
--

CREATE TABLE `dailytasks` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` enum('pending', 'completed') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `difficulty` enum('easy', 'medium', 'hard') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `category` enum(
    'Physical Health',
    'Mental Wellness',
    'Personal Growth',
    'Career / Studies',
    'Finance',
    'Home Environment',
    'Relationships Social',
    'Passion Hobbies'
  ) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `coins` int DEFAULT '0',
  `xp` int DEFAULT '0',
  `last_reset` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
--
-- Triggers `dailytasks`
--
DELIMITER $$
CREATE TRIGGER `after_dailytask_completion`
AFTER
UPDATE ON `dailytasks` FOR EACH ROW BEGIN IF NEW.status = 'completed'
  AND OLD.status != 'completed' THEN
INSERT INTO activity_log (
    user_id,
    activity_type,
    activity_details,
    log_timestamp
  )
VALUES (
    NEW.user_id,
    'Daily Task Completed',
    JSON_OBJECT(
      'task_id',
      NEW.id,
      'title',
      NEW.title,
      'difficulty',
      NEW.difficulty,
      'category',
      NEW.category,
      'coins',
      NEW.coins,
      'xp',
      NEW.xp
    ),
    NOW()
  );
END IF;
END $$ DELIMITER;
-- --------------------------------------------------------
--
-- Table structure for table `goodhabits`
--

CREATE TABLE `goodhabits` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `difficulty` enum('easy', 'medium', 'hard') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `category` enum(
    'Physical Health',
    'Mental Wellness',
    'Personal Growth',
    'Career / Studies',
    'Finance',
    'Home Environment',
    'Relationships Social',
    'Passion Hobbies'
  ) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `status` enum('pending', 'completed') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'pending',
  `coins` int DEFAULT '0',
  `xp` int DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;
--
-- Triggers `goodhabits`
--
DELIMITER $$
CREATE TRIGGER `after_good_habits_completion`
AFTER
UPDATE ON `goodhabits` FOR EACH ROW BEGIN IF NEW.status = 'completed'
  AND OLD.status != 'completed' THEN
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
      'task_id',
      NEW.id,
      'title',
      NEW.title,
      'difficulty',
      NEW.difficulty,
      'category',
      NEW.category,
      'coins',
      NEW.coins,
      'xp',
      NEW.xp
    ),
    NOW()
  );
END IF;
END $$ DELIMITER;
-- --------------------------------------------------------
--
-- Table structure for table `item_categories`
--

CREATE TABLE `item_categories` (
  `category_id` int NOT NULL,
  `category_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `category_description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `icon` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
--
-- Dumping data for table `item_categories`
--

INSERT INTO `item_categories` (
    `category_id`,
    `category_name`,
    `category_description`,
    `icon`
  )
VALUES (
    1,
    'Consumables',
    'Items that can be used once for immediate effects',
    '/assets/images/marketplace/icons/consumable.png'
  ),
  (
    2,
    'Equipment',
    'Items that provide passive benefits when equipped',
    '/assets/images/marketplace/icons/equipment.png'
  ),
  (
    3,
    'Collectibles',
    'Rare items with special effects or cosmetic value',
    '/assets/images/marketplace/icons/collectible.png'
  ),
  (
    4,
    'Boosts',
    'Items that provide temporary buffs to stats or rewards',
    '/assets/images/marketplace/icons/boost.png'
  );
-- --------------------------------------------------------
--
-- Table structure for table `item_usage_history`
--

CREATE TABLE `item_usage_history` (
  `usage_id` int NOT NULL,
  `inventory_id` int NOT NULL,
  `used_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `effect_applied` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
--
-- Dumping data for table `item_usage_history`
--

INSERT INTO `item_usage_history` (
    `usage_id`,
    `inventory_id`,
    `used_at`,
    `effect_applied`
  )
VALUES (
    1,
    3,
    '2025-05-20 14:17:33',
    'Activated xp_multiplier boost of 25%'
  ),
  (
    2,
    3,
    '2025-05-20 14:17:40',
    'Activated xp_multiplier boost of 25%'
  ),
  (
    3,
    3,
    '2025-05-20 14:17:41',
    'Activated xp_multiplier boost of 25%'
  ),
  (
    5,
    4,
    '2025-05-24 09:02:09',
    'Item equipped successfully'
  ),
  (
    12,
    3,
    '2025-05-24 10:02:50',
    'Activated a 25% boost for 24 hours'
  ),
  (
    13,
    4,
    '2025-05-24 10:03:01',
    'Item equipped successfully'
  ),
  (
    15,
    3,
    '2025-05-24 10:08:16',
    'Activated a 25% boost for 24 hours'
  ),
  (
    17,
    3,
    '2025-05-24 10:09:12',
    'Activated a 25% boost for 24 hours'
  ),
  (
    18,
    4,
    '2025-05-24 10:09:21',
    'Item equipped successfully'
  ),
  (
    25,
    3,
    '2025-05-24 10:49:37',
    'Activated a 25% boost for 24 hours'
  ),
  (
    28,
    4,
    '2025-05-24 12:36:28',
    'Item equipped successfully'
  ),
  (
    29,
    3,
    '2025-05-24 12:36:32',
    'Activated a 25% boost for 24 hours'
  );
-- --------------------------------------------------------
--
-- Table structure for table `journals`
--

CREATE TABLE `journals` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `content` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `date` date NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- --------------------------------------------------------
--
-- Table structure for table `marketplace_items`
--

CREATE TABLE `marketplace_items` (
  `item_id` int NOT NULL,
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
  `cooldown_period` int DEFAULT NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
--
-- Dumping data for table `marketplace_items`
--

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
    'test2',
    'angas',
    0.00,
    '',
    NULL,
    'collectible',
    NULL,
    NULL,
    NULL,
    NULL
  ),
  (
    2,
    'hahah',
    'ha',
    12.00,
    '',
    NULL,
    'collectible',
    NULL,
    NULL,
    NULL,
    NULL
  ),
  (
    3,
    'gaga',
    'gagaga',
    12.00,
    '',
    NULL,
    'collectible',
    NULL,
    NULL,
    NULL,
    NULL
  ),
  (
    4,
    'Health Potion',
    'Restores 10 health points immediately',
    50.00,
    '/assets/images/marketplace/health_potion.png',
    1,
    'consumable',
    'health',
    10,
    NULL,
    NULL
  ),
  (
    5,
    'XP Booster',
    'Increases XP gain by 25% for 24 hours',
    100.00,
    '/assets/images/marketplace/xp_booster.png',
    4,
    'boost',
    'xp_multiplier',
    25,
    NULL,
    NULL
  ),
  (
    6,
    'Focus Crystal',
    'Increases focus by 5 points when equipped',
    75.00,
    '/assets/images/marketplace/focus_crystal.png',
    2,
    'equipment',
    'focus',
    5,
    NULL,
    NULL
  ),
  (
    7,
    'Golden Trophy',
    'A rare collectible that grants special profile badge',
    200.00,
    '/assets/images/marketplace/golden_trophy.png',
    3,
    'collectible',
    'badge',
    1,
    NULL,
    NULL
  );
-- --------------------------------------------------------
--
-- Table structure for table `streaks`
--

CREATE TABLE `streaks` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `streak_type` enum(
    'check_in',
    'task_completion',
    'dailtask_completion',
    'GoodHabits_completion',
    'journal_writing'
  ) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `current_streak` int NOT NULL DEFAULT '0',
  `longest_streak` int NOT NULL DEFAULT '0',
  `last_streak_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `next_expected_date` date DEFAULT NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
--
-- Dumping data for table `streaks`
--

INSERT INTO `streaks` (
    `id`,
    `user_id`,
    `streak_type`,
    `current_streak`,
    `longest_streak`,
    `last_streak_date`,
    `next_expected_date`
  )
VALUES (
    1,
    1,
    'check_in',
    1,
    8,
    '2025-05-24 08:18:08',
    NULL
  ),
  (
    2,
    1,
    'task_completion',
    1,
    1,
    '2025-05-20 13:38:47',
    NULL
  ),
  (
    3,
    1,
    'dailtask_completion',
    0,
    0,
    '2025-05-16 04:34:10',
    NULL
  ),
  (
    4,
    1,
    'GoodHabits_completion',
    0,
    0,
    '2025-05-16 04:34:10',
    NULL
  ),
  (
    5,
    1,
    'journal_writing',
    0,
    0,
    '2025-05-16 04:34:10',
    NULL
  ),
  (
    6,
    2,
    'check_in',
    4,
    4,
    '2025-05-20 09:35:48',
    NULL
  ),
  (
    7,
    2,
    'task_completion',
    0,
    0,
    '2025-05-16 19:33:17',
    NULL
  ),
  (
    8,
    2,
    'dailtask_completion',
    0,
    0,
    '2025-05-16 19:33:17',
    NULL
  ),
  (
    9,
    2,
    'GoodHabits_completion',
    0,
    0,
    '2025-05-16 19:33:17',
    NULL
  ),
  (
    10,
    2,
    'journal_writing',
    0,
    0,
    '2025-05-16 19:33:17',
    NULL
  ),
  (
    11,
    3,
    'check_in',
    1,
    1,
    '2025-05-19 08:54:18',
    NULL
  ),
  (
    12,
    3,
    'task_completion',
    0,
    0,
    '2025-05-16 19:36:07',
    NULL
  ),
  (
    13,
    3,
    'dailtask_completion',
    0,
    0,
    '2025-05-16 19:36:07',
    NULL
  ),
  (
    14,
    3,
    'GoodHabits_completion',
    0,
    0,
    '2025-05-16 19:36:07',
    NULL
  ),
  (
    15,
    3,
    'journal_writing',
    0,
    0,
    '2025-05-16 19:36:07',
    NULL
  ),
  (
    16,
    4,
    'check_in',
    1,
    1,
    '2025-05-19 08:57:39',
    NULL
  ),
  (
    17,
    4,
    'task_completion',
    0,
    0,
    '2025-05-17 10:04:51',
    NULL
  ),
  (
    18,
    4,
    'dailtask_completion',
    0,
    0,
    '2025-05-17 10:04:51',
    NULL
  ),
  (
    19,
    4,
    'GoodHabits_completion',
    0,
    0,
    '2025-05-17 10:04:51',
    NULL
  ),
  (
    20,
    4,
    'journal_writing',
    0,
    0,
    '2025-05-17 10:04:51',
    NULL
  ),
  (
    21,
    5,
    'check_in',
    0,
    0,
    '2025-05-18 06:34:20',
    NULL
  ),
  (
    22,
    5,
    'task_completion',
    0,
    0,
    '2025-05-18 06:34:20',
    NULL
  ),
  (
    23,
    5,
    'dailtask_completion',
    0,
    0,
    '2025-05-18 06:34:20',
    NULL
  ),
  (
    24,
    5,
    'GoodHabits_completion',
    0,
    0,
    '2025-05-18 06:34:20',
    NULL
  ),
  (
    25,
    5,
    'journal_writing',
    0,
    0,
    '2025-05-18 06:34:20',
    NULL
  );
-- --------------------------------------------------------
--
-- Stand-in structure for view `streaks_view`
-- (See below for the actual view)
--
CREATE TABLE `streaks_view` (
`id` int,
`user_id` int,
`streak_type` enum(
  'check_in',
  'task_completion',
  'dailtask_completion',
  'GoodHabits_completion',
  'journal_writing'
),
`current_streak` int,
`longest_streak` int,
`last_streak_date` timestamp,
`last_activity_date` timestamp,
`next_expected_date` date
);
-- --------------------------------------------------------
--
-- Table structure for table `tasks`
--

CREATE TABLE `tasks` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` enum('pending', 'completed') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `difficulty` enum('easy', 'medium', 'hard') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'easy',
  `category` enum(
    'Physical Health',
    'Mental Wellness',
    'Personal Growth',
    'Career / Studies',
    'Finance',
    'Home Environment',
    'Relationships Social',
    'Passion Hobbies'
  ) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `coins` int DEFAULT '0',
  `xp` int DEFAULT '0'
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
--
-- Dumping data for table `tasks`
--

INSERT INTO `tasks` (
    `id`,
    `user_id`,
    `title`,
    `status`,
    `difficulty`,
    `category`,
    `coins`,
    `xp`
  )
VALUES (
    1,
    1,
    'hahaha',
    'completed',
    'easy',
    'Physical Health',
    5,
    10
  ),
  (
    2,
    1,
    'saasa',
    'completed',
    'easy',
    'Physical Health',
    5,
    10
  ),
  (
    3,
    1,
    'lwyt',
    'pending',
    'hard',
    'Physical Health',
    15,
    30
  );
--
-- Triggers `tasks`
--
DELIMITER $$
CREATE TRIGGER `after_task_completion`
AFTER
UPDATE ON `tasks` FOR EACH ROW BEGIN IF NEW.status = 'completed'
  AND OLD.status != 'completed' THEN
INSERT INTO activity_log (
    user_id,
    activity_type,
    activity_details,
    log_timestamp
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
      NEW.difficulty,
      'category',
      NEW.category,
      'coins',
      NEW.coins,
      'xp',
      NEW.xp
    ),
    NOW()
  );
END IF;
END $$ DELIMITER;
-- --------------------------------------------------------
--
-- Table structure for table `test_data`
--

CREATE TABLE `test_data` (
  `id` int NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` text,
  `category` varchar(50) DEFAULT NULL,
  `price` decimal(10, 2) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;
-- --------------------------------------------------------
--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int NOT NULL,
  `email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `password` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `role` enum('admin', 'user') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'user',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `coins` int DEFAULT '0',
  `character_created` tinyint(1) DEFAULT '0' COMMENT 'Tracks if character setup is complete',
  `email_notifications` tinyint(1) DEFAULT '1',
  `task_reminders` tinyint(1) DEFAULT '1',
  `achievement_alerts` tinyint(1) DEFAULT '1',
  `theme` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'light',
  `color_scheme` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'default'
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
--
-- Dumping data for table `users`
--

INSERT INTO `users` (
    `id`,
    `email`,
    `username`,
    `password`,
    `name`,
    `role`,
    `created_at`,
    `updated_at`,
    `coins`,
    `character_created`,
    `email_notifications`,
    `task_reminders`,
    `achievement_alerts`,
    `theme`,
    `color_scheme`
  )
VALUES (
    1,
    'sean@test.com',
    'cshan',
    '$2y$12$gBAi1irBLrd608bjSEdlDeJcVUiAVj1j3tnazkuFl.9LZRY6A/iqi',
    'sean agustine lumandong esparagoza',
    'user',
    '2025-05-16 04:34:10',
    '2025-05-24 08:21:04',
    567,
    0,
    1,
    1,
    1,
    'light',
    'default'
  ),
  (
    2,
    'admin@test.com',
    'admins',
    '$2y$12$aKcAhRRF0BDCzLC5aPPWzekYgP4o1Uvz4K9Hqfj6RWFAY3g1K55fO',
    'admin',
    'admin',
    '2025-05-16 19:33:17',
    '2025-05-20 09:35:48',
    30,
    0,
    1,
    1,
    1,
    'light',
    'default'
  ),
  (
    3,
    'marvin@test.com',
    'marvin',
    '$2y$12$TJkI38.fHsrGikN.sy2QnOKKvrKsLUB72hN3QSAH53a4Yt1wtjA.2',
    'marvin',
    'user',
    '2025-05-16 19:36:07',
    '2025-05-19 08:55:35',
    39,
    0,
    1,
    1,
    1,
    'light',
    'default'
  ),
  (
    4,
    'bady@test.com',
    'bady',
    '$2y$12$Q18lWoFuY8o0wJvYJDbPU.kpUs64S8zL5JdIpWqKsI4vCqoLYXyXS',
    'Bady Sinco',
    'user',
    '2025-05-17 10:04:51',
    '2025-05-19 08:57:39',
    17,
    0,
    1,
    1,
    1,
    'light',
    'default'
  ),
  (
    5,
    'has@test.com',
    'has',
    '$2y$12$LZLeJSAV1v0CIs/lmMc2KePBs7zSUsoHBrF7aL93MWtAvRlrg0TTu',
    'hahaha',
    'user',
    '2025-05-17 22:34:20',
    '2025-05-18 06:34:20',
    0,
    0,
    1,
    1,
    1,
    'light',
    'default'
  );
-- --------------------------------------------------------
--
-- Table structure for table `userstats`
--

CREATE TABLE `userstats` (
  `id` int NOT NULL,
  `user_id` int DEFAULT NULL,
  `level` int NOT NULL,
  `xp` int NOT NULL,
  `health` int DEFAULT '3',
  `avatar_id` int DEFAULT NULL,
  `objective` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `physicalHealth` int DEFAULT '5',
  `mentalWellness` int DEFAULT '5',
  `personalGrowth` int DEFAULT '5',
  `careerStudies` int DEFAULT '5',
  `finance` int DEFAULT '5',
  `homeEnvironment` int DEFAULT '5',
  `relationshipsSocial` int DEFAULT '5',
  `passionHobbies` int DEFAULT '5'
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;
--
-- Dumping data for table `userstats`
--

INSERT INTO `userstats` (
    `id`,
    `user_id`,
    `level`,
    `xp`,
    `health`,
    `avatar_id`,
    `objective`,
    `physicalHealth`,
    `mentalWellness`,
    `personalGrowth`,
    `careerStudies`,
    `finance`,
    `homeEnvironment`,
    `relationshipsSocial`,
    `passionHobbies`
  )
VALUES (
    1,
    1,
    1,
    72,
    50,
    4,
    'Learn to Code',
    8,
    5,
    5,
    5,
    5,
    5,
    5,
    5
  ),
  (
    3,
    3,
    1,
    44,
    100,
    1,
    '123',
    5,
    5,
    5,
    5,
    5,
    5,
    5,
    5
  ),
  (
    4,
    2,
    1,
    42,
    100,
    4,
    'admin',
    5,
    5,
    5,
    5,
    5,
    5,
    5,
    5
  ),
  (
    5,
    4,
    1,
    10,
    100,
    3,
    'master my master',
    5,
    5,
    5,
    5,
    5,
    5,
    5,
    5
  ),
  (
    6,
    5,
    1,
    0,
    100,
    1,
    'Become the best version of myself',
    5,
    5,
    5,
    5,
    5,
    5,
    5,
    5
  );
-- --------------------------------------------------------
--
-- Table structure for table `user_active_boosts`
--

CREATE TABLE `user_active_boosts` (
  `boost_id` int NOT NULL,
  `user_id` int NOT NULL,
  `boost_type` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `boost_value` int NOT NULL,
  `activated_at` datetime NOT NULL,
  `expires_at` datetime NOT NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
--
-- Dumping data for table `user_active_boosts`
--

INSERT INTO `user_active_boosts` (
    `boost_id`,
    `user_id`,
    `boost_type`,
    `boost_value`,
    `activated_at`,
    `expires_at`
  )
VALUES (
    1,
    1,
    'xp_multiplier',
    25,
    '2025-05-24 18:02:50',
    '2025-05-25 18:02:50'
  ),
  (
    2,
    1,
    'xp_multiplier',
    25,
    '2025-05-24 18:08:16',
    '2025-05-25 18:08:16'
  ),
  (
    3,
    1,
    'xp_multiplier',
    25,
    '2025-05-24 18:09:12',
    '2025-05-25 18:09:12'
  );
-- --------------------------------------------------------
--
-- Table structure for table `user_event`
--

CREATE TABLE `user_event` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `event_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `event_description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `start_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `end_date` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `reward_xp` int NOT NULL DEFAULT '0',
  `reward_coins` int NOT NULL DEFAULT '0',
  `status` enum('active', 'inactive') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
--
-- Dumping data for table `user_event`
--

INSERT INTO `user_event` (
    `id`,
    `user_id`,
    `event_name`,
    `event_description`,
    `start_date`,
    `end_date`,
    `reward_xp`,
    `reward_coins`,
    `status`,
    `created_at`,
    `updated_at`
  )
VALUES (
    1,
    2,
    'OPLAN TULI',
    'mag pa tuli',
    '2025-05-18 00:13:53',
    '2025-05-17 16:00:00',
    12,
    12,
    'inactive',
    '2025-05-16 19:39:17',
    '2025-05-18 00:13:53'
  ),
  (
    2,
    2,
    'OPLAN TULIs',
    'mag pa tulidasdasd',
    '2025-05-20 09:37:17',
    '2025-05-19 16:00:00',
    12,
    12,
    'inactive',
    '2025-05-18 02:54:01',
    '2025-05-20 09:37:17'
  ),
  (
    3,
    2,
    'testing',
    'test',
    '2025-05-17 16:00:00',
    '2025-05-20 16:00:00',
    12,
    12,
    'active',
    '2025-05-18 05:58:31',
    '2025-05-18 05:58:31'
  ),
  (
    4,
    2,
    'sda',
    'sda',
    '2025-05-19 16:00:00',
    '2025-05-20 16:00:00',
    1,
    1,
    'active',
    '2025-05-20 09:37:17',
    '2025-05-20 09:37:17'
  );
-- --------------------------------------------------------
--
-- Table structure for table `user_event_completions`
--

CREATE TABLE `user_event_completions` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `taskevent_id` int NOT NULL,
  `completed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
--
-- Dumping data for table `user_event_completions`
--

INSERT INTO `user_event_completions` (`id`, `user_id`, `taskevent_id`, `completed_at`)
VALUES (2, 3, 1, '2025-05-16 19:54:57'),
  (3, 3, 1, '2025-05-16 20:06:01'),
  (4, 3, 1, '2025-05-16 20:12:30'),
  (5, 1, 1, '2025-05-17 04:42:29'),
  (6, 4, 1, '2025-05-17 10:05:25');
--
-- Triggers `user_event_completions`
--
DELIMITER $$
CREATE TRIGGER `after_event_completion_log`
AFTER
INSERT ON `user_event_completions` FOR EACH ROW BEGIN -- Get event details from user_event table
DECLARE event_name_val VARCHAR(255);
DECLARE event_desc_val TEXT;
DECLARE reward_xp_val INT;
DECLARE reward_coins_val INT;
SELECT event_name,
  event_description,
  reward_xp,
  reward_coins INTO event_name_val,
  event_desc_val,
  reward_xp_val,
  reward_coins_val
FROM user_event
WHERE id = NEW.taskevent_id;
-- Insert into activity log
INSERT INTO activity_log (
    user_id,
    activity_type,
    activity_details,
    log_timestamp
  )
VALUES (
    NEW.user_id,
    'Event Completed',
    JSON_OBJECT(
      'event_id',
      NEW.taskevent_id,
      'event_name',
      event_name_val,
      'event_description',
      event_desc_val,
      'reward_xp',
      reward_xp_val,
      'reward_coins',
      reward_coins_val,
      'completed_at',
      NEW.completed_at
    ),
    NEW.completed_at
  );
END $$ DELIMITER;
-- --------------------------------------------------------
--
-- Table structure for table `user_inventory`
--

CREATE TABLE `user_inventory` (
  `inventory_id` int NOT NULL,
  `user_id` int NOT NULL,
  `item_id` int NOT NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
--
-- Dumping data for table `user_inventory`
--

INSERT INTO `user_inventory` (`inventory_id`, `user_id`, `item_id`)
VALUES (1, 1, 1),
  (2, 1, 2),
  (3, 1, 5),
  (4, 1, 6),
  (5, 1, 7),
  (6, 1, 3),
  (7, 1, 4);
--
-- Triggers `user_inventory`
--
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
    'ITEM_PURCHASED',
    JSON_OBJECT(
      'item_id',
      NEW.item_id,
      'item_name',
      item_name_var
    )
  );
END $$ DELIMITER;
-- --------------------------------------------------------
--
-- Stand-in structure for view `user_items`
-- (See below for the actual view)
--
CREATE TABLE `user_items` (
`user_id` int,
`item_name` varchar(255)
);
-- --------------------------------------------------------
--
-- Stand-in structure for view `view_bad_habits_activity`
-- (See below for the actual view)
--
CREATE TABLE `view_bad_habits_activity` (
`log_id` int,
`user_id` int,
`activity_title` longtext,
`difficulty` longtext,
`category` longtext,
`coins` longtext,
`xp` longtext,
`log_timestamp` timestamp
);
-- --------------------------------------------------------
--
-- Stand-in structure for view `view_daily_task_activity`
-- (See below for the actual view)
--
CREATE TABLE `view_daily_task_activity` (
`log_id` int,
`user_id` int,
`task_title` longtext,
`difficulty` longtext,
`category` longtext,
`coins` longtext,
`xp` longtext,
`log_timestamp` timestamp
);
-- --------------------------------------------------------
--
-- Stand-in structure for view `view_event_activity`
-- (See below for the actual view)
--
CREATE TABLE `view_event_activity` (
`log_id` int,
`user_id` int,
`username` varchar(50),
`event_id` longtext,
`event_name` longtext,
`event_description` longtext,
`coins` longtext,
`xp` longtext,
`completion_time` longtext,
`log_timestamp` timestamp
);
-- --------------------------------------------------------
--
-- Stand-in structure for view `view_good_habits_activity`
-- (See below for the actual view)
--
CREATE TABLE `view_good_habits_activity` (
`log_id` int,
`user_id` int,
`activity_title` longtext,
`difficulty` longtext,
`category` longtext,
`coins` longtext,
`xp` longtext,
`log_timestamp` timestamp
);
-- --------------------------------------------------------
--
-- Stand-in structure for view `view_poke_activity`
-- (See below for the actual view)
--
CREATE TABLE `view_poke_activity` (
`log_id` int,
`target_user_id` int,
`poker_user_id` longtext,
`poker_username` longtext,
`poke_timestamp` timestamp,
`target_username` varchar(50),
`poker_username_from_users` varchar(50)
);
-- --------------------------------------------------------
--
-- Stand-in structure for view `view_task_activity`
-- (See below for the actual view)
--
CREATE TABLE `view_task_activity` (
`log_id` int,
`user_id` int,
`task_title` longtext,
`difficulty` longtext,
`category` longtext,
`coins` longtext,
`xp` longtext,
`log_timestamp` timestamp
);
--
-- Indexes for dumped tables
--

--
-- Indexes for table `activity_log`
--
ALTER TABLE `activity_log`
ADD PRIMARY KEY (`log_id`),
  ADD KEY `idx_activity_user` (`user_id`),
  ADD KEY `idx_activity_time` (`log_timestamp`);
--
-- Indexes for table `avatars`
--
ALTER TABLE `avatars`
ADD PRIMARY KEY (`id`);
--
-- Indexes for table `badhabits`
--
ALTER TABLE `badhabits`
ADD PRIMARY KEY (`id`),
  ADD KEY `fk_badhabits_user` (`user_id`);
--
-- Indexes for table `dailytasks`
--
ALTER TABLE `dailytasks`
ADD PRIMARY KEY (`id`),
  ADD KEY `fk_dailytasks_user` (`user_id`);
--
-- Indexes for table `goodhabits`
--
ALTER TABLE `goodhabits`
ADD PRIMARY KEY (`id`),
  ADD KEY `fk_goodhabits_user` (`user_id`);
--
-- Indexes for table `item_categories`
--
ALTER TABLE `item_categories`
ADD PRIMARY KEY (`category_id`);
--
-- Indexes for table `item_usage_history`
--
ALTER TABLE `item_usage_history`
ADD PRIMARY KEY (`usage_id`),
  ADD KEY `fk_usage_inventory` (`inventory_id`);
--
-- Indexes for table `journals`
--
ALTER TABLE `journals`
ADD PRIMARY KEY (`id`),
  ADD KEY `fk_journals_user` (`user_id`);
--
-- Indexes for table `marketplace_items`
--
ALTER TABLE `marketplace_items`
ADD PRIMARY KEY (`item_id`),
  ADD KEY `fk_item_category` (`category_id`);
--
-- Indexes for table `streaks`
--
ALTER TABLE `streaks`
ADD PRIMARY KEY (`id`),
  ADD KEY `fk_streaks_user` (`user_id`);
--
-- Indexes for table `tasks`
--
ALTER TABLE `tasks`
ADD PRIMARY KEY (`id`),
  ADD KEY `fk_tasks_user` (`user_id`);
--
-- Indexes for table `test_data`
--
ALTER TABLE `test_data`
ADD PRIMARY KEY (`id`);
--
-- Indexes for table `users`
--
ALTER TABLE `users`
ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD UNIQUE KEY `username_UNIQUE` (`username`);
--
-- Indexes for table `userstats`
--
ALTER TABLE `userstats`
ADD PRIMARY KEY (`id`),
  ADD KEY `fk_userstats_user` (`user_id`),
  ADD KEY `fk_userstats_avatar` (`avatar_id`);
--
-- Indexes for table `user_active_boosts`
--
ALTER TABLE `user_active_boosts`
ADD PRIMARY KEY (`boost_id`),
  ADD KEY `idx_user_boosts` (`user_id`);
--
-- Indexes for table `user_event`
--
ALTER TABLE `user_event`
ADD PRIMARY KEY (`id`),
  ADD KEY `fk_user_event_user` (`user_id`);
--
-- Indexes for table `user_event_completions`
--
ALTER TABLE `user_event_completions`
ADD PRIMARY KEY (`id`),
  ADD KEY `fk_user_event_completions_user` (`user_id`),
  ADD KEY `fk_user_event_completions_id` (`taskevent_id`);
--
-- Indexes for table `user_inventory`
--
ALTER TABLE `user_inventory`
ADD PRIMARY KEY (`inventory_id`),
  ADD KEY `fk_inventory_user` (`user_id`),
  ADD KEY `fk_inventory_item` (`item_id`);
--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `activity_log`
--
ALTER TABLE `activity_log`
MODIFY `log_id` int NOT NULL AUTO_INCREMENT,
  AUTO_INCREMENT = 84;
--
-- AUTO_INCREMENT for table `avatars`
--
ALTER TABLE `avatars`
MODIFY `id` int NOT NULL AUTO_INCREMENT,
  AUTO_INCREMENT = 5;
--
-- AUTO_INCREMENT for table `badhabits`
--
ALTER TABLE `badhabits`
MODIFY `id` int NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `dailytasks`
--
ALTER TABLE `dailytasks`
MODIFY `id` int NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `goodhabits`
--
ALTER TABLE `goodhabits`
MODIFY `id` int NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `item_categories`
--
ALTER TABLE `item_categories`
MODIFY `category_id` int NOT NULL AUTO_INCREMENT,
  AUTO_INCREMENT = 5;
--
-- AUTO_INCREMENT for table `item_usage_history`
--
ALTER TABLE `item_usage_history`
MODIFY `usage_id` int NOT NULL AUTO_INCREMENT,
  AUTO_INCREMENT = 37;
--
-- AUTO_INCREMENT for table `journals`
--
ALTER TABLE `journals`
MODIFY `id` int NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `marketplace_items`
--
ALTER TABLE `marketplace_items`
MODIFY `item_id` int NOT NULL AUTO_INCREMENT,
  AUTO_INCREMENT = 8;
--
-- AUTO_INCREMENT for table `streaks`
--
ALTER TABLE `streaks`
MODIFY `id` int NOT NULL AUTO_INCREMENT,
  AUTO_INCREMENT = 26;
--
-- AUTO_INCREMENT for table `tasks`
--
ALTER TABLE `tasks`
MODIFY `id` int NOT NULL AUTO_INCREMENT,
  AUTO_INCREMENT = 4;
--
-- AUTO_INCREMENT for table `test_data`
--
ALTER TABLE `test_data`
MODIFY `id` int NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
MODIFY `id` int NOT NULL AUTO_INCREMENT,
  AUTO_INCREMENT = 6;
--
-- AUTO_INCREMENT for table `userstats`
--
ALTER TABLE `userstats`
MODIFY `id` int NOT NULL AUTO_INCREMENT,
  AUTO_INCREMENT = 7;
--
-- AUTO_INCREMENT for table `user_active_boosts`
--
ALTER TABLE `user_active_boosts`
MODIFY `boost_id` int NOT NULL AUTO_INCREMENT,
  AUTO_INCREMENT = 4;
--
-- AUTO_INCREMENT for table `user_event`
--
ALTER TABLE `user_event`
MODIFY `id` int NOT NULL AUTO_INCREMENT,
  AUTO_INCREMENT = 5;
--
-- AUTO_INCREMENT for table `user_event_completions`
--
ALTER TABLE `user_event_completions`
MODIFY `id` int NOT NULL AUTO_INCREMENT,
  AUTO_INCREMENT = 7;
--
-- AUTO_INCREMENT for table `user_inventory`
--
ALTER TABLE `user_inventory`
MODIFY `inventory_id` int NOT NULL AUTO_INCREMENT,
  AUTO_INCREMENT = 8;
-- --------------------------------------------------------
--
-- Structure for view `streaks_view`
--
DROP TABLE IF EXISTS `streaks_view`;
CREATE ALGORITHM = UNDEFINED DEFINER = `root` @`localhost` SQL SECURITY DEFINER VIEW `streaks_view` AS
SELECT `streaks`.`id` AS `id`,
  `streaks`.`user_id` AS `user_id`,
  `streaks`.`streak_type` AS `streak_type`,
  `streaks`.`current_streak` AS `current_streak`,
  `streaks`.`longest_streak` AS `longest_streak`,
  `streaks`.`last_streak_date` AS `last_streak_date`,
  `streaks`.`last_streak_date` AS `last_activity_date`,
  `streaks`.`next_expected_date` AS `next_expected_date`
FROM `streaks`;
-- --------------------------------------------------------
--
-- Structure for view `user_items`
--
DROP TABLE IF EXISTS `user_items`;
CREATE ALGORITHM = UNDEFINED DEFINER = `root` @`localhost` SQL SECURITY DEFINER VIEW `user_items` AS
SELECT `u`.`id` AS `user_id`,
  `mi`.`item_name` AS `item_name`
FROM (
    (
      `users` `u`
      join `user_inventory` `ui` on((`u`.`id` = `ui`.`user_id`))
    )
    join `marketplace_items` `mi` on((`ui`.`item_id` = `mi`.`item_id`))
  );
-- --------------------------------------------------------
--
-- Structure for view `view_bad_habits_activity`
--
DROP TABLE IF EXISTS `view_bad_habits_activity`;
CREATE ALGORITHM = UNDEFINED DEFINER = `root` @`localhost` SQL SECURITY DEFINER VIEW `view_bad_habits_activity` AS
SELECT `a`.`log_id` AS `log_id`,
  `a`.`user_id` AS `user_id`,
  json_unquote(json_extract(`a`.`activity_details`, '$.title')) AS `activity_title`,
  json_unquote(
    json_extract(`a`.`activity_details`, '$.difficulty')
  ) AS `difficulty`,
  json_unquote(
    json_extract(`a`.`activity_details`, '$.category')
  ) AS `category`,
  json_unquote(json_extract(`a`.`activity_details`, '$.coins')) AS `coins`,
  json_unquote(json_extract(`a`.`activity_details`, '$.xp')) AS `xp`,
  `a`.`log_timestamp` AS `log_timestamp`
FROM (
    `activity_log` `a`
    join `users` `u` on((`a`.`user_id` = `u`.`id`))
  )
WHERE (`a`.`activity_type` = 'Bad Habit Logged');
-- --------------------------------------------------------
--
-- Structure for view `view_daily_task_activity`
--
DROP TABLE IF EXISTS `view_daily_task_activity`;
CREATE ALGORITHM = UNDEFINED DEFINER = `root` @`localhost` SQL SECURITY DEFINER VIEW `view_daily_task_activity` AS
SELECT `a`.`log_id` AS `log_id`,
  `a`.`user_id` AS `user_id`,
  json_unquote(json_extract(`a`.`activity_details`, '$.title')) AS `task_title`,
  json_unquote(
    json_extract(`a`.`activity_details`, '$.difficulty')
  ) AS `difficulty`,
  json_unquote(
    json_extract(`a`.`activity_details`, '$.category')
  ) AS `category`,
  json_unquote(json_extract(`a`.`activity_details`, '$.coins')) AS `coins`,
  json_unquote(json_extract(`a`.`activity_details`, '$.xp')) AS `xp`,
  `a`.`log_timestamp` AS `log_timestamp`
FROM (
    `activity_log` `a`
    join `users` `u` on((`a`.`user_id` = `u`.`id`))
  )
WHERE (`a`.`activity_type` = 'Daily Task Completed');
-- --------------------------------------------------------
--
-- Structure for view `view_event_activity`
--
DROP TABLE IF EXISTS `view_event_activity`;
CREATE ALGORITHM = UNDEFINED DEFINER = `root` @`localhost` SQL SECURITY DEFINER VIEW `view_event_activity` AS
SELECT `a`.`log_id` AS `log_id`,
  `a`.`user_id` AS `user_id`,
  `u`.`username` AS `username`,
  json_unquote(
    json_extract(`a`.`activity_details`, '$.event_id')
  ) AS `event_id`,
  json_unquote(
    json_extract(`a`.`activity_details`, '$.event_name')
  ) AS `event_name`,
  json_unquote(
    json_extract(`a`.`activity_details`, '$.event_description')
  ) AS `event_description`,
  json_unquote(
    json_extract(`a`.`activity_details`, '$.reward_coins')
  ) AS `coins`,
  json_unquote(
    json_extract(`a`.`activity_details`, '$.reward_xp')
  ) AS `xp`,
  json_unquote(
    json_extract(`a`.`activity_details`, '$.completed_at')
  ) AS `completion_time`,
  `a`.`log_timestamp` AS `log_timestamp`
FROM (
    `activity_log` `a`
    join `users` `u` on((`a`.`user_id` = `u`.`id`))
  )
WHERE (`a`.`activity_type` = 'Event Completed');
-- --------------------------------------------------------
--
-- Structure for view `view_good_habits_activity`
--
DROP TABLE IF EXISTS `view_good_habits_activity`;
CREATE ALGORITHM = UNDEFINED DEFINER = `root` @`localhost` SQL SECURITY DEFINER VIEW `view_good_habits_activity` AS
SELECT `a`.`log_id` AS `log_id`,
  `a`.`user_id` AS `user_id`,
  json_unquote(json_extract(`a`.`activity_details`, '$.title')) AS `activity_title`,
  json_unquote(
    json_extract(`a`.`activity_details`, '$.difficulty')
  ) AS `difficulty`,
  json_unquote(
    json_extract(`a`.`activity_details`, '$.category')
  ) AS `category`,
  json_unquote(json_extract(`a`.`activity_details`, '$.coins')) AS `coins`,
  json_unquote(json_extract(`a`.`activity_details`, '$.xp')) AS `xp`,
  `a`.`log_timestamp` AS `log_timestamp`
FROM (
    `activity_log` `a`
    join `users` `u` on((`a`.`user_id` = `u`.`id`))
  )
WHERE (`a`.`activity_type` = 'Good Habit Logged');
-- --------------------------------------------------------
--
-- Structure for view `view_poke_activity`
--
DROP TABLE IF EXISTS `view_poke_activity`;
CREATE ALGORITHM = UNDEFINED DEFINER = `root` @`localhost` SQL SECURITY DEFINER VIEW `view_poke_activity` AS
SELECT `a`.`log_id` AS `log_id`,
  `a`.`user_id` AS `target_user_id`,
  json_unquote(
    json_extract(`a`.`activity_details`, '$.poker_id')
  ) AS `poker_user_id`,
  json_unquote(
    json_extract(`a`.`activity_details`, '$.poker_name')
  ) AS `poker_username`,
  `a`.`log_timestamp` AS `poke_timestamp`,
  `u1`.`username` AS `target_username`,
  `u2`.`username` AS `poker_username_from_users`
FROM (
    (
      `activity_log` `a`
      join `users` `u1` on((`a`.`user_id` = `u1`.`id`))
    )
    left join `users` `u2` on(
      (
        json_unquote(
          json_extract(`a`.`activity_details`, '$.poker_id')
        ) = `u2`.`id`
      )
    )
  )
WHERE (`a`.`activity_type` = 'User Poked');
-- --------------------------------------------------------
--
-- Structure for view `view_task_activity`
--
DROP TABLE IF EXISTS `view_task_activity`;
CREATE ALGORITHM = UNDEFINED DEFINER = `root` @`localhost` SQL SECURITY DEFINER VIEW `view_task_activity` AS
SELECT `a`.`log_id` AS `log_id`,
  `a`.`user_id` AS `user_id`,
  json_unquote(json_extract(`a`.`activity_details`, '$.title')) AS `task_title`,
  json_unquote(
    json_extract(`a`.`activity_details`, '$.difficulty')
  ) AS `difficulty`,
  json_unquote(
    json_extract(`a`.`activity_details`, '$.category')
  ) AS `category`,
  json_unquote(json_extract(`a`.`activity_details`, '$.coins')) AS `coins`,
  json_unquote(json_extract(`a`.`activity_details`, '$.xp')) AS `xp`,
  `a`.`log_timestamp` AS `log_timestamp`
FROM (
    `activity_log` `a`
    join `users` `u` on((`a`.`user_id` = `u`.`id`))
  )
WHERE (`a`.`activity_type` = 'Task Completed');
--
-- Constraints for dumped tables
--

--
-- Constraints for table `activity_log`
--
ALTER TABLE `activity_log`
ADD CONSTRAINT `fk_log_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
--
-- Constraints for table `badhabits`
--
ALTER TABLE `badhabits`
ADD CONSTRAINT `fk_badhabits_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
--
-- Constraints for table `dailytasks`
--
ALTER TABLE `dailytasks`
ADD CONSTRAINT `fk_dailytasks_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
--
-- Constraints for table `goodhabits`
--
ALTER TABLE `goodhabits`
ADD CONSTRAINT `fk_goodhabits_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
--
-- Constraints for table `item_usage_history`
--
ALTER TABLE `item_usage_history`
ADD CONSTRAINT `fk_usage_inventory` FOREIGN KEY (`inventory_id`) REFERENCES `user_inventory` (`inventory_id`);
--
-- Constraints for table `journals`
--
ALTER TABLE `journals`
ADD CONSTRAINT `fk_journals_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
--
-- Constraints for table `marketplace_items`
--
ALTER TABLE `marketplace_items`
ADD CONSTRAINT `fk_item_category` FOREIGN KEY (`category_id`) REFERENCES `item_categories` (`category_id`);
--
-- Constraints for table `streaks`
--
ALTER TABLE `streaks`
ADD CONSTRAINT `fk_streaks_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
--
-- Constraints for table `tasks`
--
ALTER TABLE `tasks`
ADD CONSTRAINT `fk_tasks_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
--
-- Constraints for table `userstats`
--
ALTER TABLE `userstats`
ADD CONSTRAINT `fk_userstats_avatar` FOREIGN KEY (`avatar_id`) REFERENCES `avatars` (`id`),
  ADD CONSTRAINT `fk_userstats_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
--
-- Constraints for table `user_event`
--
ALTER TABLE `user_event`
ADD CONSTRAINT `fk_user_event_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
--
-- Constraints for table `user_event_completions`
--
ALTER TABLE `user_event_completions`
ADD CONSTRAINT `fk_user_event_completions_id` FOREIGN KEY (`taskevent_id`) REFERENCES `user_event` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_user_event_completions_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
--
-- Constraints for table `user_inventory`
--
ALTER TABLE `user_inventory`
ADD CONSTRAINT `fk_inventory_item` FOREIGN KEY (`item_id`) REFERENCES `marketplace_items` (`item_id`),
  ADD CONSTRAINT `fk_inventory_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);
COMMIT;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */
;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */
;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */
;
-- CLEANUP: Remove duplicate userstats rows, keep the one with the lowest id per user_id
DELETE us1
FROM userstats us1
  JOIN userstats us2 ON us1.user_id = us2.user_id
  AND us1.id > us2.id;
-- Ensure every user has a userstats row (insert for missing users)
INSERT INTO userstats (
    user_id,
    level,
    xp,
    health,
    avatar_id,
    objective,
    physicalHealth,
    mentalWellness,
    personalGrowth,
    careerStudies,
    finance,
    homeEnvironment,
    relationshipsSocial,
    passionHobbies
  )
SELECT u.id,
  1,
  0,
  100,
  1,
  'Auto-created',
  5,
  5,
  5,
  5,
  5,
  5,
  5,
  5
FROM users u
  LEFT JOIN userstats us ON u.id = us.user_id
WHERE us.user_id IS NULL;
-- Add a unique constraint to userstats.user_id
ALTER TABLE userstats
ADD CONSTRAINT unique_userstats_user UNIQUE (user_id);
-- =============================
-- POST-IMPORT CLEANUP: Ensure userstats is unique per user and valid
-- =============================
-- Remove duplicate userstats rows, keep the one with the lowest id per user_id
DELETE us1
FROM userstats us1
  JOIN userstats us2 ON us1.user_id = us2.user_id
  AND us1.id > us2.id;
-- Ensure every user has a userstats row (insert for missing users)
INSERT INTO userstats (
    user_id,
    level,
    xp,
    health,
    avatar_id,
    objective,
    physicalHealth,
    mentalWellness,
    personalGrowth,
    careerStudies,
    finance,
    homeEnvironment,
    relationshipsSocial,
    passionHobbies
  )
SELECT u.id,
  1,
  0,
  100,
  1,
  'Auto-created',
  5,
  5,
  5,
  5,
  5,
  5,
  5,
  5
FROM users u
  LEFT JOIN userstats us ON u.id = us.user_id
WHERE us.user_id IS NULL;
-- Add a unique constraint to userstats.user_id
ALTER TABLE userstats
ADD CONSTRAINT unique_userstats_user UNIQUE (user_id);