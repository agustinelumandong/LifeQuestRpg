-- phpMyAdmin SQL Dump
-- version 6.0.0-dev+20250328.9291a9ff8f
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: May 28, 2025 at 02:52 AM
-- Server version: 8.4.3
-- PHP Version: 8.4.3

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `lifequestrpg`
--

DELIMITER $$
--
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
    ),    NOW()
  );
SELECT ROW_COUNT() AS success;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `PurchaseMarketplaceItem` (IN `p_user_id` INT, IN `p_item_id` INT, IN `p_quantity` INT)   proc: BEGIN
    DECLARE v_item_price DECIMAL(10, 2);
    DECLARE v_user_coins INT;
    DECLARE v_item_name VARCHAR(255);
    DECLARE v_item_type VARCHAR(50);
    DECLARE v_item_status VARCHAR(50);
    DECLARE v_total_cost DECIMAL(10, 2);
    DECLARE v_existing_inventory_id INT DEFAULT NULL;
    DECLARE v_existing_quantity INT DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Purchase failed due to database error!' AS message;
    END;
    
    -- Handle default quantity if null or 0
    IF p_quantity IS NULL OR p_quantity <= 0 THEN
        SET p_quantity = 1;
    END IF;
    
    -- Start transaction
    START TRANSACTION;
    
    -- Get item details
    SELECT item_price, item_name, item_type, status 
    INTO v_item_price, v_item_name, v_item_type, v_item_status
    FROM marketplace_items
    WHERE item_id = p_item_id;
    
    -- Check if item exists
    IF v_item_price IS NULL THEN
        SELECT 'Item not found!' AS message;
        ROLLBACK;
        LEAVE proc;
    END IF;
    
    -- Check if item is available (match your PHP logic: disabled = not available)
    IF v_item_status = 'disabled' THEN
        SELECT 'Item is not available for purchase.' AS message;
        ROLLBACK;
        LEAVE proc;
    END IF;
    
    -- Handle one-time purchase items (collectibles and equipment)
    IF v_item_type IN ('collectible', 'equipment') THEN
        -- Check if user already owns this item
        SELECT inventory_id INTO v_existing_inventory_id
        FROM user_inventory 
        WHERE user_id = p_user_id AND item_id = p_item_id
        LIMIT 1;
        
        IF v_existing_inventory_id IS NOT NULL THEN
            SELECT CONCAT('You already own this ', v_item_type, '. This item can only be purchased once.') AS message;
            ROLLBACK;
            LEAVE proc;
        END IF;
        
        -- Force quantity to 1 for one-time purchase items
        SET p_quantity = 1;
    END IF;
    
    -- Calculate total cost
    SET v_total_cost = v_item_price * p_quantity;
    
    -- Get user coins
    SELECT coins INTO v_user_coins
    FROM users
    WHERE id = p_user_id;
    
    IF v_user_coins IS NULL THEN
        SELECT 'User not found!' AS message;
        ROLLBACK;
        LEAVE proc;
    END IF;
    
    IF v_user_coins < v_total_cost THEN
        SELECT 'Insufficient coins for this purchase.' AS message;
        ROLLBACK;
        LEAVE proc;
    END IF;
    
    -- Deduct coins
    UPDATE users
    SET coins = coins - v_total_cost
    WHERE id = p_user_id;
    
    -- Reset variables for reuse
    SET v_existing_inventory_id = NULL;
    SET v_existing_quantity = 0;
    
    -- Check if item already exists in inventory (for multi-purchase items)
    SELECT inventory_id, quantity INTO v_existing_inventory_id, v_existing_quantity
    FROM user_inventory 
    WHERE user_id = p_user_id AND item_id = p_item_id
    LIMIT 1;
    
    IF v_existing_inventory_id IS NOT NULL THEN
        -- For multi-purchase items (boosts, consumables), update quantity
        IF v_item_type IN ('boost', 'consumable') THEN
            UPDATE user_inventory 
            SET quantity = quantity + p_quantity 
            WHERE inventory_id = v_existing_inventory_id;
        END IF;
        -- Note: One-time items won't reach here due to earlier check
    ELSE
        -- Insert new item
        INSERT INTO user_inventory (user_id, item_id, quantity, acquired_at)
        VALUES (p_user_id, p_item_id, p_quantity, NOW());
    END IF;
    
    -- Log purchase in activity_log (if table exists)
    INSERT INTO activity_log (user_id, activity_type, activity_details)
    VALUES (
        p_user_id,
        'ITEM_PURCHASED',
        JSON_OBJECT(
            'item_id', p_item_id, 
            'item_name', v_item_name,
            'quantity', p_quantity,
            'total_cost', v_total_cost
        )
    );
    
    -- Commit transaction
    COMMIT;
    
    -- Return success message matching your PHP logic
    IF v_item_type IN ('collectible', 'equipment') THEN
        SELECT CONCAT('Purchase successful! You acquired this ', v_item_type, ' for ', v_total_cost, ' coins.') AS message;
    ELSE
        SELECT CONCAT('Purchase successful! You bought ', p_quantity, ' item(s) for ', v_total_cost, ' coins.') AS message;
    END IF;
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `UseInventoryItem` (IN `p_inventory_id` INT, IN `p_user_id` INT)   proc_label: BEGIN
DECLARE v_item_id INT;
DECLARE v_item_name VARCHAR(255);
DECLARE v_item_type VARCHAR(50);
DECLARE v_effect_type VARCHAR(50);
DECLARE v_effect_value INT;
DECLARE v_quantity INT;
-- Get inventory item details
SELECT ui.item_id,
  mi.item_name,
  mi.item_type,
  mi.effect_type,
  mi.effect_value,
  ui.quantity INTO v_item_id,
  v_item_name,
  v_item_type,
  v_effect_type,
  v_effect_value,
  v_quantity
FROM user_inventory ui
  JOIN marketplace_items mi ON ui.item_id = mi.item_id
WHERE ui.inventory_id = p_inventory_id
  AND ui.user_id = p_user_id;
IF v_item_id IS NULL THEN
SELECT 'Item not found in inventory!' AS message;
LEAVE proc_label;
END IF;
-- Use the item based on type
IF v_item_type = 'consumable' THEN -- Handle consumable items
IF v_effect_type = 'health_restore' THEN
UPDATE userstats
SET health = LEAST(health + v_effect_value, 10)
WHERE user_id = p_user_id;
ELSEIF v_effect_type = 'xp_boost' THEN -- Add XP boost (simplified)
INSERT INTO user_active_boosts (
    user_id,
    boost_type,
    boost_value,
    activated_at,
    expires_at
  )
VALUES (
    p_user_id,
    'xp_multiplier',
    v_effect_value,
    NOW(),
    DATE_ADD(NOW(), INTERVAL 1 HOUR)
  );
END IF;
-- Reduce quantity
IF v_quantity > 1 THEN
UPDATE user_inventory
SET quantity = quantity - 1
WHERE inventory_id = p_inventory_id;
ELSE
DELETE FROM user_inventory
WHERE inventory_id = p_inventory_id;
END IF;
ELSEIF v_item_type = 'equipment' THEN -- Handle equipment (simplified - just mark as equipped)
SELECT 'Item equipped successfully' AS effect_message;
END IF;
-- Log usage
INSERT INTO activity_log (user_id, activity_type, activity_details)
VALUES (
    p_user_id,
    'item_use',
    JSON_OBJECT('message', CONCAT('Used item: ', v_item_name))
  );
-- Record in usage history
INSERT INTO item_usage_history (inventory_id, used_at, effect_applied)
VALUES (
    p_inventory_id,
    NOW(),
    CONCAT('Applied ', v_effect_type, ' effect')
  );
SELECT CONCAT('Successfully used ', v_item_name) AS message;
END$$

DELIMITER ;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `activity_log`
--

INSERT INTO `activity_log` (`log_id`, `user_id`, `activity_type`, `activity_details`, `log_timestamp`) VALUES
(5, 1, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-05 00:33:32\"}', '2025-05-27 00:33:32'),
(6, 1, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-27 00:33:32\"}', '2025-05-27 00:33:32'),
(7, 1, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-03 00:33:32\"}', '2025-05-27 00:33:32'),
(8, 2, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-03 00:33:32\"}', '2025-05-27 00:33:32'),
(9, 2, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-22 00:33:32\"}', '2025-05-27 00:33:32'),
(10, 2, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-09 00:33:32\"}', '2025-05-27 00:33:32'),
(11, 2, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-13 00:33:32\"}', '2025-05-27 00:33:32'),
(12, 2, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-04-28 00:33:32\"}', '2025-05-27 00:33:32'),
(13, 2, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-15 00:33:32\"}', '2025-05-27 00:33:32'),
(14, 2, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-04-29 00:33:32\"}', '2025-05-27 00:33:32'),
(15, 2, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-16 00:33:32\"}', '2025-05-27 00:33:32'),
(16, 3, 'ITEM_PURCHASED', '{\"item_id\":4,\"item_name\":\"Golden Trophy\"}', '2025-05-27 00:33:32'),
(17, 3, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-27 00:33:32\"}', '2025-05-27 00:33:32'),
(18, 3, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-14 00:33:32\"}', '2025-05-27 00:33:32'),
(19, 3, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-04-27 00:33:32\"}', '2025-05-27 00:33:32'),
(20, 3, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-08 00:33:32\"}', '2025-05-27 00:33:32'),
(21, 4, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-17 00:33:32\"}', '2025-05-27 00:33:32'),
(22, 4, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-04-29 00:33:32\"}', '2025-05-27 00:33:32'),
(23, 4, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-04-28 00:33:32\"}', '2025-05-27 00:33:32'),
(24, 4, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-01 00:33:32\"}', '2025-05-27 00:33:32'),
(25, 5, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-16 00:33:32\"}', '2025-05-27 00:33:32'),
(26, 5, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-17 00:33:32\"}', '2025-05-27 00:33:32'),
(27, 5, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-04-28 00:33:32\"}', '2025-05-27 00:33:32'),
(28, 5, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-20 00:33:32\"}', '2025-05-27 00:33:32'),
(29, 5, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-16 00:33:32\"}', '2025-05-27 00:33:32'),
(30, 1, 'ITEM_PURCHASED', '{\"item_id\":2,\"item_name\":\"XP Booster\"}', '2025-05-27 00:33:58'),
(31, 1, 'ITEM_PURCHASED', '{\"item_id\":4,\"item_name\":\"Golden Trophy\"}', '2025-05-27 00:33:58'),
(32, 1, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-17 00:33:58\"}', '2025-05-27 00:33:58'),
(33, 1, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-25 00:33:58\"}', '2025-05-27 00:33:58'),
(34, 2, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-20 00:33:58\"}', '2025-05-27 00:33:58'),
(35, 2, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-07 00:33:58\"}', '2025-05-27 00:33:58'),
(36, 2, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-26 00:33:58\"}', '2025-05-27 00:33:58'),
(37, 2, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-20 00:33:58\"}', '2025-05-27 00:33:58'),
(38, 2, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-14 00:33:58\"}', '2025-05-27 00:33:58'),
(39, 2, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-26 00:33:58\"}', '2025-05-27 00:33:58'),
(40, 3, 'ITEM_PURCHASED', '{\"item_id\":3,\"item_name\":\"Focus Crystal\"}', '2025-05-27 00:33:58'),
(41, 3, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-08 00:33:58\"}', '2025-05-27 00:33:58'),
(42, 3, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-26 00:33:58\"}', '2025-05-27 00:33:58'),
(43, 3, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-20 00:33:58\"}', '2025-05-27 00:33:58'),
(44, 3, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-22 00:33:58\"}', '2025-05-27 00:33:58'),
(45, 3, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-10 00:33:58\"}', '2025-05-27 00:33:58'),
(46, 3, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-07 00:33:58\"}', '2025-05-27 00:33:58'),
(47, 3, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-19 00:33:58\"}', '2025-05-27 00:33:58'),
(48, 4, 'ITEM_PURCHASED', '{\"item_id\":2,\"item_name\":\"XP Booster\"}', '2025-05-27 00:33:58'),
(49, 4, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-04-28 00:33:58\"}', '2025-05-27 00:33:58'),
(50, 4, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-20 00:33:58\"}', '2025-05-27 00:33:58'),
(51, 4, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-22 00:33:58\"}', '2025-05-27 00:33:58'),
(52, 4, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-14 00:33:58\"}', '2025-05-27 00:33:58'),
(53, 4, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-24 00:33:58\"}', '2025-05-27 00:33:58'),
(54, 4, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-04-27 00:33:58\"}', '2025-05-27 00:33:58'),
(55, 4, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-14 00:33:58\"}', '2025-05-27 00:33:58'),
(56, 5, 'ITEM_PURCHASED', '{\"item_id\":2,\"item_name\":\"XP Booster\"}', '2025-05-27 00:33:58'),
(57, 5, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-13 00:33:58\"}', '2025-05-27 00:33:58'),
(58, 5, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-10 00:33:58\"}', '2025-05-27 00:33:58'),
(59, 5, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-09 00:33:58\"}', '2025-05-27 00:33:58'),
(60, 5, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-25 00:33:58\"}', '2025-05-27 00:33:58'),
(61, 5, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-20 00:33:58\"}', '2025-05-27 00:33:58'),
(62, 5, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-07 00:33:58\"}', '2025-05-27 00:33:58'),
(63, 1, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-13 00:35:36\"}', '2025-05-27 00:35:36'),
(64, 1, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-17 00:35:36\"}', '2025-05-27 00:35:36'),
(65, 1, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-20 00:35:36\"}', '2025-05-27 00:35:36'),
(66, 1, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-22 00:35:36\"}', '2025-05-27 00:35:36'),
(67, 2, 'ITEM_PURCHASED', '{\"item_id\":3,\"item_name\":\"Focus Crystal\"}', '2025-05-27 00:35:36'),
(68, 2, 'ITEM_PURCHASED', '{\"item_id\":1,\"item_name\":\"Health Potion\"}', '2025-05-27 00:35:36'),
(69, 2, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-02 00:35:36\"}', '2025-05-27 00:35:36'),
(70, 2, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-08 00:35:36\"}', '2025-05-27 00:35:36'),
(71, 2, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-13 00:35:36\"}', '2025-05-27 00:35:36'),
(72, 2, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-22 00:35:36\"}', '2025-05-27 00:35:36'),
(73, 2, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-22 00:35:36\"}', '2025-05-27 00:35:36'),
(74, 3, 'ITEM_PURCHASED', '{\"item_id\":1,\"item_name\":\"Health Potion\"}', '2025-05-27 00:35:36'),
(75, 3, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-26 00:35:36\"}', '2025-05-27 00:35:36'),
(76, 3, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-22 00:35:36\"}', '2025-05-27 00:35:36'),
(77, 3, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-19 00:35:36\"}', '2025-05-27 00:35:36'),
(78, 3, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-18 00:35:36\"}', '2025-05-27 00:35:36'),
(79, 4, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-04-29 00:35:36\"}', '2025-05-27 00:35:36'),
(80, 4, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-11 00:35:36\"}', '2025-05-27 00:35:36'),
(81, 4, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-03 00:35:36\"}', '2025-05-27 00:35:36'),
(82, 4, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-23 00:35:36\"}', '2025-05-27 00:35:36'),
(83, 4, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-09 00:35:36\"}', '2025-05-27 00:35:36'),
(84, 4, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-05 00:35:36\"}', '2025-05-27 00:35:36'),
(85, 4, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-12 00:35:36\"}', '2025-05-27 00:35:36'),
(86, 4, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-12 00:35:36\"}', '2025-05-27 00:35:36'),
(87, 5, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-15 00:35:36\"}', '2025-05-27 00:35:36'),
(88, 5, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-04-29 00:35:36\"}', '2025-05-27 00:35:36'),
(89, 5, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-13 00:35:36\"}', '2025-05-27 00:35:36'),
(90, 5, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-25 00:35:36\"}', '2025-05-27 00:35:36'),
(91, 5, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-25 00:35:36\"}', '2025-05-27 00:35:36'),
(92, 5, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-11 00:35:36\"}', '2025-05-27 00:35:36'),
(93, 5, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-20 00:35:36\"}', '2025-05-27 00:35:36'),
(94, 5, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-12 00:35:36\"}', '2025-05-27 00:35:36'),
(95, 6, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-13 00:35:36\"}', '2025-05-27 00:35:36'),
(96, 6, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-23 00:35:36\"}', '2025-05-27 00:35:36'),
(97, 6, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-18 00:35:36\"}', '2025-05-27 00:35:36'),
(98, 7, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-04-28 00:35:36\"}', '2025-05-27 00:35:36'),
(99, 7, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-04-30 00:35:36\"}', '2025-05-27 00:35:36'),
(100, 8, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-03 00:35:36\"}', '2025-05-27 00:35:36'),
(101, 8, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-04 00:35:36\"}', '2025-05-27 00:35:36'),
(102, 8, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-02 00:35:36\"}', '2025-05-27 00:35:36'),
(103, 8, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-22 00:35:36\"}', '2025-05-27 00:35:36'),
(104, 9, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-04 00:35:36\"}', '2025-05-27 00:35:36'),
(105, 9, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-13 00:35:36\"}', '2025-05-27 00:35:36'),
(106, 9, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-20 00:35:36\"}', '2025-05-27 00:35:36'),
(107, 9, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-15 00:35:36\"}', '2025-05-27 00:35:36'),
(108, 9, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-07 00:35:36\"}', '2025-05-27 00:35:36'),
(109, 9, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-04-29 00:35:36\"}', '2025-05-27 00:35:36'),
(110, 9, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-20 00:35:36\"}', '2025-05-27 00:35:36'),
(111, 9, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-14 00:35:36\"}', '2025-05-27 00:35:36'),
(112, 10, 'ITEM_PURCHASED', '{\"item_id\":4,\"item_name\":\"Golden Trophy\"}', '2025-05-27 00:35:36'),
(113, 10, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-06 00:35:36\"}', '2025-05-27 00:35:36'),
(114, 10, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-11 00:35:36\"}', '2025-05-27 00:35:36'),
(115, 10, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-19 00:35:36\"}', '2025-05-27 00:35:36'),
(116, 10, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-25 00:35:36\"}', '2025-05-27 00:35:36'),
(117, 10, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-04-30 00:35:36\"}', '2025-05-27 00:35:36'),
(118, 10, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-05 00:35:36\"}', '2025-05-27 00:35:36'),
(119, 1, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-14 00:35:57\"}', '2025-05-27 00:35:57'),
(120, 1, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-22 00:35:57\"}', '2025-05-27 00:35:57'),
(121, 2, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-22 00:35:57\"}', '2025-05-27 00:35:57'),
(122, 2, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-23 00:35:57\"}', '2025-05-27 00:35:57'),
(123, 2, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-08 00:35:57\"}', '2025-05-27 00:35:57'),
(124, 2, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-22 00:35:57\"}', '2025-05-27 00:35:57'),
(125, 3, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-06 00:35:57\"}', '2025-05-27 00:35:57'),
(126, 3, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-21 00:35:57\"}', '2025-05-27 00:35:57'),
(127, 3, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-27 00:35:57\"}', '2025-05-27 00:35:57'),
(128, 3, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-05 00:35:57\"}', '2025-05-27 00:35:57'),
(129, 3, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-18 00:35:57\"}', '2025-05-27 00:35:57'),
(130, 3, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-18 00:35:57\"}', '2025-05-27 00:35:57'),
(131, 4, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-04-30 00:35:57\"}', '2025-05-27 00:35:57'),
(132, 4, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-25 00:35:57\"}', '2025-05-27 00:35:57'),
(133, 4, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-05 00:35:57\"}', '2025-05-27 00:35:57'),
(134, 4, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-04-30 00:35:57\"}', '2025-05-27 00:35:57'),
(135, 4, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-25 00:35:57\"}', '2025-05-27 00:35:57'),
(136, 4, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-27 00:35:57\"}', '2025-05-27 00:35:57'),
(137, 4, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-14 00:35:57\"}', '2025-05-27 00:35:57'),
(138, 4, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-19 00:35:57\"}', '2025-05-27 00:35:57'),
(139, 5, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-16 00:35:57\"}', '2025-05-27 00:35:57'),
(140, 5, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-02 00:35:57\"}', '2025-05-27 00:35:57'),
(141, 6, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-04 00:35:57\"}', '2025-05-27 00:35:57'),
(142, 6, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-07 00:35:57\"}', '2025-05-27 00:35:57'),
(143, 6, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-18 00:35:57\"}', '2025-05-27 00:35:57'),
(144, 7, 'ITEM_PURCHASED', '{\"item_id\":2,\"item_name\":\"XP Booster\"}', '2025-05-27 00:35:57'),
(145, 7, 'ITEM_PURCHASED', '{\"item_id\":3,\"item_name\":\"Focus Crystal\"}', '2025-05-27 00:35:57'),
(146, 7, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-03 00:35:57\"}', '2025-05-27 00:35:57'),
(147, 7, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-19 00:35:57\"}', '2025-05-27 00:35:57'),
(148, 8, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-17 00:35:57\"}', '2025-05-27 00:35:57'),
(149, 8, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-02 00:35:57\"}', '2025-05-27 00:35:57'),
(150, 8, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-06 00:35:57\"}', '2025-05-27 00:35:57'),
(151, 8, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-26 00:35:57\"}', '2025-05-27 00:35:57'),
(152, 8, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-17 00:35:57\"}', '2025-05-27 00:35:57'),
(153, 9, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-23 00:35:57\"}', '2025-05-27 00:35:57'),
(154, 9, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-05 00:35:57\"}', '2025-05-27 00:35:57'),
(155, 9, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-27 00:35:57\"}', '2025-05-27 00:35:57'),
(156, 10, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-09 00:35:57\"}', '2025-05-27 00:35:57'),
(157, 10, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-02 00:35:57\"}', '2025-05-27 00:35:57'),
(158, 10, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-09 00:35:57\"}', '2025-05-27 00:35:57'),
(159, 10, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-16 00:35:57\"}', '2025-05-27 00:35:57'),
(160, 10, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-26 00:35:57\"}', '2025-05-27 00:35:57'),
(161, 10, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-21 00:35:57\"}', '2025-05-27 00:35:57'),
(162, 11, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-15 00:35:57\"}', '2025-05-27 00:35:57'),
(163, 11, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-22 00:35:57\"}', '2025-05-27 00:35:57'),
(164, 11, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-04-29 00:35:57\"}', '2025-05-27 00:35:57'),
(165, 11, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-18 00:35:57\"}', '2025-05-27 00:35:57'),
(166, 11, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-09 00:35:57\"}', '2025-05-27 00:35:57'),
(167, 12, 'ITEM_PURCHASED', '{\"item_id\":4,\"item_name\":\"Golden Trophy\"}', '2025-05-27 00:35:57'),
(168, 12, 'ITEM_PURCHASED', '{\"item_id\":2,\"item_name\":\"XP Booster\"}', '2025-05-27 00:35:57'),
(169, 12, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-03 00:35:57\"}', '2025-05-27 00:35:57'),
(170, 12, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-04-29 00:35:57\"}', '2025-05-27 00:35:57'),
(171, 12, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-18 00:35:57\"}', '2025-05-27 00:35:57'),
(172, 12, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-21 00:35:57\"}', '2025-05-27 00:35:57'),
(173, 12, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-25 00:35:57\"}', '2025-05-27 00:35:57'),
(174, 12, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-05 00:35:57\"}', '2025-05-27 00:35:57'),
(175, 13, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-10 00:35:58\"}', '2025-05-27 00:35:58'),
(176, 13, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-20 00:35:58\"}', '2025-05-27 00:35:58'),
(177, 13, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-18 00:35:58\"}', '2025-05-27 00:35:58'),
(178, 13, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-04-30 00:35:58\"}', '2025-05-27 00:35:58'),
(179, 13, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-24 00:35:58\"}', '2025-05-27 00:35:58'),
(180, 14, 'ITEM_PURCHASED', '{\"item_id\":4,\"item_name\":\"Golden Trophy\"}', '2025-05-27 00:35:58'),
(181, 14, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-16 00:35:58\"}', '2025-05-27 00:35:58'),
(182, 14, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-14 00:35:58\"}', '2025-05-27 00:35:58'),
(183, 14, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-04 00:35:58\"}', '2025-05-27 00:35:58'),
(184, 14, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-25 00:35:58\"}', '2025-05-27 00:35:58'),
(185, 14, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-12 00:35:58\"}', '2025-05-27 00:35:58'),
(186, 14, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-12 00:35:58\"}', '2025-05-27 00:35:58'),
(187, 14, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-15 00:35:58\"}', '2025-05-27 00:35:58'),
(188, 14, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-05 00:35:58\"}', '2025-05-27 00:35:58'),
(189, 15, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-23 00:35:58\"}', '2025-05-27 00:35:58'),
(190, 15, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-02 00:35:58\"}', '2025-05-27 00:35:58'),
(191, 15, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-25 00:35:58\"}', '2025-05-27 00:35:58'),
(192, 16, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-03 00:35:58\"}', '2025-05-27 00:35:58'),
(193, 16, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-26 00:35:58\"}', '2025-05-27 00:35:58'),
(194, 16, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-26 00:35:58\"}', '2025-05-27 00:35:58'),
(195, 16, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-20 00:35:58\"}', '2025-05-27 00:35:58'),
(196, 16, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-02 00:35:58\"}', '2025-05-27 00:35:58'),
(197, 17, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-01 00:35:58\"}', '2025-05-27 00:35:58'),
(198, 17, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-17 00:35:58\"}', '2025-05-27 00:35:58'),
(199, 17, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-10 00:35:58\"}', '2025-05-27 00:35:58'),
(200, 17, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-04-29 00:35:58\"}', '2025-05-27 00:35:58'),
(201, 17, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-21 00:35:58\"}', '2025-05-27 00:35:58'),
(202, 17, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-02 00:35:58\"}', '2025-05-27 00:35:58'),
(203, 18, 'ITEM_PURCHASED', '{\"item_id\":2,\"item_name\":\"XP Booster\"}', '2025-05-27 00:35:58'),
(204, 18, 'ITEM_PURCHASED', '{\"item_id\":4,\"item_name\":\"Golden Trophy\"}', '2025-05-27 00:35:58'),
(205, 18, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-04-29 00:35:58\"}', '2025-05-27 00:35:58'),
(206, 18, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-14 00:35:58\"}', '2025-05-27 00:35:58'),
(207, 18, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-14 00:35:58\"}', '2025-05-27 00:35:58'),
(208, 18, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-04 00:35:58\"}', '2025-05-27 00:35:58'),
(209, 19, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-17 00:35:58\"}', '2025-05-27 00:35:58'),
(210, 19, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-10 00:35:58\"}', '2025-05-27 00:35:58'),
(211, 19, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-24 00:35:58\"}', '2025-05-27 00:35:58'),
(212, 19, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-24 00:35:58\"}', '2025-05-27 00:35:58'),
(213, 19, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-10 00:35:58\"}', '2025-05-27 00:35:58'),
(214, 20, 'ITEM_PURCHASED', '{\"item_id\":3,\"item_name\":\"Focus Crystal\"}', '2025-05-27 00:35:58'),
(215, 20, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-05 00:35:58\"}', '2025-05-27 00:35:58'),
(216, 20, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-23 00:35:58\"}', '2025-05-27 00:35:58'),
(217, 20, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-04-27 00:35:58\"}', '2025-05-27 00:35:58'),
(218, 20, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-04-28 00:35:58\"}', '2025-05-27 00:35:58'),
(219, 20, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-15 00:35:58\"}', '2025-05-27 00:35:58'),
(220, 20, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-22 00:35:58\"}', '2025-05-27 00:35:58'),
(221, 20, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-06 00:35:58\"}', '2025-05-27 00:35:58'),
(222, 20, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-22 00:35:58\"}', '2025-05-27 00:35:58'),
(223, 21, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-15 00:35:58\"}', '2025-05-27 00:35:58'),
(224, 21, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-02 00:35:58\"}', '2025-05-27 00:35:58'),
(225, 21, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-19 00:35:58\"}', '2025-05-27 00:35:58'),
(226, 21, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-23 00:35:58\"}', '2025-05-27 00:35:58'),
(227, 22, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-16 00:35:58\"}', '2025-05-27 00:35:58'),
(228, 22, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-04-28 00:35:58\"}', '2025-05-27 00:35:58'),
(229, 22, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-01 00:35:58\"}', '2025-05-27 00:35:58'),
(230, 22, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-19 00:35:58\"}', '2025-05-27 00:35:58'),
(231, 22, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-26 00:35:58\"}', '2025-05-27 00:35:58'),
(232, 22, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-11 00:35:58\"}', '2025-05-27 00:35:58'),
(233, 23, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-04 00:35:58\"}', '2025-05-27 00:35:58'),
(234, 23, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-23 00:35:58\"}', '2025-05-27 00:35:58'),
(235, 23, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-20 00:35:58\"}', '2025-05-27 00:35:58'),
(236, 23, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-09 00:35:58\"}', '2025-05-27 00:35:58'),
(237, 23, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-02 00:35:58\"}', '2025-05-27 00:35:58'),
(238, 23, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-07 00:35:58\"}', '2025-05-27 00:35:58'),
(239, 24, 'ITEM_PURCHASED', '{\"item_id\":2,\"item_name\":\"XP Booster\"}', '2025-05-27 00:35:58'),
(240, 24, 'ITEM_PURCHASED', '{\"item_id\":1,\"item_name\":\"Health Potion\"}', '2025-05-27 00:35:58'),
(241, 24, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-06 00:35:58\"}', '2025-05-27 00:35:58'),
(242, 24, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-15 00:35:58\"}', '2025-05-27 00:35:58'),
(243, 24, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-13 00:35:58\"}', '2025-05-27 00:35:58'),
(244, 24, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-12 00:35:58\"}', '2025-05-27 00:35:58'),
(245, 24, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-08 00:35:58\"}', '2025-05-27 00:35:58'),
(246, 24, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-25 00:35:58\"}', '2025-05-27 00:35:58'),
(247, 25, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-04-28 00:35:58\"}', '2025-05-27 00:35:58'),
(248, 25, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-03 00:35:58\"}', '2025-05-27 00:35:58'),
(249, 25, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-12 00:35:58\"}', '2025-05-27 00:35:58'),
(250, 26, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-11 00:35:58\"}', '2025-05-27 00:35:58'),
(251, 26, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-02 00:35:58\"}', '2025-05-27 00:35:58'),
(252, 26, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-09 00:35:58\"}', '2025-05-27 00:35:58'),
(253, 27, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-13 00:35:58\"}', '2025-05-27 00:35:58'),
(254, 27, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-08 00:35:58\"}', '2025-05-27 00:35:58'),
(255, 27, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-21 00:35:58\"}', '2025-05-27 00:35:58'),
(256, 27, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-18 00:35:58\"}', '2025-05-27 00:35:58'),
(257, 27, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-19 00:35:58\"}', '2025-05-27 00:35:58'),
(258, 27, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-09 00:35:58\"}', '2025-05-27 00:35:58'),
(259, 28, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-14 00:35:58\"}', '2025-05-27 00:35:58'),
(260, 28, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-19 00:35:58\"}', '2025-05-27 00:35:58'),
(261, 28, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-24 00:35:58\"}', '2025-05-27 00:35:58'),
(262, 28, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-23 00:35:58\"}', '2025-05-27 00:35:58'),
(263, 28, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-21 00:35:58\"}', '2025-05-27 00:35:58'),
(264, 29, 'ITEM_PURCHASED', '{\"item_id\":4,\"item_name\":\"Golden Trophy\"}', '2025-05-27 00:35:58'),
(265, 29, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-04 00:35:58\"}', '2025-05-27 00:35:58'),
(266, 29, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-04-30 00:35:58\"}', '2025-05-27 00:35:58'),
(267, 29, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-11 00:35:58\"}', '2025-05-27 00:35:58'),
(268, 29, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-12 00:35:58\"}', '2025-05-27 00:35:58'),
(269, 29, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-15 00:35:58\"}', '2025-05-27 00:35:58'),
(270, 29, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-04 00:35:58\"}', '2025-05-27 00:35:58'),
(271, 29, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-01 00:35:58\"}', '2025-05-27 00:35:58'),
(272, 29, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-04-27 00:35:58\"}', '2025-05-27 00:35:58'),
(273, 30, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-04-29 00:35:58\"}', '2025-05-27 00:35:58'),
(274, 30, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-08 00:35:58\"}', '2025-05-27 00:35:58'),
(275, 30, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-23 00:35:58\"}', '2025-05-27 00:35:58'),
(276, 30, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-12 00:35:58\"}', '2025-05-27 00:35:58'),
(277, 30, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-08 00:35:58\"}', '2025-05-27 00:35:58'),
(278, 31, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-07 00:35:58\"}', '2025-05-27 00:35:58'),
(279, 31, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-06 00:35:58\"}', '2025-05-27 00:35:58'),
(280, 31, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-16 00:35:58\"}', '2025-05-27 00:35:58'),
(281, 31, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-05 00:35:58\"}', '2025-05-27 00:35:58'),
(282, 31, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-04-29 00:35:58\"}', '2025-05-27 00:35:58'),
(283, 31, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-20 00:35:58\"}', '2025-05-27 00:35:58'),
(284, 32, 'ITEM_PURCHASED', '{\"item_id\":2,\"item_name\":\"XP Booster\"}', '2025-05-27 00:35:58'),
(285, 32, 'ITEM_PURCHASED', '{\"item_id\":1,\"item_name\":\"Health Potion\"}', '2025-05-27 00:35:58'),
(286, 32, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-04-27 00:35:58\"}', '2025-05-27 00:35:58'),
(287, 32, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-09 00:35:58\"}', '2025-05-27 00:35:58'),
(288, 32, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-04-30 00:35:58\"}', '2025-05-27 00:35:58'),
(289, 32, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-04 00:35:58\"}', '2025-05-27 00:35:58'),
(290, 32, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-15 00:35:58\"}', '2025-05-27 00:35:58'),
(291, 32, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-01 00:35:58\"}', '2025-05-27 00:35:58'),
(292, 32, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-23 00:35:58\"}', '2025-05-27 00:35:58'),
(293, 33, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-04 00:35:58\"}', '2025-05-27 00:35:58'),
(294, 33, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-27 00:35:58\"}', '2025-05-27 00:35:58'),
(295, 33, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-06 00:35:58\"}', '2025-05-27 00:35:58'),
(296, 33, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-11 00:35:58\"}', '2025-05-27 00:35:58'),
(297, 33, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-15 00:35:58\"}', '2025-05-27 00:35:58'),
(298, 33, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-17 00:35:58\"}', '2025-05-27 00:35:58'),
(299, 34, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-10 00:35:58\"}', '2025-05-27 00:35:58'),
(300, 34, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-22 00:35:58\"}', '2025-05-27 00:35:58'),
(301, 34, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-21 00:35:58\"}', '2025-05-27 00:35:58'),
(302, 34, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-14 00:35:58\"}', '2025-05-27 00:35:58'),
(303, 34, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-11 00:35:58\"}', '2025-05-27 00:35:58'),
(304, 34, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-12 00:35:58\"}', '2025-05-27 00:35:58'),
(305, 34, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-16 00:35:58\"}', '2025-05-27 00:35:58'),
(306, 35, 'ITEM_PURCHASED', '{\"item_id\":3,\"item_name\":\"Focus Crystal\"}', '2025-05-27 00:35:58'),
(307, 35, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-05 00:35:58\"}', '2025-05-27 00:35:58'),
(308, 35, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-01 00:35:58\"}', '2025-05-27 00:35:58'),
(309, 35, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-08 00:35:58\"}', '2025-05-27 00:35:58'),
(310, 35, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-23 00:35:58\"}', '2025-05-27 00:35:58'),
(311, 35, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-21 00:35:58\"}', '2025-05-27 00:35:58'),
(312, 35, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-25 00:35:58\"}', '2025-05-27 00:35:58'),
(313, 35, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-01 00:35:58\"}', '2025-05-27 00:35:58'),
(314, 36, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-25 00:35:58\"}', '2025-05-27 00:35:58'),
(315, 36, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-25 00:35:58\"}', '2025-05-27 00:35:58'),
(316, 36, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-27 00:35:58\"}', '2025-05-27 00:35:58'),
(317, 36, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-04-30 00:35:58\"}', '2025-05-27 00:35:58'),
(318, 36, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-09 00:35:58\"}', '2025-05-27 00:35:58'),
(319, 36, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-13 00:35:58\"}', '2025-05-27 00:35:58'),
(320, 37, 'ITEM_PURCHASED', '{\"item_id\":4,\"item_name\":\"Golden Trophy\"}', '2025-05-27 00:35:58'),
(321, 37, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-23 00:35:58\"}', '2025-05-27 00:35:58'),
(322, 37, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-02 00:35:58\"}', '2025-05-27 00:35:58'),
(323, 37, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-17 00:35:58\"}', '2025-05-27 00:35:58'),
(324, 37, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-02 00:35:58\"}', '2025-05-27 00:35:58'),
(325, 37, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-09 00:35:58\"}', '2025-05-27 00:35:58'),
(326, 37, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-12 00:35:58\"}', '2025-05-27 00:35:58'),
(327, 37, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-25 00:35:58\"}', '2025-05-27 00:35:58');
INSERT INTO `activity_log` (`log_id`, `user_id`, `activity_type`, `activity_details`, `log_timestamp`) VALUES
(328, 38, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-25 00:35:58\"}', '2025-05-27 00:35:58'),
(329, 38, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-08 00:35:58\"}', '2025-05-27 00:35:58'),
(330, 38, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-26 00:35:58\"}', '2025-05-27 00:35:58'),
(331, 38, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-07 00:35:58\"}', '2025-05-27 00:35:58'),
(332, 39, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-18 00:35:58\"}', '2025-05-27 00:35:58'),
(333, 39, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-03 00:35:58\"}', '2025-05-27 00:35:58'),
(334, 39, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-04-29 00:35:58\"}', '2025-05-27 00:35:58'),
(335, 39, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-04-28 00:35:58\"}', '2025-05-27 00:35:58'),
(336, 39, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-04-29 00:35:58\"}', '2025-05-27 00:35:58'),
(337, 40, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-04-27 00:35:58\"}', '2025-05-27 00:35:58'),
(338, 40, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-03 00:35:58\"}', '2025-05-27 00:35:58'),
(339, 40, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-09 00:35:58\"}', '2025-05-27 00:35:58'),
(340, 41, 'ITEM_PURCHASED', '{\"item_id\":2,\"item_name\":\"XP Booster\"}', '2025-05-27 00:35:58'),
(341, 41, 'ITEM_PURCHASED', '{\"item_id\":4,\"item_name\":\"Golden Trophy\"}', '2025-05-27 00:35:58'),
(342, 41, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-27 00:35:58\"}', '2025-05-27 00:35:58'),
(343, 41, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-15 00:35:58\"}', '2025-05-27 00:35:58'),
(344, 41, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-27 00:35:58\"}', '2025-05-27 00:35:58'),
(345, 41, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-01 00:35:58\"}', '2025-05-27 00:35:58'),
(346, 42, 'ITEM_PURCHASED', '{\"item_id\":2,\"item_name\":\"XP Booster\"}', '2025-05-27 00:35:58'),
(347, 42, 'ITEM_PURCHASED', '{\"item_id\":1,\"item_name\":\"Health Potion\"}', '2025-05-27 00:35:58'),
(348, 42, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-19 00:35:58\"}', '2025-05-27 00:35:58'),
(349, 42, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-04-27 00:35:58\"}', '2025-05-27 00:35:58'),
(350, 42, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-26 00:35:58\"}', '2025-05-27 00:35:58'),
(351, 42, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-17 00:35:58\"}', '2025-05-27 00:35:58'),
(352, 42, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-19 00:35:58\"}', '2025-05-27 00:35:58'),
(353, 42, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-17 00:35:58\"}', '2025-05-27 00:35:58'),
(354, 43, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-04-29 00:35:58\"}', '2025-05-27 00:35:58'),
(355, 43, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-06 00:35:58\"}', '2025-05-27 00:35:58'),
(356, 43, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-24 00:35:58\"}', '2025-05-27 00:35:58'),
(357, 43, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-27 00:35:58\"}', '2025-05-27 00:35:58'),
(358, 43, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-14 00:35:58\"}', '2025-05-27 00:35:58'),
(359, 44, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-12 00:35:58\"}', '2025-05-27 00:35:58'),
(360, 44, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-19 00:35:58\"}', '2025-05-27 00:35:58'),
(361, 44, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-01 00:35:58\"}', '2025-05-27 00:35:58'),
(362, 44, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-22 00:35:58\"}', '2025-05-27 00:35:58'),
(363, 44, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-12 00:35:58\"}', '2025-05-27 00:35:58'),
(364, 44, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-11 00:35:58\"}', '2025-05-27 00:35:58'),
(365, 45, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-25 00:35:58\"}', '2025-05-27 00:35:58'),
(366, 45, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-23 00:35:58\"}', '2025-05-27 00:35:58'),
(367, 45, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-04-29 00:35:58\"}', '2025-05-27 00:35:58'),
(368, 45, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-18 00:35:58\"}', '2025-05-27 00:35:58'),
(369, 45, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-04-27 00:35:58\"}', '2025-05-27 00:35:58'),
(370, 45, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-20 00:35:59\"}', '2025-05-27 00:35:59'),
(371, 45, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-05 00:35:59\"}', '2025-05-27 00:35:59'),
(372, 45, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-01 00:35:59\"}', '2025-05-27 00:35:59'),
(373, 46, 'ITEM_PURCHASED', '{\"item_id\":2,\"item_name\":\"XP Booster\"}', '2025-05-27 00:35:59'),
(374, 46, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-04-28 00:35:59\"}', '2025-05-27 00:35:59'),
(375, 46, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-04 00:35:59\"}', '2025-05-27 00:35:59'),
(376, 47, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-24 00:35:59\"}', '2025-05-27 00:35:59'),
(377, 47, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-14 00:35:59\"}', '2025-05-27 00:35:59'),
(378, 47, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-12 00:35:59\"}', '2025-05-27 00:35:59'),
(379, 47, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-20 00:35:59\"}', '2025-05-27 00:35:59'),
(380, 47, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-19 00:35:59\"}', '2025-05-27 00:35:59'),
(381, 47, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-06 00:35:59\"}', '2025-05-27 00:35:59'),
(382, 47, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-04-30 00:35:59\"}', '2025-05-27 00:35:59'),
(383, 47, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-12 00:35:59\"}', '2025-05-27 00:35:59'),
(384, 48, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-25 00:35:59\"}', '2025-05-27 00:35:59'),
(385, 48, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-10 00:35:59\"}', '2025-05-27 00:35:59'),
(386, 48, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-02 00:35:59\"}', '2025-05-27 00:35:59'),
(387, 48, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-14 00:35:59\"}', '2025-05-27 00:35:59'),
(388, 48, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-08 00:35:59\"}', '2025-05-27 00:35:59'),
(389, 48, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-23 00:35:59\"}', '2025-05-27 00:35:59'),
(390, 49, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-03 00:35:59\"}', '2025-05-27 00:35:59'),
(391, 49, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-24 00:35:59\"}', '2025-05-27 00:35:59'),
(392, 49, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-17 00:35:59\"}', '2025-05-27 00:35:59'),
(393, 49, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-16 00:35:59\"}', '2025-05-27 00:35:59'),
(394, 49, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-08 00:35:59\"}', '2025-05-27 00:35:59'),
(395, 49, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-24 00:35:59\"}', '2025-05-27 00:35:59'),
(396, 50, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-12 00:35:59\"}', '2025-05-27 00:35:59'),
(397, 50, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-04-29 00:35:59\"}', '2025-05-27 00:35:59'),
(398, 50, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-11 00:35:59\"}', '2025-05-27 00:35:59'),
(399, 50, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-04-28 00:35:59\"}', '2025-05-27 00:35:59'),
(400, 50, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-06 00:35:59\"}', '2025-05-27 00:35:59'),
(401, 50, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-25 00:35:59\"}', '2025-05-27 00:35:59'),
(402, 51, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-04-27 00:35:59\"}', '2025-05-27 00:35:59'),
(403, 51, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-04-27 00:35:59\"}', '2025-05-27 00:35:59'),
(404, 51, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-02 00:35:59\"}', '2025-05-27 00:35:59'),
(405, 52, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-19 00:35:59\"}', '2025-05-27 00:35:59'),
(406, 52, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-10 00:35:59\"}', '2025-05-27 00:35:59'),
(407, 52, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-19 00:35:59\"}', '2025-05-27 00:35:59'),
(408, 52, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-26 00:35:59\"}', '2025-05-27 00:35:59'),
(409, 52, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-27 00:35:59\"}', '2025-05-27 00:35:59'),
(410, 52, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-08 00:35:59\"}', '2025-05-27 00:35:59'),
(411, 53, 'ITEM_PURCHASED', '{\"item_id\":4,\"item_name\":\"Golden Trophy\"}', '2025-05-27 00:35:59'),
(412, 53, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-17 00:35:59\"}', '2025-05-27 00:35:59'),
(413, 53, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-24 00:35:59\"}', '2025-05-27 00:35:59'),
(414, 53, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-19 00:35:59\"}', '2025-05-27 00:35:59'),
(415, 53, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-11 00:35:59\"}', '2025-05-27 00:35:59'),
(416, 53, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-16 00:35:59\"}', '2025-05-27 00:35:59'),
(417, 53, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-27 00:35:59\"}', '2025-05-27 00:35:59'),
(418, 53, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-23 00:35:59\"}', '2025-05-27 00:35:59'),
(419, 53, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-20 00:35:59\"}', '2025-05-27 00:35:59'),
(420, 54, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-18 00:35:59\"}', '2025-05-27 00:35:59'),
(421, 54, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-10 00:35:59\"}', '2025-05-27 00:35:59'),
(422, 54, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-05 00:35:59\"}', '2025-05-27 00:35:59'),
(423, 54, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-23 00:35:59\"}', '2025-05-27 00:35:59'),
(424, 54, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-06 00:35:59\"}', '2025-05-27 00:35:59'),
(425, 54, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-04-30 00:35:59\"}', '2025-05-27 00:35:59'),
(426, 54, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-25 00:35:59\"}', '2025-05-27 00:35:59'),
(427, 54, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-24 00:35:59\"}', '2025-05-27 00:35:59'),
(428, 55, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-10 00:35:59\"}', '2025-05-27 00:35:59'),
(429, 55, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-20 00:35:59\"}', '2025-05-27 00:35:59'),
(430, 55, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-04-28 00:35:59\"}', '2025-05-27 00:35:59'),
(431, 55, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-14 00:35:59\"}', '2025-05-27 00:35:59'),
(432, 56, 'ITEM_PURCHASED', '{\"item_id\":2,\"item_name\":\"XP Booster\"}', '2025-05-27 00:35:59'),
(433, 56, 'ITEM_PURCHASED', '{\"item_id\":1,\"item_name\":\"Health Potion\"}', '2025-05-27 00:35:59'),
(434, 56, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-21 00:35:59\"}', '2025-05-27 00:35:59'),
(435, 56, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-03 00:35:59\"}', '2025-05-27 00:35:59'),
(436, 56, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-14 00:35:59\"}', '2025-05-27 00:35:59'),
(437, 56, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-13 00:35:59\"}', '2025-05-27 00:35:59'),
(438, 56, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-04 00:35:59\"}', '2025-05-27 00:35:59'),
(439, 56, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-07 00:35:59\"}', '2025-05-27 00:35:59'),
(440, 56, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-09 00:35:59\"}', '2025-05-27 00:35:59'),
(441, 57, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-26 00:35:59\"}', '2025-05-27 00:35:59'),
(442, 57, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-16 00:35:59\"}', '2025-05-27 00:35:59'),
(443, 57, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-26 00:35:59\"}', '2025-05-27 00:35:59'),
(444, 57, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-20 00:35:59\"}', '2025-05-27 00:35:59'),
(445, 58, 'ITEM_PURCHASED', '{\"item_id\":4,\"item_name\":\"Golden Trophy\"}', '2025-05-27 00:35:59'),
(446, 58, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-27 00:35:59\"}', '2025-05-27 00:35:59'),
(447, 58, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-09 00:35:59\"}', '2025-05-27 00:35:59'),
(448, 58, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-12 00:35:59\"}', '2025-05-27 00:35:59'),
(449, 58, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-15 00:35:59\"}', '2025-05-27 00:35:59'),
(450, 59, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-21 00:35:59\"}', '2025-05-27 00:35:59'),
(451, 59, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-04-30 00:35:59\"}', '2025-05-27 00:35:59'),
(452, 59, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-04-30 00:35:59\"}', '2025-05-27 00:35:59'),
(453, 59, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-02 00:35:59\"}', '2025-05-27 00:35:59'),
(454, 59, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-05 00:35:59\"}', '2025-05-27 00:35:59'),
(455, 59, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-08 00:35:59\"}', '2025-05-27 00:35:59'),
(456, 60, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-13 00:35:59\"}', '2025-05-27 00:35:59'),
(457, 60, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-04-30 00:35:59\"}', '2025-05-27 00:35:59'),
(458, 60, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-15 00:35:59\"}', '2025-05-27 00:35:59'),
(459, 60, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-20 00:35:59\"}', '2025-05-27 00:35:59'),
(460, 60, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-04-30 00:35:59\"}', '2025-05-27 00:35:59'),
(461, 60, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-05 00:35:59\"}', '2025-05-27 00:35:59'),
(462, 60, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-25 00:35:59\"}', '2025-05-27 00:35:59'),
(463, 61, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-13 00:35:59\"}', '2025-05-27 00:35:59'),
(464, 61, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-04-29 00:35:59\"}', '2025-05-27 00:35:59'),
(465, 62, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-24 00:35:59\"}', '2025-05-27 00:35:59'),
(466, 62, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-04-28 00:35:59\"}', '2025-05-27 00:35:59'),
(467, 62, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-05 00:35:59\"}', '2025-05-27 00:35:59'),
(468, 62, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-23 00:35:59\"}', '2025-05-27 00:35:59'),
(469, 62, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-08 00:35:59\"}', '2025-05-27 00:35:59'),
(470, 62, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-04-28 00:35:59\"}', '2025-05-27 00:35:59'),
(471, 62, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-07 00:35:59\"}', '2025-05-27 00:35:59'),
(472, 62, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-18 00:35:59\"}', '2025-05-27 00:35:59'),
(473, 63, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-20 00:35:59\"}', '2025-05-27 00:35:59'),
(474, 63, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-20 00:35:59\"}', '2025-05-27 00:35:59'),
(475, 63, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-19 00:35:59\"}', '2025-05-27 00:35:59'),
(476, 64, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-14 00:35:59\"}', '2025-05-27 00:35:59'),
(477, 64, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-12 00:35:59\"}', '2025-05-27 00:35:59'),
(478, 64, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-04-27 00:35:59\"}', '2025-05-27 00:35:59'),
(479, 64, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-18 00:35:59\"}', '2025-05-27 00:35:59'),
(480, 64, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-06 00:35:59\"}', '2025-05-27 00:35:59'),
(481, 64, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-17 00:35:59\"}', '2025-05-27 00:35:59'),
(482, 65, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-04-29 00:35:59\"}', '2025-05-27 00:35:59'),
(483, 65, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-11 00:35:59\"}', '2025-05-27 00:35:59'),
(484, 65, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-22 00:35:59\"}', '2025-05-27 00:35:59'),
(485, 66, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-04-30 00:35:59\"}', '2025-05-27 00:35:59'),
(486, 66, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-03 00:35:59\"}', '2025-05-27 00:35:59'),
(487, 66, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-23 00:35:59\"}', '2025-05-27 00:35:59'),
(488, 66, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-04-30 00:35:59\"}', '2025-05-27 00:35:59'),
(489, 66, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-12 00:35:59\"}', '2025-05-27 00:35:59'),
(490, 66, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-10 00:35:59\"}', '2025-05-27 00:35:59'),
(491, 66, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-19 00:35:59\"}', '2025-05-27 00:35:59'),
(492, 67, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-25 00:35:59\"}', '2025-05-27 00:35:59'),
(493, 67, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-03 00:35:59\"}', '2025-05-27 00:35:59'),
(494, 68, 'ITEM_PURCHASED', '{\"item_id\":4,\"item_name\":\"Golden Trophy\"}', '2025-05-27 00:35:59'),
(495, 68, 'ITEM_PURCHASED', '{\"item_id\":1,\"item_name\":\"Health Potion\"}', '2025-05-27 00:35:59'),
(496, 68, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-11 00:35:59\"}', '2025-05-27 00:35:59'),
(497, 68, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-12 00:35:59\"}', '2025-05-27 00:35:59'),
(498, 68, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-08 00:35:59\"}', '2025-05-27 00:35:59'),
(499, 68, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-03 00:35:59\"}', '2025-05-27 00:35:59'),
(500, 68, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-16 00:35:59\"}', '2025-05-27 00:35:59'),
(501, 68, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-11 00:35:59\"}', '2025-05-27 00:35:59'),
(502, 68, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-11 00:35:59\"}', '2025-05-27 00:35:59'),
(503, 68, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-18 00:35:59\"}', '2025-05-27 00:35:59'),
(504, 69, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-06 00:35:59\"}', '2025-05-27 00:35:59'),
(505, 69, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-17 00:35:59\"}', '2025-05-27 00:35:59'),
(506, 69, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-24 00:35:59\"}', '2025-05-27 00:35:59'),
(507, 69, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-20 00:35:59\"}', '2025-05-27 00:35:59'),
(508, 69, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-18 00:35:59\"}', '2025-05-27 00:35:59'),
(509, 70, 'ITEM_PURCHASED', '{\"item_id\":4,\"item_name\":\"Golden Trophy\"}', '2025-05-27 00:35:59'),
(510, 70, 'ITEM_PURCHASED', '{\"item_id\":2,\"item_name\":\"XP Booster\"}', '2025-05-27 00:35:59'),
(511, 70, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-09 00:35:59\"}', '2025-05-27 00:35:59'),
(512, 70, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-21 00:35:59\"}', '2025-05-27 00:35:59'),
(513, 70, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-03 00:35:59\"}', '2025-05-27 00:35:59'),
(514, 70, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-24 00:35:59\"}', '2025-05-27 00:35:59'),
(515, 70, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-10 00:35:59\"}', '2025-05-27 00:35:59'),
(516, 70, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-08 00:35:59\"}', '2025-05-27 00:35:59'),
(517, 70, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-04-27 00:35:59\"}', '2025-05-27 00:35:59'),
(518, 70, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-11 00:35:59\"}', '2025-05-27 00:35:59'),
(519, 71, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-08 00:35:59\"}', '2025-05-27 00:35:59'),
(520, 71, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-17 00:35:59\"}', '2025-05-27 00:35:59'),
(521, 72, 'ITEM_PURCHASED', '{\"item_id\":4,\"item_name\":\"Golden Trophy\"}', '2025-05-27 00:35:59'),
(522, 72, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-09 00:35:59\"}', '2025-05-27 00:35:59'),
(523, 72, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-20 00:35:59\"}', '2025-05-27 00:35:59'),
(524, 72, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-04-29 00:35:59\"}', '2025-05-27 00:35:59'),
(525, 72, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-04-28 00:35:59\"}', '2025-05-27 00:35:59'),
(526, 72, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-08 00:35:59\"}', '2025-05-27 00:35:59'),
(527, 73, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-04-28 00:35:59\"}', '2025-05-27 00:35:59'),
(528, 73, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-12 00:35:59\"}', '2025-05-27 00:35:59'),
(529, 74, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-01 00:35:59\"}', '2025-05-27 00:35:59'),
(530, 74, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-17 00:35:59\"}', '2025-05-27 00:35:59'),
(531, 74, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-09 00:35:59\"}', '2025-05-27 00:35:59'),
(532, 74, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-01 00:35:59\"}', '2025-05-27 00:35:59'),
(533, 74, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-01 00:35:59\"}', '2025-05-27 00:35:59'),
(534, 75, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-10 00:35:59\"}', '2025-05-27 00:35:59'),
(535, 75, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-22 00:35:59\"}', '2025-05-27 00:35:59'),
(536, 75, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-25 00:35:59\"}', '2025-05-27 00:35:59'),
(537, 76, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-01 00:36:00\"}', '2025-05-27 00:36:00'),
(538, 76, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-14 00:36:00\"}', '2025-05-27 00:36:00'),
(539, 76, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-26 00:36:00\"}', '2025-05-27 00:36:00'),
(540, 76, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-14 00:36:00\"}', '2025-05-27 00:36:00'),
(541, 76, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-04-27 00:36:00\"}', '2025-05-27 00:36:00'),
(542, 76, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-16 00:36:00\"}', '2025-05-27 00:36:00'),
(543, 76, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-04-28 00:36:00\"}', '2025-05-27 00:36:00'),
(544, 77, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-27 00:36:00\"}', '2025-05-27 00:36:00'),
(545, 77, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-05 00:36:00\"}', '2025-05-27 00:36:00'),
(546, 77, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-04-28 00:36:00\"}', '2025-05-27 00:36:00'),
(547, 77, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-07 00:36:00\"}', '2025-05-27 00:36:00'),
(548, 77, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-25 00:36:00\"}', '2025-05-27 00:36:00'),
(549, 77, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-25 00:36:00\"}', '2025-05-27 00:36:00'),
(550, 78, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-10 00:36:00\"}', '2025-05-27 00:36:00'),
(551, 78, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-04-28 00:36:00\"}', '2025-05-27 00:36:00'),
(552, 78, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-18 00:36:00\"}', '2025-05-27 00:36:00'),
(553, 79, 'ITEM_PURCHASED', '{\"item_id\":2,\"item_name\":\"XP Booster\"}', '2025-05-27 00:36:00'),
(554, 79, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-14 00:36:00\"}', '2025-05-27 00:36:00'),
(555, 79, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-22 00:36:00\"}', '2025-05-27 00:36:00'),
(556, 79, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-10 00:36:00\"}', '2025-05-27 00:36:00'),
(557, 79, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-20 00:36:00\"}', '2025-05-27 00:36:00'),
(558, 80, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-24 00:36:00\"}', '2025-05-27 00:36:00'),
(559, 80, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-20 00:36:00\"}', '2025-05-27 00:36:00'),
(560, 80, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-05 00:36:00\"}', '2025-05-27 00:36:00'),
(561, 81, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-16 00:36:00\"}', '2025-05-27 00:36:00'),
(562, 81, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-27 00:36:00\"}', '2025-05-27 00:36:00'),
(563, 81, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-17 00:36:00\"}', '2025-05-27 00:36:00'),
(564, 81, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-01 00:36:00\"}', '2025-05-27 00:36:00'),
(565, 81, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-15 00:36:00\"}', '2025-05-27 00:36:00'),
(566, 82, 'ITEM_PURCHASED', '{\"item_id\":4,\"item_name\":\"Golden Trophy\"}', '2025-05-27 00:36:00'),
(567, 82, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-19 00:36:00\"}', '2025-05-27 00:36:00'),
(568, 82, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-11 00:36:00\"}', '2025-05-27 00:36:00'),
(569, 82, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-10 00:36:00\"}', '2025-05-27 00:36:00'),
(570, 82, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-01 00:36:00\"}', '2025-05-27 00:36:00'),
(571, 83, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-09 00:36:00\"}', '2025-05-27 00:36:00'),
(572, 83, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-27 00:36:00\"}', '2025-05-27 00:36:00'),
(573, 83, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-08 00:36:00\"}', '2025-05-27 00:36:00'),
(574, 83, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-10 00:36:00\"}', '2025-05-27 00:36:00'),
(575, 83, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-02 00:36:00\"}', '2025-05-27 00:36:00'),
(576, 83, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-13 00:36:00\"}', '2025-05-27 00:36:00'),
(577, 84, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-25 00:36:00\"}', '2025-05-27 00:36:00'),
(578, 84, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-19 00:36:00\"}', '2025-05-27 00:36:00'),
(579, 84, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-23 00:36:00\"}', '2025-05-27 00:36:00'),
(580, 84, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-10 00:36:00\"}', '2025-05-27 00:36:00'),
(581, 84, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-19 00:36:00\"}', '2025-05-27 00:36:00'),
(582, 84, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-11 00:36:00\"}', '2025-05-27 00:36:00'),
(583, 85, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-19 00:36:00\"}', '2025-05-27 00:36:00'),
(584, 85, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-24 00:36:00\"}', '2025-05-27 00:36:00'),
(585, 85, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-22 00:36:00\"}', '2025-05-27 00:36:00'),
(586, 85, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-16 00:36:00\"}', '2025-05-27 00:36:00'),
(587, 85, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-01 00:36:00\"}', '2025-05-27 00:36:00'),
(588, 86, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-21 00:36:00\"}', '2025-05-27 00:36:00'),
(589, 86, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-05 00:36:00\"}', '2025-05-27 00:36:00'),
(590, 87, 'ITEM_PURCHASED', '{\"item_id\":2,\"item_name\":\"XP Booster\"}', '2025-05-27 00:36:00'),
(591, 87, 'ITEM_PURCHASED', '{\"item_id\":1,\"item_name\":\"Health Potion\"}', '2025-05-27 00:36:00'),
(592, 87, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-04-27 00:36:00\"}', '2025-05-27 00:36:00'),
(593, 87, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-04-30 00:36:00\"}', '2025-05-27 00:36:00'),
(594, 87, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-20 00:36:00\"}', '2025-05-27 00:36:00'),
(595, 87, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-19 00:36:00\"}', '2025-05-27 00:36:00'),
(596, 87, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-04-29 00:36:00\"}', '2025-05-27 00:36:00'),
(597, 87, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-21 00:36:00\"}', '2025-05-27 00:36:00'),
(598, 87, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-11 00:36:00\"}', '2025-05-27 00:36:00'),
(599, 87, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-26 00:36:00\"}', '2025-05-27 00:36:00'),
(600, 88, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-11 00:36:00\"}', '2025-05-27 00:36:00'),
(601, 88, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-26 00:36:00\"}', '2025-05-27 00:36:00'),
(602, 88, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-04-29 00:36:00\"}', '2025-05-27 00:36:00'),
(603, 88, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-16 00:36:00\"}', '2025-05-27 00:36:00'),
(604, 89, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-17 00:36:00\"}', '2025-05-27 00:36:00'),
(605, 89, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-27 00:36:00\"}', '2025-05-27 00:36:00'),
(606, 90, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-04-28 00:36:00\"}', '2025-05-27 00:36:00'),
(607, 90, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-09 00:36:00\"}', '2025-05-27 00:36:00'),
(608, 91, 'ITEM_PURCHASED', '{\"item_id\":2,\"item_name\":\"XP Booster\"}', '2025-05-27 00:36:00'),
(609, 91, 'ITEM_PURCHASED', '{\"item_id\":4,\"item_name\":\"Golden Trophy\"}', '2025-05-27 00:36:00'),
(610, 91, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-09 00:36:00\"}', '2025-05-27 00:36:00'),
(611, 91, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-27 00:36:00\"}', '2025-05-27 00:36:00'),
(612, 91, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-19 00:36:00\"}', '2025-05-27 00:36:00'),
(613, 92, 'ITEM_PURCHASED', '{\"item_id\":1,\"item_name\":\"Health Potion\"}', '2025-05-27 00:36:00'),
(614, 92, 'ITEM_PURCHASED', '{\"item_id\":2,\"item_name\":\"XP Booster\"}', '2025-05-27 00:36:00'),
(615, 92, 'ITEM_PURCHASED', '{\"item_id\":3,\"item_name\":\"Focus Crystal\"}', '2025-05-27 00:36:00'),
(616, 92, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-26 00:36:00\"}', '2025-05-27 00:36:00'),
(617, 92, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-11 00:36:00\"}', '2025-05-27 00:36:00'),
(618, 92, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-07 00:36:00\"}', '2025-05-27 00:36:00'),
(619, 92, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-20 00:36:00\"}', '2025-05-27 00:36:00'),
(620, 93, 'ITEM_PURCHASED', '{\"item_id\":2,\"item_name\":\"XP Booster\"}', '2025-05-27 00:36:00'),
(621, 93, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-12 00:36:00\"}', '2025-05-27 00:36:00'),
(622, 93, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-17 00:36:00\"}', '2025-05-27 00:36:00'),
(623, 93, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-22 00:36:00\"}', '2025-05-27 00:36:00'),
(624, 94, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-04-28 00:36:00\"}', '2025-05-27 00:36:00'),
(625, 94, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-18 00:36:00\"}', '2025-05-27 00:36:00'),
(626, 94, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-04 00:36:00\"}', '2025-05-27 00:36:00'),
(627, 94, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-05 00:36:00\"}', '2025-05-27 00:36:00'),
(628, 94, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-12 00:36:00\"}', '2025-05-27 00:36:00'),
(629, 94, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-27 00:36:00\"}', '2025-05-27 00:36:00'),
(630, 95, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-01 00:36:00\"}', '2025-05-27 00:36:00'),
(631, 95, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-17 00:36:00\"}', '2025-05-27 00:36:00'),
(632, 96, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-04-30 00:36:00\"}', '2025-05-27 00:36:00'),
(633, 96, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-13 00:36:00\"}', '2025-05-27 00:36:00'),
(634, 96, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-27 00:36:00\"}', '2025-05-27 00:36:00'),
(635, 96, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-26 00:36:00\"}', '2025-05-27 00:36:00'),
(636, 96, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-23 00:36:00\"}', '2025-05-27 00:36:00'),
(637, 96, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-18 00:36:00\"}', '2025-05-27 00:36:00'),
(638, 97, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-08 00:36:00\"}', '2025-05-27 00:36:00'),
(639, 97, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-04-28 00:36:00\"}', '2025-05-27 00:36:00'),
(640, 97, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-21 00:36:00\"}', '2025-05-27 00:36:00'),
(641, 97, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-05 00:36:00\"}', '2025-05-27 00:36:00'),
(642, 97, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-22 00:36:00\"}', '2025-05-27 00:36:00'),
(643, 98, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-10 00:36:00\"}', '2025-05-27 00:36:00'),
(644, 98, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-13 00:36:00\"}', '2025-05-27 00:36:00'),
(645, 98, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-20 00:36:00\"}', '2025-05-27 00:36:00'),
(646, 98, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-04-28 00:36:00\"}', '2025-05-27 00:36:00'),
(647, 98, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-23 00:36:00\"}', '2025-05-27 00:36:00'),
(648, 98, 'level_up', '{\"activity_type\":\"level_up\",\"description\":\"Level up\",\"timestamp\":\"2025-05-20 00:36:00\"}', '2025-05-27 00:36:00');
INSERT INTO `activity_log` (`log_id`, `user_id`, `activity_type`, `activity_details`, `log_timestamp`) VALUES
(649, 98, 'achievement_unlocked', '{\"activity_type\":\"achievement_unlocked\",\"description\":\"Achievement unlocked\",\"timestamp\":\"2025-05-12 00:36:00\"}', '2025-05-27 00:36:00'),
(650, 99, 'ITEM_PURCHASED', '{\"item_id\":4,\"item_name\":\"Golden Trophy\"}', '2025-05-27 00:36:00'),
(651, 99, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-23 00:36:00\"}', '2025-05-27 00:36:00'),
(652, 99, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-04-29 00:36:00\"}', '2025-05-27 00:36:00'),
(653, 100, 'login', '{\"activity_type\":\"login\",\"description\":\"Login\",\"timestamp\":\"2025-05-05 00:36:00\"}', '2025-05-27 00:36:00'),
(654, 100, 'item_purchased', '{\"activity_type\":\"item_purchased\",\"description\":\"Item purchased\",\"timestamp\":\"2025-05-21 00:36:00\"}', '2025-05-27 00:36:00'),
(655, 100, 'journal_entry', '{\"activity_type\":\"journal_entry\",\"description\":\"Journal entry\",\"timestamp\":\"2025-05-12 00:36:00\"}', '2025-05-27 00:36:00'),
(656, 100, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-03 00:36:00\"}', '2025-05-27 00:36:00'),
(657, 100, 'habit_completed', '{\"activity_type\":\"habit_completed\",\"description\":\"Habit completed\",\"timestamp\":\"2025-05-04 00:36:00\"}', '2025-05-27 00:36:00'),
(658, 100, 'task_completed', '{\"activity_type\":\"task_completed\",\"description\":\"Task completed\",\"timestamp\":\"2025-05-02 00:36:00\"}', '2025-05-27 00:36:00'),
(659, 100, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-05-11 00:36:00\"}', '2025-05-27 00:36:00'),
(660, 100, 'item_used', '{\"activity_type\":\"item_used\",\"description\":\"Item used\",\"timestamp\":\"2025-04-27 00:36:00\"}', '2025-05-27 00:36:00'),
(661, 101, 'User Login', '{\"message\":\"New user registration and first login\",\"timestamp\":\"2025-05-27 00:38:31\"}', '2025-05-27 00:38:31'),
(662, 102, 'User Login', '{\"message\":\"New user registration and first login\",\"timestamp\":\"2025-05-27 00:42:02\"}', '2025-05-27 00:42:02'),
(663, 101, 'User Login', '{\"message\":\"User logged in\",\"timestamp\":\"2025-05-27 04:20:31\"}', '2025-05-27 04:20:32'),
(664, 102, 'User Login', '{\"message\":\"User logged in\",\"timestamp\":\"2025-05-27 04:28:24\"}', '2025-05-27 04:28:24'),
(665, 102, 'Task Completed', '{\"xp\": 10, \"coins\": 5, \"title\": \"repokls\", \"task_id\": 668, \"category\": \"Physical Health\", \"difficulty\": \"easy\"}', '2025-05-27 04:28:46'),
(666, 102, 'User Login', '{\"message\":\"User logged in\",\"timestamp\":\"2025-05-28 02:49:36\"}', '2025-05-28 02:49:36'),
(667, 102, 'ITEM_PURCHASED', '{\"item_id\":1,\"item_name\":\"Health Potion\"}', '2025-05-28 02:50:11'),
(668, 102, 'ITEM_PURCHASED', '{\"item_id\": 1, \"quantity\": 1, \"item_name\": \"Health Potion\", \"total_cost\": 10.00}', '2025-05-28 02:50:11'),
(669, 102, 'Bad Habit Logged', '{\"xp\": 0, \"coins\": 0, \"title\": \"social media\", \"task_id\": 1, \"category\": \"Personal Growth\", \"difficulty\": \"medium\"}', '2025-05-28 02:50:50'),
(670, 102, 'item_use', '{\"message\": \"Used item: Health Potion\"}', '2025-05-28 02:51:03'),
(671, 102, 'Task Completed', '{\"xp\": 10, \"coins\": 5, \"title\": \"repokls\", \"task_id\": 668, \"category\": \"Physical Health\", \"difficulty\": \"easy\"}', '2025-05-28 02:51:27'),
(672, 102, 'Task Completed', '{\"xp\": 10, \"coins\": 5, \"title\": \"repokls\", \"task_id\": 668, \"category\": \"Physical Health\", \"difficulty\": \"easy\"}', '2025-05-28 02:51:27'),
(673, 102, 'ITEM_PURCHASED', '{\"item_id\":1,\"item_name\":\"Health Potion\"}', '2025-05-28 02:51:33'),
(674, 102, 'ITEM_PURCHASED', '{\"item_id\": 1, \"quantity\": 1, \"item_name\": \"Health Potion\", \"total_cost\": 10.00}', '2025-05-28 02:51:33'),
(675, 102, 'ITEM_PURCHASED', '{\"item_id\": 1, \"quantity\": 1, \"item_name\": \"Health Potion\", \"total_cost\": 10.00}', '2025-05-28 02:51:36'),
(676, 102, 'item_use', '{\"message\": \"Used item: Health Potion\"}', '2025-05-28 02:51:43');

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `avatars`
--

INSERT INTO `avatars` (`id`, `name`, `image_path`, `category`, `created_at`) VALUES
(1, 'Warrior', 'assets/images/avatars/warrior1.png', 'warrior', '2025-05-15 20:29:15'),
(2, 'Mage', 'assets/images/avatars/mage1.png', 'mage', '2025-05-15 20:29:15'),
(3, 'Explorer', 'assets/images/avatars/explorer1.png', 'explorer', '2025-05-15 20:29:15'),
(4, 'Scholar', 'assets/images/avatars/scholar1.png', 'scholar', '2025-05-15 20:29:15');

-- --------------------------------------------------------

--
-- Table structure for table `badhabits`
--

CREATE TABLE `badhabits` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `status` enum('pending','completed') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'pending',
  `difficulty` enum('easy','medium','hard') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `category` enum('Physical Health','Mental Wellness','Personal Growth','Career / Studies','Finance','Home Environment','Relationships Social','Passion Hobbies') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `coins` int NOT NULL,
  `xp` int NOT NULL,
  `avoided` int NOT NULL DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `badhabits`
--

INSERT INTO `badhabits` (`id`, `user_id`, `title`, `status`, `difficulty`, `category`, `coins`, `xp`, `avoided`, `created_at`, `updated_at`, `deleted_at`) VALUES
(1, 102, 'social media', 'completed', 'medium', 'Personal Growth', 0, 0, 0, '2025-05-28 02:50:48', '2025-05-28 02:50:50', NULL);

--
-- Triggers `badhabits`
--
DELIMITER $$
CREATE TRIGGER `after_bad_habits_completion` AFTER UPDATE ON `badhabits` FOR EACH ROW BEGIN 
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
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `dailytasks`
--

CREATE TABLE `dailytasks` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` enum('pending','completed') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `difficulty` enum('easy','medium','hard') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `category` enum('Physical Health','Mental Wellness','Personal Growth','Career / Studies','Finance','Home Environment','Relationships Social','Passion Hobbies') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `coins` int DEFAULT '0',
  `xp` int DEFAULT '0',
  `last_reset` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `dailytasks`
--

INSERT INTO `dailytasks` (`id`, `user_id`, `title`, `status`, `difficulty`, `category`, `coins`, `xp`, `last_reset`) VALUES
(4, 1, 'Daily Take photos', 'pending', 'hard', 'Passion Hobbies', 6, 12, '2025-05-27 00:33:32'),
(5, 1, 'Daily Practice public speaking', 'pending', 'medium', 'Personal Growth', 3, 14, '2025-05-27 00:33:32'),
(6, 1, 'Daily Play board games', 'pending', 'hard', 'Passion Hobbies', 5, 13, '2025-05-27 00:33:32'),
(7, 2, 'Daily Practice coding', 'pending', 'medium', 'Career / Studies', 3, 6, '2025-05-27 00:33:32'),
(8, 2, 'Daily Research investments', 'pending', 'medium', 'Finance', 3, 8, '2025-05-27 00:33:32'),
(9, 3, 'Daily Track expenses', 'pending', 'easy', 'Finance', 4, 7, '2025-05-27 00:33:32'),
(10, 4, 'Daily Meditate for 10 minutes', 'completed', 'medium', 'Mental Wellness', 8, 5, '2025-05-27 00:33:32'),
(11, 4, 'Daily Garden for 30 minutes', 'pending', 'hard', 'Passion Hobbies', 3, 10, '2025-05-27 00:33:32'),
(12, 4, 'Daily Work on art project', 'pending', 'medium', 'Passion Hobbies', 3, 8, '2025-05-27 00:33:32'),
(13, 5, 'Daily Clean living space', 'pending', 'hard', 'Home Environment', 7, 6, '2025-05-27 00:33:32'),
(14, 5, 'Daily Cook new recipe', 'completed', 'hard', 'Passion Hobbies', 6, 11, '2025-05-27 00:33:32'),
(15, 1, 'Daily Drink 8 glasses of water', 'pending', 'hard', 'Physical Health', 8, 13, '2025-05-27 00:33:58'),
(16, 1, 'Daily Eat a healthy breakfast', 'pending', 'hard', 'Physical Health', 3, 10, '2025-05-27 00:33:58'),
(17, 1, 'Daily Listen to calming music', 'completed', 'easy', 'Mental Wellness', 5, 14, '2025-05-27 00:33:58'),
(18, 2, 'Daily Review budget', 'completed', 'hard', 'Finance', 5, 11, '2025-05-27 00:33:58'),
(19, 2, 'Daily Practice coding', 'completed', 'medium', 'Career / Studies', 6, 7, '2025-05-27 00:33:58'),
(20, 2, 'Daily Research investments', 'pending', 'easy', 'Finance', 5, 5, '2025-05-27 00:33:58'),
(21, 3, 'Daily Write gratitude list', 'pending', 'hard', 'Mental Wellness', 3, 5, '2025-05-27 00:33:58'),
(22, 3, 'Daily Network with professionals', 'completed', 'easy', 'Career / Studies', 8, 15, '2025-05-27 00:33:58'),
(23, 3, 'Daily Spend time with family', 'pending', 'hard', 'Relationships Social', 7, 7, '2025-05-27 00:33:58'),
(24, 4, 'Daily Learn new hobby', 'pending', 'medium', 'Passion Hobbies', 8, 9, '2025-05-27 00:33:58'),
(25, 4, 'Daily Watch educational video', 'pending', 'hard', 'Personal Growth', 2, 15, '2025-05-27 00:33:58'),
(26, 4, 'Daily Practice active listening', 'pending', 'medium', 'Relationships Social', 5, 7, '2025-05-27 00:33:58'),
(27, 5, 'Daily Plan social activity', 'pending', 'medium', 'Relationships Social', 2, 14, '2025-05-27 00:33:58'),
(28, 5, 'Daily Organize workspace', 'pending', 'medium', 'Home Environment', 6, 14, '2025-05-27 00:33:58'),
(29, 5, 'Daily Read self-help book', 'pending', 'easy', 'Personal Growth', 3, 6, '2025-05-27 00:33:58'),
(30, 1, 'Daily Cook new recipe', 'pending', 'hard', 'Passion Hobbies', 2, 9, '2025-05-27 00:35:36'),
(31, 1, 'Daily Stretch for 10 minutes', 'completed', 'hard', 'Physical Health', 4, 6, '2025-05-27 00:35:36'),
(32, 1, 'Daily Garden for 30 minutes', 'pending', 'hard', 'Passion Hobbies', 2, 10, '2025-05-27 00:35:36'),
(33, 2, 'Daily Watch educational video', 'completed', 'easy', 'Personal Growth', 3, 9, '2025-05-27 00:35:36'),
(34, 2, 'Daily Read for 30 minutes', 'completed', 'medium', 'Mental Wellness', 8, 5, '2025-05-27 00:35:36'),
(35, 2, 'Daily Make new connections', 'completed', 'easy', 'Relationships Social', 2, 14, '2025-05-27 00:35:36'),
(36, 3, 'Daily Review budget', 'pending', 'easy', 'Finance', 5, 9, '2025-05-27 00:35:36'),
(37, 3, 'Daily Review budget', 'pending', 'hard', 'Finance', 3, 6, '2025-05-27 00:35:36'),
(38, 3, 'Daily Take online course', 'pending', 'medium', 'Career / Studies', 5, 8, '2025-05-27 00:35:36'),
(39, 4, 'Daily Pay bills on time', 'pending', 'hard', 'Finance', 2, 10, '2025-05-27 00:35:36'),
(40, 5, 'Daily Drink 8 glasses of water', 'pending', 'hard', 'Physical Health', 7, 11, '2025-05-27 00:35:36'),
(41, 5, 'Daily Work on art project', 'completed', 'easy', 'Passion Hobbies', 3, 11, '2025-05-27 00:35:36'),
(42, 6, 'Daily Take vitamins', 'pending', 'medium', 'Physical Health', 8, 8, '2025-05-27 00:35:36'),
(43, 7, 'Daily Take a mental health break', 'pending', 'medium', 'Mental Wellness', 6, 6, '2025-05-27 00:35:36'),
(44, 7, 'Daily Track expenses', 'completed', 'medium', 'Finance', 8, 8, '2025-05-27 00:35:36'),
(45, 8, 'Daily Take photos', 'pending', 'hard', 'Passion Hobbies', 4, 5, '2025-05-27 00:35:36'),
(46, 8, 'Daily Set daily goals', 'pending', 'easy', 'Personal Growth', 6, 7, '2025-05-27 00:35:36'),
(47, 8, 'Daily Take a mental health break', 'pending', 'hard', 'Mental Wellness', 5, 9, '2025-05-27 00:35:36'),
(48, 9, 'Daily Practice a skill', 'pending', 'hard', 'Personal Growth', 3, 13, '2025-05-27 00:35:36'),
(49, 9, 'Daily Take vitamins', 'pending', 'medium', 'Physical Health', 6, 12, '2025-05-27 00:35:36'),
(50, 9, 'Daily Read self-help book', 'completed', 'hard', 'Personal Growth', 4, 8, '2025-05-27 00:35:36'),
(51, 10, 'Daily Practice yoga', 'pending', 'medium', 'Physical Health', 4, 14, '2025-05-27 00:35:36'),
(52, 10, 'Daily Pay bills on time', 'pending', 'medium', 'Finance', 7, 14, '2025-05-27 00:35:36'),
(53, 10, 'Daily Update resume', 'pending', 'easy', 'Career / Studies', 3, 6, '2025-05-27 00:35:36'),
(54, 1, 'Daily Water plants', 'pending', 'hard', 'Home Environment', 2, 6, '2025-05-27 00:35:57'),
(55, 1, 'Daily Practice guitar', 'pending', 'medium', 'Passion Hobbies', 2, 10, '2025-05-27 00:35:57'),
(56, 1, 'Daily Stretch for 10 minutes', 'completed', 'medium', 'Physical Health', 2, 13, '2025-05-27 00:35:57'),
(57, 2, 'Daily Reflect on progress', 'pending', 'hard', 'Personal Growth', 2, 7, '2025-05-27 00:35:57'),
(58, 3, 'Daily Do 20 push-ups', 'completed', 'hard', 'Physical Health', 4, 12, '2025-05-27 00:35:57'),
(59, 3, 'Daily Do laundry', 'pending', 'easy', 'Home Environment', 3, 9, '2025-05-27 00:35:57'),
(60, 3, 'Daily Track expenses', 'completed', 'easy', 'Finance', 5, 8, '2025-05-27 00:35:57'),
(61, 4, 'Daily Water plants', 'completed', 'hard', 'Home Environment', 2, 15, '2025-05-27 00:35:57'),
(62, 4, 'Daily Vacuum house', 'pending', 'hard', 'Home Environment', 7, 6, '2025-05-27 00:35:57'),
(63, 4, 'Daily Learn about finances', 'completed', 'easy', 'Finance', 4, 14, '2025-05-27 00:35:57'),
(64, 5, 'Daily Pay bills on time', 'pending', 'medium', 'Finance', 2, 12, '2025-05-27 00:35:57'),
(65, 5, 'Daily Practice interview skills', 'pending', 'medium', 'Career / Studies', 7, 15, '2025-05-27 00:35:57'),
(66, 6, 'Daily Work on portfolio', 'completed', 'hard', 'Career / Studies', 5, 7, '2025-05-27 00:35:57'),
(67, 7, 'Daily Pay bills on time', 'pending', 'hard', 'Finance', 3, 10, '2025-05-27 00:35:57'),
(68, 7, 'Daily Pay bills on time', 'completed', 'medium', 'Finance', 8, 14, '2025-05-27 00:35:57'),
(69, 7, 'Daily Learn about finances', 'pending', 'easy', 'Finance', 3, 8, '2025-05-27 00:35:57'),
(70, 8, 'Daily Cook new recipe', 'pending', 'hard', 'Passion Hobbies', 6, 5, '2025-05-27 00:35:57'),
(71, 8, 'Daily Eat a healthy breakfast', 'pending', 'easy', 'Physical Health', 7, 15, '2025-05-27 00:35:57'),
(72, 8, 'Daily Practice mindfulness', 'pending', 'easy', 'Mental Wellness', 7, 8, '2025-05-27 00:35:57'),
(73, 9, 'Daily Pay bills on time', 'completed', 'easy', 'Finance', 7, 9, '2025-05-27 00:35:57'),
(74, 9, 'Daily Practice coding', 'pending', 'medium', 'Career / Studies', 8, 5, '2025-05-27 00:35:57'),
(75, 9, 'Daily Practice interview skills', 'pending', 'easy', 'Career / Studies', 3, 8, '2025-05-27 00:35:57'),
(76, 10, 'Daily Drink 8 glasses of water', 'completed', 'medium', 'Physical Health', 2, 7, '2025-05-27 00:35:57'),
(77, 10, 'Daily Meditate for 10 minutes', 'pending', 'medium', 'Mental Wellness', 3, 13, '2025-05-27 00:35:57'),
(78, 10, 'Daily Reflect on progress', 'completed', 'medium', 'Personal Growth', 8, 11, '2025-05-27 00:35:57'),
(79, 11, 'Daily Drink 8 glasses of water', 'pending', 'hard', 'Physical Health', 7, 15, '2025-05-27 00:35:57'),
(80, 11, 'Daily Meditate for 10 minutes', 'pending', 'easy', 'Mental Wellness', 4, 7, '2025-05-27 00:35:57'),
(81, 12, 'Daily Practice deep breathing', 'pending', 'hard', 'Mental Wellness', 6, 15, '2025-05-27 00:35:57'),
(82, 13, 'Daily Learn something new', 'pending', 'medium', 'Personal Growth', 4, 11, '2025-05-27 00:35:57'),
(83, 14, 'Daily Research investments', 'pending', 'hard', 'Finance', 2, 7, '2025-05-27 00:35:58'),
(84, 15, 'Daily Review budget', 'pending', 'medium', 'Finance', 8, 11, '2025-05-27 00:35:58'),
(85, 15, 'Daily Do laundry', 'completed', 'hard', 'Home Environment', 4, 10, '2025-05-27 00:35:58'),
(86, 15, 'Daily Cook new recipe', 'pending', 'easy', 'Passion Hobbies', 8, 15, '2025-05-27 00:35:58'),
(87, 16, 'Daily Read for 30 minutes', 'pending', 'easy', 'Mental Wellness', 5, 15, '2025-05-27 00:35:58'),
(88, 16, 'Daily Take vitamins', 'completed', 'medium', 'Physical Health', 4, 7, '2025-05-27 00:35:58'),
(89, 16, 'Daily Write in journal', 'pending', 'hard', 'Passion Hobbies', 4, 5, '2025-05-27 00:35:58'),
(90, 17, 'Daily Watch educational video', 'pending', 'hard', 'Personal Growth', 5, 7, '2025-05-27 00:35:58'),
(91, 17, 'Daily Take vitamins', 'pending', 'hard', 'Physical Health', 5, 5, '2025-05-27 00:35:58'),
(92, 18, 'Daily Learn about finances', 'completed', 'medium', 'Finance', 8, 7, '2025-05-27 00:35:58'),
(93, 18, 'Daily Read self-help book', 'completed', 'easy', 'Personal Growth', 5, 8, '2025-05-27 00:35:58'),
(94, 18, 'Daily Clean living space', 'completed', 'medium', 'Home Environment', 3, 15, '2025-05-27 00:35:58'),
(95, 19, 'Daily Eat a healthy breakfast', 'pending', 'easy', 'Physical Health', 3, 8, '2025-05-27 00:35:58'),
(96, 19, 'Daily Take a mental health break', 'pending', 'medium', 'Mental Wellness', 7, 7, '2025-05-27 00:35:58'),
(97, 20, 'Daily Take online course', 'pending', 'medium', 'Career / Studies', 3, 10, '2025-05-27 00:35:58'),
(98, 20, 'Daily Research investments', 'pending', 'easy', 'Finance', 6, 15, '2025-05-27 00:35:58'),
(99, 20, 'Daily Practice a skill', 'completed', 'hard', 'Personal Growth', 2, 7, '2025-05-27 00:35:58'),
(100, 21, 'Daily Spend time with family', 'completed', 'easy', 'Relationships Social', 7, 12, '2025-05-27 00:35:58'),
(101, 21, 'Daily Call a friend', 'completed', 'hard', 'Relationships Social', 6, 15, '2025-05-27 00:35:58'),
(102, 22, 'Daily Write gratitude list', 'pending', 'hard', 'Mental Wellness', 5, 11, '2025-05-27 00:35:58'),
(103, 23, 'Daily Practice mindfulness', 'pending', 'hard', 'Mental Wellness', 2, 15, '2025-05-27 00:35:58'),
(104, 24, 'Daily Learn about finances', 'pending', 'medium', 'Finance', 6, 10, '2025-05-27 00:35:58'),
(105, 24, 'Daily Research investments', 'completed', 'hard', 'Finance', 5, 14, '2025-05-27 00:35:58'),
(106, 25, 'Daily Plan social activity', 'pending', 'hard', 'Relationships Social', 3, 6, '2025-05-27 00:35:58'),
(107, 25, 'Daily Work on portfolio', 'completed', 'hard', 'Career / Studies', 3, 10, '2025-05-27 00:35:58'),
(108, 26, 'Daily Meditate for 10 minutes', 'completed', 'medium', 'Mental Wellness', 2, 8, '2025-05-27 00:35:58'),
(109, 26, 'Daily Read industry news', 'pending', 'easy', 'Career / Studies', 7, 12, '2025-05-27 00:35:58'),
(110, 27, 'Daily Write in journal', 'pending', 'medium', 'Passion Hobbies', 3, 7, '2025-05-27 00:35:58'),
(111, 28, 'Daily Vacuum house', 'pending', 'easy', 'Home Environment', 2, 13, '2025-05-27 00:35:58'),
(112, 29, 'Daily Take photos', 'pending', 'easy', 'Passion Hobbies', 7, 15, '2025-05-27 00:35:58'),
(113, 29, 'Daily Save money', 'pending', 'hard', 'Finance', 4, 14, '2025-05-27 00:35:58'),
(114, 29, 'Daily Show appreciation', 'completed', 'medium', 'Relationships Social', 7, 9, '2025-05-27 00:35:58'),
(115, 30, 'Daily Read for 30 minutes', 'pending', 'hard', 'Mental Wellness', 5, 6, '2025-05-27 00:35:58'),
(116, 30, 'Daily Learn new hobby', 'pending', 'hard', 'Passion Hobbies', 3, 12, '2025-05-27 00:35:58'),
(117, 31, 'Daily Pay bills on time', 'pending', 'easy', 'Finance', 3, 11, '2025-05-27 00:35:58'),
(118, 32, 'Daily Vacuum house', 'pending', 'medium', 'Home Environment', 7, 5, '2025-05-27 00:35:58'),
(119, 33, 'Daily Call a friend', 'pending', 'medium', 'Relationships Social', 2, 14, '2025-05-27 00:35:58'),
(120, 34, 'Daily Plan future goals', 'completed', 'easy', 'Personal Growth', 4, 6, '2025-05-27 00:35:58'),
(121, 35, 'Daily Do cardio workout', 'completed', 'easy', 'Physical Health', 3, 14, '2025-05-27 00:35:58'),
(122, 35, 'Daily Update resume', 'completed', 'easy', 'Career / Studies', 7, 10, '2025-05-27 00:35:58'),
(123, 36, 'Daily Write in journal', 'completed', 'medium', 'Passion Hobbies', 8, 13, '2025-05-27 00:35:58'),
(124, 36, 'Daily Watch educational video', 'completed', 'easy', 'Personal Growth', 4, 14, '2025-05-27 00:35:58'),
(125, 37, 'Daily Practice deep breathing', 'pending', 'medium', 'Mental Wellness', 8, 14, '2025-05-27 00:35:58'),
(126, 37, 'Daily Practice mindfulness', 'completed', 'easy', 'Mental Wellness', 2, 14, '2025-05-27 00:35:58'),
(127, 37, 'Daily Make bed', 'completed', 'hard', 'Home Environment', 6, 6, '2025-05-27 00:35:58'),
(128, 38, 'Daily Do 20 push-ups', 'pending', 'hard', 'Physical Health', 3, 11, '2025-05-27 00:35:58'),
(129, 38, 'Daily Make new connections', 'pending', 'medium', 'Relationships Social', 7, 8, '2025-05-27 00:35:58'),
(130, 39, 'Daily Write in journal', 'pending', 'medium', 'Passion Hobbies', 5, 11, '2025-05-27 00:35:58'),
(131, 39, 'Daily Make bed', 'pending', 'hard', 'Home Environment', 3, 10, '2025-05-27 00:35:58'),
(132, 39, 'Daily Reflect on progress', 'pending', 'hard', 'Personal Growth', 6, 6, '2025-05-27 00:35:58'),
(133, 40, 'Daily Practice deep breathing', 'completed', 'medium', 'Mental Wellness', 3, 8, '2025-05-27 00:35:58'),
(134, 40, 'Daily Take photos', 'pending', 'medium', 'Passion Hobbies', 5, 8, '2025-05-27 00:35:58'),
(135, 40, 'Daily Write in journal', 'pending', 'easy', 'Passion Hobbies', 6, 14, '2025-05-27 00:35:58'),
(136, 41, 'Daily Vacuum house', 'completed', 'easy', 'Home Environment', 7, 10, '2025-05-27 00:35:58'),
(137, 41, 'Daily Vacuum house', 'pending', 'medium', 'Home Environment', 2, 15, '2025-05-27 00:35:58'),
(138, 41, 'Daily Cook new recipe', 'completed', 'medium', 'Passion Hobbies', 7, 15, '2025-05-27 00:35:58'),
(139, 42, 'Daily Play board games', 'completed', 'easy', 'Passion Hobbies', 6, 13, '2025-05-27 00:35:58'),
(140, 42, 'Daily Organize workspace', 'completed', 'hard', 'Home Environment', 5, 8, '2025-05-27 00:35:58'),
(141, 42, 'Daily Meal prep', 'completed', 'hard', 'Home Environment', 3, 6, '2025-05-27 00:35:58'),
(142, 43, 'Daily Meditate for 10 minutes', 'pending', 'medium', 'Mental Wellness', 5, 8, '2025-05-27 00:35:58'),
(143, 43, 'Daily Research investments', 'completed', 'medium', 'Finance', 3, 14, '2025-05-27 00:35:58'),
(144, 43, 'Daily Review budget', 'completed', 'hard', 'Finance', 3, 11, '2025-05-27 00:35:58'),
(145, 44, 'Daily Plan social activity', 'completed', 'easy', 'Relationships Social', 5, 5, '2025-05-27 00:35:58'),
(146, 44, 'Daily Update resume', 'pending', 'hard', 'Career / Studies', 5, 7, '2025-05-27 00:35:58'),
(147, 44, 'Daily Track expenses', 'pending', 'hard', 'Finance', 3, 13, '2025-05-27 00:35:58'),
(148, 45, 'Daily Review financial goals', 'completed', 'hard', 'Finance', 7, 11, '2025-05-27 00:35:58'),
(149, 45, 'Daily Eat a healthy breakfast', 'completed', 'medium', 'Physical Health', 7, 11, '2025-05-27 00:35:58'),
(150, 45, 'Daily Resolve conflicts', 'pending', 'easy', 'Relationships Social', 7, 7, '2025-05-27 00:35:58'),
(151, 46, 'Daily Work on art project', 'pending', 'medium', 'Passion Hobbies', 5, 10, '2025-05-27 00:35:59'),
(152, 46, 'Daily Drink 8 glasses of water', 'completed', 'hard', 'Physical Health', 8, 13, '2025-05-27 00:35:59'),
(153, 46, 'Daily Play board games', 'completed', 'hard', 'Passion Hobbies', 2, 14, '2025-05-27 00:35:59'),
(154, 47, 'Daily Take vitamins', 'pending', 'medium', 'Physical Health', 3, 15, '2025-05-27 00:35:59'),
(155, 48, 'Daily Cook new recipe', 'pending', 'medium', 'Passion Hobbies', 4, 7, '2025-05-27 00:35:59'),
(156, 48, 'Daily Do 20 push-ups', 'pending', 'hard', 'Physical Health', 8, 14, '2025-05-27 00:35:59'),
(157, 48, 'Daily Practice mindfulness', 'pending', 'medium', 'Mental Wellness', 5, 13, '2025-05-27 00:35:59'),
(158, 49, 'Daily Write in journal', 'pending', 'medium', 'Passion Hobbies', 8, 11, '2025-05-27 00:35:59'),
(159, 49, 'Daily Meal prep', 'pending', 'hard', 'Home Environment', 6, 9, '2025-05-27 00:35:59'),
(160, 49, 'Daily Make new connections', 'pending', 'easy', 'Relationships Social', 6, 15, '2025-05-27 00:35:59'),
(161, 50, 'Daily Take photos', 'pending', 'medium', 'Passion Hobbies', 2, 12, '2025-05-27 00:35:59'),
(162, 50, 'Daily Practice coding', 'pending', 'hard', 'Career / Studies', 4, 13, '2025-05-27 00:35:59'),
(163, 50, 'Daily Meal prep', 'completed', 'easy', 'Home Environment', 3, 6, '2025-05-27 00:35:59'),
(164, 51, 'Daily Work on art project', 'pending', 'hard', 'Passion Hobbies', 4, 13, '2025-05-27 00:35:59'),
(165, 51, 'Daily Clean living space', 'pending', 'medium', 'Home Environment', 3, 14, '2025-05-27 00:35:59'),
(166, 51, 'Daily Watch educational video', 'pending', 'hard', 'Personal Growth', 6, 15, '2025-05-27 00:35:59'),
(167, 52, 'Daily Work on art project', 'completed', 'easy', 'Passion Hobbies', 7, 9, '2025-05-27 00:35:59'),
(168, 53, 'Daily Pay bills on time', 'pending', 'easy', 'Finance', 2, 14, '2025-05-27 00:35:59'),
(169, 53, 'Daily Call a friend', 'pending', 'easy', 'Relationships Social', 4, 8, '2025-05-27 00:35:59'),
(170, 54, 'Daily Practice deep breathing', 'pending', 'easy', 'Mental Wellness', 2, 8, '2025-05-27 00:35:59'),
(171, 55, 'Daily Set daily goals', 'pending', 'hard', 'Personal Growth', 6, 15, '2025-05-27 00:35:59'),
(172, 55, 'Daily Call a friend', 'completed', 'medium', 'Relationships Social', 3, 13, '2025-05-27 00:35:59'),
(173, 56, 'Daily Write gratitude list', 'pending', 'medium', 'Mental Wellness', 8, 13, '2025-05-27 00:35:59'),
(174, 57, 'Daily Practice interview skills', 'pending', 'hard', 'Career / Studies', 3, 12, '2025-05-27 00:35:59'),
(175, 57, 'Daily Make new connections', 'pending', 'hard', 'Relationships Social', 4, 12, '2025-05-27 00:35:59'),
(176, 58, 'Daily Plan social activity', 'pending', 'hard', 'Relationships Social', 5, 15, '2025-05-27 00:35:59'),
(177, 59, 'Daily Reflect on progress', 'pending', 'easy', 'Personal Growth', 6, 6, '2025-05-27 00:35:59'),
(178, 60, 'Daily Pay bills on time', 'completed', 'hard', 'Finance', 2, 12, '2025-05-27 00:35:59'),
(179, 60, 'Daily Take a mental health break', 'completed', 'hard', 'Mental Wellness', 8, 11, '2025-05-27 00:35:59'),
(180, 61, 'Daily Cut unnecessary expenses', 'completed', 'medium', 'Finance', 4, 10, '2025-05-27 00:35:59'),
(181, 61, 'Daily Stretch for 10 minutes', 'completed', 'hard', 'Physical Health', 2, 8, '2025-05-27 00:35:59'),
(182, 61, 'Daily Practice yoga', 'pending', 'easy', 'Physical Health', 4, 12, '2025-05-27 00:35:59'),
(183, 62, 'Daily Practice a skill', 'pending', 'easy', 'Personal Growth', 3, 11, '2025-05-27 00:35:59'),
(184, 63, 'Daily Study programming', 'pending', 'hard', 'Career / Studies', 4, 14, '2025-05-27 00:35:59'),
(185, 63, 'Daily Practice active listening', 'pending', 'hard', 'Relationships Social', 2, 6, '2025-05-27 00:35:59'),
(186, 63, 'Daily Spend time with family', 'pending', 'hard', 'Relationships Social', 5, 5, '2025-05-27 00:35:59'),
(187, 64, 'Daily Research investments', 'pending', 'medium', 'Finance', 7, 15, '2025-05-27 00:35:59'),
(188, 64, 'Daily Work on art project', 'pending', 'easy', 'Passion Hobbies', 7, 14, '2025-05-27 00:35:59'),
(189, 65, 'Daily Do cardio workout', 'pending', 'medium', 'Physical Health', 6, 9, '2025-05-27 00:35:59'),
(190, 65, 'Daily Show appreciation', 'completed', 'easy', 'Relationships Social', 6, 11, '2025-05-27 00:35:59'),
(191, 66, 'Daily Listen to calming music', 'completed', 'easy', 'Mental Wellness', 3, 8, '2025-05-27 00:35:59'),
(192, 66, 'Daily Show appreciation', 'completed', 'hard', 'Relationships Social', 8, 9, '2025-05-27 00:35:59'),
(193, 67, 'Daily Practice a skill', 'pending', 'hard', 'Personal Growth', 6, 5, '2025-05-27 00:35:59'),
(194, 68, 'Daily Learn something new', 'pending', 'medium', 'Personal Growth', 5, 14, '2025-05-27 00:35:59'),
(195, 69, 'Daily Plan future goals', 'pending', 'medium', 'Personal Growth', 2, 5, '2025-05-27 00:35:59'),
(196, 69, 'Daily Plan future goals', 'pending', 'hard', 'Personal Growth', 8, 13, '2025-05-27 00:35:59'),
(197, 70, 'Daily Make bed', 'pending', 'medium', 'Home Environment', 7, 11, '2025-05-27 00:35:59'),
(198, 70, 'Daily Resolve conflicts', 'completed', 'hard', 'Relationships Social', 5, 14, '2025-05-27 00:35:59'),
(199, 70, 'Daily Read for 30 minutes', 'pending', 'medium', 'Mental Wellness', 2, 12, '2025-05-27 00:35:59'),
(200, 71, 'Daily Research investments', 'completed', 'hard', 'Finance', 8, 8, '2025-05-27 00:35:59'),
(201, 71, 'Daily Cook new recipe', 'pending', 'easy', 'Passion Hobbies', 2, 5, '2025-05-27 00:35:59'),
(202, 71, 'Daily Make new connections', 'pending', 'hard', 'Relationships Social', 7, 7, '2025-05-27 00:35:59'),
(203, 72, 'Daily Set daily goals', 'pending', 'hard', 'Personal Growth', 5, 14, '2025-05-27 00:35:59'),
(204, 72, 'Daily Resolve conflicts', 'completed', 'medium', 'Relationships Social', 3, 14, '2025-05-27 00:35:59'),
(205, 73, 'Daily Show appreciation', 'pending', 'medium', 'Relationships Social', 2, 7, '2025-05-27 00:35:59'),
(206, 74, 'Daily Declutter room', 'pending', 'easy', 'Home Environment', 4, 9, '2025-05-27 00:35:59'),
(207, 74, 'Daily Meditate for 10 minutes', 'pending', 'medium', 'Mental Wellness', 4, 12, '2025-05-27 00:35:59'),
(208, 74, 'Daily Network with professionals', 'completed', 'medium', 'Career / Studies', 5, 9, '2025-05-27 00:35:59'),
(209, 75, 'Daily Plan future goals', 'pending', 'medium', 'Personal Growth', 3, 13, '2025-05-27 00:35:59'),
(210, 75, 'Daily Garden for 30 minutes', 'pending', 'hard', 'Passion Hobbies', 6, 9, '2025-05-27 00:35:59'),
(211, 76, 'Daily Pay bills on time', 'completed', 'hard', 'Finance', 6, 8, '2025-05-27 00:35:59'),
(212, 77, 'Daily Practice a skill', 'pending', 'hard', 'Personal Growth', 5, 8, '2025-05-27 00:36:00'),
(213, 77, 'Daily Practice deep breathing', 'pending', 'easy', 'Mental Wellness', 4, 12, '2025-05-27 00:36:00'),
(214, 77, 'Daily Read industry news', 'pending', 'easy', 'Career / Studies', 5, 13, '2025-05-27 00:36:00'),
(215, 78, 'Daily Do laundry', 'pending', 'medium', 'Home Environment', 8, 10, '2025-05-27 00:36:00'),
(216, 78, 'Daily Work on portfolio', 'completed', 'hard', 'Career / Studies', 2, 14, '2025-05-27 00:36:00'),
(217, 79, 'Daily Learn about finances', 'completed', 'easy', 'Finance', 5, 11, '2025-05-27 00:36:00'),
(218, 79, 'Daily Learn something new', 'pending', 'easy', 'Personal Growth', 4, 11, '2025-05-27 00:36:00'),
(219, 79, 'Daily Listen to calming music', 'completed', 'medium', 'Mental Wellness', 4, 13, '2025-05-27 00:36:00'),
(220, 80, 'Daily Listen to calming music', 'pending', 'medium', 'Mental Wellness', 8, 7, '2025-05-27 00:36:00'),
(221, 80, 'Daily Meditate for 10 minutes', 'pending', 'medium', 'Mental Wellness', 2, 10, '2025-05-27 00:36:00'),
(222, 80, 'Daily Work on portfolio', 'pending', 'hard', 'Career / Studies', 8, 13, '2025-05-27 00:36:00'),
(223, 81, 'Daily Do cardio workout', 'pending', 'easy', 'Physical Health', 2, 13, '2025-05-27 00:36:00'),
(224, 81, 'Daily Network with professionals', 'pending', 'medium', 'Career / Studies', 3, 10, '2025-05-27 00:36:00'),
(225, 82, 'Daily Practice yoga', 'pending', 'easy', 'Physical Health', 5, 15, '2025-05-27 00:36:00'),
(226, 83, 'Daily Do 20 push-ups', 'pending', 'medium', 'Physical Health', 4, 7, '2025-05-27 00:36:00'),
(227, 83, 'Daily Plan future goals', 'pending', 'medium', 'Personal Growth', 3, 10, '2025-05-27 00:36:00'),
(228, 84, 'Daily Read for 30 minutes', 'pending', 'easy', 'Mental Wellness', 5, 10, '2025-05-27 00:36:00'),
(229, 84, 'Daily Set daily goals', 'pending', 'hard', 'Personal Growth', 3, 12, '2025-05-27 00:36:00'),
(230, 85, 'Daily Make new connections', 'pending', 'medium', 'Relationships Social', 5, 13, '2025-05-27 00:36:00'),
(231, 85, 'Daily Track expenses', 'completed', 'easy', 'Finance', 2, 15, '2025-05-27 00:36:00'),
(232, 86, 'Daily Spend time with family', 'completed', 'easy', 'Relationships Social', 4, 11, '2025-05-27 00:36:00'),
(233, 86, 'Daily Cook new recipe', 'pending', 'easy', 'Passion Hobbies', 5, 6, '2025-05-27 00:36:00'),
(234, 86, 'Daily Water plants', 'pending', 'medium', 'Home Environment', 2, 7, '2025-05-27 00:36:00'),
(235, 87, 'Daily Do cardio workout', 'pending', 'easy', 'Physical Health', 5, 14, '2025-05-27 00:36:00'),
(236, 87, 'Daily Resolve conflicts', 'completed', 'hard', 'Relationships Social', 8, 11, '2025-05-27 00:36:00'),
(237, 88, 'Daily Practice active listening', 'pending', 'hard', 'Relationships Social', 6, 13, '2025-05-27 00:36:00'),
(238, 89, 'Daily Read industry news', 'pending', 'easy', 'Career / Studies', 4, 7, '2025-05-27 00:36:00'),
(239, 90, 'Daily Make new connections', 'pending', 'medium', 'Relationships Social', 3, 13, '2025-05-27 00:36:00'),
(240, 90, 'Daily Learn about finances', 'pending', 'medium', 'Finance', 2, 6, '2025-05-27 00:36:00'),
(241, 91, 'Daily Practice coding', 'completed', 'hard', 'Career / Studies', 6, 5, '2025-05-27 00:36:00'),
(242, 91, 'Daily Show appreciation', 'pending', 'hard', 'Relationships Social', 6, 7, '2025-05-27 00:36:00'),
(243, 91, 'Daily Work on art project', 'pending', 'medium', 'Passion Hobbies', 3, 5, '2025-05-27 00:36:00'),
(244, 92, 'Daily Make bed', 'pending', 'easy', 'Home Environment', 5, 14, '2025-05-27 00:36:00'),
(245, 93, 'Daily Show appreciation', 'pending', 'easy', 'Relationships Social', 7, 11, '2025-05-27 00:36:00'),
(246, 93, 'Daily Practice coding', 'pending', 'easy', 'Career / Studies', 7, 6, '2025-05-27 00:36:00'),
(247, 94, 'Daily Work on art project', 'completed', 'medium', 'Passion Hobbies', 8, 15, '2025-05-27 00:36:00'),
(248, 94, 'Daily Do 20 push-ups', 'pending', 'medium', 'Physical Health', 3, 6, '2025-05-27 00:36:00'),
(249, 94, 'Daily Clean living space', 'completed', 'medium', 'Home Environment', 2, 5, '2025-05-27 00:36:00'),
(250, 95, 'Daily Clean living space', 'completed', 'medium', 'Home Environment', 8, 14, '2025-05-27 00:36:00'),
(251, 96, 'Daily Write in journal', 'completed', 'easy', 'Passion Hobbies', 6, 15, '2025-05-27 00:36:00'),
(252, 96, 'Daily Go for a 30-minute walk', 'completed', 'hard', 'Physical Health', 5, 10, '2025-05-27 00:36:00'),
(253, 96, 'Daily Declutter room', 'completed', 'hard', 'Home Environment', 6, 5, '2025-05-27 00:36:00'),
(254, 97, 'Daily Call a friend', 'pending', 'hard', 'Relationships Social', 3, 8, '2025-05-27 00:36:00'),
(255, 97, 'Daily Do cardio workout', 'pending', 'medium', 'Physical Health', 7, 13, '2025-05-27 00:36:00'),
(256, 98, 'Daily Track expenses', 'completed', 'hard', 'Finance', 7, 12, '2025-05-27 00:36:00'),
(257, 98, 'Daily Network with professionals', 'pending', 'easy', 'Career / Studies', 7, 15, '2025-05-27 00:36:00'),
(258, 99, 'Daily Meal prep', 'pending', 'medium', 'Home Environment', 3, 13, '2025-05-27 00:36:00'),
(259, 99, 'Daily Set daily goals', 'pending', 'easy', 'Personal Growth', 3, 15, '2025-05-27 00:36:00'),
(260, 99, 'Daily Set daily goals', 'completed', 'easy', 'Personal Growth', 2, 15, '2025-05-27 00:36:00'),
(261, 100, 'Daily Vacuum house', 'pending', 'medium', 'Home Environment', 7, 5, '2025-05-27 00:36:00');

--
-- Triggers `dailytasks`
--
DELIMITER $$
CREATE TRIGGER `after_dailytask_completion` AFTER UPDATE ON `dailytasks` FOR EACH ROW BEGIN 
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
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
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `goodhabits`
--

CREATE TABLE `goodhabits` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `difficulty` enum('easy','medium','hard') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `category` enum('Physical Health','Mental Wellness','Personal Growth','Career / Studies','Finance','Home Environment','Relationships Social','Passion Hobbies') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `status` enum('pending','completed') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'pending',
  `coins` int DEFAULT '0',
  `xp` int DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `goodhabits`
--

INSERT INTO `goodhabits` (`id`, `user_id`, `title`, `difficulty`, `category`, `status`, `coins`, `xp`, `created_at`, `updated_at`, `deleted_at`) VALUES
(5, 1, 'Bill management', 'medium', 'Finance', 'pending', 2, 14, '2025-05-27 00:33:32', '2025-05-27 00:33:32', NULL),
(6, 1, 'Organization', 'easy', 'Home Environment', 'pending', 10, 10, '2025-05-27 00:33:32', '2025-05-27 00:33:32', NULL),
(7, 1, 'Connection', 'easy', 'Relationships Social', 'pending', 3, 6, '2025-05-27 00:33:32', '2025-05-27 00:33:32', NULL),
(8, 1, 'Skill practice', 'medium', 'Personal Growth', 'pending', 4, 19, '2025-05-27 00:33:32', '2025-05-27 00:33:32', NULL),
(9, 1, 'Daily meditation', 'medium', 'Mental Wellness', 'pending', 5, 5, '2025-05-27 00:33:32', '2025-05-27 00:33:32', NULL),
(10, 2, 'Portfolio work', 'medium', 'Career / Studies', 'pending', 5, 17, '2025-05-27 00:33:32', '2025-05-27 00:33:32', NULL),
(11, 2, 'Code practice', 'easy', 'Career / Studies', 'pending', 3, 11, '2025-05-27 00:33:32', '2025-05-27 00:33:32', NULL),
(12, 2, 'Quality time', 'easy', 'Relationships Social', 'pending', 9, 11, '2025-05-27 00:33:32', '2025-05-27 00:33:32', NULL),
(13, 2, 'Saving habit', 'medium', 'Finance', 'pending', 10, 18, '2025-05-27 00:33:32', '2025-05-27 00:33:32', NULL),
(14, 2, 'Take vitamins', 'medium', 'Physical Health', 'pending', 10, 20, '2025-05-27 00:33:32', '2025-05-27 00:33:32', NULL),
(15, 3, 'Daily walk', 'easy', 'Physical Health', 'pending', 2, 5, '2025-05-27 00:33:32', '2025-05-27 00:33:32', NULL),
(16, 3, 'Communication', 'easy', 'Relationships Social', 'pending', 8, 11, '2025-05-27 00:33:32', '2025-05-27 00:33:32', NULL),
(17, 3, 'Financial learning', 'easy', 'Finance', 'pending', 7, 5, '2025-05-27 00:33:32', '2025-05-27 00:33:32', NULL),
(18, 3, 'Skill building', 'medium', 'Career / Studies', 'pending', 6, 11, '2025-05-27 00:33:32', '2025-05-27 00:33:32', NULL),
(19, 3, 'Daily check-in', 'easy', 'Relationships Social', 'pending', 4, 13, '2025-05-27 00:33:32', '2025-05-27 00:33:32', NULL),
(20, 4, 'Hobby practice', 'medium', 'Passion Hobbies', 'pending', 4, 12, '2025-05-27 00:33:32', '2025-05-27 00:33:32', NULL),
(21, 4, 'Hobby practice', 'medium', 'Passion Hobbies', 'pending', 10, 15, '2025-05-27 00:33:32', '2025-05-27 00:33:32', NULL),
(22, 5, 'Skill building', 'medium', 'Career / Studies', 'pending', 4, 18, '2025-05-27 00:33:32', '2025-05-27 00:33:32', NULL),
(23, 5, 'Saving habit', 'easy', 'Finance', 'pending', 10, 16, '2025-05-27 00:33:32', '2025-05-27 00:33:32', NULL),
(24, 5, 'Daily meditation', 'easy', 'Mental Wellness', 'pending', 2, 16, '2025-05-27 00:33:32', '2025-05-27 00:33:32', NULL),
(25, 5, 'Fun activity', 'medium', 'Passion Hobbies', 'pending', 5, 6, '2025-05-27 00:33:32', '2025-05-27 00:33:32', NULL),
(26, 5, 'Morning stretch', 'medium', 'Physical Health', 'pending', 2, 11, '2025-05-27 00:33:32', '2025-05-27 00:33:32', NULL),
(27, 1, 'Reading habit', 'easy', 'Mental Wellness', 'pending', 7, 13, '2025-05-27 00:33:58', '2025-05-27 00:33:58', NULL),
(28, 1, 'Saving habit', 'medium', 'Finance', 'pending', 2, 6, '2025-05-27 00:33:58', '2025-05-27 00:33:58', NULL),
(29, 1, 'Bill management', 'easy', 'Finance', 'pending', 4, 18, '2025-05-27 00:33:58', '2025-05-27 00:33:58', NULL),
(30, 1, 'Music practice', 'medium', 'Passion Hobbies', 'pending', 9, 19, '2025-05-27 00:33:58', '2025-05-27 00:33:58', NULL),
(31, 1, 'Bill management', 'easy', 'Finance', 'pending', 2, 10, '2025-05-27 00:33:58', '2025-05-27 00:33:58', NULL),
(32, 2, 'Study session', 'medium', 'Career / Studies', 'pending', 5, 5, '2025-05-27 00:33:58', '2025-05-27 00:33:58', NULL),
(33, 2, 'Morning stretch', 'easy', 'Physical Health', 'pending', 6, 5, '2025-05-27 00:33:58', '2025-05-27 00:33:58', NULL),
(34, 2, 'Study session', 'medium', 'Career / Studies', 'pending', 3, 11, '2025-05-27 00:33:58', '2025-05-27 00:33:58', NULL),
(35, 3, 'Learning', 'easy', 'Career / Studies', 'pending', 8, 17, '2025-05-27 00:33:58', '2025-05-27 00:33:58', NULL),
(36, 3, 'Music practice', 'easy', 'Passion Hobbies', 'pending', 2, 9, '2025-05-27 00:33:58', '2025-05-27 00:33:58', NULL),
(37, 3, 'Bill management', 'medium', 'Finance', 'pending', 7, 17, '2025-05-27 00:33:58', '2025-05-27 00:33:58', NULL),
(38, 4, 'Exercise routine', 'medium', 'Physical Health', 'pending', 9, 7, '2025-05-27 00:33:58', '2025-05-27 00:33:58', NULL),
(39, 4, 'Daily check-in', 'medium', 'Relationships Social', 'pending', 7, 19, '2025-05-27 00:33:58', '2025-05-27 00:33:58', NULL),
(40, 4, 'Maintenance', 'easy', 'Home Environment', 'pending', 10, 7, '2025-05-27 00:33:58', '2025-05-27 00:33:58', NULL),
(41, 5, 'Expense tracking', 'easy', 'Finance', 'pending', 6, 5, '2025-05-27 00:33:58', '2025-05-27 00:33:58', NULL),
(42, 5, 'Art creation', 'easy', 'Passion Hobbies', 'pending', 9, 5, '2025-05-27 00:33:58', '2025-05-27 00:33:58', NULL),
(43, 5, 'Room cleaning', 'easy', 'Home Environment', 'pending', 5, 12, '2025-05-27 00:33:58', '2025-05-27 00:33:58', NULL),
(44, 1, 'Goal setting', 'medium', 'Personal Growth', 'pending', 9, 16, '2025-05-27 00:35:36', '2025-05-27 00:35:36', NULL),
(45, 1, 'Expense tracking', 'easy', 'Finance', 'pending', 3, 18, '2025-05-27 00:35:36', '2025-05-27 00:35:36', NULL),
(46, 1, 'Skill practice', 'medium', 'Personal Growth', 'pending', 8, 10, '2025-05-27 00:35:36', '2025-05-27 00:35:36', NULL),
(47, 1, 'Daily learning', 'easy', 'Personal Growth', 'pending', 3, 17, '2025-05-27 00:35:36', '2025-05-27 00:35:36', NULL),
(48, 1, 'Skill building', 'medium', 'Career / Studies', 'pending', 2, 12, '2025-05-27 00:35:36', '2025-05-27 00:35:36', NULL),
(49, 2, 'Creative time', 'easy', 'Passion Hobbies', 'pending', 5, 8, '2025-05-27 00:35:36', '2025-05-27 00:35:36', NULL),
(50, 2, 'Connection', 'easy', 'Relationships Social', 'pending', 2, 18, '2025-05-27 00:35:36', '2025-05-27 00:35:36', NULL),
(51, 2, 'Planning', 'medium', 'Personal Growth', 'pending', 2, 7, '2025-05-27 00:35:36', '2025-05-27 00:35:36', NULL),
(52, 3, 'Morning stretch', 'medium', 'Physical Health', 'pending', 8, 5, '2025-05-27 00:35:36', '2025-05-27 00:35:36', NULL),
(53, 3, 'Creative time', 'medium', 'Passion Hobbies', 'pending', 3, 12, '2025-05-27 00:35:36', '2025-05-27 00:35:36', NULL),
(54, 3, 'Expense tracking', 'easy', 'Finance', 'pending', 8, 8, '2025-05-27 00:35:36', '2025-05-27 00:35:36', NULL),
(55, 4, 'Saving habit', 'medium', 'Finance', 'pending', 9, 17, '2025-05-27 00:35:36', '2025-05-27 00:35:36', NULL),
(56, 4, 'Exercise routine', 'easy', 'Physical Health', 'pending', 10, 13, '2025-05-27 00:35:36', '2025-05-27 00:35:36', NULL),
(57, 5, 'Reading habit', 'medium', 'Mental Wellness', 'pending', 9, 9, '2025-05-27 00:35:36', '2025-05-27 00:35:36', NULL),
(58, 5, 'Daily learning', 'easy', 'Personal Growth', 'pending', 9, 20, '2025-05-27 00:35:36', '2025-05-27 00:35:36', NULL),
(59, 5, 'Connection', 'easy', 'Relationships Social', 'pending', 3, 20, '2025-05-27 00:35:36', '2025-05-27 00:35:36', NULL),
(60, 5, 'Take vitamins', 'easy', 'Physical Health', 'pending', 10, 18, '2025-05-27 00:35:36', '2025-05-27 00:35:36', NULL),
(61, 6, 'Self reflection', 'easy', 'Personal Growth', 'pending', 5, 19, '2025-05-27 00:35:36', '2025-05-27 00:35:36', NULL),
(62, 6, 'Budget review', 'easy', 'Finance', 'pending', 10, 7, '2025-05-27 00:35:36', '2025-05-27 00:35:36', NULL),
(63, 6, 'Code practice', 'medium', 'Career / Studies', 'pending', 4, 20, '2025-05-27 00:35:36', '2025-05-27 00:35:36', NULL),
(64, 7, 'Connection', 'easy', 'Relationships Social', 'pending', 10, 9, '2025-05-27 00:35:36', '2025-05-27 00:35:36', NULL),
(65, 7, 'Decluttering', 'medium', 'Home Environment', 'pending', 4, 20, '2025-05-27 00:35:36', '2025-05-27 00:35:36', NULL),
(66, 7, 'Music practice', 'easy', 'Passion Hobbies', 'pending', 8, 6, '2025-05-27 00:35:36', '2025-05-27 00:35:36', NULL),
(67, 8, 'Communication', 'medium', 'Relationships Social', 'pending', 6, 9, '2025-05-27 00:35:36', '2025-05-27 00:35:36', NULL),
(68, 8, 'Gratitude practice', 'easy', 'Mental Wellness', 'pending', 6, 13, '2025-05-27 00:35:36', '2025-05-27 00:35:36', NULL),
(69, 8, 'Expense tracking', 'easy', 'Finance', 'pending', 4, 16, '2025-05-27 00:35:36', '2025-05-27 00:35:36', NULL),
(70, 8, 'Daily learning', 'easy', 'Personal Growth', 'pending', 3, 10, '2025-05-27 00:35:36', '2025-05-27 00:35:36', NULL),
(71, 9, 'Reading habit', 'medium', 'Mental Wellness', 'pending', 9, 18, '2025-05-27 00:35:36', '2025-05-27 00:35:36', NULL),
(72, 9, 'Room cleaning', 'easy', 'Home Environment', 'pending', 2, 9, '2025-05-27 00:35:36', '2025-05-27 00:35:36', NULL),
(73, 9, 'Daily meditation', 'medium', 'Mental Wellness', 'pending', 3, 20, '2025-05-27 00:35:36', '2025-05-27 00:35:36', NULL),
(74, 9, 'Skill practice', 'medium', 'Personal Growth', 'pending', 9, 6, '2025-05-27 00:35:36', '2025-05-27 00:35:36', NULL),
(75, 9, 'Saving habit', 'easy', 'Finance', 'pending', 4, 11, '2025-05-27 00:35:36', '2025-05-27 00:35:36', NULL),
(76, 10, 'Daily meditation', 'medium', 'Mental Wellness', 'pending', 10, 8, '2025-05-27 00:35:36', '2025-05-27 00:35:36', NULL),
(77, 10, 'Fun activity', 'medium', 'Passion Hobbies', 'pending', 7, 13, '2025-05-27 00:35:36', '2025-05-27 00:35:36', NULL),
(78, 10, 'Appreciation', 'easy', 'Relationships Social', 'pending', 2, 16, '2025-05-27 00:35:36', '2025-05-27 00:35:36', NULL),
(79, 10, 'Art creation', 'medium', 'Passion Hobbies', 'pending', 10, 14, '2025-05-27 00:35:36', '2025-05-27 00:35:36', NULL),
(80, 1, 'Decluttering', 'easy', 'Home Environment', 'pending', 8, 11, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(81, 1, 'Organization', 'medium', 'Home Environment', 'pending', 2, 16, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(82, 2, 'Gratitude practice', 'medium', 'Mental Wellness', 'pending', 4, 20, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(83, 2, 'Skill building', 'easy', 'Career / Studies', 'pending', 6, 12, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(84, 2, 'Take vitamins', 'medium', 'Physical Health', 'pending', 9, 10, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(85, 2, 'Skill building', 'easy', 'Career / Studies', 'pending', 4, 15, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(86, 3, 'Daily check-in', 'easy', 'Relationships Social', 'pending', 7, 9, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(87, 3, 'Expense tracking', 'medium', 'Finance', 'pending', 8, 15, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(88, 3, 'Room cleaning', 'easy', 'Home Environment', 'pending', 8, 13, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(89, 3, 'Journaling', 'easy', 'Mental Wellness', 'pending', 4, 11, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(90, 3, 'Daily learning', 'medium', 'Personal Growth', 'pending', 4, 7, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(91, 4, 'Take vitamins', 'easy', 'Physical Health', 'pending', 5, 5, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(92, 4, 'Learning', 'easy', 'Career / Studies', 'pending', 3, 16, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(93, 4, 'Learning', 'medium', 'Career / Studies', 'pending', 3, 9, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(94, 4, 'Appreciation', 'medium', 'Relationships Social', 'pending', 9, 14, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(95, 5, 'Music practice', 'easy', 'Passion Hobbies', 'pending', 10, 8, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(96, 5, 'Meal prep', 'easy', 'Home Environment', 'pending', 2, 17, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(97, 5, 'Financial learning', 'medium', 'Finance', 'pending', 7, 15, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(98, 5, 'Planning', 'easy', 'Personal Growth', 'pending', 9, 11, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(99, 6, 'Daily walk', 'medium', 'Physical Health', 'pending', 4, 16, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(100, 6, 'Organization', 'easy', 'Home Environment', 'pending', 9, 12, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(101, 7, 'Mindfulness', 'easy', 'Mental Wellness', 'pending', 8, 17, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(102, 7, 'Journaling', 'medium', 'Mental Wellness', 'pending', 10, 6, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(103, 8, 'Daily walk', 'medium', 'Physical Health', 'pending', 2, 5, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(104, 8, 'Learning', 'easy', 'Career / Studies', 'pending', 8, 12, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(105, 8, 'Hobby practice', 'easy', 'Passion Hobbies', 'pending', 7, 18, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(106, 8, 'Skill building', 'easy', 'Career / Studies', 'pending', 8, 6, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(107, 8, 'Art creation', 'medium', 'Passion Hobbies', 'pending', 3, 13, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(108, 9, 'Morning stretch', 'easy', 'Physical Health', 'pending', 9, 5, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(109, 9, 'Learning', 'medium', 'Career / Studies', 'pending', 3, 17, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(110, 9, 'Morning stretch', 'medium', 'Physical Health', 'pending', 10, 11, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(111, 10, 'Bill management', 'medium', 'Finance', 'pending', 6, 5, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(112, 10, 'Daily walk', 'easy', 'Physical Health', 'pending', 3, 19, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(113, 11, 'Portfolio work', 'medium', 'Career / Studies', 'pending', 6, 10, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(114, 11, 'Take vitamins', 'easy', 'Physical Health', 'pending', 5, 20, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(115, 12, 'Connection', 'medium', 'Relationships Social', 'pending', 3, 13, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(116, 12, 'Bill management', 'medium', 'Finance', 'pending', 9, 19, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(117, 13, 'Maintenance', 'easy', 'Home Environment', 'pending', 10, 14, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(118, 13, 'Maintenance', 'medium', 'Home Environment', 'pending', 3, 13, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(119, 13, 'Connection', 'medium', 'Relationships Social', 'pending', 5, 7, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(120, 13, 'Daily check-in', 'medium', 'Relationships Social', 'pending', 9, 14, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(121, 13, 'Creative time', 'easy', 'Passion Hobbies', 'pending', 3, 5, '2025-05-27 00:35:57', '2025-05-27 00:35:57', NULL),
(122, 14, 'Music practice', 'easy', 'Passion Hobbies', 'pending', 2, 18, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(123, 14, 'Code practice', 'easy', 'Career / Studies', 'pending', 2, 16, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(124, 14, 'Learning', 'medium', 'Career / Studies', 'pending', 6, 10, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(125, 15, 'Mindfulness', 'medium', 'Mental Wellness', 'pending', 9, 15, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(126, 15, 'Drink water', 'easy', 'Physical Health', 'pending', 2, 20, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(127, 15, 'Connection', 'easy', 'Relationships Social', 'pending', 3, 14, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(128, 15, 'Daily meditation', 'medium', 'Mental Wellness', 'pending', 2, 18, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(129, 16, 'Exercise routine', 'easy', 'Physical Health', 'pending', 10, 7, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(130, 16, 'Study session', 'medium', 'Career / Studies', 'pending', 10, 9, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(131, 17, 'Bill management', 'medium', 'Finance', 'pending', 10, 7, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(132, 17, 'Mindfulness', 'medium', 'Mental Wellness', 'pending', 6, 17, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(133, 17, 'Drink water', 'easy', 'Physical Health', 'pending', 5, 13, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(134, 17, 'Learning', 'medium', 'Career / Studies', 'pending', 10, 6, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(135, 17, 'Morning stretch', 'easy', 'Physical Health', 'pending', 2, 12, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(136, 18, 'Learning', 'easy', 'Career / Studies', 'pending', 7, 19, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(137, 18, 'Daily meditation', 'medium', 'Mental Wellness', 'pending', 3, 19, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(138, 18, 'Daily learning', 'easy', 'Personal Growth', 'pending', 4, 14, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(139, 19, 'Daily meditation', 'easy', 'Mental Wellness', 'pending', 3, 8, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(140, 19, 'Room cleaning', 'medium', 'Home Environment', 'pending', 8, 11, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(141, 20, 'Expense tracking', 'medium', 'Finance', 'pending', 7, 13, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(142, 20, 'Financial learning', 'easy', 'Finance', 'pending', 9, 14, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(143, 20, 'Planning', 'medium', 'Personal Growth', 'pending', 8, 9, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(144, 20, 'Daily walk', 'easy', 'Physical Health', 'pending', 10, 18, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(145, 20, 'Daily check-in', 'easy', 'Relationships Social', 'pending', 2, 11, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(146, 21, 'Decluttering', 'medium', 'Home Environment', 'pending', 2, 19, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(147, 21, 'Daily learning', 'easy', 'Personal Growth', 'pending', 5, 11, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(148, 21, 'Study session', 'medium', 'Career / Studies', 'pending', 7, 16, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(149, 21, 'Daily learning', 'medium', 'Personal Growth', 'pending', 6, 14, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(150, 22, 'Mindfulness', 'easy', 'Mental Wellness', 'pending', 6, 20, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(151, 22, 'Fun activity', 'easy', 'Passion Hobbies', 'pending', 6, 16, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(152, 23, 'Connection', 'medium', 'Relationships Social', 'pending', 2, 16, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(153, 23, 'Creative time', 'easy', 'Passion Hobbies', 'pending', 9, 19, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(154, 23, 'Communication', 'easy', 'Relationships Social', 'pending', 8, 7, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(155, 24, 'Connection', 'easy', 'Relationships Social', 'pending', 6, 15, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(156, 24, 'Daily learning', 'easy', 'Personal Growth', 'pending', 2, 5, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(157, 24, 'Organization', 'medium', 'Home Environment', 'pending', 10, 15, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(158, 25, 'Room cleaning', 'medium', 'Home Environment', 'pending', 7, 17, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(159, 25, 'Fun activity', 'medium', 'Passion Hobbies', 'pending', 9, 19, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(160, 25, 'Reading habit', 'medium', 'Mental Wellness', 'pending', 4, 8, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(161, 26, 'Planning', 'medium', 'Personal Growth', 'pending', 4, 12, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(162, 26, 'Communication', 'easy', 'Relationships Social', 'pending', 5, 12, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(163, 26, 'Creative time', 'easy', 'Passion Hobbies', 'pending', 4, 18, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(164, 26, 'Drink water', 'medium', 'Physical Health', 'pending', 3, 5, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(165, 27, 'Expense tracking', 'medium', 'Finance', 'pending', 2, 20, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(166, 27, 'Mindfulness', 'easy', 'Mental Wellness', 'pending', 7, 8, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(167, 28, 'Reading habit', 'easy', 'Mental Wellness', 'pending', 8, 10, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(168, 28, 'Creative time', 'easy', 'Passion Hobbies', 'pending', 3, 7, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(169, 29, 'Creative time', 'easy', 'Passion Hobbies', 'pending', 9, 11, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(170, 29, 'Connection', 'easy', 'Relationships Social', 'pending', 10, 7, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(171, 30, 'Morning stretch', 'medium', 'Physical Health', 'pending', 8, 16, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(172, 30, 'Skill building', 'medium', 'Career / Studies', 'pending', 8, 12, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(173, 31, 'Meal prep', 'medium', 'Home Environment', 'pending', 8, 13, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(174, 31, 'Learning', 'medium', 'Career / Studies', 'pending', 3, 6, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(175, 31, 'Skill building', 'easy', 'Career / Studies', 'pending', 8, 19, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(176, 31, 'Daily walk', 'medium', 'Physical Health', 'pending', 10, 7, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(177, 32, 'Hobby practice', 'medium', 'Passion Hobbies', 'pending', 2, 11, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(178, 32, 'Goal setting', 'easy', 'Personal Growth', 'pending', 10, 7, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(179, 32, 'Creative time', 'medium', 'Passion Hobbies', 'pending', 5, 11, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(180, 33, 'Quality time', 'easy', 'Relationships Social', 'pending', 10, 14, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(181, 33, 'Learning', 'medium', 'Career / Studies', 'pending', 10, 16, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(182, 33, 'Self reflection', 'easy', 'Personal Growth', 'pending', 5, 9, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(183, 33, 'Daily walk', 'easy', 'Physical Health', 'pending', 4, 20, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(184, 34, 'Appreciation', 'medium', 'Relationships Social', 'pending', 5, 18, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(185, 34, 'Morning stretch', 'easy', 'Physical Health', 'pending', 3, 5, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(186, 34, 'Daily walk', 'easy', 'Physical Health', 'pending', 3, 17, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(187, 34, 'Decluttering', 'easy', 'Home Environment', 'pending', 8, 14, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(188, 34, 'Meal prep', 'medium', 'Home Environment', 'pending', 7, 18, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(189, 35, 'Connection', 'easy', 'Relationships Social', 'pending', 10, 6, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(190, 35, 'Gratitude practice', 'medium', 'Mental Wellness', 'pending', 2, 19, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(191, 35, 'Hobby practice', 'easy', 'Passion Hobbies', 'pending', 7, 6, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(192, 35, 'Code practice', 'easy', 'Career / Studies', 'pending', 2, 11, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(193, 36, 'Skill practice', 'medium', 'Personal Growth', 'pending', 8, 8, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(194, 36, 'Fun activity', 'easy', 'Passion Hobbies', 'pending', 3, 15, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(195, 36, 'Fun activity', 'easy', 'Passion Hobbies', 'pending', 4, 9, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(196, 36, 'Learning', 'medium', 'Career / Studies', 'pending', 2, 20, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(197, 36, 'Meal prep', 'easy', 'Home Environment', 'pending', 3, 15, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(198, 37, 'Study session', 'easy', 'Career / Studies', 'pending', 10, 14, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(199, 37, 'Reading habit', 'medium', 'Mental Wellness', 'pending', 8, 13, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(200, 38, 'Room cleaning', 'medium', 'Home Environment', 'pending', 3, 16, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(201, 38, 'Bill management', 'easy', 'Finance', 'pending', 4, 7, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(202, 39, 'Reading habit', 'easy', 'Mental Wellness', 'pending', 4, 6, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(203, 39, 'Expense tracking', 'medium', 'Finance', 'pending', 3, 14, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(204, 40, 'Self reflection', 'medium', 'Personal Growth', 'pending', 10, 12, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(205, 40, 'Journaling', 'easy', 'Mental Wellness', 'pending', 6, 7, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(206, 41, 'Goal setting', 'easy', 'Personal Growth', 'pending', 3, 13, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(207, 41, 'Skill building', 'medium', 'Career / Studies', 'pending', 10, 8, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(208, 41, 'Organization', 'easy', 'Home Environment', 'pending', 10, 16, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(209, 41, 'Skill practice', 'easy', 'Personal Growth', 'pending', 8, 6, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(210, 42, 'Planning', 'medium', 'Personal Growth', 'pending', 4, 7, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(211, 42, 'Study session', 'medium', 'Career / Studies', 'pending', 9, 16, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(212, 42, 'Daily learning', 'medium', 'Personal Growth', 'pending', 9, 19, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(213, 42, 'Music practice', 'medium', 'Passion Hobbies', 'pending', 6, 20, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(214, 43, 'Maintenance', 'medium', 'Home Environment', 'pending', 10, 8, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(215, 43, 'Music practice', 'medium', 'Passion Hobbies', 'pending', 7, 17, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(216, 43, 'Skill building', 'easy', 'Career / Studies', 'pending', 4, 6, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(217, 43, 'Morning stretch', 'medium', 'Physical Health', 'pending', 3, 18, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(218, 43, 'Expense tracking', 'easy', 'Finance', 'pending', 9, 17, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(219, 44, 'Meal prep', 'medium', 'Home Environment', 'pending', 5, 8, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(220, 44, 'Drink water', 'medium', 'Physical Health', 'pending', 5, 18, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(221, 44, 'Goal setting', 'easy', 'Personal Growth', 'pending', 5, 9, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(222, 44, 'Hobby practice', 'easy', 'Passion Hobbies', 'pending', 10, 8, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(223, 44, 'Morning stretch', 'easy', 'Physical Health', 'pending', 6, 18, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(224, 45, 'Appreciation', 'medium', 'Relationships Social', 'pending', 7, 17, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(225, 45, 'Fun activity', 'easy', 'Passion Hobbies', 'pending', 4, 13, '2025-05-27 00:35:58', '2025-05-27 00:35:58', NULL),
(226, 46, 'Portfolio work', 'easy', 'Career / Studies', 'pending', 5, 18, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(227, 46, 'Saving habit', 'easy', 'Finance', 'pending', 10, 15, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(228, 46, 'Budget review', 'medium', 'Finance', 'pending', 2, 20, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(229, 47, 'Study session', 'easy', 'Career / Studies', 'pending', 8, 19, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(230, 47, 'Skill practice', 'medium', 'Personal Growth', 'pending', 3, 8, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(231, 47, 'Music practice', 'medium', 'Passion Hobbies', 'pending', 4, 14, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(232, 47, 'Planning', 'easy', 'Personal Growth', 'pending', 10, 5, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(233, 47, 'Daily meditation', 'medium', 'Mental Wellness', 'pending', 6, 11, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(234, 48, 'Code practice', 'medium', 'Career / Studies', 'pending', 9, 16, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(235, 48, 'Reading habit', 'medium', 'Mental Wellness', 'pending', 3, 9, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(236, 49, 'Bill management', 'easy', 'Finance', 'pending', 5, 12, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(237, 49, 'Daily meditation', 'medium', 'Mental Wellness', 'pending', 8, 17, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(238, 49, 'Budget review', 'easy', 'Finance', 'pending', 4, 15, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(239, 49, 'Maintenance', 'medium', 'Home Environment', 'pending', 7, 19, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(240, 50, 'Fun activity', 'medium', 'Passion Hobbies', 'pending', 2, 13, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(241, 50, 'Room cleaning', 'medium', 'Home Environment', 'pending', 10, 9, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(242, 51, 'Reading habit', 'easy', 'Mental Wellness', 'pending', 9, 10, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(243, 51, 'Mindfulness', 'easy', 'Mental Wellness', 'pending', 2, 14, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(244, 51, 'Bill management', 'medium', 'Finance', 'pending', 7, 5, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(245, 52, 'Morning stretch', 'medium', 'Physical Health', 'pending', 6, 6, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(246, 52, 'Hobby practice', 'medium', 'Passion Hobbies', 'pending', 10, 19, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(247, 52, 'Drink water', 'easy', 'Physical Health', 'pending', 10, 8, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(248, 52, 'Daily walk', 'easy', 'Physical Health', 'pending', 7, 13, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(249, 53, 'Daily walk', 'easy', 'Physical Health', 'pending', 9, 17, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(250, 53, 'Budget review', 'easy', 'Finance', 'pending', 8, 11, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(251, 54, 'Saving habit', 'easy', 'Finance', 'pending', 8, 9, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(252, 54, 'Self reflection', 'easy', 'Personal Growth', 'pending', 10, 11, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(253, 54, 'Exercise routine', 'easy', 'Physical Health', 'pending', 2, 11, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(254, 54, 'Room cleaning', 'medium', 'Home Environment', 'pending', 3, 14, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(255, 55, 'Music practice', 'easy', 'Passion Hobbies', 'pending', 6, 9, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(256, 55, 'Code practice', 'medium', 'Career / Studies', 'pending', 2, 12, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(257, 55, 'Skill building', 'medium', 'Career / Studies', 'pending', 5, 16, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(258, 55, 'Connection', 'medium', 'Relationships Social', 'pending', 9, 11, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(259, 56, 'Art creation', 'medium', 'Passion Hobbies', 'pending', 5, 7, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(260, 56, 'Morning stretch', 'easy', 'Physical Health', 'pending', 3, 7, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(261, 56, 'Study session', 'medium', 'Career / Studies', 'pending', 3, 7, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(262, 57, 'Take vitamins', 'easy', 'Physical Health', 'pending', 4, 8, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(263, 57, 'Communication', 'medium', 'Relationships Social', 'pending', 5, 19, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(264, 57, 'Learning', 'easy', 'Career / Studies', 'pending', 7, 17, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(265, 57, 'Hobby practice', 'easy', 'Passion Hobbies', 'pending', 7, 12, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(266, 58, 'Exercise routine', 'easy', 'Physical Health', 'pending', 10, 7, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(267, 58, 'Portfolio work', 'easy', 'Career / Studies', 'pending', 3, 20, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(268, 59, 'Gratitude practice', 'easy', 'Mental Wellness', 'pending', 6, 13, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(269, 59, 'Journaling', 'medium', 'Mental Wellness', 'pending', 6, 5, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(270, 60, 'Daily meditation', 'medium', 'Mental Wellness', 'pending', 10, 15, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(271, 60, 'Connection', 'medium', 'Relationships Social', 'pending', 6, 13, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(272, 60, 'Bill management', 'easy', 'Finance', 'pending', 7, 19, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(273, 60, 'Morning stretch', 'easy', 'Physical Health', 'pending', 8, 5, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(274, 61, 'Hobby practice', 'easy', 'Passion Hobbies', 'pending', 9, 11, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(275, 61, 'Creative time', 'medium', 'Passion Hobbies', 'pending', 8, 20, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(276, 61, 'Bill management', 'easy', 'Finance', 'pending', 2, 18, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(277, 62, 'Decluttering', 'easy', 'Home Environment', 'pending', 4, 13, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(278, 62, 'Saving habit', 'medium', 'Finance', 'pending', 9, 15, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(279, 62, 'Portfolio work', 'easy', 'Career / Studies', 'pending', 4, 14, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(280, 62, 'Skill building', 'medium', 'Career / Studies', 'pending', 9, 20, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(281, 63, 'Planning', 'easy', 'Personal Growth', 'pending', 10, 6, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(282, 63, 'Reading habit', 'easy', 'Mental Wellness', 'pending', 2, 15, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(283, 63, 'Drink water', 'easy', 'Physical Health', 'pending', 8, 13, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(284, 64, 'Appreciation', 'easy', 'Relationships Social', 'pending', 4, 10, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(285, 64, 'Saving habit', 'medium', 'Finance', 'pending', 3, 5, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(286, 64, 'Budget review', 'easy', 'Finance', 'pending', 10, 8, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(287, 65, 'Journaling', 'medium', 'Mental Wellness', 'pending', 7, 6, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(288, 65, 'Take vitamins', 'easy', 'Physical Health', 'pending', 6, 14, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(289, 66, 'Quality time', 'easy', 'Relationships Social', 'pending', 8, 11, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(290, 66, 'Budget review', 'medium', 'Finance', 'pending', 7, 17, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(291, 66, 'Maintenance', 'easy', 'Home Environment', 'pending', 6, 9, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(292, 66, 'Decluttering', 'easy', 'Home Environment', 'pending', 5, 15, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(293, 67, 'Bill management', 'medium', 'Finance', 'pending', 2, 6, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(294, 67, 'Meal prep', 'medium', 'Home Environment', 'pending', 2, 19, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(295, 68, 'Music practice', 'medium', 'Passion Hobbies', 'pending', 2, 14, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(296, 68, 'Quality time', 'easy', 'Relationships Social', 'pending', 2, 12, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(297, 68, 'Meal prep', 'easy', 'Home Environment', 'pending', 10, 19, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(298, 68, 'Room cleaning', 'medium', 'Home Environment', 'pending', 9, 17, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(299, 69, 'Creative time', 'easy', 'Passion Hobbies', 'pending', 2, 13, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(300, 69, 'Take vitamins', 'medium', 'Physical Health', 'pending', 2, 10, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(301, 69, 'Drink water', 'easy', 'Physical Health', 'pending', 5, 14, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(302, 69, 'Organization', 'easy', 'Home Environment', 'pending', 3, 7, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(303, 69, 'Decluttering', 'medium', 'Home Environment', 'pending', 8, 15, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(304, 70, 'Journaling', 'medium', 'Mental Wellness', 'pending', 4, 11, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(305, 70, 'Saving habit', 'medium', 'Finance', 'pending', 5, 5, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(306, 70, 'Planning', 'easy', 'Personal Growth', 'pending', 5, 17, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(307, 70, 'Code practice', 'easy', 'Career / Studies', 'pending', 2, 20, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(308, 70, 'Organization', 'medium', 'Home Environment', 'pending', 2, 20, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(309, 71, 'Decluttering', 'easy', 'Home Environment', 'pending', 3, 14, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(310, 71, 'Expense tracking', 'medium', 'Finance', 'pending', 2, 12, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(311, 71, 'Communication', 'easy', 'Relationships Social', 'pending', 2, 20, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(312, 71, 'Quality time', 'medium', 'Relationships Social', 'pending', 10, 8, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(313, 72, 'Take vitamins', 'easy', 'Physical Health', 'pending', 6, 7, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(314, 72, 'Appreciation', 'easy', 'Relationships Social', 'pending', 10, 11, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(315, 72, 'Budget review', 'medium', 'Finance', 'pending', 3, 12, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(316, 72, 'Bill management', 'easy', 'Finance', 'pending', 6, 17, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(317, 73, 'Skill building', 'medium', 'Career / Studies', 'pending', 9, 13, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(318, 73, 'Creative time', 'easy', 'Passion Hobbies', 'pending', 3, 10, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(319, 73, 'Exercise routine', 'easy', 'Physical Health', 'pending', 5, 15, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(320, 73, 'Daily check-in', 'medium', 'Relationships Social', 'pending', 2, 8, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(321, 73, 'Bill management', 'medium', 'Finance', 'pending', 4, 20, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(322, 74, 'Skill practice', 'easy', 'Personal Growth', 'pending', 3, 11, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(323, 74, 'Saving habit', 'easy', 'Finance', 'pending', 2, 14, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(324, 75, 'Expense tracking', 'medium', 'Finance', 'pending', 5, 8, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(325, 75, 'Daily walk', 'medium', 'Physical Health', 'pending', 3, 20, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(326, 76, 'Mindfulness', 'medium', 'Mental Wellness', 'pending', 10, 13, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(327, 76, 'Maintenance', 'easy', 'Home Environment', 'pending', 7, 18, '2025-05-27 00:35:59', '2025-05-27 00:35:59', NULL),
(328, 77, 'Music practice', 'easy', 'Passion Hobbies', 'pending', 4, 10, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(329, 77, 'Study session', 'medium', 'Career / Studies', 'pending', 4, 17, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(330, 77, 'Morning stretch', 'easy', 'Physical Health', 'pending', 6, 12, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(331, 77, 'Organization', 'medium', 'Home Environment', 'pending', 3, 15, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(332, 78, 'Journaling', 'medium', 'Mental Wellness', 'pending', 3, 12, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(333, 78, 'Bill management', 'easy', 'Finance', 'pending', 7, 9, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(334, 78, 'Fun activity', 'medium', 'Passion Hobbies', 'pending', 6, 9, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(335, 78, 'Code practice', 'easy', 'Career / Studies', 'pending', 5, 6, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(336, 78, 'Creative time', 'easy', 'Passion Hobbies', 'pending', 4, 17, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(337, 79, 'Code practice', 'easy', 'Career / Studies', 'pending', 10, 11, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(338, 79, 'Communication', 'easy', 'Relationships Social', 'pending', 6, 7, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(339, 79, 'Maintenance', 'easy', 'Home Environment', 'pending', 10, 8, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(340, 80, 'Meal prep', 'medium', 'Home Environment', 'pending', 4, 19, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(341, 80, 'Portfolio work', 'medium', 'Career / Studies', 'pending', 10, 20, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(342, 80, 'Code practice', 'easy', 'Career / Studies', 'pending', 7, 16, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(343, 81, 'Drink water', 'medium', 'Physical Health', 'pending', 9, 13, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(344, 81, 'Gratitude practice', 'medium', 'Mental Wellness', 'pending', 5, 10, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(345, 82, 'Organization', 'medium', 'Home Environment', 'pending', 4, 9, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(346, 82, 'Take vitamins', 'easy', 'Physical Health', 'pending', 5, 16, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(347, 82, 'Saving habit', 'easy', 'Finance', 'pending', 4, 18, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(348, 82, 'Financial learning', 'medium', 'Finance', 'pending', 3, 5, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(349, 83, 'Connection', 'easy', 'Relationships Social', 'pending', 3, 6, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(350, 83, 'Connection', 'easy', 'Relationships Social', 'pending', 4, 7, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(351, 83, 'Organization', 'medium', 'Home Environment', 'pending', 7, 10, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(352, 84, 'Bill management', 'medium', 'Finance', 'pending', 8, 5, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(353, 84, 'Daily learning', 'medium', 'Personal Growth', 'pending', 6, 10, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(354, 84, 'Exercise routine', 'medium', 'Physical Health', 'pending', 9, 5, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(355, 85, 'Journaling', 'medium', 'Mental Wellness', 'pending', 3, 7, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(356, 85, 'Take vitamins', 'easy', 'Physical Health', 'pending', 9, 11, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(357, 86, 'Room cleaning', 'medium', 'Home Environment', 'pending', 6, 10, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(358, 86, 'Daily walk', 'easy', 'Physical Health', 'pending', 3, 18, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(359, 86, 'Daily walk', 'easy', 'Physical Health', 'pending', 2, 10, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(360, 86, 'Daily check-in', 'easy', 'Relationships Social', 'pending', 7, 19, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(361, 87, 'Daily meditation', 'easy', 'Mental Wellness', 'pending', 6, 8, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(362, 87, 'Creative time', 'easy', 'Passion Hobbies', 'pending', 5, 17, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(363, 87, 'Learning', 'medium', 'Career / Studies', 'pending', 9, 7, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(364, 87, 'Daily check-in', 'medium', 'Relationships Social', 'pending', 3, 16, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(365, 87, 'Study session', 'easy', 'Career / Studies', 'pending', 3, 19, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(366, 88, 'Daily learning', 'easy', 'Personal Growth', 'pending', 8, 15, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(367, 88, 'Meal prep', 'medium', 'Home Environment', 'pending', 8, 6, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(368, 89, 'Connection', 'medium', 'Relationships Social', 'pending', 9, 13, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(369, 89, 'Connection', 'easy', 'Relationships Social', 'pending', 8, 19, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(370, 89, 'Code practice', 'easy', 'Career / Studies', 'pending', 4, 17, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(371, 89, 'Daily walk', 'medium', 'Physical Health', 'pending', 8, 17, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(372, 89, 'Mindfulness', 'easy', 'Mental Wellness', 'pending', 2, 17, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(373, 90, 'Mindfulness', 'medium', 'Mental Wellness', 'pending', 2, 14, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(374, 90, 'Take vitamins', 'easy', 'Physical Health', 'pending', 10, 13, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(375, 90, 'Quality time', 'easy', 'Relationships Social', 'pending', 10, 18, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(376, 90, 'Study session', 'medium', 'Career / Studies', 'pending', 7, 5, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(377, 90, 'Maintenance', 'medium', 'Home Environment', 'pending', 6, 16, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(378, 91, 'Saving habit', 'medium', 'Finance', 'pending', 8, 13, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(379, 91, 'Meal prep', 'medium', 'Home Environment', 'pending', 5, 6, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(380, 91, 'Quality time', 'easy', 'Relationships Social', 'pending', 8, 7, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(381, 91, 'Art creation', 'medium', 'Passion Hobbies', 'pending', 6, 20, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(382, 92, 'Connection', 'medium', 'Relationships Social', 'pending', 2, 5, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(383, 92, 'Music practice', 'easy', 'Passion Hobbies', 'pending', 2, 16, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(384, 92, 'Organization', 'easy', 'Home Environment', 'pending', 2, 7, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(385, 92, 'Saving habit', 'easy', 'Finance', 'pending', 2, 9, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(386, 93, 'Self reflection', 'medium', 'Personal Growth', 'pending', 10, 5, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(387, 93, 'Connection', 'medium', 'Relationships Social', 'pending', 4, 18, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(388, 93, 'Connection', 'medium', 'Relationships Social', 'pending', 6, 12, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(389, 93, 'Learning', 'easy', 'Career / Studies', 'pending', 8, 17, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(390, 94, 'Goal setting', 'medium', 'Personal Growth', 'pending', 4, 20, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(391, 94, 'Meal prep', 'easy', 'Home Environment', 'pending', 7, 12, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(392, 94, 'Reading habit', 'medium', 'Mental Wellness', 'pending', 10, 12, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(393, 94, 'Quality time', 'easy', 'Relationships Social', 'pending', 5, 5, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(394, 94, 'Self reflection', 'easy', 'Personal Growth', 'pending', 4, 11, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(395, 95, 'Creative time', 'easy', 'Passion Hobbies', 'pending', 5, 16, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(396, 95, 'Planning', 'easy', 'Personal Growth', 'pending', 5, 7, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(397, 95, 'Daily check-in', 'easy', 'Relationships Social', 'pending', 6, 12, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(398, 95, 'Planning', 'easy', 'Personal Growth', 'pending', 7, 8, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(399, 96, 'Budget review', 'easy', 'Finance', 'pending', 9, 14, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(400, 96, 'Decluttering', 'easy', 'Home Environment', 'pending', 3, 12, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(401, 96, 'Reading habit', 'medium', 'Mental Wellness', 'pending', 7, 11, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(402, 96, 'Quality time', 'medium', 'Relationships Social', 'pending', 7, 12, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(403, 96, 'Skill practice', 'medium', 'Personal Growth', 'pending', 3, 5, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(404, 97, 'Budget review', 'medium', 'Finance', 'pending', 5, 7, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(405, 97, 'Daily meditation', 'medium', 'Mental Wellness', 'pending', 8, 7, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(406, 97, 'Hobby practice', 'medium', 'Passion Hobbies', 'pending', 3, 12, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(407, 98, 'Quality time', 'easy', 'Relationships Social', 'pending', 4, 8, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(408, 98, 'Creative time', 'easy', 'Passion Hobbies', 'pending', 10, 6, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(409, 99, 'Daily meditation', 'medium', 'Mental Wellness', 'pending', 9, 12, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL);
INSERT INTO `goodhabits` (`id`, `user_id`, `title`, `difficulty`, `category`, `status`, `coins`, `xp`, `created_at`, `updated_at`, `deleted_at`) VALUES
(410, 99, 'Morning stretch', 'medium', 'Physical Health', 'pending', 2, 17, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(411, 100, 'Morning stretch', 'easy', 'Physical Health', 'pending', 8, 16, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL),
(412, 100, 'Hobby practice', 'medium', 'Passion Hobbies', 'pending', 6, 20, '2025-05-27 00:36:00', '2025-05-27 00:36:00', NULL);

--
-- Triggers `goodhabits`
--
DELIMITER $$
CREATE TRIGGER `after_good_habits_completion` AFTER UPDATE ON `goodhabits` FOR EACH ROW BEGIN 
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
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `item_categories`
--

CREATE TABLE `item_categories` (
  `category_id` int NOT NULL,
  `category_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `category_description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `icon` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `item_categories`
--

INSERT INTO `item_categories` (`category_id`, `category_name`, `category_description`, `icon`) VALUES
(1, 'Consumables', 'Items that can be consumed for temporary benefits', 'fa-flask'),
(2, 'Equipment', 'Permanent items that enhance character abilities', 'fa-shield'),
(3, 'Collectibles', 'Special items for collection and display', 'fa-gem'),
(4, 'Boosts', 'Temporary enhancement items', 'fa-bolt');

-- --------------------------------------------------------

--
-- Table structure for table `item_usage_history`
--

CREATE TABLE `item_usage_history` (
  `usage_id` int NOT NULL,
  `inventory_id` int DEFAULT NULL,
  `used_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `effect_applied` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `item_usage_history`
--

INSERT INTO `item_usage_history` (`usage_id`, `inventory_id`, `used_at`, `effect_applied`) VALUES
(2, 52, '2025-05-28 02:51:43', 'Applied health effect');

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `journals`
--

INSERT INTO `journals` (`id`, `user_id`, `title`, `content`, `date`, `created_at`, `updated_at`) VALUES
(3, 1, 'What moment made me smile today?', 'Today I reflected on: What moment made me smile today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-11', '2025-05-27 00:33:32', '2025-05-27 00:33:32'),
(4, 1, 'What inspired me today?', 'Today I reflected on: What inspired me today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-14', '2025-05-27 00:33:32', '2025-05-27 00:33:32'),
(5, 1, 'What creative activity did I do?', 'Today I reflected on: What creative activity did I do?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-02', '2025-05-27 00:33:32', '2025-05-27 00:33:32'),
(6, 1, 'What inspired me today?', 'Today I reflected on: What inspired me today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-07', '2025-05-27 00:33:32', '2025-05-27 00:33:32'),
(7, 1, 'How did I contribute to my community?', 'Today I reflected on: How did I contribute to my community?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-12', '2025-05-27 00:33:32', '2025-05-27 00:33:32'),
(8, 2, 'What new perspective did I gain today?', 'Today I reflected on: What new perspective did I gain today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-06', '2025-05-27 00:33:32', '2025-05-27 00:33:32'),
(9, 2, 'How did I contribute to my community?', 'Today I reflected on: How did I contribute to my community?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-23', '2025-05-27 00:33:32', '2025-05-27 00:33:32'),
(10, 2, 'What positive impact did I make today?', 'Today I reflected on: What positive impact did I make today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-19', '2025-05-27 00:33:32', '2025-05-27 00:33:32'),
(11, 2, 'How did I practice mindfulness today?', 'Today I reflected on: How did I practice mindfulness today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-22', '2025-05-27 00:33:32', '2025-05-27 00:33:32'),
(12, 2, 'What goal am I working towards?', 'Today I reflected on: What goal am I working towards?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-01', '2025-05-27 00:33:32', '2025-05-27 00:33:32'),
(13, 3, 'What creative activity did I do?', 'Today I reflected on: What creative activity did I do?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-15', '2025-05-27 00:33:32', '2025-05-27 00:33:32'),
(14, 3, 'What book or article influenced me?', 'Today I reflected on: What book or article influenced me?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-19', '2025-05-27 00:33:32', '2025-05-27 00:33:32'),
(15, 3, 'What moment made me smile today?', 'Today I reflected on: What moment made me smile today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-03', '2025-05-27 00:33:32', '2025-05-27 00:33:32'),
(16, 3, 'What book or article influenced me?', 'Today I reflected on: What book or article influenced me?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-30', '2025-05-27 00:33:32', '2025-05-27 00:33:32'),
(17, 4, 'How did I manage stress today?', 'Today I reflected on: How did I manage stress today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-12', '2025-05-27 00:33:32', '2025-05-27 00:33:32'),
(18, 4, 'What relationships did I nurture today?', 'Today I reflected on: What relationships did I nurture today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-09', '2025-05-27 00:33:32', '2025-05-27 00:33:32'),
(19, 5, 'What positive impact did I make today?', 'Today I reflected on: What positive impact did I make today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-12', '2025-05-27 00:33:32', '2025-05-27 00:33:32'),
(20, 5, 'How did I practice mindfulness today?', 'Today I reflected on: How did I practice mindfulness today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-05', '2025-05-27 00:33:32', '2025-05-27 00:33:32'),
(21, 5, 'What creative activity did I do?', 'Today I reflected on: What creative activity did I do?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-10', '2025-05-27 00:33:32', '2025-05-27 00:33:32'),
(22, 5, 'How did I step out of my comfort zone?', 'Today I reflected on: How did I step out of my comfort zone?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-20', '2025-05-27 00:33:32', '2025-05-27 00:33:32'),
(23, 5, 'What did I learn about myself today?', 'Today I reflected on: What did I learn about myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-23', '2025-05-27 00:33:32', '2025-05-27 00:33:32'),
(24, 1, 'What inspired me today?', 'Today I reflected on: What inspired me today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-01', '2025-05-27 00:33:58', '2025-05-27 00:33:58'),
(25, 1, 'How did I contribute to my community?', 'Today I reflected on: How did I contribute to my community?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-28', '2025-05-27 00:33:58', '2025-05-27 00:33:58'),
(26, 1, 'What moment made me smile today?', 'Today I reflected on: What moment made me smile today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-09', '2025-05-27 00:33:58', '2025-05-27 00:33:58'),
(27, 1, 'What positive impact did I make today?', 'Today I reflected on: What positive impact did I make today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-12', '2025-05-27 00:33:58', '2025-05-27 00:33:58'),
(28, 1, 'How did I take care of myself today?', 'Today I reflected on: How did I take care of myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-05', '2025-05-27 00:33:58', '2025-05-27 00:33:58'),
(29, 2, 'What creative activity did I do?', 'Today I reflected on: What creative activity did I do?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-27', '2025-05-27 00:33:58', '2025-05-27 00:33:58'),
(30, 2, 'How did I contribute to my community?', 'Today I reflected on: How did I contribute to my community?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-12', '2025-05-27 00:33:58', '2025-05-27 00:33:58'),
(31, 2, 'How did I grow as a person today?', 'Today I reflected on: How did I grow as a person today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-16', '2025-05-27 00:33:58', '2025-05-27 00:33:58'),
(32, 2, 'What goal am I working towards?', 'Today I reflected on: What goal am I working towards?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-07', '2025-05-27 00:33:58', '2025-05-27 00:33:58'),
(33, 2, 'How did I manage stress today?', 'Today I reflected on: How did I manage stress today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-03', '2025-05-27 00:33:58', '2025-05-27 00:33:58'),
(34, 3, 'What moment made me smile today?', 'Today I reflected on: What moment made me smile today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-26', '2025-05-27 00:33:58', '2025-05-27 00:33:58'),
(35, 3, 'What new perspective did I gain today?', 'Today I reflected on: What new perspective did I gain today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-17', '2025-05-27 00:33:58', '2025-05-27 00:33:58'),
(36, 3, 'What relationships did I nurture today?', 'Today I reflected on: What relationships did I nurture today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-08', '2025-05-27 00:33:58', '2025-05-27 00:33:58'),
(37, 4, 'What are three things I\'m grateful for today?', 'Today I reflected on: What are three things I\'m grateful for today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-03', '2025-05-27 00:33:58', '2025-05-27 00:33:58'),
(38, 4, 'How did I manage stress today?', 'Today I reflected on: How did I manage stress today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-21', '2025-05-27 00:33:58', '2025-05-27 00:33:58'),
(39, 4, 'What did I learn about myself today?', 'Today I reflected on: What did I learn about myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-06', '2025-05-27 00:33:58', '2025-05-27 00:33:58'),
(40, 5, 'What are three things I\'m grateful for today?', 'Today I reflected on: What are three things I\'m grateful for today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-18', '2025-05-27 00:33:58', '2025-05-27 00:33:58'),
(41, 1, 'What book or article influenced me?', 'Today I reflected on: What book or article influenced me?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-28', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(42, 1, 'What inspired me today?', 'Today I reflected on: What inspired me today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-18', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(43, 1, 'What skill did I practice today?', 'Today I reflected on: What skill did I practice today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-18', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(44, 1, 'What inspired me today?', 'Today I reflected on: What inspired me today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-05', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(45, 1, 'What positive impact did I make today?', 'Today I reflected on: What positive impact did I make today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-22', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(46, 2, 'How did I take care of myself today?', 'Today I reflected on: How did I take care of myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-14', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(47, 3, 'What skill did I practice today?', 'Today I reflected on: What skill did I practice today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-25', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(48, 3, 'What did I learn about myself today?', 'Today I reflected on: What did I learn about myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-11', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(49, 3, 'What did I learn about myself today?', 'Today I reflected on: What did I learn about myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-19', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(50, 4, 'How did I take care of myself today?', 'Today I reflected on: How did I take care of myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-01', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(51, 4, 'What book or article influenced me?', 'Today I reflected on: What book or article influenced me?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-21', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(52, 4, 'What creative activity did I do?', 'Today I reflected on: What creative activity did I do?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-07', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(53, 4, 'How did I take care of myself today?', 'Today I reflected on: How did I take care of myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-26', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(54, 5, 'What creative activity did I do?', 'Today I reflected on: What creative activity did I do?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-15', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(55, 5, 'What healthy choice did I make?', 'Today I reflected on: What healthy choice did I make?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-30', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(56, 5, 'What book or article influenced me?', 'Today I reflected on: What book or article influenced me?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-19', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(57, 6, 'What new perspective did I gain today?', 'Today I reflected on: What new perspective did I gain today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-23', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(58, 6, 'How did I take care of myself today?', 'Today I reflected on: How did I take care of myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-02', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(59, 6, 'What relationships did I nurture today?', 'Today I reflected on: What relationships did I nurture today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-16', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(60, 7, 'What did I learn about myself today?', 'Today I reflected on: What did I learn about myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-17', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(61, 7, 'What did I learn about myself today?', 'Today I reflected on: What did I learn about myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-11', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(62, 7, 'What healthy choice did I make?', 'Today I reflected on: What healthy choice did I make?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-19', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(63, 8, 'What did I learn about myself today?', 'Today I reflected on: What did I learn about myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-18', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(64, 9, 'What inspired me today?', 'Today I reflected on: What inspired me today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-03', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(65, 9, 'What healthy choice did I make?', 'Today I reflected on: What healthy choice did I make?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-09', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(66, 9, 'What positive habit did I maintain?', 'Today I reflected on: What positive habit did I maintain?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-04', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(67, 9, 'How did I practice mindfulness today?', 'Today I reflected on: How did I practice mindfulness today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-25', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(68, 10, 'What challenge did I overcome today?', 'Today I reflected on: What challenge did I overcome today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-09', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(69, 10, 'How did I contribute to my community?', 'Today I reflected on: How did I contribute to my community?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-30', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(70, 1, 'What healthy choice did I make?', 'Today I reflected on: What healthy choice did I make?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-26', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(71, 1, 'What healthy choice did I make?', 'Today I reflected on: What healthy choice did I make?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-24', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(72, 1, 'How did I practice mindfulness today?', 'Today I reflected on: How did I practice mindfulness today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-29', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(73, 2, 'What relationships did I nurture today?', 'Today I reflected on: What relationships did I nurture today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-15', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(74, 2, 'What skill did I practice today?', 'Today I reflected on: What skill did I practice today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-02', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(75, 2, 'How did I take care of myself today?', 'Today I reflected on: How did I take care of myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-23', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(76, 2, 'What book or article influenced me?', 'Today I reflected on: What book or article influenced me?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-13', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(77, 2, 'What moment made me smile today?', 'Today I reflected on: What moment made me smile today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-07', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(78, 3, 'How did I take care of myself today?', 'Today I reflected on: How did I take care of myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-26', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(79, 3, 'What creative activity did I do?', 'Today I reflected on: What creative activity did I do?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-17', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(80, 4, 'What skill did I practice today?', 'Today I reflected on: What skill did I practice today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-14', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(81, 4, 'How did I practice mindfulness today?', 'Today I reflected on: How did I practice mindfulness today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-20', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(82, 4, 'What skill did I practice today?', 'Today I reflected on: What skill did I practice today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-18', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(83, 5, 'What new perspective did I gain today?', 'Today I reflected on: What new perspective did I gain today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-26', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(84, 5, 'What skill did I practice today?', 'Today I reflected on: What skill did I practice today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-16', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(85, 6, 'What moment made me smile today?', 'Today I reflected on: What moment made me smile today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-02', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(86, 6, 'What healthy choice did I make?', 'Today I reflected on: What healthy choice did I make?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-08', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(87, 6, 'What challenge did I overcome today?', 'Today I reflected on: What challenge did I overcome today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-06', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(88, 7, 'What positive habit did I maintain?', 'Today I reflected on: What positive habit did I maintain?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-20', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(89, 8, 'How did I take care of myself today?', 'Today I reflected on: How did I take care of myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-24', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(90, 8, 'What creative activity did I do?', 'Today I reflected on: What creative activity did I do?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-27', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(91, 8, 'What challenge did I overcome today?', 'Today I reflected on: What challenge did I overcome today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-30', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(92, 8, 'What book or article influenced me?', 'Today I reflected on: What book or article influenced me?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-02', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(93, 8, 'What goal am I working towards?', 'Today I reflected on: What goal am I working towards?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-10', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(94, 9, 'How did I grow as a person today?', 'Today I reflected on: How did I grow as a person today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-03', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(95, 9, 'What goal am I working towards?', 'Today I reflected on: What goal am I working towards?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-19', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(96, 10, 'How did I take care of myself today?', 'Today I reflected on: How did I take care of myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-24', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(97, 10, 'How did I contribute to my community?', 'Today I reflected on: How did I contribute to my community?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-17', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(98, 10, 'What moment made me smile today?', 'Today I reflected on: What moment made me smile today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-17', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(99, 10, 'What challenge did I overcome today?', 'Today I reflected on: What challenge did I overcome today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-22', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(100, 11, 'How did I contribute to my community?', 'Today I reflected on: How did I contribute to my community?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-09', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(101, 12, 'What creative activity did I do?', 'Today I reflected on: What creative activity did I do?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-03', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(102, 12, 'What positive impact did I make today?', 'Today I reflected on: What positive impact did I make today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-20', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(103, 12, 'What book or article influenced me?', 'Today I reflected on: What book or article influenced me?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-26', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(104, 13, 'How did I manage stress today?', 'Today I reflected on: How did I manage stress today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-27', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(105, 14, 'What inspired me today?', 'Today I reflected on: What inspired me today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-01', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(106, 14, 'What new perspective did I gain today?', 'Today I reflected on: What new perspective did I gain today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-04', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(107, 14, 'What positive impact did I make today?', 'Today I reflected on: What positive impact did I make today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-24', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(108, 14, 'What new perspective did I gain today?', 'Today I reflected on: What new perspective did I gain today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-19', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(109, 15, 'What challenge did I overcome today?', 'Today I reflected on: What challenge did I overcome today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-07', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(110, 15, 'What are three things I\'m grateful for today?', 'Today I reflected on: What are three things I\'m grateful for today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-08', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(111, 15, 'What did I learn about myself today?', 'Today I reflected on: What did I learn about myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-28', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(112, 15, 'How did I contribute to my community?', 'Today I reflected on: How did I contribute to my community?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-10', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(113, 15, 'What new perspective did I gain today?', 'Today I reflected on: What new perspective did I gain today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-08', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(114, 16, 'What new perspective did I gain today?', 'Today I reflected on: What new perspective did I gain today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-23', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(115, 17, 'What challenge did I overcome today?', 'Today I reflected on: What challenge did I overcome today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-16', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(116, 18, 'What positive habit did I maintain?', 'Today I reflected on: What positive habit did I maintain?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-24', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(117, 18, 'What inspired me today?', 'Today I reflected on: What inspired me today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-11', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(118, 18, 'What healthy choice did I make?', 'Today I reflected on: What healthy choice did I make?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-22', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(119, 18, 'How did I contribute to my community?', 'Today I reflected on: How did I contribute to my community?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-29', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(120, 18, 'How did I grow as a person today?', 'Today I reflected on: How did I grow as a person today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-28', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(121, 19, 'How did I manage stress today?', 'Today I reflected on: How did I manage stress today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-18', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(122, 19, 'How did I manage stress today?', 'Today I reflected on: How did I manage stress today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-26', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(123, 20, 'How did I contribute to my community?', 'Today I reflected on: How did I contribute to my community?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-10', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(124, 20, 'What moment made me smile today?', 'Today I reflected on: What moment made me smile today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-10', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(125, 20, 'What skill did I practice today?', 'Today I reflected on: What skill did I practice today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-14', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(126, 20, 'What inspired me today?', 'Today I reflected on: What inspired me today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-08', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(127, 20, 'What goal am I working towards?', 'Today I reflected on: What goal am I working towards?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-08', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(128, 21, 'What creative activity did I do?', 'Today I reflected on: What creative activity did I do?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-24', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(129, 21, 'How did I practice mindfulness today?', 'Today I reflected on: How did I practice mindfulness today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-14', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(130, 21, 'What new perspective did I gain today?', 'Today I reflected on: What new perspective did I gain today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-08', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(131, 21, 'What book or article influenced me?', 'Today I reflected on: What book or article influenced me?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-22', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(132, 22, 'What goal am I working towards?', 'Today I reflected on: What goal am I working towards?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-17', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(133, 22, 'What did I learn about myself today?', 'Today I reflected on: What did I learn about myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-15', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(134, 22, 'What creative activity did I do?', 'Today I reflected on: What creative activity did I do?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-11', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(135, 23, 'What challenge did I overcome today?', 'Today I reflected on: What challenge did I overcome today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-30', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(136, 24, 'What book or article influenced me?', 'Today I reflected on: What book or article influenced me?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-26', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(137, 24, 'What relationships did I nurture today?', 'Today I reflected on: What relationships did I nurture today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-26', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(138, 25, 'What positive impact did I make today?', 'Today I reflected on: What positive impact did I make today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-23', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(139, 25, 'What skill did I practice today?', 'Today I reflected on: What skill did I practice today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-26', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(140, 25, 'What book or article influenced me?', 'Today I reflected on: What book or article influenced me?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-11', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(141, 25, 'What book or article influenced me?', 'Today I reflected on: What book or article influenced me?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-10', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(142, 25, 'What book or article influenced me?', 'Today I reflected on: What book or article influenced me?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-03', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(143, 26, 'What goal am I working towards?', 'Today I reflected on: What goal am I working towards?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-13', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(144, 26, 'What moment made me smile today?', 'Today I reflected on: What moment made me smile today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-07', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(145, 27, 'How did I step out of my comfort zone?', 'Today I reflected on: How did I step out of my comfort zone?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-05', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(146, 28, 'What are three things I\'m grateful for today?', 'Today I reflected on: What are three things I\'m grateful for today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-20', '2025-05-27 00:35:58', '2025-05-27 00:35:58');
INSERT INTO `journals` (`id`, `user_id`, `title`, `content`, `date`, `created_at`, `updated_at`) VALUES
(147, 28, 'How did I practice mindfulness today?', 'Today I reflected on: How did I practice mindfulness today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-03', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(148, 28, 'What relationships did I nurture today?', 'Today I reflected on: What relationships did I nurture today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-28', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(149, 29, 'What skill did I practice today?', 'Today I reflected on: What skill did I practice today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-26', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(150, 29, 'What challenge did I overcome today?', 'Today I reflected on: What challenge did I overcome today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-30', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(151, 30, 'What creative activity did I do?', 'Today I reflected on: What creative activity did I do?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-29', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(152, 30, 'What goal am I working towards?', 'Today I reflected on: What goal am I working towards?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-03', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(153, 31, 'What goal am I working towards?', 'Today I reflected on: What goal am I working towards?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-10', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(154, 32, 'How did I manage stress today?', 'Today I reflected on: How did I manage stress today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-27', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(155, 32, 'What positive habit did I maintain?', 'Today I reflected on: What positive habit did I maintain?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-10', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(156, 32, 'What new perspective did I gain today?', 'Today I reflected on: What new perspective did I gain today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-06', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(157, 33, 'What skill did I practice today?', 'Today I reflected on: What skill did I practice today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-24', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(158, 33, 'How did I practice mindfulness today?', 'Today I reflected on: How did I practice mindfulness today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-11', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(159, 33, 'What skill did I practice today?', 'Today I reflected on: What skill did I practice today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-21', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(160, 34, 'What new perspective did I gain today?', 'Today I reflected on: What new perspective did I gain today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-02', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(161, 34, 'What positive habit did I maintain?', 'Today I reflected on: What positive habit did I maintain?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-07', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(162, 34, 'What new perspective did I gain today?', 'Today I reflected on: What new perspective did I gain today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-13', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(163, 34, 'What book or article influenced me?', 'Today I reflected on: What book or article influenced me?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-25', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(164, 34, 'What new perspective did I gain today?', 'Today I reflected on: What new perspective did I gain today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-24', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(165, 35, 'What relationships did I nurture today?', 'Today I reflected on: What relationships did I nurture today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-25', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(166, 35, 'What inspired me today?', 'Today I reflected on: What inspired me today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-29', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(167, 35, 'What moment made me smile today?', 'Today I reflected on: What moment made me smile today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-23', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(168, 35, 'How did I contribute to my community?', 'Today I reflected on: How did I contribute to my community?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-15', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(169, 36, 'How did I grow as a person today?', 'Today I reflected on: How did I grow as a person today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-09', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(170, 36, 'What goal am I working towards?', 'Today I reflected on: What goal am I working towards?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-08', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(171, 36, 'How did I manage stress today?', 'Today I reflected on: How did I manage stress today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-19', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(172, 37, 'How did I contribute to my community?', 'Today I reflected on: How did I contribute to my community?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-05', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(173, 37, 'What creative activity did I do?', 'Today I reflected on: What creative activity did I do?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-18', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(174, 38, 'What challenge did I overcome today?', 'Today I reflected on: What challenge did I overcome today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-30', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(175, 39, 'What are three things I\'m grateful for today?', 'Today I reflected on: What are three things I\'m grateful for today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-05', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(176, 40, 'What inspired me today?', 'Today I reflected on: What inspired me today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-10', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(177, 40, 'What skill did I practice today?', 'Today I reflected on: What skill did I practice today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-06', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(178, 40, 'How did I grow as a person today?', 'Today I reflected on: How did I grow as a person today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-27', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(179, 40, 'How did I step out of my comfort zone?', 'Today I reflected on: How did I step out of my comfort zone?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-04', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(180, 41, 'What moment made me smile today?', 'Today I reflected on: What moment made me smile today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-10', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(181, 41, 'What moment made me smile today?', 'Today I reflected on: What moment made me smile today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-24', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(182, 41, 'What are three things I\'m grateful for today?', 'Today I reflected on: What are three things I\'m grateful for today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-25', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(183, 41, 'What challenge did I overcome today?', 'Today I reflected on: What challenge did I overcome today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-25', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(184, 42, 'What goal am I working towards?', 'Today I reflected on: What goal am I working towards?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-24', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(185, 42, 'How did I contribute to my community?', 'Today I reflected on: How did I contribute to my community?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-03', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(186, 42, 'What goal am I working towards?', 'Today I reflected on: What goal am I working towards?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-15', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(187, 42, 'What inspired me today?', 'Today I reflected on: What inspired me today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-04', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(188, 42, 'What positive habit did I maintain?', 'Today I reflected on: What positive habit did I maintain?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-01', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(189, 43, 'What positive impact did I make today?', 'Today I reflected on: What positive impact did I make today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-07', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(190, 43, 'What goal am I working towards?', 'Today I reflected on: What goal am I working towards?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-26', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(191, 43, 'What challenge did I overcome today?', 'Today I reflected on: What challenge did I overcome today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-09', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(192, 43, 'What skill did I practice today?', 'Today I reflected on: What skill did I practice today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-09', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(193, 43, 'What goal am I working towards?', 'Today I reflected on: What goal am I working towards?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-30', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(194, 44, 'How did I practice mindfulness today?', 'Today I reflected on: How did I practice mindfulness today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-29', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(195, 44, 'What inspired me today?', 'Today I reflected on: What inspired me today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-25', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(196, 44, 'What positive habit did I maintain?', 'Today I reflected on: What positive habit did I maintain?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-05', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(197, 45, 'How did I contribute to my community?', 'Today I reflected on: How did I contribute to my community?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-13', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(198, 45, 'What did I learn about myself today?', 'Today I reflected on: What did I learn about myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-25', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(199, 45, 'What new perspective did I gain today?', 'Today I reflected on: What new perspective did I gain today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-10', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(200, 45, 'What challenge did I overcome today?', 'Today I reflected on: What challenge did I overcome today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-03', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(201, 46, 'What moment made me smile today?', 'Today I reflected on: What moment made me smile today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-02', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(202, 46, 'What positive habit did I maintain?', 'Today I reflected on: What positive habit did I maintain?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-24', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(203, 47, 'What positive impact did I make today?', 'Today I reflected on: What positive impact did I make today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-20', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(204, 47, 'What goal am I working towards?', 'Today I reflected on: What goal am I working towards?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-04', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(205, 47, 'What are three things I\'m grateful for today?', 'Today I reflected on: What are three things I\'m grateful for today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-15', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(206, 47, 'What goal am I working towards?', 'Today I reflected on: What goal am I working towards?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-09', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(207, 48, 'What goal am I working towards?', 'Today I reflected on: What goal am I working towards?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-28', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(208, 49, 'What goal am I working towards?', 'Today I reflected on: What goal am I working towards?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-14', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(209, 49, 'How did I practice mindfulness today?', 'Today I reflected on: How did I practice mindfulness today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-03', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(210, 50, 'What book or article influenced me?', 'Today I reflected on: What book or article influenced me?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-25', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(211, 50, 'What positive habit did I maintain?', 'Today I reflected on: What positive habit did I maintain?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-23', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(212, 50, 'How did I practice mindfulness today?', 'Today I reflected on: How did I practice mindfulness today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-13', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(213, 50, 'What book or article influenced me?', 'Today I reflected on: What book or article influenced me?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-08', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(214, 50, 'What skill did I practice today?', 'Today I reflected on: What skill did I practice today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-13', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(215, 51, 'What positive impact did I make today?', 'Today I reflected on: What positive impact did I make today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-25', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(216, 51, 'How did I practice mindfulness today?', 'Today I reflected on: How did I practice mindfulness today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-10', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(217, 51, 'What positive impact did I make today?', 'Today I reflected on: What positive impact did I make today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-10', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(218, 51, 'What did I learn about myself today?', 'Today I reflected on: What did I learn about myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-22', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(219, 52, 'How did I practice mindfulness today?', 'Today I reflected on: How did I practice mindfulness today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-16', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(220, 52, 'What healthy choice did I make?', 'Today I reflected on: What healthy choice did I make?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-02', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(221, 52, 'What book or article influenced me?', 'Today I reflected on: What book or article influenced me?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-15', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(222, 53, 'How did I contribute to my community?', 'Today I reflected on: How did I contribute to my community?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-12', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(223, 53, 'How did I take care of myself today?', 'Today I reflected on: How did I take care of myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-29', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(224, 54, 'How did I contribute to my community?', 'Today I reflected on: How did I contribute to my community?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-16', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(225, 54, 'How did I practice mindfulness today?', 'Today I reflected on: How did I practice mindfulness today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-01', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(226, 55, 'What goal am I working towards?', 'Today I reflected on: What goal am I working towards?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-02', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(227, 55, 'What are three things I\'m grateful for today?', 'Today I reflected on: What are three things I\'m grateful for today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-15', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(228, 55, 'What inspired me today?', 'Today I reflected on: What inspired me today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-11', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(229, 55, 'What relationships did I nurture today?', 'Today I reflected on: What relationships did I nurture today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-16', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(230, 55, 'What are three things I\'m grateful for today?', 'Today I reflected on: What are three things I\'m grateful for today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-12', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(231, 56, 'What positive impact did I make today?', 'Today I reflected on: What positive impact did I make today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-22', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(232, 56, 'How did I grow as a person today?', 'Today I reflected on: How did I grow as a person today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-05', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(233, 56, 'How did I manage stress today?', 'Today I reflected on: How did I manage stress today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-17', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(234, 56, 'What positive habit did I maintain?', 'Today I reflected on: What positive habit did I maintain?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-18', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(235, 57, 'How did I step out of my comfort zone?', 'Today I reflected on: How did I step out of my comfort zone?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-07', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(236, 57, 'How did I step out of my comfort zone?', 'Today I reflected on: How did I step out of my comfort zone?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-09', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(237, 57, 'How did I step out of my comfort zone?', 'Today I reflected on: How did I step out of my comfort zone?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-13', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(238, 57, 'How did I grow as a person today?', 'Today I reflected on: How did I grow as a person today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-21', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(239, 57, 'How did I contribute to my community?', 'Today I reflected on: How did I contribute to my community?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-02', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(240, 58, 'What relationships did I nurture today?', 'Today I reflected on: What relationships did I nurture today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-27', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(241, 59, 'What book or article influenced me?', 'Today I reflected on: What book or article influenced me?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-09', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(242, 59, 'What positive impact did I make today?', 'Today I reflected on: What positive impact did I make today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-16', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(243, 59, 'What goal am I working towards?', 'Today I reflected on: What goal am I working towards?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-22', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(244, 59, 'What are three things I\'m grateful for today?', 'Today I reflected on: What are three things I\'m grateful for today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-07', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(245, 59, 'How did I manage stress today?', 'Today I reflected on: How did I manage stress today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-08', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(246, 60, 'What goal am I working towards?', 'Today I reflected on: What goal am I working towards?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-26', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(247, 61, 'What positive habit did I maintain?', 'Today I reflected on: What positive habit did I maintain?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-02', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(248, 61, 'How did I take care of myself today?', 'Today I reflected on: How did I take care of myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-06', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(249, 61, 'How did I take care of myself today?', 'Today I reflected on: How did I take care of myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-20', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(250, 61, 'What creative activity did I do?', 'Today I reflected on: What creative activity did I do?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-03', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(251, 62, 'What did I learn about myself today?', 'Today I reflected on: What did I learn about myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-18', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(252, 62, 'What inspired me today?', 'Today I reflected on: What inspired me today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-27', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(253, 62, 'What relationships did I nurture today?', 'Today I reflected on: What relationships did I nurture today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-03', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(254, 62, 'What are three things I\'m grateful for today?', 'Today I reflected on: What are three things I\'m grateful for today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-04', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(255, 62, 'What challenge did I overcome today?', 'Today I reflected on: What challenge did I overcome today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-29', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(256, 63, 'What inspired me today?', 'Today I reflected on: What inspired me today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-14', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(257, 63, 'How did I manage stress today?', 'Today I reflected on: How did I manage stress today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-29', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(258, 63, 'What did I learn about myself today?', 'Today I reflected on: What did I learn about myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-22', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(259, 64, 'How did I practice mindfulness today?', 'Today I reflected on: How did I practice mindfulness today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-02', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(260, 64, 'How did I contribute to my community?', 'Today I reflected on: How did I contribute to my community?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-01', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(261, 65, 'What positive habit did I maintain?', 'Today I reflected on: What positive habit did I maintain?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-15', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(262, 65, 'What book or article influenced me?', 'Today I reflected on: What book or article influenced me?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-27', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(263, 66, 'What healthy choice did I make?', 'Today I reflected on: What healthy choice did I make?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-25', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(264, 66, 'How did I manage stress today?', 'Today I reflected on: How did I manage stress today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-01', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(265, 67, 'What book or article influenced me?', 'Today I reflected on: What book or article influenced me?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-16', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(266, 68, 'How did I practice mindfulness today?', 'Today I reflected on: How did I practice mindfulness today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-23', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(267, 68, 'What challenge did I overcome today?', 'Today I reflected on: What challenge did I overcome today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-30', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(268, 68, 'What are three things I\'m grateful for today?', 'Today I reflected on: What are three things I\'m grateful for today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-17', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(269, 68, 'How did I practice mindfulness today?', 'Today I reflected on: How did I practice mindfulness today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-15', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(270, 68, 'What new perspective did I gain today?', 'Today I reflected on: What new perspective did I gain today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-15', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(271, 69, 'How did I manage stress today?', 'Today I reflected on: How did I manage stress today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-05', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(272, 69, 'What creative activity did I do?', 'Today I reflected on: What creative activity did I do?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-11', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(273, 69, 'What goal am I working towards?', 'Today I reflected on: What goal am I working towards?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-27', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(274, 70, 'How did I practice mindfulness today?', 'Today I reflected on: How did I practice mindfulness today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-12', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(275, 71, 'How did I take care of myself today?', 'Today I reflected on: How did I take care of myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-27', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(276, 71, 'What challenge did I overcome today?', 'Today I reflected on: What challenge did I overcome today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-16', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(277, 71, 'What new perspective did I gain today?', 'Today I reflected on: What new perspective did I gain today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-15', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(278, 72, 'What book or article influenced me?', 'Today I reflected on: What book or article influenced me?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-14', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(279, 72, 'What did I learn about myself today?', 'Today I reflected on: What did I learn about myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-07', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(280, 72, 'What positive impact did I make today?', 'Today I reflected on: What positive impact did I make today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-16', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(281, 72, 'What healthy choice did I make?', 'Today I reflected on: What healthy choice did I make?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-02', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(282, 72, 'What inspired me today?', 'Today I reflected on: What inspired me today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-25', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(283, 73, 'How did I manage stress today?', 'Today I reflected on: How did I manage stress today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-26', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(284, 73, 'What skill did I practice today?', 'Today I reflected on: What skill did I practice today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-25', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(285, 73, 'What relationships did I nurture today?', 'Today I reflected on: What relationships did I nurture today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-27', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(286, 73, 'What positive impact did I make today?', 'Today I reflected on: What positive impact did I make today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-03', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(287, 73, 'What did I learn about myself today?', 'Today I reflected on: What did I learn about myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-24', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(288, 74, 'What relationships did I nurture today?', 'Today I reflected on: What relationships did I nurture today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-27', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(289, 74, 'What relationships did I nurture today?', 'Today I reflected on: What relationships did I nurture today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-10', '2025-05-27 00:35:59', '2025-05-27 00:35:59');
INSERT INTO `journals` (`id`, `user_id`, `title`, `content`, `date`, `created_at`, `updated_at`) VALUES
(290, 74, 'What did I learn about myself today?', 'Today I reflected on: What did I learn about myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-30', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(291, 74, 'What challenge did I overcome today?', 'Today I reflected on: What challenge did I overcome today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-29', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(292, 75, 'What book or article influenced me?', 'Today I reflected on: What book or article influenced me?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-13', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(293, 75, 'What are three things I\'m grateful for today?', 'Today I reflected on: What are three things I\'m grateful for today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-30', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(294, 75, 'How did I contribute to my community?', 'Today I reflected on: How did I contribute to my community?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-11', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(295, 75, 'How did I practice mindfulness today?', 'Today I reflected on: How did I practice mindfulness today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-22', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(296, 76, 'What new perspective did I gain today?', 'Today I reflected on: What new perspective did I gain today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-27', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(297, 76, 'What positive impact did I make today?', 'Today I reflected on: What positive impact did I make today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-20', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(298, 76, 'How did I step out of my comfort zone?', 'Today I reflected on: How did I step out of my comfort zone?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-27', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(299, 76, 'How did I step out of my comfort zone?', 'Today I reflected on: How did I step out of my comfort zone?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-16', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(300, 76, 'What challenge did I overcome today?', 'Today I reflected on: What challenge did I overcome today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-22', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(301, 77, 'What healthy choice did I make?', 'Today I reflected on: What healthy choice did I make?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-09', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(302, 77, 'What moment made me smile today?', 'Today I reflected on: What moment made me smile today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-29', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(303, 77, 'What challenge did I overcome today?', 'Today I reflected on: What challenge did I overcome today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-16', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(304, 78, 'What new perspective did I gain today?', 'Today I reflected on: What new perspective did I gain today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-26', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(305, 79, 'What skill did I practice today?', 'Today I reflected on: What skill did I practice today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-22', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(306, 80, 'What challenge did I overcome today?', 'Today I reflected on: What challenge did I overcome today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-16', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(307, 80, 'How did I contribute to my community?', 'Today I reflected on: How did I contribute to my community?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-14', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(308, 80, 'How did I grow as a person today?', 'Today I reflected on: How did I grow as a person today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-11', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(309, 80, 'How did I grow as a person today?', 'Today I reflected on: How did I grow as a person today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-07', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(310, 81, 'What are three things I\'m grateful for today?', 'Today I reflected on: What are three things I\'m grateful for today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-17', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(311, 81, 'What skill did I practice today?', 'Today I reflected on: What skill did I practice today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-24', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(312, 82, 'How did I practice mindfulness today?', 'Today I reflected on: How did I practice mindfulness today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-11', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(313, 83, 'What relationships did I nurture today?', 'Today I reflected on: What relationships did I nurture today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-18', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(314, 84, 'What inspired me today?', 'Today I reflected on: What inspired me today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-20', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(315, 85, 'What healthy choice did I make?', 'Today I reflected on: What healthy choice did I make?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-11', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(316, 85, 'How did I practice mindfulness today?', 'Today I reflected on: How did I practice mindfulness today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-26', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(317, 85, 'What positive habit did I maintain?', 'Today I reflected on: What positive habit did I maintain?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-12', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(318, 85, 'What book or article influenced me?', 'Today I reflected on: What book or article influenced me?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-21', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(319, 85, 'What positive impact did I make today?', 'Today I reflected on: What positive impact did I make today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-21', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(320, 86, 'What are three things I\'m grateful for today?', 'Today I reflected on: What are three things I\'m grateful for today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-20', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(321, 86, 'What positive impact did I make today?', 'Today I reflected on: What positive impact did I make today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-18', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(322, 86, 'What creative activity did I do?', 'Today I reflected on: What creative activity did I do?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-10', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(323, 86, 'What are three things I\'m grateful for today?', 'Today I reflected on: What are three things I\'m grateful for today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-06', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(324, 86, 'How did I manage stress today?', 'Today I reflected on: How did I manage stress today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-08', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(325, 87, 'What new perspective did I gain today?', 'Today I reflected on: What new perspective did I gain today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-15', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(326, 87, 'What positive impact did I make today?', 'Today I reflected on: What positive impact did I make today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-03', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(327, 87, 'What challenge did I overcome today?', 'Today I reflected on: What challenge did I overcome today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-19', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(328, 88, 'What new perspective did I gain today?', 'Today I reflected on: What new perspective did I gain today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-20', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(329, 89, 'What new perspective did I gain today?', 'Today I reflected on: What new perspective did I gain today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-27', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(330, 90, 'How did I step out of my comfort zone?', 'Today I reflected on: How did I step out of my comfort zone?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-07', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(331, 90, 'How did I manage stress today?', 'Today I reflected on: How did I manage stress today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-28', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(332, 91, 'What creative activity did I do?', 'Today I reflected on: What creative activity did I do?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-12', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(333, 92, 'How did I practice mindfulness today?', 'Today I reflected on: How did I practice mindfulness today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-02', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(334, 92, 'How did I practice mindfulness today?', 'Today I reflected on: How did I practice mindfulness today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-06', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(335, 92, 'What book or article influenced me?', 'Today I reflected on: What book or article influenced me?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-18', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(336, 92, 'What healthy choice did I make?', 'Today I reflected on: What healthy choice did I make?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-18', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(337, 92, 'What healthy choice did I make?', 'Today I reflected on: What healthy choice did I make?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-17', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(338, 93, 'How did I grow as a person today?', 'Today I reflected on: How did I grow as a person today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-16', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(339, 93, 'What relationships did I nurture today?', 'Today I reflected on: What relationships did I nurture today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-20', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(340, 93, 'What challenge did I overcome today?', 'Today I reflected on: What challenge did I overcome today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-03', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(341, 93, 'What skill did I practice today?', 'Today I reflected on: What skill did I practice today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-06', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(342, 94, 'What healthy choice did I make?', 'Today I reflected on: What healthy choice did I make?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-25', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(343, 94, 'How did I manage stress today?', 'Today I reflected on: How did I manage stress today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-01', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(344, 94, 'What book or article influenced me?', 'Today I reflected on: What book or article influenced me?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-14', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(345, 95, 'What positive impact did I make today?', 'Today I reflected on: What positive impact did I make today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-16', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(346, 95, 'How did I step out of my comfort zone?', 'Today I reflected on: How did I step out of my comfort zone?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-30', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(347, 95, 'What inspired me today?', 'Today I reflected on: What inspired me today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-16', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(348, 95, 'How did I manage stress today?', 'Today I reflected on: How did I manage stress today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-23', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(349, 95, 'How did I step out of my comfort zone?', 'Today I reflected on: How did I step out of my comfort zone?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-28', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(350, 96, 'What inspired me today?', 'Today I reflected on: What inspired me today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-21', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(351, 96, 'What skill did I practice today?', 'Today I reflected on: What skill did I practice today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-23', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(352, 97, 'How did I contribute to my community?', 'Today I reflected on: How did I contribute to my community?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-18', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(353, 98, 'How did I take care of myself today?', 'Today I reflected on: How did I take care of myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-17', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(354, 99, 'What book or article influenced me?', 'Today I reflected on: What book or article influenced me?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-09', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(355, 99, 'How did I take care of myself today?', 'Today I reflected on: How did I take care of myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-20', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(356, 100, 'What healthy choice did I make?', 'Today I reflected on: What healthy choice did I make?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-25', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(357, 100, 'What are three things I\'m grateful for today?', 'Today I reflected on: What are three things I\'m grateful for today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-08', '2025-05-27 00:36:00', '2025-05-27 00:36:00');

-- --------------------------------------------------------

--
-- Table structure for table `marketplace_items`
--

CREATE TABLE `marketplace_items` (
  `item_id` int NOT NULL,
  `item_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `item_description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `item_price` decimal(10,2) NOT NULL,
  `image_url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `category_id` int DEFAULT NULL,
  `item_type` enum('consumable','equipment','collectible','boost') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'collectible',
  `effect_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `effect_value` int DEFAULT NULL,
  `durability` int DEFAULT NULL,
  `cooldown_period` int DEFAULT NULL,
  `status` enum('available','disabled') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'available'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `marketplace_items`
--

INSERT INTO `marketplace_items` (`item_id`, `item_name`, `item_description`, `item_price`, `image_url`, `category_id`, `item_type`, `effect_type`, `effect_value`, `durability`, `cooldown_period`, `status`) VALUES
(1, 'Health Potion', 'Restores 25 health points', 10.00, 'assets/images/items/health_potion.png', 1, 'consumable', 'health', 25, NULL, NULL, 'available'),
(2, 'XP Booster', 'Increases XP gain by 50% for 24 hours', 50.00, 'assets/images/items/xp_booster.png', 4, 'boost', 'xp', 50, NULL, 86400, 'available'),
(3, 'Focus Crystal', 'Increases productivity boost by 25% for 24 hours', 75.00, 'assets/images/items/focus_crystal.png', 4, 'boost', 'productivity', 25, NULL, 86400, 'available'),
(4, 'Golden Trophy', 'A prestigious trophy for your collection', 100.00, 'assets/images/items/golden_trophy.png', 3, 'collectible', NULL, NULL, NULL, NULL, 'available');

-- --------------------------------------------------------

--
-- Table structure for table `migrations`
--

CREATE TABLE `migrations` (
  `id` int NOT NULL,
  `migration` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `executed_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `migrations`
--

INSERT INTO `migrations` (`id`, `migration`, `executed_at`) VALUES
(1, '001_create_users_table', '2025-05-26 23:43:19'),
(2, '002_create_avatars_table', '2025-05-26 23:43:19'),
(3, '003_create_userstats_table', '2025-05-26 23:43:19'),
(4, '004_create_activity_log_table', '2025-05-26 23:43:19'),
(5, '005_create_tasks_table', '2025-05-26 23:43:19'),
(6, '006_create_dailytasks_table', '2025-05-26 23:43:19'),
(7, '007_create_goodhabits_table', '2025-05-26 23:43:19'),
(8, '008_create_badhabits_table', '2025-05-26 23:43:19'),
(9, '009_create_streaks_table', '2025-05-26 23:43:20'),
(10, '010_create_journals_table', '2025-05-26 23:43:20'),
(11, '011_create_item_categories_table', '2025-05-26 23:43:20'),
(12, '012_create_marketplace_items_table', '2025-05-26 23:43:20'),
(13, '013_create_user_inventory_table', '2025-05-26 23:43:20'),
(14, '014_create_item_usage_history_table', '2025-05-26 23:43:20'),
(15, '015_create_user_active_boosts_table', '2025-05-26 23:43:20'),
(16, '016_create_user_event_table', '2025-05-26 23:43:20'),
(17, '017_create_user_event_completions_table', '2025-05-26 23:43:20'),
(18, '018_create_test_data_table', '2025-05-26 23:43:20'),
(19, '019_insert_default_avatars', '2025-05-26 23:43:20'),
(20, '020_insert_default_item_categories', '2025-05-26 23:43:20'),
(21, '021_insert_default_marketplace_items', '2025-05-26 23:43:20'),
(22, '022_create_triggers', '2025-05-26 23:43:27'),
(23, '023_create_inventory_triggers', '2025-05-26 23:43:28'),
(24, '024_create_procedures_part1', '2025-05-26 23:53:31'),
(25, '025_create_use_inventory_procedure', '2025-05-26 23:55:28'),
(26, '026_add_userstats_unique_constraint', '2025-05-26 23:55:28'),
(27, '027_generate_test_data', '2025-05-26 23:58:42'),
(28, '028_create_views_part1', '2025-05-26 23:58:42'),
(29, '029_create_views_part2', '2025-05-26 23:58:42'),
(30, '030_create_views_part3', '2025-05-26 23:58:43');

-- --------------------------------------------------------

--
-- Table structure for table `streaks`
--

CREATE TABLE `streaks` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `streak_type` enum('check_in','task_completion','dailtask_completion','GoodHabits_completion','journal_writing') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `current_streak` int NOT NULL DEFAULT '0',
  `longest_streak` int NOT NULL DEFAULT '0',
  `last_streak_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `next_expected_date` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `streaks`
--

INSERT INTO `streaks` (`id`, `user_id`, `streak_type`, `current_streak`, `longest_streak`, `last_streak_date`, `next_expected_date`) VALUES
(1, 1, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(2, 1, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(3, 1, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(4, 1, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(5, 1, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(6, 2, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(7, 2, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(8, 2, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(9, 2, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(10, 2, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(11, 3, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(12, 3, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(13, 3, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(14, 3, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(15, 3, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(16, 4, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(17, 4, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(18, 4, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(19, 4, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(20, 4, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(21, 5, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(22, 5, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(23, 5, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(24, 5, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(25, 5, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(26, 6, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(27, 6, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(28, 6, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(29, 6, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(30, 6, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(31, 7, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(32, 7, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(33, 7, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(34, 7, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(35, 7, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(36, 8, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(37, 8, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(38, 8, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(39, 8, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(40, 8, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(41, 9, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(42, 9, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(43, 9, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(44, 9, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(45, 9, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(46, 10, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(47, 10, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(48, 10, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(49, 10, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(50, 10, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(51, 11, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(52, 11, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(53, 11, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(54, 11, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(55, 11, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(56, 12, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(57, 12, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(58, 12, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(59, 12, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(60, 12, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(61, 13, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(62, 13, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(63, 13, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(64, 13, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(65, 13, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(66, 14, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(67, 14, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(68, 14, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(69, 14, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(70, 14, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(71, 15, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(72, 15, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(73, 15, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(74, 15, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(75, 15, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(76, 16, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(77, 16, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(78, 16, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(79, 16, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(80, 16, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(81, 17, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(82, 17, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(83, 17, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(84, 17, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(85, 17, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(86, 18, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(87, 18, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(88, 18, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(89, 18, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(90, 18, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(91, 19, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(92, 19, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(93, 19, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(94, 19, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(95, 19, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(96, 20, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(97, 20, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(98, 20, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(99, 20, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(100, 20, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(101, 21, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(102, 21, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(103, 21, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(104, 21, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(105, 21, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(106, 22, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(107, 22, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(108, 22, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(109, 22, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(110, 22, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(111, 23, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(112, 23, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(113, 23, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(114, 23, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(115, 23, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(116, 24, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(117, 24, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(118, 24, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(119, 24, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(120, 24, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(121, 25, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(122, 25, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(123, 25, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(124, 25, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(125, 25, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(126, 26, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(127, 26, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(128, 26, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(129, 26, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(130, 26, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(131, 27, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(132, 27, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(133, 27, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(134, 27, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(135, 27, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(136, 28, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(137, 28, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(138, 28, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(139, 28, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(140, 28, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(141, 29, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(142, 29, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(143, 29, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(144, 29, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(145, 29, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(146, 30, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(147, 30, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(148, 30, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(149, 30, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(150, 30, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(151, 31, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(152, 31, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(153, 31, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(154, 31, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(155, 31, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(156, 32, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(157, 32, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(158, 32, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(159, 32, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(160, 32, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(161, 33, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(162, 33, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(163, 33, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(164, 33, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(165, 33, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(166, 34, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(167, 34, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(168, 34, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(169, 34, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(170, 34, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(171, 35, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(172, 35, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(173, 35, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(174, 35, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(175, 35, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(176, 36, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(177, 36, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(178, 36, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(179, 36, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(180, 36, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(181, 37, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(182, 37, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(183, 37, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(184, 37, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(185, 37, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(186, 38, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(187, 38, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(188, 38, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(189, 38, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(190, 38, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(191, 39, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(192, 39, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(193, 39, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(194, 39, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(195, 39, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(196, 40, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(197, 40, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(198, 40, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(199, 40, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(200, 40, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(201, 41, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(202, 41, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(203, 41, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(204, 41, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(205, 41, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(206, 42, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(207, 42, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(208, 42, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(209, 42, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(210, 42, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(211, 43, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(212, 43, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(213, 43, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(214, 43, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(215, 43, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(216, 44, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(217, 44, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(218, 44, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(219, 44, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(220, 44, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(221, 45, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(222, 45, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(223, 45, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(224, 45, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(225, 45, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(226, 46, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(227, 46, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(228, 46, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(229, 46, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(230, 46, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(231, 47, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(232, 47, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(233, 47, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(234, 47, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(235, 47, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(236, 48, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(237, 48, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(238, 48, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(239, 48, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(240, 48, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(241, 49, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(242, 49, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(243, 49, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(244, 49, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(245, 49, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(246, 50, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(247, 50, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(248, 50, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(249, 50, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(250, 50, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(251, 51, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(252, 51, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(253, 51, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(254, 51, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(255, 51, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(256, 52, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(257, 52, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(258, 52, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(259, 52, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(260, 52, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(261, 53, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(262, 53, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(263, 53, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(264, 53, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(265, 53, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(266, 54, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(267, 54, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(268, 54, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(269, 54, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(270, 54, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(271, 55, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(272, 55, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(273, 55, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(274, 55, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(275, 55, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(276, 56, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(277, 56, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(278, 56, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(279, 56, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(280, 56, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(281, 57, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(282, 57, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(283, 57, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(284, 57, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(285, 57, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(286, 58, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(287, 58, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(288, 58, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(289, 58, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(290, 58, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(291, 59, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(292, 59, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(293, 59, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(294, 59, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(295, 59, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(296, 60, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(297, 60, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(298, 60, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(299, 60, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(300, 60, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(301, 61, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(302, 61, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(303, 61, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(304, 61, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(305, 61, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(306, 62, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(307, 62, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(308, 62, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(309, 62, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(310, 62, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(311, 63, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(312, 63, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(313, 63, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(314, 63, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(315, 63, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(316, 64, 'check_in', 0, 0, '2025-05-27 00:03:14', NULL),
(317, 64, 'task_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(318, 64, 'dailtask_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(319, 64, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:14', NULL),
(320, 64, 'journal_writing', 0, 0, '2025-05-27 00:03:14', NULL),
(321, 65, 'check_in', 0, 0, '2025-05-27 00:03:15', NULL),
(322, 65, 'task_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(323, 65, 'dailtask_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(324, 65, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(325, 65, 'journal_writing', 0, 0, '2025-05-27 00:03:15', NULL),
(326, 66, 'check_in', 0, 0, '2025-05-27 00:03:15', NULL),
(327, 66, 'task_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(328, 66, 'dailtask_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(329, 66, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(330, 66, 'journal_writing', 0, 0, '2025-05-27 00:03:15', NULL),
(331, 67, 'check_in', 0, 0, '2025-05-27 00:03:15', NULL),
(332, 67, 'task_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(333, 67, 'dailtask_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(334, 67, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(335, 67, 'journal_writing', 0, 0, '2025-05-27 00:03:15', NULL),
(336, 68, 'check_in', 0, 0, '2025-05-27 00:03:15', NULL),
(337, 68, 'task_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(338, 68, 'dailtask_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(339, 68, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(340, 68, 'journal_writing', 0, 0, '2025-05-27 00:03:15', NULL),
(341, 69, 'check_in', 0, 0, '2025-05-27 00:03:15', NULL),
(342, 69, 'task_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(343, 69, 'dailtask_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(344, 69, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(345, 69, 'journal_writing', 0, 0, '2025-05-27 00:03:15', NULL),
(346, 70, 'check_in', 0, 0, '2025-05-27 00:03:15', NULL),
(347, 70, 'task_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(348, 70, 'dailtask_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(349, 70, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(350, 70, 'journal_writing', 0, 0, '2025-05-27 00:03:15', NULL),
(351, 71, 'check_in', 0, 0, '2025-05-27 00:03:15', NULL),
(352, 71, 'task_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(353, 71, 'dailtask_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(354, 71, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(355, 71, 'journal_writing', 0, 0, '2025-05-27 00:03:15', NULL),
(356, 72, 'check_in', 0, 0, '2025-05-27 00:03:15', NULL),
(357, 72, 'task_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(358, 72, 'dailtask_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(359, 72, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(360, 72, 'journal_writing', 0, 0, '2025-05-27 00:03:15', NULL),
(361, 73, 'check_in', 0, 0, '2025-05-27 00:03:15', NULL),
(362, 73, 'task_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(363, 73, 'dailtask_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(364, 73, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(365, 73, 'journal_writing', 0, 0, '2025-05-27 00:03:15', NULL),
(366, 74, 'check_in', 0, 0, '2025-05-27 00:03:15', NULL),
(367, 74, 'task_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(368, 74, 'dailtask_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(369, 74, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(370, 74, 'journal_writing', 0, 0, '2025-05-27 00:03:15', NULL),
(371, 75, 'check_in', 0, 0, '2025-05-27 00:03:15', NULL),
(372, 75, 'task_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(373, 75, 'dailtask_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(374, 75, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(375, 75, 'journal_writing', 0, 0, '2025-05-27 00:03:15', NULL),
(376, 76, 'check_in', 0, 0, '2025-05-27 00:03:15', NULL),
(377, 76, 'task_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(378, 76, 'dailtask_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(379, 76, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(380, 76, 'journal_writing', 0, 0, '2025-05-27 00:03:15', NULL),
(381, 77, 'check_in', 0, 0, '2025-05-27 00:03:15', NULL),
(382, 77, 'task_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(383, 77, 'dailtask_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(384, 77, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(385, 77, 'journal_writing', 0, 0, '2025-05-27 00:03:15', NULL),
(386, 78, 'check_in', 0, 0, '2025-05-27 00:03:15', NULL),
(387, 78, 'task_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(388, 78, 'dailtask_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(389, 78, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(390, 78, 'journal_writing', 0, 0, '2025-05-27 00:03:15', NULL),
(391, 79, 'check_in', 0, 0, '2025-05-27 00:03:15', NULL),
(392, 79, 'task_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(393, 79, 'dailtask_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(394, 79, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(395, 79, 'journal_writing', 0, 0, '2025-05-27 00:03:15', NULL),
(396, 80, 'check_in', 0, 0, '2025-05-27 00:03:15', NULL),
(397, 80, 'task_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(398, 80, 'dailtask_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(399, 80, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(400, 80, 'journal_writing', 0, 0, '2025-05-27 00:03:15', NULL),
(401, 81, 'check_in', 0, 0, '2025-05-27 00:03:15', NULL),
(402, 81, 'task_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(403, 81, 'dailtask_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(404, 81, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(405, 81, 'journal_writing', 0, 0, '2025-05-27 00:03:15', NULL),
(406, 82, 'check_in', 0, 0, '2025-05-27 00:03:15', NULL),
(407, 82, 'task_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(408, 82, 'dailtask_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(409, 82, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(410, 82, 'journal_writing', 0, 0, '2025-05-27 00:03:15', NULL),
(411, 83, 'check_in', 0, 0, '2025-05-27 00:03:15', NULL),
(412, 83, 'task_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(413, 83, 'dailtask_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(414, 83, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(415, 83, 'journal_writing', 0, 0, '2025-05-27 00:03:15', NULL),
(416, 84, 'check_in', 0, 0, '2025-05-27 00:03:15', NULL),
(417, 84, 'task_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(418, 84, 'dailtask_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(419, 84, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(420, 84, 'journal_writing', 0, 0, '2025-05-27 00:03:15', NULL),
(421, 85, 'check_in', 0, 0, '2025-05-27 00:03:15', NULL),
(422, 85, 'task_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(423, 85, 'dailtask_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(424, 85, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(425, 85, 'journal_writing', 0, 0, '2025-05-27 00:03:15', NULL),
(426, 86, 'check_in', 0, 0, '2025-05-27 00:03:15', NULL),
(427, 86, 'task_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(428, 86, 'dailtask_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(429, 86, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(430, 86, 'journal_writing', 0, 0, '2025-05-27 00:03:15', NULL),
(431, 87, 'check_in', 0, 0, '2025-05-27 00:03:15', NULL),
(432, 87, 'task_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(433, 87, 'dailtask_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(434, 87, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(435, 87, 'journal_writing', 0, 0, '2025-05-27 00:03:15', NULL),
(436, 88, 'check_in', 0, 0, '2025-05-27 00:03:15', NULL),
(437, 88, 'task_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(438, 88, 'dailtask_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(439, 88, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(440, 88, 'journal_writing', 0, 0, '2025-05-27 00:03:15', NULL),
(441, 89, 'check_in', 0, 0, '2025-05-27 00:03:15', NULL),
(442, 89, 'task_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(443, 89, 'dailtask_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(444, 89, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(445, 89, 'journal_writing', 0, 0, '2025-05-27 00:03:15', NULL),
(446, 90, 'check_in', 0, 0, '2025-05-27 00:03:15', NULL),
(447, 90, 'task_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(448, 90, 'dailtask_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(449, 90, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(450, 90, 'journal_writing', 0, 0, '2025-05-27 00:03:15', NULL),
(451, 91, 'check_in', 0, 0, '2025-05-27 00:03:15', NULL),
(452, 91, 'task_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(453, 91, 'dailtask_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(454, 91, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(455, 91, 'journal_writing', 0, 0, '2025-05-27 00:03:15', NULL),
(456, 92, 'check_in', 0, 0, '2025-05-27 00:03:15', NULL),
(457, 92, 'task_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(458, 92, 'dailtask_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(459, 92, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(460, 92, 'journal_writing', 0, 0, '2025-05-27 00:03:15', NULL),
(461, 93, 'check_in', 0, 0, '2025-05-27 00:03:15', NULL),
(462, 93, 'task_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(463, 93, 'dailtask_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(464, 93, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(465, 93, 'journal_writing', 0, 0, '2025-05-27 00:03:15', NULL),
(466, 94, 'check_in', 0, 0, '2025-05-27 00:03:15', NULL),
(467, 94, 'task_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(468, 94, 'dailtask_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(469, 94, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(470, 94, 'journal_writing', 0, 0, '2025-05-27 00:03:15', NULL),
(471, 95, 'check_in', 0, 0, '2025-05-27 00:03:15', NULL),
(472, 95, 'task_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(473, 95, 'dailtask_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(474, 95, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(475, 95, 'journal_writing', 0, 0, '2025-05-27 00:03:15', NULL),
(476, 96, 'check_in', 0, 0, '2025-05-27 00:03:15', NULL),
(477, 96, 'task_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(478, 96, 'dailtask_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(479, 96, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(480, 96, 'journal_writing', 0, 0, '2025-05-27 00:03:15', NULL),
(481, 97, 'check_in', 0, 0, '2025-05-27 00:03:15', NULL),
(482, 97, 'task_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(483, 97, 'dailtask_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(484, 97, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(485, 97, 'journal_writing', 0, 0, '2025-05-27 00:03:15', NULL),
(486, 98, 'check_in', 0, 0, '2025-05-27 00:03:15', NULL),
(487, 98, 'task_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(488, 98, 'dailtask_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(489, 98, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(490, 98, 'journal_writing', 0, 0, '2025-05-27 00:03:15', NULL),
(491, 99, 'check_in', 0, 0, '2025-05-27 00:03:15', NULL),
(492, 99, 'task_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(493, 99, 'dailtask_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(494, 99, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(495, 99, 'journal_writing', 0, 0, '2025-05-27 00:03:15', NULL),
(496, 100, 'check_in', 0, 0, '2025-05-27 00:03:15', NULL),
(497, 100, 'task_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(498, 100, 'dailtask_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(499, 100, 'GoodHabits_completion', 0, 0, '2025-05-27 00:03:15', NULL),
(500, 100, 'journal_writing', 0, 0, '2025-05-27 00:03:15', NULL),
(501, 101, 'check_in', 0, 0, '2025-05-27 00:38:31', NULL),
(502, 101, 'task_completion', 0, 0, '2025-05-27 00:38:31', NULL),
(503, 101, 'dailtask_completion', 0, 0, '2025-05-27 00:38:31', NULL),
(504, 101, 'GoodHabits_completion', 0, 0, '2025-05-27 00:38:31', NULL),
(505, 101, 'journal_writing', 0, 0, '2025-05-27 00:38:31', NULL),
(506, 102, 'check_in', 1, 1, '2025-05-28 02:49:36', NULL),
(507, 102, 'task_completion', 1, 1, '2025-05-28 02:51:27', NULL),
(508, 102, 'dailtask_completion', 0, 0, '2025-05-27 00:42:02', NULL),
(509, 102, 'GoodHabits_completion', 0, 0, '2025-05-27 00:42:02', NULL),
(510, 102, 'journal_writing', 0, 0, '2025-05-27 00:42:02', NULL);

-- --------------------------------------------------------

--
-- Stand-in structure for view `streaks_view`
-- (See below for the actual view)
--
CREATE TABLE `streaks_view` (
`id` int
,`user_id` int
,`streak_type` enum('check_in','task_completion','dailtask_completion','GoodHabits_completion','journal_writing')
,`current_streak` int
,`longest_streak` int
,`last_streak_date` timestamp
,`last_activity_date` timestamp
,`next_expected_date` date
);

-- --------------------------------------------------------

--
-- Table structure for table `tasks`
--

CREATE TABLE `tasks` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` enum('pending','completed') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `difficulty` enum('easy','medium','hard') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'easy',
  `category` enum('Physical Health','Mental Wellness','Personal Growth','Career / Studies','Finance','Home Environment','Relationships Social','Passion Hobbies') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `coins` int DEFAULT '0',
  `xp` int DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `tasks`
--

INSERT INTO `tasks` (`id`, `user_id`, `title`, `status`, `difficulty`, `category`, `coins`, `xp`) VALUES
(10, 1, 'Take online course', 'pending', 'easy', 'Career / Studies', 14, 17),
(11, 1, 'Practice active listening', 'pending', 'hard', 'Relationships Social', 5, 35),
(12, 1, 'Save money', 'pending', 'medium', 'Finance', 18, 13),
(13, 1, 'Make bed', 'pending', 'easy', 'Home Environment', 12, 25),
(14, 1, 'Cut unnecessary expenses', 'completed', 'easy', 'Finance', 11, 49),
(15, 1, 'Plan future goals', 'pending', 'easy', 'Personal Growth', 22, 26),
(16, 1, 'Resolve conflicts', 'pending', 'easy', 'Relationships Social', 16, 42),
(17, 2, 'Learn something new', 'pending', 'hard', 'Personal Growth', 10, 20),
(18, 2, 'Set daily goals', 'pending', 'hard', 'Personal Growth', 13, 42),
(19, 2, 'Research investments', 'completed', 'hard', 'Finance', 8, 48),
(20, 2, 'Go for a 30-minute walk', 'pending', 'hard', 'Physical Health', 25, 35),
(21, 2, 'Cook new recipe', 'pending', 'easy', 'Passion Hobbies', 18, 23),
(22, 2, 'Learn about finances', 'pending', 'medium', 'Finance', 19, 10),
(23, 2, 'Learn something new', 'pending', 'easy', 'Personal Growth', 22, 24),
(24, 2, 'Network with professionals', 'completed', 'easy', 'Career / Studies', 11, 41),
(25, 3, 'Take vitamins', 'completed', 'easy', 'Physical Health', 6, 21),
(26, 3, 'Do laundry', 'pending', 'easy', 'Home Environment', 14, 42),
(27, 3, 'Garden for 30 minutes', 'pending', 'hard', 'Passion Hobbies', 12, 42),
(28, 4, 'Practice interview skills', 'pending', 'easy', 'Career / Studies', 14, 20),
(29, 4, 'Reflect on progress', 'pending', 'hard', 'Personal Growth', 18, 40),
(30, 4, 'Practice deep breathing', 'pending', 'medium', 'Mental Wellness', 20, 33),
(31, 4, 'Update resume', 'completed', 'medium', 'Career / Studies', 14, 21),
(32, 4, 'Take online course', 'pending', 'medium', 'Career / Studies', 20, 32),
(33, 4, 'Practice mindfulness', 'pending', 'medium', 'Mental Wellness', 25, 34),
(34, 5, 'Meal prep', 'pending', 'medium', 'Home Environment', 19, 14),
(35, 5, 'Organize workspace', 'completed', 'medium', 'Home Environment', 13, 32),
(36, 5, 'Go for a 30-minute walk', 'pending', 'easy', 'Physical Health', 21, 28),
(37, 5, 'Read self-help book', 'completed', 'hard', 'Personal Growth', 11, 31),
(38, 5, 'Water plants', 'completed', 'medium', 'Home Environment', 20, 32),
(39, 5, 'Declutter room', 'pending', 'easy', 'Home Environment', 14, 34),
(40, 5, 'Practice guitar', 'pending', 'hard', 'Passion Hobbies', 9, 29),
(41, 1, 'Plan social activity', 'pending', 'medium', 'Relationships Social', 22, 32),
(42, 1, 'Practice deep breathing', 'pending', 'easy', 'Mental Wellness', 5, 39),
(43, 1, 'Practice mindfulness', 'pending', 'hard', 'Mental Wellness', 15, 32),
(44, 2, 'Water plants', 'pending', 'easy', 'Home Environment', 11, 45),
(45, 2, 'Take a mental health break', 'completed', 'hard', 'Mental Wellness', 5, 44),
(46, 2, 'Do laundry', 'pending', 'easy', 'Home Environment', 20, 39),
(47, 2, 'Read self-help book', 'pending', 'hard', 'Personal Growth', 16, 18),
(48, 2, 'Practice interview skills', 'completed', 'hard', 'Career / Studies', 18, 27),
(49, 2, 'Write gratitude list', 'pending', 'medium', 'Mental Wellness', 7, 26),
(50, 3, 'Practice guitar', 'pending', 'hard', 'Passion Hobbies', 18, 23),
(51, 3, 'Do laundry', 'pending', 'hard', 'Home Environment', 25, 22),
(52, 3, 'Do cardio workout', 'pending', 'easy', 'Physical Health', 15, 30),
(53, 3, 'Set daily goals', 'pending', 'hard', 'Personal Growth', 12, 44),
(54, 3, 'Pay bills on time', 'completed', 'easy', 'Finance', 8, 12),
(55, 3, 'Meditate for 10 minutes', 'pending', 'hard', 'Mental Wellness', 15, 19),
(56, 4, 'Review financial goals', 'pending', 'medium', 'Finance', 12, 45),
(57, 4, 'Eat a healthy breakfast', 'pending', 'easy', 'Physical Health', 6, 41),
(58, 4, 'Show appreciation', 'pending', 'easy', 'Relationships Social', 14, 10),
(59, 4, 'Learn something new', 'pending', 'medium', 'Personal Growth', 5, 20),
(60, 4, 'Spend time with family', 'pending', 'medium', 'Relationships Social', 25, 15),
(61, 4, 'Listen to calming music', 'pending', 'medium', 'Mental Wellness', 12, 42),
(62, 5, 'Play board games', 'pending', 'medium', 'Passion Hobbies', 25, 39),
(63, 5, 'Do 20 push-ups', 'completed', 'easy', 'Physical Health', 10, 38),
(64, 5, 'Listen to calming music', 'pending', 'medium', 'Mental Wellness', 18, 45),
(65, 5, 'Practice coding', 'pending', 'hard', 'Career / Studies', 12, 39),
(66, 1, 'Write gratitude list', 'completed', 'hard', 'Mental Wellness', 7, 27),
(67, 1, 'Read self-help book', 'completed', 'medium', 'Personal Growth', 22, 27),
(68, 1, 'Write in journal', 'pending', 'hard', 'Passion Hobbies', 9, 21),
(69, 1, 'Track expenses', 'pending', 'easy', 'Finance', 20, 29),
(70, 2, 'Spend time with family', 'pending', 'hard', 'Relationships Social', 17, 49),
(71, 2, 'Do cardio workout', 'pending', 'medium', 'Physical Health', 19, 30),
(72, 2, 'Practice a skill', 'pending', 'easy', 'Personal Growth', 21, 12),
(73, 3, 'Practice public speaking', 'pending', 'medium', 'Personal Growth', 17, 37),
(74, 3, 'Practice deep breathing', 'pending', 'easy', 'Mental Wellness', 12, 10),
(75, 3, 'Water plants', 'pending', 'hard', 'Home Environment', 14, 45),
(76, 3, 'Practice mindfulness', 'pending', 'medium', 'Mental Wellness', 20, 28),
(77, 3, 'Learn something new', 'pending', 'medium', 'Personal Growth', 12, 34),
(78, 3, 'Spend time with family', 'pending', 'medium', 'Relationships Social', 13, 45),
(79, 3, 'Practice active listening', 'pending', 'medium', 'Relationships Social', 22, 29),
(80, 4, 'Eat a healthy breakfast', 'pending', 'medium', 'Physical Health', 14, 50),
(81, 4, 'Declutter room', 'pending', 'easy', 'Home Environment', 13, 48),
(82, 4, 'Make bed', 'pending', 'medium', 'Home Environment', 11, 21),
(83, 4, 'Organize workspace', 'completed', 'easy', 'Home Environment', 14, 20),
(84, 4, 'Network with professionals', 'pending', 'easy', 'Career / Studies', 14, 12),
(85, 4, 'Plan future goals', 'pending', 'medium', 'Personal Growth', 8, 26),
(86, 4, 'Study programming', 'pending', 'medium', 'Career / Studies', 23, 18),
(87, 5, 'Show appreciation', 'completed', 'easy', 'Relationships Social', 20, 21),
(88, 5, 'Practice active listening', 'pending', 'medium', 'Relationships Social', 14, 12),
(89, 5, 'Learn about finances', 'completed', 'medium', 'Finance', 7, 39),
(90, 5, 'Update resume', 'pending', 'hard', 'Career / Studies', 19, 28),
(91, 5, 'Plan future goals', 'pending', 'hard', 'Personal Growth', 7, 37),
(92, 5, 'Vacuum house', 'completed', 'hard', 'Home Environment', 20, 30),
(93, 5, 'Drink 8 glasses of water', 'completed', 'easy', 'Physical Health', 25, 37),
(94, 6, 'Organize workspace', 'completed', 'medium', 'Home Environment', 14, 20),
(95, 6, 'Write thank you note', 'pending', 'easy', 'Relationships Social', 23, 47),
(96, 6, 'Practice active listening', 'pending', 'hard', 'Relationships Social', 9, 43),
(97, 6, 'Work on art project', 'pending', 'hard', 'Passion Hobbies', 23, 17),
(98, 6, 'Update resume', 'completed', 'hard', 'Career / Studies', 17, 23),
(99, 6, 'Save money', 'pending', 'hard', 'Finance', 19, 13),
(100, 6, 'Learn about finances', 'pending', 'hard', 'Finance', 17, 38),
(101, 6, 'Spend time with family', 'completed', 'easy', 'Relationships Social', 19, 20),
(102, 7, 'Review budget', 'pending', 'hard', 'Finance', 19, 47),
(103, 7, 'Make bed', 'pending', 'medium', 'Home Environment', 16, 47),
(104, 7, 'Write gratitude list', 'completed', 'hard', 'Mental Wellness', 25, 38),
(105, 7, 'Cook new recipe', 'pending', 'hard', 'Passion Hobbies', 6, 44),
(106, 8, 'Go for a 30-minute walk', 'completed', 'medium', 'Physical Health', 5, 17),
(107, 8, 'Update resume', 'pending', 'hard', 'Career / Studies', 7, 25),
(108, 8, 'Cut unnecessary expenses', 'pending', 'easy', 'Finance', 17, 29),
(109, 9, 'Water plants', 'completed', 'hard', 'Home Environment', 17, 35),
(110, 9, 'Take online course', 'pending', 'easy', 'Career / Studies', 8, 49),
(111, 9, 'Practice mindfulness', 'pending', 'easy', 'Mental Wellness', 24, 23),
(112, 10, 'Study programming', 'pending', 'easy', 'Career / Studies', 17, 23),
(113, 10, 'Declutter room', 'pending', 'easy', 'Home Environment', 25, 16),
(114, 10, 'Practice coding', 'completed', 'easy', 'Career / Studies', 25, 35),
(115, 10, 'Meditate for 10 minutes', 'pending', 'medium', 'Mental Wellness', 20, 47),
(116, 10, 'Resolve conflicts', 'pending', 'hard', 'Relationships Social', 13, 23),
(117, 10, 'Work on art project', 'completed', 'hard', 'Passion Hobbies', 23, 14),
(118, 10, 'Work on art project', 'pending', 'hard', 'Passion Hobbies', 6, 44),
(119, 10, 'Review financial goals', 'pending', 'medium', 'Finance', 8, 46),
(120, 1, 'Organize workspace', 'completed', 'easy', 'Home Environment', 17, 28),
(121, 1, 'Set daily goals', 'pending', 'easy', 'Personal Growth', 17, 25),
(122, 1, 'Do cardio workout', 'pending', 'easy', 'Physical Health', 23, 50),
(123, 1, 'Stretch for 10 minutes', 'completed', 'easy', 'Physical Health', 21, 18),
(124, 2, 'Write gratitude list', 'pending', 'hard', 'Mental Wellness', 14, 26),
(125, 2, 'Learn new hobby', 'completed', 'easy', 'Passion Hobbies', 11, 10),
(126, 2, 'Pay bills on time', 'completed', 'medium', 'Finance', 15, 18),
(127, 2, 'Practice coding', 'pending', 'easy', 'Career / Studies', 9, 42),
(128, 2, 'Study programming', 'pending', 'easy', 'Career / Studies', 14, 29),
(129, 2, 'Practice active listening', 'pending', 'hard', 'Relationships Social', 18, 17),
(130, 2, 'Practice guitar', 'pending', 'medium', 'Passion Hobbies', 24, 48),
(131, 2, 'Go for a 30-minute walk', 'pending', 'medium', 'Physical Health', 19, 14),
(132, 3, 'Practice guitar', 'pending', 'hard', 'Passion Hobbies', 20, 40),
(133, 3, 'Work on art project', 'pending', 'easy', 'Passion Hobbies', 13, 35),
(134, 3, 'Play board games', 'completed', 'hard', 'Passion Hobbies', 24, 48),
(135, 3, 'Do laundry', 'pending', 'hard', 'Home Environment', 21, 32),
(136, 3, 'Learn about finances', 'pending', 'easy', 'Finance', 10, 30),
(137, 3, 'Plan social activity', 'completed', 'medium', 'Relationships Social', 19, 49),
(138, 3, 'Practice a skill', 'pending', 'easy', 'Personal Growth', 22, 14),
(139, 3, 'Study programming', 'completed', 'easy', 'Career / Studies', 15, 49),
(140, 4, 'Resolve conflicts', 'pending', 'easy', 'Relationships Social', 12, 41),
(141, 4, 'Vacuum house', 'pending', 'easy', 'Home Environment', 17, 10),
(142, 4, 'Watch educational video', 'completed', 'medium', 'Personal Growth', 10, 10),
(143, 5, 'Call a friend', 'completed', 'easy', 'Relationships Social', 24, 47),
(144, 5, 'Garden for 30 minutes', 'pending', 'medium', 'Passion Hobbies', 15, 33),
(145, 5, 'Call a friend', 'pending', 'medium', 'Relationships Social', 15, 26),
(146, 5, 'Stretch for 10 minutes', 'completed', 'hard', 'Physical Health', 24, 10),
(147, 5, 'Write thank you note', 'pending', 'hard', 'Relationships Social', 24, 28),
(148, 5, 'Play board games', 'pending', 'easy', 'Passion Hobbies', 5, 29),
(149, 6, 'Learn new hobby', 'pending', 'medium', 'Passion Hobbies', 11, 14),
(150, 6, 'Write in journal', 'pending', 'medium', 'Passion Hobbies', 25, 10),
(151, 6, 'Learn new hobby', 'pending', 'medium', 'Passion Hobbies', 6, 43),
(152, 6, 'Write thank you note', 'pending', 'medium', 'Relationships Social', 23, 38),
(153, 6, 'Spend time with family', 'pending', 'hard', 'Relationships Social', 17, 32),
(154, 6, 'Take vitamins', 'pending', 'easy', 'Physical Health', 6, 46),
(155, 6, 'Water plants', 'pending', 'hard', 'Home Environment', 5, 44),
(156, 7, 'Stretch for 10 minutes', 'pending', 'easy', 'Physical Health', 12, 46),
(157, 7, 'Do cardio workout', 'pending', 'easy', 'Physical Health', 10, 14),
(158, 7, 'Cook new recipe', 'completed', 'hard', 'Passion Hobbies', 9, 21),
(159, 8, 'Do cardio workout', 'pending', 'easy', 'Physical Health', 9, 28),
(160, 8, 'Make new connections', 'pending', 'medium', 'Relationships Social', 15, 30),
(161, 8, 'Review financial goals', 'completed', 'easy', 'Finance', 19, 27),
(162, 8, 'Declutter room', 'pending', 'medium', 'Home Environment', 14, 45),
(163, 9, 'Pay bills on time', 'pending', 'medium', 'Finance', 17, 49),
(164, 9, 'Read self-help book', 'pending', 'hard', 'Personal Growth', 10, 10),
(165, 9, 'Resolve conflicts', 'pending', 'hard', 'Relationships Social', 8, 14),
(166, 9, 'Eat a healthy breakfast', 'completed', 'easy', 'Physical Health', 21, 21),
(167, 9, 'Track expenses', 'pending', 'hard', 'Finance', 19, 29),
(168, 10, 'Reflect on progress', 'pending', 'easy', 'Personal Growth', 7, 36),
(169, 10, 'Eat a healthy breakfast', 'completed', 'hard', 'Physical Health', 5, 26),
(170, 10, 'Learn something new', 'pending', 'easy', 'Personal Growth', 9, 22),
(171, 11, 'Practice deep breathing', 'completed', 'hard', 'Mental Wellness', 13, 44),
(172, 11, 'Stretch for 10 minutes', 'pending', 'medium', 'Physical Health', 11, 35),
(173, 11, 'Reflect on progress', 'completed', 'hard', 'Personal Growth', 6, 44),
(174, 11, 'Garden for 30 minutes', 'pending', 'easy', 'Passion Hobbies', 7, 18),
(175, 11, 'Study programming', 'completed', 'medium', 'Career / Studies', 12, 43),
(176, 11, 'Meal prep', 'pending', 'medium', 'Home Environment', 18, 27),
(177, 11, 'Meal prep', 'pending', 'easy', 'Home Environment', 20, 45),
(178, 11, 'Go for a 30-minute walk', 'pending', 'medium', 'Physical Health', 12, 12),
(179, 12, 'Review financial goals', 'pending', 'hard', 'Finance', 21, 36),
(180, 12, 'Organize workspace', 'pending', 'easy', 'Home Environment', 7, 11),
(181, 12, 'Read self-help book', 'pending', 'medium', 'Personal Growth', 24, 31),
(182, 12, 'Take online course', 'completed', 'medium', 'Career / Studies', 21, 21),
(183, 12, 'Call a friend', 'pending', 'medium', 'Relationships Social', 15, 34),
(184, 12, 'Write gratitude list', 'pending', 'hard', 'Mental Wellness', 13, 35),
(185, 13, 'Network with professionals', 'completed', 'easy', 'Career / Studies', 17, 47),
(186, 13, 'Meditate for 10 minutes', 'pending', 'easy', 'Mental Wellness', 23, 23),
(187, 13, 'Network with professionals', 'pending', 'easy', 'Career / Studies', 23, 19),
(188, 14, 'Resolve conflicts', 'completed', 'hard', 'Relationships Social', 17, 32),
(189, 14, 'Stretch for 10 minutes', 'pending', 'easy', 'Physical Health', 15, 13),
(190, 14, 'Resolve conflicts', 'pending', 'medium', 'Relationships Social', 11, 29),
(191, 15, 'Write in journal', 'completed', 'hard', 'Passion Hobbies', 21, 36),
(192, 15, 'Review budget', 'completed', 'medium', 'Finance', 11, 39),
(193, 15, 'Meal prep', 'pending', 'hard', 'Home Environment', 18, 14),
(194, 15, 'Practice interview skills', 'completed', 'easy', 'Career / Studies', 23, 36),
(195, 16, 'Water plants', 'pending', 'hard', 'Home Environment', 7, 47),
(196, 16, 'Make bed', 'pending', 'medium', 'Home Environment', 11, 25),
(197, 16, 'Pay bills on time', 'pending', 'medium', 'Finance', 22, 44),
(198, 16, 'Research investments', 'pending', 'easy', 'Finance', 11, 38),
(199, 16, 'Practice mindfulness', 'pending', 'easy', 'Mental Wellness', 7, 39),
(200, 16, 'Do laundry', 'pending', 'easy', 'Home Environment', 22, 45),
(201, 16, 'Practice yoga', 'completed', 'hard', 'Physical Health', 16, 13),
(202, 17, 'Do laundry', 'pending', 'easy', 'Home Environment', 15, 40),
(203, 17, 'Practice public speaking', 'pending', 'hard', 'Personal Growth', 13, 40),
(204, 17, 'Read industry news', 'completed', 'hard', 'Career / Studies', 21, 30),
(205, 17, 'Practice mindfulness', 'completed', 'easy', 'Mental Wellness', 18, 14),
(206, 17, 'Go for a 30-minute walk', 'pending', 'easy', 'Physical Health', 25, 23),
(207, 17, 'Write thank you note', 'pending', 'easy', 'Relationships Social', 17, 45),
(208, 17, 'Clean living space', 'pending', 'medium', 'Home Environment', 18, 27),
(209, 17, 'Show appreciation', 'pending', 'medium', 'Relationships Social', 18, 11),
(210, 18, 'Stretch for 10 minutes', 'completed', 'easy', 'Physical Health', 15, 49),
(211, 18, 'Drink 8 glasses of water', 'pending', 'hard', 'Physical Health', 9, 50),
(212, 18, 'Do 20 push-ups', 'pending', 'hard', 'Physical Health', 13, 15),
(213, 18, 'Research investments', 'pending', 'medium', 'Finance', 21, 13),
(214, 18, 'Work on portfolio', 'pending', 'hard', 'Career / Studies', 21, 10),
(215, 18, 'Practice guitar', 'pending', 'hard', 'Passion Hobbies', 5, 28),
(216, 18, 'Water plants', 'pending', 'hard', 'Home Environment', 7, 49),
(217, 18, 'Practice mindfulness', 'pending', 'hard', 'Mental Wellness', 8, 13),
(218, 19, 'Practice mindfulness', 'pending', 'easy', 'Mental Wellness', 17, 27),
(219, 19, 'Pay bills on time', 'pending', 'medium', 'Finance', 20, 43),
(220, 19, 'Practice a skill', 'pending', 'hard', 'Personal Growth', 9, 30),
(221, 19, 'Listen to calming music', 'completed', 'easy', 'Mental Wellness', 22, 22),
(222, 19, 'Practice public speaking', 'pending', 'hard', 'Personal Growth', 5, 24),
(223, 19, 'Take vitamins', 'pending', 'hard', 'Physical Health', 22, 13),
(224, 20, 'Write gratitude list', 'pending', 'hard', 'Mental Wellness', 22, 43),
(225, 20, 'Play board games', 'pending', 'easy', 'Passion Hobbies', 22, 21),
(226, 20, 'Take vitamins', 'pending', 'easy', 'Physical Health', 12, 25),
(227, 20, 'Write gratitude list', 'pending', 'medium', 'Mental Wellness', 8, 27),
(228, 20, 'Stretch for 10 minutes', 'completed', 'medium', 'Physical Health', 17, 35),
(229, 21, 'Cook new recipe', 'pending', 'easy', 'Passion Hobbies', 25, 34),
(230, 21, 'Go for a 30-minute walk', 'pending', 'medium', 'Physical Health', 7, 43),
(231, 21, 'Review budget', 'completed', 'medium', 'Finance', 21, 21),
(232, 21, 'Call a friend', 'pending', 'hard', 'Relationships Social', 20, 34),
(233, 21, 'Practice deep breathing', 'completed', 'easy', 'Mental Wellness', 22, 22),
(234, 22, 'Stretch for 10 minutes', 'pending', 'medium', 'Physical Health', 6, 39),
(235, 22, 'Organize workspace', 'completed', 'easy', 'Home Environment', 9, 40),
(236, 22, 'Track expenses', 'completed', 'hard', 'Finance', 15, 27),
(237, 22, 'Play board games', 'pending', 'medium', 'Passion Hobbies', 19, 18),
(238, 22, 'Meal prep', 'completed', 'easy', 'Home Environment', 6, 30),
(239, 22, 'Garden for 30 minutes', 'pending', 'easy', 'Passion Hobbies', 16, 18),
(240, 22, 'Write thank you note', 'completed', 'hard', 'Relationships Social', 10, 22),
(241, 22, 'Make bed', 'pending', 'medium', 'Home Environment', 13, 38),
(242, 23, 'Watch educational video', 'pending', 'hard', 'Personal Growth', 15, 17),
(243, 23, 'Play board games', 'pending', 'hard', 'Passion Hobbies', 8, 32),
(244, 23, 'Do brain exercises', 'pending', 'medium', 'Mental Wellness', 16, 39),
(245, 23, 'Learn about finances', 'pending', 'easy', 'Finance', 21, 23),
(246, 23, 'Declutter room', 'pending', 'easy', 'Home Environment', 23, 16),
(247, 23, 'Spend time with family', 'completed', 'medium', 'Relationships Social', 18, 40),
(248, 24, 'Do cardio workout', 'pending', 'medium', 'Physical Health', 24, 12),
(249, 24, 'Practice deep breathing', 'pending', 'medium', 'Mental Wellness', 8, 15),
(250, 24, 'Network with professionals', 'pending', 'medium', 'Career / Studies', 6, 21),
(251, 25, 'Save money', 'pending', 'easy', 'Finance', 14, 48),
(252, 25, 'Make new connections', 'pending', 'hard', 'Relationships Social', 21, 17),
(253, 25, 'Cut unnecessary expenses', 'pending', 'medium', 'Finance', 25, 45),
(254, 25, 'Read self-help book', 'pending', 'easy', 'Personal Growth', 10, 45),
(255, 25, 'Do cardio workout', 'pending', 'easy', 'Physical Health', 7, 27),
(256, 25, 'Go for a 30-minute walk', 'pending', 'hard', 'Physical Health', 25, 20),
(257, 25, 'Drink 8 glasses of water', 'pending', 'medium', 'Physical Health', 8, 10),
(258, 25, 'Resolve conflicts', 'pending', 'medium', 'Relationships Social', 23, 49),
(259, 26, 'Research investments', 'completed', 'hard', 'Finance', 23, 28),
(260, 26, 'Track expenses', 'pending', 'hard', 'Finance', 7, 23),
(261, 26, 'Update resume', 'completed', 'easy', 'Career / Studies', 22, 20),
(262, 26, 'Research investments', 'pending', 'medium', 'Finance', 17, 25),
(263, 26, 'Write in journal', 'pending', 'easy', 'Passion Hobbies', 19, 40),
(264, 26, 'Read self-help book', 'pending', 'hard', 'Personal Growth', 21, 47),
(265, 27, 'Organize workspace', 'pending', 'easy', 'Home Environment', 20, 41),
(266, 27, 'Eat a healthy breakfast', 'pending', 'easy', 'Physical Health', 19, 49),
(267, 27, 'Meal prep', 'pending', 'medium', 'Home Environment', 20, 48),
(268, 27, 'Practice active listening', 'pending', 'medium', 'Relationships Social', 16, 11),
(269, 28, 'Write gratitude list', 'pending', 'medium', 'Mental Wellness', 21, 29),
(270, 28, 'Update resume', 'pending', 'medium', 'Career / Studies', 6, 23),
(271, 28, 'Review budget', 'completed', 'easy', 'Finance', 11, 46),
(272, 28, 'Track expenses', 'completed', 'medium', 'Finance', 11, 25),
(273, 28, 'Plan future goals', 'pending', 'hard', 'Personal Growth', 24, 33),
(274, 28, 'Do brain exercises', 'pending', 'easy', 'Mental Wellness', 7, 25),
(275, 28, 'Update resume', 'pending', 'easy', 'Career / Studies', 7, 15),
(276, 28, 'Meal prep', 'pending', 'medium', 'Home Environment', 16, 23),
(277, 29, 'Learn new hobby', 'pending', 'medium', 'Passion Hobbies', 12, 48),
(278, 29, 'Declutter room', 'pending', 'medium', 'Home Environment', 14, 23),
(279, 29, 'Organize workspace', 'pending', 'medium', 'Home Environment', 14, 25),
(280, 30, 'Play board games', 'pending', 'hard', 'Passion Hobbies', 14, 47),
(281, 30, 'Write thank you note', 'pending', 'hard', 'Relationships Social', 19, 49),
(282, 30, 'Learn something new', 'pending', 'medium', 'Personal Growth', 14, 35),
(283, 30, 'Do brain exercises', 'pending', 'medium', 'Mental Wellness', 14, 11),
(284, 31, 'Review budget', 'pending', 'hard', 'Finance', 18, 30),
(285, 31, 'Read self-help book', 'pending', 'hard', 'Personal Growth', 5, 14),
(286, 31, 'Meditate for 10 minutes', 'pending', 'easy', 'Mental Wellness', 15, 50),
(287, 31, 'Learn something new', 'pending', 'hard', 'Personal Growth', 18, 35),
(288, 32, 'Meditate for 10 minutes', 'completed', 'medium', 'Mental Wellness', 25, 11),
(289, 32, 'Clean living space', 'pending', 'medium', 'Home Environment', 20, 27),
(290, 32, 'Clean living space', 'pending', 'hard', 'Home Environment', 9, 44),
(291, 32, 'Make new connections', 'completed', 'easy', 'Relationships Social', 5, 19),
(292, 32, 'Make new connections', 'pending', 'easy', 'Relationships Social', 25, 43),
(293, 32, 'Play board games', 'pending', 'easy', 'Passion Hobbies', 23, 36),
(294, 33, 'Listen to calming music', 'completed', 'medium', 'Mental Wellness', 14, 43),
(295, 33, 'Cook new recipe', 'pending', 'medium', 'Passion Hobbies', 18, 39),
(296, 33, 'Write thank you note', 'pending', 'medium', 'Relationships Social', 19, 25),
(297, 33, 'Cut unnecessary expenses', 'pending', 'hard', 'Finance', 22, 11),
(298, 34, 'Plan future goals', 'completed', 'easy', 'Personal Growth', 8, 48),
(299, 34, 'Write in journal', 'pending', 'medium', 'Passion Hobbies', 23, 48),
(300, 34, 'Make new connections', 'pending', 'easy', 'Relationships Social', 5, 19),
(301, 34, 'Practice mindfulness', 'pending', 'medium', 'Mental Wellness', 16, 29),
(302, 34, 'Go for a 30-minute walk', 'pending', 'easy', 'Physical Health', 21, 18),
(303, 34, 'Call a friend', 'pending', 'hard', 'Relationships Social', 12, 37),
(304, 34, 'Practice guitar', 'pending', 'easy', 'Passion Hobbies', 22, 15),
(305, 35, 'Practice interview skills', 'pending', 'hard', 'Career / Studies', 14, 24),
(306, 35, 'Practice a skill', 'pending', 'medium', 'Personal Growth', 18, 39),
(307, 35, 'Learn something new', 'pending', 'hard', 'Personal Growth', 19, 11),
(308, 36, 'Learn something new', 'pending', 'hard', 'Personal Growth', 21, 47),
(309, 36, 'Watch educational video', 'pending', 'easy', 'Personal Growth', 24, 11),
(310, 36, 'Do 20 push-ups', 'pending', 'easy', 'Physical Health', 11, 25),
(311, 37, 'Cut unnecessary expenses', 'pending', 'hard', 'Finance', 7, 36),
(312, 37, 'Eat a healthy breakfast', 'pending', 'easy', 'Physical Health', 5, 42),
(313, 37, 'Water plants', 'pending', 'hard', 'Home Environment', 10, 49),
(314, 37, 'Meditate for 10 minutes', 'completed', 'medium', 'Mental Wellness', 14, 49),
(315, 37, 'Cook new recipe', 'pending', 'easy', 'Passion Hobbies', 21, 37),
(316, 37, 'Write thank you note', 'completed', 'easy', 'Relationships Social', 5, 12),
(317, 38, 'Pay bills on time', 'pending', 'easy', 'Finance', 9, 49),
(318, 38, 'Take photos', 'pending', 'easy', 'Passion Hobbies', 20, 36),
(319, 38, 'Practice a skill', 'pending', 'medium', 'Personal Growth', 10, 18),
(320, 38, 'Organize workspace', 'pending', 'easy', 'Home Environment', 11, 46),
(321, 38, 'Meal prep', 'pending', 'easy', 'Home Environment', 18, 32),
(322, 39, 'Review financial goals', 'completed', 'medium', 'Finance', 9, 47),
(323, 39, 'Stretch for 10 minutes', 'pending', 'easy', 'Physical Health', 24, 13),
(324, 39, 'Meditate for 10 minutes', 'pending', 'medium', 'Mental Wellness', 8, 23),
(325, 39, 'Take photos', 'pending', 'hard', 'Passion Hobbies', 8, 47),
(326, 39, 'Eat a healthy breakfast', 'pending', 'hard', 'Physical Health', 21, 49),
(327, 39, 'Track expenses', 'completed', 'hard', 'Finance', 12, 13),
(328, 40, 'Practice interview skills', 'completed', 'easy', 'Career / Studies', 20, 17),
(329, 40, 'Eat a healthy breakfast', 'completed', 'easy', 'Physical Health', 16, 14),
(330, 40, 'Set daily goals', 'pending', 'easy', 'Personal Growth', 7, 41),
(331, 40, 'Practice public speaking', 'completed', 'hard', 'Personal Growth', 20, 37),
(332, 40, 'Stretch for 10 minutes', 'pending', 'medium', 'Physical Health', 21, 36),
(333, 41, 'Take vitamins', 'completed', 'easy', 'Physical Health', 21, 43),
(334, 41, 'Track expenses', 'completed', 'medium', 'Finance', 22, 31),
(335, 41, 'Practice a skill', 'completed', 'easy', 'Personal Growth', 5, 41),
(336, 41, 'Declutter room', 'pending', 'medium', 'Home Environment', 6, 29),
(337, 41, 'Practice interview skills', 'pending', 'easy', 'Career / Studies', 17, 49),
(338, 41, 'Cook new recipe', 'pending', 'hard', 'Passion Hobbies', 13, 47),
(339, 41, 'Read industry news', 'pending', 'easy', 'Career / Studies', 10, 14),
(340, 42, 'Make bed', 'pending', 'medium', 'Home Environment', 7, 33),
(341, 42, 'Read self-help book', 'pending', 'hard', 'Personal Growth', 20, 18),
(342, 42, 'Write in journal', 'pending', 'easy', 'Passion Hobbies', 12, 19),
(343, 42, 'Practice active listening', 'pending', 'hard', 'Relationships Social', 19, 28),
(344, 42, 'Take vitamins', 'pending', 'medium', 'Physical Health', 9, 38),
(345, 42, 'Play board games', 'completed', 'hard', 'Passion Hobbies', 24, 49),
(346, 43, 'Practice public speaking', 'completed', 'easy', 'Personal Growth', 6, 20),
(347, 43, 'Stretch for 10 minutes', 'pending', 'easy', 'Physical Health', 21, 24),
(348, 43, 'Cut unnecessary expenses', 'pending', 'easy', 'Finance', 15, 50),
(349, 43, 'Practice a skill', 'pending', 'hard', 'Personal Growth', 16, 42),
(350, 43, 'Pay bills on time', 'pending', 'medium', 'Finance', 7, 50),
(351, 43, 'Organize workspace', 'pending', 'medium', 'Home Environment', 9, 33),
(352, 43, 'Read for 30 minutes', 'pending', 'hard', 'Mental Wellness', 21, 17),
(353, 43, 'Save money', 'pending', 'easy', 'Finance', 8, 42),
(354, 44, 'Set daily goals', 'pending', 'hard', 'Personal Growth', 15, 29),
(355, 44, 'Read self-help book', 'pending', 'medium', 'Personal Growth', 23, 14),
(356, 44, 'Save money', 'pending', 'hard', 'Finance', 11, 38),
(357, 44, 'Plan future goals', 'pending', 'hard', 'Personal Growth', 20, 27),
(358, 44, 'Reflect on progress', 'completed', 'medium', 'Personal Growth', 24, 18),
(359, 44, 'Write gratitude list', 'pending', 'medium', 'Mental Wellness', 24, 36),
(360, 44, 'Write thank you note', 'completed', 'medium', 'Relationships Social', 23, 49),
(361, 45, 'Take vitamins', 'pending', 'hard', 'Physical Health', 6, 24),
(362, 45, 'Write thank you note', 'pending', 'hard', 'Relationships Social', 21, 20),
(363, 45, 'Vacuum house', 'pending', 'medium', 'Home Environment', 18, 24),
(364, 45, 'Review financial goals', 'pending', 'easy', 'Finance', 15, 34),
(365, 45, 'Drink 8 glasses of water', 'completed', 'easy', 'Physical Health', 14, 32),
(366, 45, 'Save money', 'pending', 'hard', 'Finance', 5, 34),
(367, 46, 'Read for 30 minutes', 'pending', 'easy', 'Mental Wellness', 23, 35),
(368, 46, 'Write in journal', 'pending', 'medium', 'Passion Hobbies', 9, 33),
(369, 46, 'Practice interview skills', 'completed', 'medium', 'Career / Studies', 21, 35),
(370, 46, 'Practice public speaking', 'pending', 'medium', 'Personal Growth', 18, 31),
(371, 46, 'Make bed', 'pending', 'medium', 'Home Environment', 7, 38),
(372, 46, 'Save money', 'pending', 'hard', 'Finance', 20, 12),
(373, 46, 'Review budget', 'completed', 'medium', 'Finance', 10, 13),
(374, 46, 'Clean living space', 'pending', 'easy', 'Home Environment', 9, 43),
(375, 47, 'Save money', 'pending', 'hard', 'Finance', 10, 28),
(376, 47, 'Take online course', 'completed', 'medium', 'Career / Studies', 23, 22),
(377, 47, 'Organize workspace', 'completed', 'hard', 'Home Environment', 22, 44),
(378, 47, 'Write in journal', 'pending', 'easy', 'Passion Hobbies', 11, 33),
(379, 48, 'Clean living space', 'completed', 'easy', 'Home Environment', 21, 26),
(380, 48, 'Show appreciation', 'completed', 'hard', 'Relationships Social', 5, 11),
(381, 48, 'Practice a skill', 'pending', 'medium', 'Personal Growth', 22, 11),
(382, 48, 'Write gratitude list', 'completed', 'easy', 'Mental Wellness', 10, 30),
(383, 48, 'Write in journal', 'completed', 'medium', 'Passion Hobbies', 21, 25),
(384, 48, 'Plan future goals', 'completed', 'easy', 'Personal Growth', 13, 46),
(385, 48, 'Vacuum house', 'pending', 'medium', 'Home Environment', 8, 49),
(386, 49, 'Watch educational video', 'pending', 'medium', 'Personal Growth', 6, 35),
(387, 49, 'Take online course', 'pending', 'medium', 'Career / Studies', 9, 32),
(388, 49, 'Read for 30 minutes', 'completed', 'easy', 'Mental Wellness', 12, 38),
(389, 50, 'Play board games', 'pending', 'easy', 'Passion Hobbies', 22, 13),
(390, 50, 'Spend time with family', 'completed', 'easy', 'Relationships Social', 14, 20),
(391, 50, 'Resolve conflicts', 'pending', 'medium', 'Relationships Social', 22, 13),
(392, 50, 'Stretch for 10 minutes', 'pending', 'medium', 'Physical Health', 12, 30),
(393, 51, 'Cook new recipe', 'pending', 'medium', 'Passion Hobbies', 19, 28),
(394, 51, 'Do brain exercises', 'pending', 'medium', 'Mental Wellness', 15, 41),
(395, 51, 'Do 20 push-ups', 'pending', 'medium', 'Physical Health', 16, 42),
(396, 51, 'Pay bills on time', 'completed', 'medium', 'Finance', 15, 38),
(397, 51, 'Plan social activity', 'pending', 'medium', 'Relationships Social', 10, 46),
(398, 52, 'Play board games', 'pending', 'easy', 'Passion Hobbies', 5, 47),
(399, 52, 'Research investments', 'pending', 'medium', 'Finance', 17, 13),
(400, 52, 'Read self-help book', 'pending', 'hard', 'Personal Growth', 6, 18),
(401, 52, 'Resolve conflicts', 'pending', 'hard', 'Relationships Social', 21, 47),
(402, 52, 'Plan future goals', 'pending', 'easy', 'Personal Growth', 10, 33),
(403, 52, 'Practice yoga', 'completed', 'hard', 'Physical Health', 23, 49),
(404, 53, 'Cook new recipe', 'pending', 'easy', 'Passion Hobbies', 7, 21),
(405, 53, 'Clean living space', 'pending', 'easy', 'Home Environment', 11, 26),
(406, 53, 'Review budget', 'pending', 'easy', 'Finance', 9, 36),
(407, 53, 'Vacuum house', 'completed', 'easy', 'Home Environment', 22, 10),
(408, 53, 'Read industry news', 'pending', 'medium', 'Career / Studies', 21, 11),
(409, 53, 'Network with professionals', 'pending', 'easy', 'Career / Studies', 22, 41),
(410, 53, 'Set daily goals', 'pending', 'easy', 'Personal Growth', 10, 14),
(411, 53, 'Make bed', 'completed', 'easy', 'Home Environment', 6, 35),
(412, 54, 'Write gratitude list', 'completed', 'hard', 'Mental Wellness', 8, 12),
(413, 54, 'Write gratitude list', 'pending', 'medium', 'Mental Wellness', 14, 48),
(414, 54, 'Make new connections', 'pending', 'easy', 'Relationships Social', 25, 13),
(415, 54, 'Pay bills on time', 'pending', 'easy', 'Finance', 9, 35),
(416, 54, 'Water plants', 'pending', 'hard', 'Home Environment', 17, 33),
(417, 54, 'Write thank you note', 'pending', 'medium', 'Relationships Social', 13, 19),
(418, 54, 'Garden for 30 minutes', 'pending', 'easy', 'Passion Hobbies', 14, 40),
(419, 55, 'Listen to calming music', 'pending', 'hard', 'Mental Wellness', 22, 10),
(420, 55, 'Cut unnecessary expenses', 'pending', 'easy', 'Finance', 19, 17),
(421, 55, 'Study programming', 'pending', 'easy', 'Career / Studies', 15, 35),
(422, 55, 'Drink 8 glasses of water', 'completed', 'easy', 'Physical Health', 8, 10),
(423, 56, 'Listen to calming music', 'pending', 'easy', 'Mental Wellness', 18, 46),
(424, 56, 'Vacuum house', 'pending', 'easy', 'Home Environment', 5, 37),
(425, 56, 'Practice public speaking', 'completed', 'medium', 'Personal Growth', 25, 46),
(426, 56, 'Pay bills on time', 'pending', 'medium', 'Finance', 15, 31),
(427, 56, 'Review budget', 'pending', 'easy', 'Finance', 11, 14),
(428, 56, 'Practice a skill', 'completed', 'medium', 'Personal Growth', 15, 31),
(429, 57, 'Reflect on progress', 'completed', 'hard', 'Personal Growth', 16, 27),
(430, 57, 'Learn something new', 'pending', 'medium', 'Personal Growth', 18, 11),
(431, 57, 'Write gratitude list', 'pending', 'hard', 'Mental Wellness', 18, 17),
(432, 57, 'Cook new recipe', 'pending', 'medium', 'Passion Hobbies', 6, 26),
(433, 57, 'Plan future goals', 'pending', 'hard', 'Personal Growth', 6, 29),
(434, 58, 'Water plants', 'pending', 'easy', 'Home Environment', 5, 14),
(435, 58, 'Show appreciation', 'pending', 'easy', 'Relationships Social', 6, 37),
(436, 58, 'Resolve conflicts', 'pending', 'hard', 'Relationships Social', 11, 50),
(437, 58, 'Declutter room', 'completed', 'hard', 'Home Environment', 20, 38),
(438, 59, 'Learn something new', 'completed', 'easy', 'Personal Growth', 21, 14),
(439, 59, 'Listen to calming music', 'completed', 'medium', 'Mental Wellness', 14, 24),
(440, 59, 'Learn about finances', 'completed', 'hard', 'Finance', 7, 29),
(441, 59, 'Read industry news', 'pending', 'hard', 'Career / Studies', 22, 46),
(442, 59, 'Organize workspace', 'pending', 'easy', 'Home Environment', 11, 34),
(443, 59, 'Water plants', 'pending', 'medium', 'Home Environment', 14, 27),
(444, 60, 'Learn something new', 'pending', 'medium', 'Personal Growth', 15, 18),
(445, 60, 'Drink 8 glasses of water', 'pending', 'easy', 'Physical Health', 9, 19),
(446, 60, 'Listen to calming music', 'pending', 'easy', 'Mental Wellness', 14, 21),
(447, 60, 'Pay bills on time', 'completed', 'medium', 'Finance', 21, 17),
(448, 60, 'Save money', 'completed', 'easy', 'Finance', 6, 19),
(449, 60, 'Learn new hobby', 'pending', 'medium', 'Passion Hobbies', 16, 38),
(450, 60, 'Practice public speaking', 'pending', 'easy', 'Personal Growth', 21, 31),
(451, 60, 'Take vitamins', 'pending', 'easy', 'Physical Health', 17, 35),
(452, 61, 'Stretch for 10 minutes', 'pending', 'medium', 'Physical Health', 8, 24),
(453, 61, 'Call a friend', 'pending', 'easy', 'Relationships Social', 22, 10),
(454, 61, 'Do laundry', 'pending', 'hard', 'Home Environment', 20, 29),
(455, 61, 'Take photos', 'pending', 'easy', 'Passion Hobbies', 25, 32),
(456, 62, 'Declutter room', 'completed', 'hard', 'Home Environment', 24, 30),
(457, 62, 'Practice public speaking', 'pending', 'hard', 'Personal Growth', 14, 23),
(458, 62, 'Play board games', 'completed', 'medium', 'Passion Hobbies', 12, 30),
(459, 62, 'Do laundry', 'pending', 'hard', 'Home Environment', 10, 39),
(460, 62, 'Plan social activity', 'completed', 'easy', 'Relationships Social', 20, 11),
(461, 62, 'Review financial goals', 'pending', 'medium', 'Finance', 21, 12),
(462, 62, 'Organize workspace', 'pending', 'medium', 'Home Environment', 18, 12),
(463, 63, 'Meal prep', 'pending', 'easy', 'Home Environment', 21, 19),
(464, 63, 'Take a mental health break', 'pending', 'medium', 'Mental Wellness', 24, 38),
(465, 63, 'Make new connections', 'completed', 'medium', 'Relationships Social', 23, 26),
(466, 64, 'Take vitamins', 'completed', 'medium', 'Physical Health', 12, 34),
(467, 64, 'Review financial goals', 'pending', 'easy', 'Finance', 14, 15),
(468, 64, 'Plan social activity', 'completed', 'easy', 'Relationships Social', 14, 49),
(469, 64, 'Garden for 30 minutes', 'pending', 'easy', 'Passion Hobbies', 23, 36),
(470, 64, 'Read self-help book', 'completed', 'easy', 'Personal Growth', 14, 18),
(471, 64, 'Practice public speaking', 'completed', 'easy', 'Personal Growth', 6, 42),
(472, 65, 'Learn new hobby', 'completed', 'easy', 'Passion Hobbies', 15, 26),
(473, 65, 'Read for 30 minutes', 'pending', 'easy', 'Mental Wellness', 24, 38),
(474, 65, 'Stretch for 10 minutes', 'completed', 'easy', 'Physical Health', 18, 29),
(475, 65, 'Listen to calming music', 'pending', 'hard', 'Mental Wellness', 23, 11),
(476, 65, 'Write in journal', 'pending', 'medium', 'Passion Hobbies', 16, 14),
(477, 65, 'Practice active listening', 'pending', 'hard', 'Relationships Social', 17, 31),
(478, 65, 'Do brain exercises', 'completed', 'hard', 'Mental Wellness', 10, 24),
(479, 65, 'Save money', 'pending', 'medium', 'Finance', 13, 32),
(480, 66, 'Call a friend', 'pending', 'medium', 'Relationships Social', 6, 24),
(481, 66, 'Do cardio workout', 'pending', 'medium', 'Physical Health', 24, 18),
(482, 66, 'Write gratitude list', 'pending', 'hard', 'Mental Wellness', 10, 11),
(483, 66, 'Do 20 push-ups', 'completed', 'easy', 'Physical Health', 18, 16),
(484, 66, 'Take a mental health break', 'pending', 'hard', 'Mental Wellness', 13, 13),
(485, 67, 'Work on art project', 'completed', 'medium', 'Passion Hobbies', 18, 42),
(486, 67, 'Work on art project', 'completed', 'easy', 'Passion Hobbies', 8, 28),
(487, 67, 'Network with professionals', 'completed', 'medium', 'Career / Studies', 23, 32),
(488, 67, 'Review financial goals', 'completed', 'medium', 'Finance', 14, 37),
(489, 67, 'Write thank you note', 'pending', 'hard', 'Relationships Social', 16, 34),
(490, 68, 'Practice guitar', 'pending', 'medium', 'Passion Hobbies', 11, 33),
(491, 68, 'Save money', 'completed', 'medium', 'Finance', 13, 41),
(492, 68, 'Review financial goals', 'completed', 'easy', 'Finance', 5, 42),
(493, 68, 'Write thank you note', 'completed', 'easy', 'Relationships Social', 15, 16),
(494, 68, 'Write thank you note', 'completed', 'hard', 'Relationships Social', 24, 40),
(495, 69, 'Take vitamins', 'pending', 'medium', 'Physical Health', 5, 35),
(496, 69, 'Work on portfolio', 'pending', 'hard', 'Career / Studies', 5, 49),
(497, 69, 'Save money', 'completed', 'medium', 'Finance', 12, 50),
(498, 69, 'Practice mindfulness', 'pending', 'easy', 'Mental Wellness', 15, 44),
(499, 70, 'Do 20 push-ups', 'pending', 'easy', 'Physical Health', 16, 14),
(500, 70, 'Resolve conflicts', 'pending', 'hard', 'Relationships Social', 16, 28),
(501, 70, 'Show appreciation', 'completed', 'easy', 'Relationships Social', 12, 33),
(502, 71, 'Read industry news', 'pending', 'medium', 'Career / Studies', 24, 46),
(503, 71, 'Learn something new', 'pending', 'medium', 'Personal Growth', 15, 31),
(504, 71, 'Take a mental health break', 'pending', 'hard', 'Mental Wellness', 14, 29),
(505, 71, 'Meditate for 10 minutes', 'pending', 'medium', 'Mental Wellness', 24, 40),
(506, 71, 'Track expenses', 'pending', 'hard', 'Finance', 5, 19),
(507, 71, 'Work on portfolio', 'pending', 'easy', 'Career / Studies', 25, 18),
(508, 71, 'Watch educational video', 'pending', 'hard', 'Personal Growth', 9, 30),
(509, 71, 'Study programming', 'pending', 'easy', 'Career / Studies', 5, 17),
(510, 72, 'Write in journal', 'pending', 'hard', 'Passion Hobbies', 9, 33),
(511, 72, 'Practice interview skills', 'pending', 'medium', 'Career / Studies', 23, 24),
(512, 72, 'Cook new recipe', 'completed', 'hard', 'Passion Hobbies', 17, 44),
(513, 72, 'Practice a skill', 'pending', 'hard', 'Personal Growth', 6, 12),
(514, 73, 'Review budget', 'completed', 'hard', 'Finance', 6, 49),
(515, 73, 'Cook new recipe', 'pending', 'hard', 'Passion Hobbies', 5, 41),
(516, 73, 'Water plants', 'pending', 'easy', 'Home Environment', 19, 26),
(517, 73, 'Research investments', 'pending', 'hard', 'Finance', 7, 27),
(518, 74, 'Water plants', 'pending', 'medium', 'Home Environment', 24, 17),
(519, 74, 'Plan future goals', 'pending', 'easy', 'Personal Growth', 24, 50),
(520, 74, 'Stretch for 10 minutes', 'pending', 'medium', 'Physical Health', 7, 32),
(521, 74, 'Practice public speaking', 'pending', 'medium', 'Personal Growth', 22, 41),
(522, 74, 'Pay bills on time', 'pending', 'hard', 'Finance', 21, 44),
(523, 75, 'Organize workspace', 'pending', 'easy', 'Home Environment', 22, 10),
(524, 75, 'Vacuum house', 'pending', 'hard', 'Home Environment', 6, 29),
(525, 75, 'Play board games', 'pending', 'hard', 'Passion Hobbies', 6, 31),
(526, 75, 'Practice interview skills', 'pending', 'easy', 'Career / Studies', 8, 49),
(527, 75, 'Read for 30 minutes', 'pending', 'easy', 'Mental Wellness', 15, 33),
(528, 76, 'Practice deep breathing', 'pending', 'hard', 'Mental Wellness', 7, 46),
(529, 76, 'Practice guitar', 'pending', 'easy', 'Passion Hobbies', 21, 14),
(530, 76, 'Practice guitar', 'pending', 'medium', 'Passion Hobbies', 23, 48),
(531, 76, 'Practice guitar', 'pending', 'hard', 'Passion Hobbies', 16, 16),
(532, 76, 'Resolve conflicts', 'pending', 'easy', 'Relationships Social', 14, 45),
(533, 76, 'Plan social activity', 'pending', 'hard', 'Relationships Social', 16, 16),
(534, 76, 'Do cardio workout', 'pending', 'medium', 'Physical Health', 20, 30),
(535, 77, 'Write gratitude list', 'completed', 'hard', 'Mental Wellness', 13, 49),
(536, 77, 'Go for a 30-minute walk', 'completed', 'easy', 'Physical Health', 5, 26),
(537, 77, 'Make new connections', 'pending', 'hard', 'Relationships Social', 16, 42),
(538, 77, 'Do 20 push-ups', 'pending', 'easy', 'Physical Health', 22, 35),
(539, 77, 'Stretch for 10 minutes', 'pending', 'easy', 'Physical Health', 15, 24),
(540, 77, 'Spend time with family', 'pending', 'medium', 'Relationships Social', 12, 30),
(541, 77, 'Take a mental health break', 'pending', 'hard', 'Mental Wellness', 16, 12),
(542, 77, 'Practice interview skills', 'completed', 'medium', 'Career / Studies', 8, 31),
(543, 78, 'Track expenses', 'pending', 'easy', 'Finance', 10, 24),
(544, 78, 'Reflect on progress', 'pending', 'medium', 'Personal Growth', 6, 45),
(545, 78, 'Study programming', 'pending', 'easy', 'Career / Studies', 12, 24),
(546, 78, 'Learn something new', 'pending', 'hard', 'Personal Growth', 11, 12),
(547, 79, 'Practice guitar', 'completed', 'hard', 'Passion Hobbies', 12, 19),
(548, 79, 'Spend time with family', 'pending', 'hard', 'Relationships Social', 13, 17),
(549, 79, 'Practice mindfulness', 'pending', 'medium', 'Mental Wellness', 10, 18),
(550, 79, 'Vacuum house', 'pending', 'medium', 'Home Environment', 16, 48),
(551, 79, 'Write thank you note', 'completed', 'easy', 'Relationships Social', 6, 50),
(552, 79, 'Read self-help book', 'pending', 'easy', 'Personal Growth', 19, 47),
(553, 79, 'Show appreciation', 'pending', 'easy', 'Relationships Social', 14, 20),
(554, 79, 'Call a friend', 'pending', 'easy', 'Relationships Social', 18, 34),
(555, 80, 'Do brain exercises', 'pending', 'easy', 'Mental Wellness', 16, 44),
(556, 80, 'Drink 8 glasses of water', 'pending', 'medium', 'Physical Health', 13, 11),
(557, 80, 'Call a friend', 'pending', 'hard', 'Relationships Social', 10, 29),
(558, 80, 'Cook new recipe', 'pending', 'medium', 'Passion Hobbies', 18, 20),
(559, 80, 'Practice guitar', 'pending', 'medium', 'Passion Hobbies', 5, 17),
(560, 80, 'Practice guitar', 'pending', 'hard', 'Passion Hobbies', 6, 43),
(561, 80, 'Declutter room', 'completed', 'hard', 'Home Environment', 12, 32),
(562, 81, 'Stretch for 10 minutes', 'pending', 'medium', 'Physical Health', 12, 15),
(563, 81, 'Do 20 push-ups', 'pending', 'easy', 'Physical Health', 17, 15),
(564, 81, 'Review financial goals', 'pending', 'medium', 'Finance', 17, 18),
(565, 81, 'Garden for 30 minutes', 'pending', 'hard', 'Passion Hobbies', 18, 27),
(566, 81, 'Make bed', 'completed', 'medium', 'Home Environment', 23, 21),
(567, 82, 'Write gratitude list', 'pending', 'easy', 'Mental Wellness', 16, 19),
(568, 82, 'Water plants', 'pending', 'easy', 'Home Environment', 11, 34),
(569, 82, 'Practice interview skills', 'completed', 'easy', 'Career / Studies', 21, 41),
(570, 82, 'Meal prep', 'completed', 'easy', 'Home Environment', 15, 31),
(571, 83, 'Practice interview skills', 'pending', 'easy', 'Career / Studies', 14, 27),
(572, 83, 'Play board games', 'pending', 'hard', 'Passion Hobbies', 19, 49),
(573, 83, 'Cook new recipe', 'pending', 'medium', 'Passion Hobbies', 25, 22),
(574, 83, 'Learn about finances', 'pending', 'hard', 'Finance', 5, 20),
(575, 84, 'Plan social activity', 'pending', 'easy', 'Relationships Social', 15, 40),
(576, 84, 'Meditate for 10 minutes', 'completed', 'hard', 'Mental Wellness', 6, 13),
(577, 84, 'Review budget', 'pending', 'hard', 'Finance', 21, 10),
(578, 84, 'Review budget', 'pending', 'easy', 'Finance', 21, 35),
(579, 84, 'Stretch for 10 minutes', 'completed', 'medium', 'Physical Health', 8, 49),
(580, 85, 'Go for a 30-minute walk', 'pending', 'medium', 'Physical Health', 15, 33),
(581, 85, 'Learn something new', 'pending', 'easy', 'Personal Growth', 19, 28),
(582, 85, 'Make new connections', 'pending', 'hard', 'Relationships Social', 22, 40),
(583, 85, 'Eat a healthy breakfast', 'pending', 'easy', 'Physical Health', 5, 18),
(584, 85, 'Do brain exercises', 'completed', 'medium', 'Mental Wellness', 11, 30),
(585, 85, 'Practice public speaking', 'pending', 'medium', 'Personal Growth', 18, 37),
(586, 85, 'Listen to calming music', 'completed', 'easy', 'Mental Wellness', 23, 44),
(587, 85, 'Eat a healthy breakfast', 'pending', 'easy', 'Physical Health', 9, 35),
(588, 86, 'Cut unnecessary expenses', 'pending', 'hard', 'Finance', 8, 17),
(589, 86, 'Write in journal', 'pending', 'easy', 'Passion Hobbies', 14, 18),
(590, 86, 'Organize workspace', 'pending', 'hard', 'Home Environment', 6, 29),
(591, 86, 'Organize workspace', 'pending', 'hard', 'Home Environment', 14, 40),
(592, 86, 'Research investments', 'pending', 'hard', 'Finance', 11, 32),
(593, 87, 'Work on portfolio', 'pending', 'hard', 'Career / Studies', 20, 42),
(594, 87, 'Learn something new', 'pending', 'easy', 'Personal Growth', 14, 40),
(595, 87, 'Make new connections', 'pending', 'medium', 'Relationships Social', 17, 11),
(596, 87, 'Practice guitar', 'pending', 'medium', 'Passion Hobbies', 21, 24),
(597, 87, 'Eat a healthy breakfast', 'pending', 'medium', 'Physical Health', 15, 36),
(598, 87, 'Eat a healthy breakfast', 'pending', 'easy', 'Physical Health', 7, 22),
(599, 87, 'Practice yoga', 'pending', 'easy', 'Physical Health', 11, 50),
(600, 88, 'Practice public speaking', 'pending', 'easy', 'Personal Growth', 25, 46),
(601, 88, 'Track expenses', 'completed', 'easy', 'Finance', 18, 26),
(602, 88, 'Practice interview skills', 'pending', 'easy', 'Career / Studies', 6, 48),
(603, 88, 'Practice interview skills', 'pending', 'hard', 'Career / Studies', 22, 16),
(604, 88, 'Meditate for 10 minutes', 'pending', 'medium', 'Mental Wellness', 12, 33),
(605, 89, 'Take online course', 'completed', 'hard', 'Career / Studies', 8, 37),
(606, 89, 'Practice guitar', 'pending', 'easy', 'Passion Hobbies', 13, 17),
(607, 89, 'Meal prep', 'pending', 'medium', 'Home Environment', 21, 41),
(608, 89, 'Learn about finances', 'completed', 'easy', 'Finance', 19, 31),
(609, 90, 'Listen to calming music', 'completed', 'easy', 'Mental Wellness', 20, 38),
(610, 90, 'Take a mental health break', 'pending', 'medium', 'Mental Wellness', 14, 22),
(611, 90, 'Practice active listening', 'completed', 'medium', 'Relationships Social', 10, 12),
(612, 91, 'Do brain exercises', 'pending', 'medium', 'Mental Wellness', 9, 23),
(613, 91, 'Spend time with family', 'completed', 'hard', 'Relationships Social', 12, 14),
(614, 91, 'Eat a healthy breakfast', 'pending', 'medium', 'Physical Health', 16, 43),
(615, 91, 'Set daily goals', 'pending', 'hard', 'Personal Growth', 19, 23),
(616, 91, 'Read for 30 minutes', 'pending', 'medium', 'Mental Wellness', 14, 10),
(617, 91, 'Stretch for 10 minutes', 'pending', 'hard', 'Physical Health', 25, 17),
(618, 91, 'Make new connections', 'pending', 'hard', 'Relationships Social', 11, 13),
(619, 92, 'Do laundry', 'pending', 'medium', 'Home Environment', 22, 45),
(620, 92, 'Go for a 30-minute walk', 'pending', 'easy', 'Physical Health', 7, 44),
(621, 92, 'Work on portfolio', 'pending', 'medium', 'Career / Studies', 19, 11),
(622, 92, 'Track expenses', 'completed', 'medium', 'Finance', 11, 27),
(623, 92, 'Save money', 'pending', 'hard', 'Finance', 18, 16),
(624, 93, 'Plan future goals', 'pending', 'medium', 'Personal Growth', 15, 17),
(625, 93, 'Practice active listening', 'pending', 'medium', 'Relationships Social', 21, 23),
(626, 93, 'Spend time with family', 'pending', 'hard', 'Relationships Social', 13, 33),
(627, 93, 'Update resume', 'pending', 'hard', 'Career / Studies', 6, 48),
(628, 93, 'Study programming', 'pending', 'easy', 'Career / Studies', 10, 47),
(629, 93, 'Meditate for 10 minutes', 'pending', 'medium', 'Mental Wellness', 6, 49),
(630, 93, 'Practice coding', 'pending', 'hard', 'Career / Studies', 13, 22),
(631, 94, 'Write gratitude list', 'pending', 'easy', 'Mental Wellness', 12, 39),
(632, 94, 'Study programming', 'pending', 'easy', 'Career / Studies', 24, 36),
(633, 94, 'Meditate for 10 minutes', 'pending', 'easy', 'Mental Wellness', 24, 38),
(634, 95, 'Play board games', 'completed', 'hard', 'Passion Hobbies', 25, 11),
(635, 95, 'Plan future goals', 'pending', 'easy', 'Personal Growth', 7, 40),
(636, 95, 'Spend time with family', 'pending', 'medium', 'Relationships Social', 9, 49),
(637, 95, 'Stretch for 10 minutes', 'pending', 'easy', 'Physical Health', 6, 40),
(638, 95, 'Learn new hobby', 'pending', 'easy', 'Passion Hobbies', 8, 10),
(639, 95, 'Drink 8 glasses of water', 'pending', 'hard', 'Physical Health', 11, 36),
(640, 95, 'Track expenses', 'pending', 'medium', 'Finance', 20, 42),
(641, 96, 'Work on portfolio', 'pending', 'medium', 'Career / Studies', 23, 43),
(642, 96, 'Meal prep', 'pending', 'hard', 'Home Environment', 14, 43),
(643, 96, 'Meditate for 10 minutes', 'pending', 'hard', 'Mental Wellness', 12, 14),
(644, 96, 'Track expenses', 'completed', 'medium', 'Finance', 20, 49),
(645, 96, 'Reflect on progress', 'completed', 'medium', 'Personal Growth', 25, 48),
(646, 96, 'Reflect on progress', 'completed', 'hard', 'Personal Growth', 7, 17),
(647, 96, 'Network with professionals', 'pending', 'hard', 'Career / Studies', 16, 36),
(648, 97, 'Save money', 'pending', 'easy', 'Finance', 9, 10),
(649, 97, 'Write gratitude list', 'pending', 'medium', 'Mental Wellness', 25, 19),
(650, 97, 'Research investments', 'pending', 'hard', 'Finance', 7, 30),
(651, 98, 'Cook new recipe', 'pending', 'hard', 'Passion Hobbies', 6, 22),
(652, 98, 'Save money', 'pending', 'hard', 'Finance', 20, 39),
(653, 98, 'Practice mindfulness', 'completed', 'hard', 'Mental Wellness', 20, 26),
(654, 98, 'Go for a 30-minute walk', 'pending', 'easy', 'Physical Health', 7, 38);
INSERT INTO `tasks` (`id`, `user_id`, `title`, `status`, `difficulty`, `category`, `coins`, `xp`) VALUES
(655, 98, 'Clean living space', 'pending', 'medium', 'Home Environment', 13, 35),
(656, 98, 'Research investments', 'pending', 'medium', 'Finance', 7, 41),
(657, 99, 'Update resume', 'pending', 'medium', 'Career / Studies', 5, 48),
(658, 99, 'Update resume', 'pending', 'easy', 'Career / Studies', 15, 20),
(659, 99, 'Learn about finances', 'pending', 'hard', 'Finance', 21, 35),
(660, 99, 'Clean living space', 'completed', 'easy', 'Home Environment', 14, 33),
(661, 100, 'Practice public speaking', 'pending', 'medium', 'Personal Growth', 11, 15),
(662, 100, 'Drink 8 glasses of water', 'pending', 'hard', 'Physical Health', 16, 13),
(663, 100, 'Review financial goals', 'pending', 'hard', 'Finance', 13, 46),
(664, 100, 'Do brain exercises', 'pending', 'easy', 'Mental Wellness', 7, 44),
(665, 100, 'Meditate for 10 minutes', 'completed', 'hard', 'Mental Wellness', 22, 11),
(666, 100, 'Declutter room', 'completed', 'medium', 'Home Environment', 10, 26),
(667, 100, 'Work on art project', 'pending', 'easy', 'Passion Hobbies', 22, 45),
(668, 102, 'repokls', 'completed', 'easy', 'Physical Health', 5, 10);

--
-- Triggers `tasks`
--
DELIMITER $$
CREATE TRIGGER `after_task_completion` AFTER UPDATE ON `tasks` FOR EACH ROW BEGIN 
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
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
                'task_id', NEW.id,
                'title', NEW.title,
                'difficulty', NEW.difficulty,
                'category', NEW.category,
                'xp', NEW.xp,
                'coins', NEW.coins
            ),
            NOW()
        );
        
        UPDATE users
        SET coins = coins + NEW.coins
        WHERE id = NEW.user_id;
        
        UPDATE userstats
        SET xp = xp + NEW.xp
        WHERE user_id = NEW.user_id;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `test_data`
--

CREATE TABLE `test_data` (
  `id` int NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `value` int DEFAULT NULL,
  `created_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

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
  `role` enum('admin','user') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'user',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `coins` int DEFAULT '0',
  `character_created` tinyint(1) DEFAULT '0' COMMENT 'Tracks if character setup is complete',
  `email_notifications` tinyint(1) DEFAULT '1',
  `task_reminders` tinyint(1) DEFAULT '1',
  `achievement_alerts` tinyint(1) DEFAULT '1',
  `theme` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'light',
  `color_scheme` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'default'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `email`, `username`, `password`, `name`, `role`, `created_at`, `updated_at`, `coins`, `character_created`, `email_notifications`, `task_reminders`, `achievement_alerts`, `theme`, `color_scheme`) VALUES
(1, 'amy.rodriguez59@hotmail.com', 'amyrodriguez990', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Amy Rodriguez', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 78, 1, 1, 1, 1, 'light', 'default'),
(2, 'ryan.wright57@gmail.com', 'ryanwright399', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Ryan Wright', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 44, 1, 1, 1, 1, 'light', 'default'),
(3, 'shirley.parker84@hotmail.com', 'shirleyparker205', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Shirley Parker', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 40, 1, 1, 1, 1, 'light', 'default'),
(4, 'brian.morris78@gmail.com', 'brianmorris172', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Brian Morris', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 15, 1, 1, 1, 1, 'light', 'default'),
(5, 'mark.williams76@example.com', 'markwilliams537', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Mark Williams', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 16, 1, 1, 1, 1, 'light', 'default'),
(6, 'tyler.moore35@hotmail.com', 'tylermoore113', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Tyler Moore', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 9, 1, 1, 1, 1, 'light', 'default'),
(7, 'brandon.rivera72@test.com', 'brandonrivera149', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Brandon Rivera', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 17, 1, 1, 1, 1, 'light', 'default'),
(8, 'sandra.cooper36@outlook.com', 'sandracooper172', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Sandra Cooper', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 17, 1, 1, 1, 1, 'light', 'default'),
(9, 'jacob.flores59@test.com', 'jacobflores413', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Jacob Flores', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 20, 1, 1, 1, 1, 'light', 'default'),
(10, 'jerry.baker92@test.com', 'jerrybaker552', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Jerry Baker', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 87, 1, 1, 1, 1, 'light', 'default'),
(11, 'paul.evans16@yahoo.com', 'paulevans601', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Paul Evans', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 85, 1, 1, 1, 1, 'light', 'default'),
(12, 'laura.lewis49@outlook.com', 'lauralewis936', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Laura Lewis', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 83, 1, 1, 1, 1, 'light', 'default'),
(13, 'jeffrey.reyes67@hotmail.com', 'jeffreyreyes539', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Jeffrey Reyes', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 97, 1, 1, 1, 1, 'light', 'default'),
(14, 'george.sanchez69@test.com', 'georgesanchez697', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'George Sanchez', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 77, 1, 1, 1, 1, 'light', 'default'),
(15, 'kevin.sanchez88@yahoo.com', 'kevinsanchez147', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Kevin Sanchez', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 49, 1, 1, 1, 1, 'light', 'default'),
(16, 'joseph.gray38@hotmail.com', 'josephgray499', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Joseph Gray', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 36, 1, 1, 1, 1, 'light', 'default'),
(17, 'betty.green27@hotmail.com', 'bettygreen787', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Betty Green', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 31, 1, 1, 1, 1, 'light', 'default'),
(18, 'carol.garcia32@hotmail.com', 'carolgarcia269', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Carol Garcia', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 7, 1, 1, 1, 1, 'light', 'default'),
(19, 'kenneth.cruz71@example.com', 'kennethcruz831', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Kenneth Cruz', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 3, 1, 1, 1, 1, 'light', 'default'),
(20, 'thomas.wilson49@hotmail.com', 'thomaswilson730', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Thomas Wilson', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 70, 1, 1, 1, 1, 'light', 'default'),
(21, 'jacob.lewis69@yahoo.com', 'jacoblewis837', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Jacob Lewis', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 65, 1, 1, 1, 1, 'light', 'default'),
(22, 'ruth.thompson70@gmail.com', 'ruththompson298', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Ruth Thompson', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 45, 1, 1, 1, 1, 'light', 'default'),
(23, 'sharon.thomas30@yahoo.com', 'sharonthomas133', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Sharon Thomas', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 43, 1, 1, 1, 1, 'light', 'default'),
(24, 'nicholas.williams96@test.com', 'nicholaswilliams297', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Nicholas Williams', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 34, 1, 1, 1, 1, 'light', 'default'),
(25, 'kimberly.cruz60@example.com', 'kimberlycruz609', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Kimberly Cruz', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 71, 1, 1, 1, 1, 'light', 'default'),
(26, 'tyler.martinez94@yahoo.com', 'tylermartinez274', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Tyler Martinez', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 40, 1, 1, 1, 1, 'light', 'default'),
(27, 'ruth.rivera27@yahoo.com', 'ruthrivera443', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Ruth Rivera', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 55, 1, 1, 1, 1, 'light', 'default'),
(28, 'timothy.campbell13@yahoo.com', 'timothycampbell309', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Timothy Campbell', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 8, 1, 1, 1, 1, 'light', 'default'),
(29, 'katherine.rogers21@test.com', 'katherinerogers870', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Katherine Rogers', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 58, 1, 1, 1, 1, 'light', 'default'),
(30, 'melissa.lopez38@outlook.com', 'melissalopez585', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Melissa Lopez', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 17, 1, 1, 1, 1, 'light', 'default'),
(31, 'donna.phillips45@yahoo.com', 'donnaphillips153', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Donna Phillips', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 40, 1, 1, 1, 1, 'light', 'default'),
(32, 'sarah.morris75@outlook.com', 'sarahmorris217', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Sarah Morris', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 38, 1, 1, 1, 1, 'light', 'default'),
(33, 'edward.ramirez42@example.com', 'edwardramirez722', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Edward Ramirez', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 93, 1, 1, 1, 1, 'light', 'default'),
(34, 'donna.smith99@yahoo.com', 'donnasmith974', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Donna Smith', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 39, 1, 1, 1, 1, 'light', 'default'),
(35, 'joshua.morris11@hotmail.com', 'joshuamorris773', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Joshua Morris', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 75, 1, 1, 1, 1, 'light', 'default'),
(36, 'katherine.cox92@example.com', 'katherinecox560', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Katherine Cox', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 24, 1, 1, 1, 1, 'light', 'default'),
(37, 'nicholas.kim20@example.com', 'nicholaskim948', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Nicholas Kim', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 79, 1, 1, 1, 1, 'light', 'default'),
(38, 'lisa.brown91@gmail.com', 'lisabrown139', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Lisa Brown', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 10, 1, 1, 1, 1, 'light', 'default'),
(39, 'eric.davis86@hotmail.com', 'ericdavis819', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Eric Davis', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 58, 1, 1, 1, 1, 'light', 'default'),
(40, 'jerry.roberts49@gmail.com', 'jerryroberts921', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Jerry Roberts', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 53, 1, 1, 1, 1, 'light', 'default'),
(41, 'jessica.stewart72@gmail.com', 'jessicastewart640', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Jessica Stewart', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 61, 1, 1, 1, 1, 'light', 'default'),
(42, 'david.carter30@gmail.com', 'davidcarter446', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'David Carter', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 97, 1, 1, 1, 1, 'light', 'default'),
(43, 'donna.cruz22@yahoo.com', 'donnacruz471', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Donna Cruz', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 43, 1, 1, 1, 1, 'light', 'default'),
(44, 'paul.ramos20@test.com', 'paulramos342', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Paul Ramos', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 31, 1, 1, 1, 1, 'light', 'default'),
(45, 'steven.adams15@outlook.com', 'stevenadams106', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Steven Adams', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 29, 1, 1, 1, 1, 'light', 'default'),
(46, 'carol.thomas18@gmail.com', 'carolthomas215', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Carol Thomas', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 86, 1, 1, 1, 1, 'light', 'default'),
(47, 'ryan.white21@hotmail.com', 'ryanwhite194', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Ryan White', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 16, 1, 1, 1, 1, 'light', 'default'),
(48, 'anthony.smith31@test.com', 'anthonysmith384', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Anthony Smith', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 54, 1, 1, 1, 1, 'light', 'default'),
(49, 'ryan.lewis17@test.com', 'ryanlewis796', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Ryan Lewis', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 71, 1, 1, 1, 1, 'light', 'default'),
(50, 'justin.richardson61@hotmail.com', 'justinrichardson963', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Justin Richardson', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 79, 1, 1, 1, 1, 'light', 'default'),
(51, 'nancy.taylor79@yahoo.com', 'nancytaylor535', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Nancy Taylor', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 12, 1, 1, 1, 1, 'light', 'default'),
(52, 'sarah.moore86@hotmail.com', 'sarahmoore968', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Sarah Moore', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 29, 1, 1, 1, 1, 'light', 'default'),
(53, 'carol.cruz80@example.com', 'carolcruz596', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Carol Cruz', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 88, 1, 1, 1, 1, 'light', 'default'),
(54, 'jacob.phillips54@outlook.com', 'jacobphillips864', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Jacob Phillips', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 17, 1, 1, 1, 1, 'light', 'default'),
(55, 'daniel.allen17@outlook.com', 'danielallen383', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Daniel Allen', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 3, 1, 1, 1, 1, 'light', 'default'),
(56, 'brandon.kim50@test.com', 'brandonkim936', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Brandon Kim', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 15, 1, 1, 1, 1, 'light', 'default'),
(57, 'justin.rivera19@outlook.com', 'justinrivera565', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Justin Rivera', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 74, 1, 1, 1, 1, 'light', 'default'),
(58, 'helen.richardson56@hotmail.com', 'helenrichardson949', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Helen Richardson', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 28, 1, 1, 1, 1, 'light', 'default'),
(59, 'richard.jackson70@test.com', 'richardjackson947', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Richard Jackson', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 38, 1, 1, 1, 1, 'light', 'default'),
(60, 'karen.perez14@example.com', 'karenperez563', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Karen Perez', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 27, 1, 1, 1, 1, 'light', 'default'),
(61, 'kimberly.roberts68@outlook.com', 'kimberlyroberts751', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Kimberly Roberts', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 49, 1, 1, 1, 1, 'light', 'default'),
(62, 'lisa.stewart79@test.com', 'lisastewart366', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Lisa Stewart', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 36, 1, 1, 1, 1, 'light', 'default'),
(63, 'linda.phillips46@outlook.com', 'lindaphillips762', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Linda Phillips', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 65, 1, 1, 1, 1, 'light', 'default'),
(64, 'carol.king82@test.com', 'carolking584', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Carol King', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 56, 1, 1, 1, 1, 'light', 'default'),
(65, 'betty.lee75@test.com', 'bettylee759', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Betty Lee', 'user', '2025-05-27 00:03:14', '2025-05-27 00:03:14', 63, 1, 1, 1, 1, 'light', 'default'),
(66, 'anna.watson82@gmail.com', 'annawatson386', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Anna Watson', 'user', '2025-05-27 00:03:15', '2025-05-27 00:03:15', 34, 1, 1, 1, 1, 'light', 'default'),
(67, 'brandon.rogers11@test.com', 'brandonrogers224', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Brandon Rogers', 'user', '2025-05-27 00:03:15', '2025-05-27 00:03:15', 53, 1, 1, 1, 1, 'light', 'default'),
(68, 'nicholas.jackson84@yahoo.com', 'nicholasjackson398', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Nicholas Jackson', 'user', '2025-05-27 00:03:15', '2025-05-27 00:03:15', 47, 1, 1, 1, 1, 'light', 'default'),
(69, 'michael.ramos40@outlook.com', 'michaelramos548', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Michael Ramos', 'user', '2025-05-27 00:03:15', '2025-05-27 00:03:15', 12, 1, 1, 1, 1, 'light', 'default'),
(70, 'helen.thompson42@test.com', 'helenthompson249', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Helen Thompson', 'user', '2025-05-27 00:03:15', '2025-05-27 00:03:15', 35, 1, 1, 1, 1, 'light', 'default'),
(71, 'sharon.young43@gmail.com', 'sharonyoung104', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Sharon Young', 'user', '2025-05-27 00:03:15', '2025-05-27 00:03:15', 51, 1, 1, 1, 1, 'light', 'default'),
(72, 'karen.white54@test.com', 'karenwhite555', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Karen White', 'user', '2025-05-27 00:03:15', '2025-05-27 00:03:15', 50, 1, 1, 1, 1, 'light', 'default'),
(73, 'donald.stewart90@hotmail.com', 'donaldstewart601', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Donald Stewart', 'user', '2025-05-27 00:03:15', '2025-05-27 00:03:15', 15, 1, 1, 1, 1, 'light', 'default'),
(74, 'daniel.rivera11@test.com', 'danielrivera105', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Daniel Rivera', 'user', '2025-05-27 00:03:15', '2025-05-27 00:03:15', 5, 1, 1, 1, 1, 'light', 'default'),
(75, 'james.chavez91@test.com', 'jameschavez160', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'James Chavez', 'user', '2025-05-27 00:03:15', '2025-05-27 00:03:15', 50, 1, 1, 1, 1, 'light', 'default'),
(76, 'gary.torres87@outlook.com', 'garytorres594', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Gary Torres', 'user', '2025-05-27 00:03:15', '2025-05-27 00:03:15', 96, 1, 1, 1, 1, 'light', 'default'),
(77, 'stephen.king71@hotmail.com', 'stephenking722', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Stephen King', 'user', '2025-05-27 00:03:15', '2025-05-27 00:03:15', 41, 1, 1, 1, 1, 'light', 'default'),
(78, 'nancy.reyes77@example.com', 'nancyreyes919', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Nancy Reyes', 'user', '2025-05-27 00:03:15', '2025-05-27 00:03:15', 67, 1, 1, 1, 1, 'light', 'default'),
(79, 'angela.evans20@gmail.com', 'angelaevans459', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Angela Evans', 'user', '2025-05-27 00:03:15', '2025-05-27 00:03:15', 89, 1, 1, 1, 1, 'light', 'default'),
(80, 'laura.nguyen42@hotmail.com', 'lauranguyen134', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Laura Nguyen', 'user', '2025-05-27 00:03:15', '2025-05-27 00:03:15', 42, 1, 1, 1, 1, 'light', 'default'),
(81, 'james.kelly91@yahoo.com', 'jameskelly476', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'James Kelly', 'user', '2025-05-27 00:03:15', '2025-05-27 00:03:15', 99, 1, 1, 1, 1, 'light', 'default'),
(82, 'gary.phillips25@yahoo.com', 'garyphillips875', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Gary Phillips', 'user', '2025-05-27 00:03:15', '2025-05-27 00:03:15', 87, 1, 1, 1, 1, 'light', 'default'),
(83, 'betty.carter16@gmail.com', 'bettycarter640', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Betty Carter', 'user', '2025-05-27 00:03:15', '2025-05-27 00:03:15', 63, 1, 1, 1, 1, 'light', 'default'),
(84, 'brandon.lopez75@outlook.com', 'brandonlopez850', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Brandon Lopez', 'user', '2025-05-27 00:03:15', '2025-05-27 00:03:15', 1, 1, 1, 1, 1, 'light', 'default'),
(85, 'brian.rodriguez54@yahoo.com', 'brianrodriguez287', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Brian Rodriguez', 'user', '2025-05-27 00:03:15', '2025-05-27 00:03:15', 16, 1, 1, 1, 1, 'light', 'default'),
(86, 'paul.cox99@hotmail.com', 'paulcox263', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Paul Cox', 'user', '2025-05-27 00:03:15', '2025-05-27 00:03:15', 61, 1, 1, 1, 1, 'light', 'default'),
(87, 'helen.wood28@gmail.com', 'helenwood976', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Helen Wood', 'user', '2025-05-27 00:03:15', '2025-05-27 00:03:15', 25, 1, 1, 1, 1, 'light', 'default'),
(88, 'donna.cook23@test.com', 'donnacook460', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Donna Cook', 'user', '2025-05-27 00:03:15', '2025-05-27 00:03:15', 49, 1, 1, 1, 1, 'light', 'default'),
(89, 'ruth.brown63@outlook.com', 'ruthbrown648', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Ruth Brown', 'user', '2025-05-27 00:03:15', '2025-05-27 00:03:15', 80, 1, 1, 1, 1, 'light', 'default'),
(90, 'dorothy.nguyen25@gmail.com', 'dorothynguyen163', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Dorothy Nguyen', 'user', '2025-05-27 00:03:15', '2025-05-27 00:03:15', 17, 1, 1, 1, 1, 'light', 'default'),
(91, 'deborah.miller93@hotmail.com', 'deborahmiller906', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Deborah Miller', 'user', '2025-05-27 00:03:15', '2025-05-27 00:03:15', 88, 1, 1, 1, 1, 'light', 'default'),
(92, 'donald.ortiz49@yahoo.com', 'donaldortiz310', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Donald Ortiz', 'user', '2025-05-27 00:03:15', '2025-05-27 00:03:15', 4, 1, 1, 1, 1, 'light', 'default'),
(93, 'richard.brown88@hotmail.com', 'richardbrown681', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Richard Brown', 'user', '2025-05-27 00:03:15', '2025-05-27 00:03:15', 54, 1, 1, 1, 1, 'light', 'default'),
(94, 'stephen.gonzalez42@outlook.com', 'stephengonzalez289', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Stephen Gonzalez', 'user', '2025-05-27 00:03:15', '2025-05-27 00:03:15', 88, 1, 1, 1, 1, 'light', 'default'),
(95, 'steven.kelly75@outlook.com', 'stevenkelly495', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Steven Kelly', 'user', '2025-05-27 00:03:15', '2025-05-27 00:03:15', 72, 1, 1, 1, 1, 'light', 'default'),
(96, 'anna.ramirez65@gmail.com', 'annaramirez895', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Anna Ramirez', 'user', '2025-05-27 00:03:15', '2025-05-27 00:03:15', 90, 1, 1, 1, 1, 'light', 'default'),
(97, 'jack.jackson67@gmail.com', 'jackjackson749', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Jack Jackson', 'user', '2025-05-27 00:03:15', '2025-05-27 00:03:15', 87, 1, 1, 1, 1, 'light', 'default'),
(98, 'kevin.wilson45@hotmail.com', 'kevinwilson509', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Kevin Wilson', 'user', '2025-05-27 00:03:15', '2025-05-27 00:03:15', 47, 1, 1, 1, 1, 'light', 'default'),
(99, 'sarah.cook42@yahoo.com', 'sarahcook531', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Sarah Cook', 'user', '2025-05-27 00:03:15', '2025-05-27 00:03:15', 1, 1, 1, 1, 1, 'light', 'default'),
(100, 'donald.white72@gmail.com', 'donaldwhite750', '$2y$12$/AVq4r6T/vLAaNQGq131KOo8iUYKfpjKWTk9gfYw/LxnjrizuXVP6', 'Donald White', 'user', '2025-05-27 00:03:15', '2025-05-27 00:03:15', 20, 1, 1, 1, 1, 'light', 'default'),
(101, 'admin@test.com', 'admin', '$2y$12$b3FbVOSA17qfC38/e631A.sBQ3CeLw2xZukeYCUsTg2GELdh6CRP2', 'admin', 'admin', '2025-05-27 00:38:31', '2025-05-27 00:39:35', 0, 0, 1, 1, 1, 'light', 'default'),
(102, 'sean@test.com', 'cshan', '$2y$12$TZxzRTIzAqifL9.ntOX0N.oSgY1izczZWiFl4bUJ4fIILDBHyS/Mu', 'sean agustine lumandong esparagoza', 'user', '2025-05-27 00:42:02', '2025-05-28 02:51:36', 5, 0, 1, 1, 1, 'light', 'default');

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `userstats`
--

INSERT INTO `userstats` (`id`, `user_id`, `level`, `xp`, `health`, `avatar_id`, `objective`, `physicalHealth`, `mentalWellness`, `personalGrowth`, `careerStudies`, `finance`, `homeEnvironment`, `relationshipsSocial`, `passionHobbies`) VALUES
(1, 1, 1, 37, 100, 2, 'Master cooking skills', 10, 25, 27, 12, 6, 21, 18, 19),
(2, 2, 1, 5, 100, 2, 'Start a YouTube channel', 17, 17, 11, 20, 21, 29, 5, 22),
(3, 3, 1, 117, 100, 4, 'Contribute to open source projects', 25, 14, 29, 7, 26, 26, 18, 14),
(4, 4, 1, 85, 100, 4, 'Run a marathon', 11, 23, 6, 9, 32, 27, 20, 25),
(5, 5, 1, 32, 100, 2, 'Build meaningful relationships', 9, 26, 26, 23, 31, 5, 17, 20),
(6, 6, 1, 179, 100, 3, 'Start my own business', 7, 28, 14, 16, 23, 24, 21, 29),
(7, 7, 1, 159, 100, 3, 'Learn to code and become a software developer', 14, 29, 31, 24, 16, 28, 32, 33),
(8, 8, 1, 34, 100, 2, 'Read 50 books this year', 6, 22, 28, 7, 14, 30, 27, 30),
(9, 9, 1, 83, 100, 1, 'Build a mobile app', 33, 5, 12, 16, 7, 21, 19, 23),
(10, 10, 1, 61, 100, 2, 'Run a marathon', 29, 21, 22, 22, 21, 14, 24, 11),
(11, 11, 1, 151, 100, 4, 'Learn to play guitar', 21, 28, 16, 24, 32, 11, 31, 21),
(12, 12, 1, 20, 100, 2, 'Become financially independent', 25, 28, 7, 23, 31, 22, 17, 16),
(13, 13, 1, 39, 100, 3, 'Master time management', 9, 7, 19, 32, 28, 6, 21, 16),
(14, 14, 1, 40, 100, 1, 'Improve work-life balance', 13, 6, 11, 7, 26, 22, 12, 31),
(15, 15, 1, 193, 100, 2, 'Save $10,000 for emergency fund', 32, 27, 23, 13, 29, 15, 7, 31),
(16, 16, 1, 125, 100, 4, 'Become financially independent', 27, 7, 21, 16, 32, 24, 12, 20),
(17, 17, 1, 200, 100, 1, 'Start a YouTube channel', 33, 19, 33, 10, 22, 26, 24, 11),
(18, 18, 1, 146, 100, 2, 'Master a new language fluently', 12, 21, 24, 9, 20, 8, 25, 22),
(19, 19, 1, 33, 100, 1, 'Write a novel', 31, 19, 13, 15, 33, 33, 22, 32),
(20, 20, 1, 20, 100, 1, 'Read 50 books this year', 32, 17, 28, 27, 31, 33, 13, 25),
(21, 21, 1, 123, 100, 3, 'Learn digital marketing', 16, 32, 19, 11, 18, 29, 11, 5),
(22, 22, 1, 80, 100, 1, 'Become financially independent', 8, 22, 8, 24, 16, 26, 8, 33),
(23, 23, 1, 115, 100, 3, 'Master cooking skills', 26, 10, 23, 33, 10, 5, 23, 30),
(24, 24, 1, 67, 100, 4, 'Build meaningful relationships', 6, 20, 21, 23, 5, 33, 20, 32),
(25, 25, 1, 28, 100, 3, 'Learn photography', 31, 7, 19, 20, 7, 27, 5, 13),
(26, 26, 1, 0, 100, 2, 'Master cooking skills', 13, 27, 14, 29, 7, 6, 27, 25),
(27, 27, 1, 116, 100, 4, 'Improve mental health and mindfulness', 25, 27, 29, 18, 23, 19, 33, 21),
(28, 28, 1, 114, 100, 2, 'Master cooking skills', 26, 21, 15, 17, 6, 28, 22, 5),
(29, 29, 1, 128, 100, 4, 'Master a new language fluently', 27, 18, 13, 25, 26, 22, 17, 26),
(30, 30, 1, 20, 100, 1, 'Improve work-life balance', 18, 19, 17, 7, 30, 23, 9, 5),
(31, 31, 1, 134, 100, 2, 'Build meaningful relationships', 22, 20, 28, 27, 16, 21, 29, 23),
(32, 32, 1, 88, 100, 4, 'Build a mobile app', 17, 19, 21, 21, 17, 16, 14, 25),
(33, 33, 1, 26, 100, 3, 'Learn photography', 26, 15, 15, 6, 15, 21, 6, 16),
(34, 34, 1, 93, 100, 2, 'Improve work-life balance', 15, 10, 29, 8, 30, 7, 6, 19),
(35, 35, 1, 56, 100, 4, 'Travel to 10 different countries', 31, 9, 23, 18, 23, 16, 32, 7),
(36, 36, 1, 96, 100, 3, 'Learn data science and machine learning', 14, 23, 31, 6, 12, 27, 12, 7),
(37, 37, 1, 108, 100, 3, 'Improve work-life balance', 31, 10, 21, 12, 16, 13, 20, 32),
(38, 38, 1, 2, 100, 3, 'Run a marathon', 12, 28, 11, 23, 29, 8, 14, 9),
(39, 39, 1, 112, 100, 2, 'Read 50 books this year', 22, 13, 18, 24, 32, 7, 24, 20),
(40, 40, 1, 84, 100, 4, 'Improve mental health and mindfulness', 31, 9, 29, 11, 32, 13, 7, 10),
(41, 41, 1, 27, 100, 2, 'Read 50 books this year', 5, 31, 21, 10, 25, 13, 24, 26),
(42, 42, 1, 56, 100, 3, 'Learn data science and machine learning', 27, 24, 22, 6, 19, 12, 11, 12),
(43, 43, 1, 57, 100, 1, 'Save $10,000 for emergency fund', 12, 7, 22, 8, 8, 30, 5, 19),
(44, 44, 1, 19, 100, 1, 'Complete a degree', 33, 33, 24, 25, 18, 26, 15, 11),
(45, 45, 1, 70, 100, 1, 'Start a YouTube channel', 27, 33, 20, 17, 24, 15, 18, 18),
(46, 46, 1, 16, 100, 4, 'Master time management', 33, 25, 32, 8, 22, 16, 24, 24),
(47, 47, 1, 111, 100, 1, 'Contribute to open source projects', 20, 7, 14, 9, 25, 22, 22, 12),
(48, 48, 1, 124, 100, 2, 'Learn to code and become a software developer', 27, 27, 29, 14, 23, 11, 20, 30),
(49, 49, 1, 30, 100, 4, 'Become a better leader', 13, 26, 7, 5, 12, 14, 7, 30),
(50, 50, 1, 106, 100, 4, 'Become financially independent', 11, 25, 25, 28, 26, 22, 5, 23),
(51, 51, 1, 113, 100, 2, 'Become a better leader', 22, 13, 15, 17, 7, 23, 12, 20),
(52, 52, 1, 139, 100, 2, 'Learn photography', 12, 14, 23, 31, 26, 15, 5, 28),
(53, 53, 1, 36, 100, 2, 'Run a marathon', 25, 20, 18, 12, 31, 19, 22, 25),
(54, 54, 1, 51, 100, 4, 'Master cooking skills', 29, 8, 12, 12, 26, 33, 10, 20),
(55, 55, 1, 67, 100, 2, 'Build a mobile app', 18, 24, 8, 31, 17, 17, 15, 14),
(56, 56, 1, 5, 100, 3, 'Write a novel', 23, 31, 14, 12, 18, 8, 5, 5),
(57, 57, 1, 38, 100, 3, 'Build a mobile app', 5, 19, 16, 25, 27, 21, 24, 15),
(58, 58, 1, 129, 100, 2, 'Master cooking skills', 32, 27, 32, 6, 5, 13, 31, 24),
(59, 59, 1, 39, 100, 4, 'Write a novel', 13, 24, 6, 25, 19, 18, 7, 25),
(60, 60, 1, 44, 100, 2, 'Improve mental health and mindfulness', 31, 23, 32, 23, 26, 18, 23, 15),
(61, 61, 1, 99, 100, 2, 'Start my own business', 6, 7, 11, 5, 7, 21, 5, 33),
(62, 62, 1, 97, 100, 4, 'Read 50 books this year', 26, 22, 31, 9, 9, 18, 31, 24),
(63, 63, 1, 69, 100, 1, 'Build meaningful relationships', 9, 15, 5, 8, 18, 6, 22, 26),
(64, 64, 1, 173, 100, 1, 'Master time management', 28, 22, 18, 6, 22, 11, 29, 6),
(65, 65, 1, 178, 100, 1, 'Run a marathon', 27, 6, 7, 32, 25, 22, 26, 12),
(66, 66, 1, 188, 100, 2, 'Complete a degree', 19, 15, 30, 14, 32, 13, 24, 18),
(67, 67, 1, 80, 100, 1, 'Become a better leader', 17, 13, 23, 24, 26, 26, 20, 9),
(68, 68, 1, 82, 100, 1, 'Travel to 10 different countries', 31, 13, 22, 15, 15, 11, 10, 6),
(69, 69, 1, 190, 100, 2, 'Improve my public speaking skills', 25, 23, 26, 29, 20, 5, 20, 26),
(70, 70, 1, 128, 100, 1, 'Improve mental health and mindfulness', 27, 18, 29, 32, 18, 27, 6, 10),
(71, 71, 1, 120, 100, 3, 'Master time management', 15, 15, 17, 9, 16, 21, 7, 31),
(72, 72, 1, 183, 100, 2, 'Improve work-life balance', 20, 11, 15, 21, 26, 14, 25, 26),
(73, 73, 1, 36, 100, 1, 'Start my own business', 29, 5, 10, 9, 16, 22, 15, 14),
(74, 74, 1, 108, 100, 4, 'Master time management', 26, 10, 12, 9, 19, 5, 21, 29),
(75, 75, 1, 114, 100, 2, 'Write a novel', 8, 25, 21, 22, 12, 26, 15, 29),
(76, 76, 1, 152, 100, 4, 'Become a better leader', 29, 31, 21, 19, 31, 18, 12, 19),
(77, 77, 1, 12, 100, 1, 'Complete a degree', 7, 13, 9, 15, 7, 22, 20, 24),
(78, 78, 1, 7, 100, 1, 'Complete a degree', 11, 28, 11, 10, 22, 21, 31, 5),
(79, 79, 1, 146, 100, 4, 'Travel to 10 different countries', 8, 6, 17, 16, 21, 31, 33, 33),
(80, 80, 1, 118, 100, 3, 'Master time management', 19, 31, 15, 8, 7, 12, 9, 10),
(81, 81, 1, 153, 100, 4, 'Write a novel', 18, 8, 26, 21, 12, 19, 5, 15),
(82, 82, 1, 47, 100, 2, 'Save $10,000 for emergency fund', 8, 17, 20, 5, 23, 31, 13, 12),
(83, 83, 1, 101, 100, 4, 'Build meaningful relationships', 17, 16, 32, 25, 12, 31, 15, 9),
(84, 84, 1, 111, 100, 3, 'Learn digital marketing', 22, 5, 12, 30, 13, 33, 32, 28),
(85, 85, 1, 67, 100, 3, 'Learn to play guitar', 27, 7, 25, 24, 17, 29, 22, 30),
(86, 86, 1, 178, 100, 4, 'Improve work-life balance', 31, 23, 9, 6, 7, 7, 10, 11),
(87, 87, 1, 50, 100, 4, 'Read 50 books this year', 9, 18, 26, 11, 24, 11, 5, 16),
(88, 88, 1, 106, 100, 3, 'Become financially independent', 28, 33, 16, 20, 20, 5, 18, 15),
(89, 89, 1, 14, 100, 3, 'Start a YouTube channel', 22, 26, 25, 18, 8, 18, 23, 6),
(90, 90, 1, 189, 100, 2, 'Save $10,000 for emergency fund', 11, 14, 18, 20, 8, 31, 21, 31),
(91, 91, 1, 155, 100, 3, 'Learn to play guitar', 14, 10, 18, 9, 11, 12, 28, 21),
(92, 92, 1, 122, 100, 3, 'Start a YouTube channel', 10, 8, 30, 19, 9, 12, 33, 19),
(93, 93, 1, 29, 100, 4, 'Build a mobile app', 13, 13, 12, 21, 25, 33, 33, 26),
(94, 94, 1, 166, 100, 4, 'Build meaningful relationships', 18, 20, 17, 27, 8, 17, 21, 33),
(95, 95, 1, 52, 100, 1, 'Master a new language fluently', 12, 32, 25, 7, 22, 16, 17, 15),
(96, 96, 1, 168, 100, 2, 'Become financially independent', 33, 18, 10, 14, 30, 33, 29, 25),
(97, 97, 1, 69, 100, 2, 'Learn data science and machine learning', 10, 24, 12, 12, 24, 29, 13, 11),
(98, 98, 1, 186, 100, 2, 'Start my own business', 19, 29, 13, 12, 6, 22, 28, 8),
(99, 99, 1, 1, 100, 2, 'Start a YouTube channel', 11, 26, 27, 30, 31, 11, 33, 30),
(100, 100, 1, 98, 100, 1, 'Contribute to open source projects', 24, 10, 28, 5, 16, 26, 33, 25),
(101, 101, 1, 0, 100, 1, 'admin', 5, 5, 5, 5, 5, 5, 5, 5),
(102, 102, 1, 70, 90, 4, 'Code for life', 8, 5, 5, 5, 5, 5, 5, 5);

-- --------------------------------------------------------

--
-- Table structure for table `user_active_boosts`
--

CREATE TABLE `user_active_boosts` (
  `boost_id` int NOT NULL,
  `user_id` int NOT NULL,
  `boost_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `boost_value` int NOT NULL,
  `activated_at` datetime NOT NULL,
  `expires_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `user_event`
--

CREATE TABLE `user_event` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `event_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `event_description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `start_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `end_date` timestamp NULL DEFAULT NULL,
  `reward_xp` int NOT NULL DEFAULT '0',
  `reward_coins` int NOT NULL DEFAULT '0',
  `status` enum('active','inactive') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `user_event`
--

INSERT INTO `user_event` (`id`, `user_id`, `event_name`, `event_description`, `start_date`, `end_date`, `reward_xp`, `reward_coins`, `status`, `created_at`, `updated_at`) VALUES
(4, 1, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-11 16:33:32', '2025-06-11 18:33:32', 39, 20, 'active', '2025-05-27 00:33:32', '2025-05-27 00:33:32'),
(5, 1, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-07-11 16:33:32', '2025-07-11 18:33:32', 43, 29, 'active', '2025-05-27 00:33:32', '2025-05-27 00:33:32'),
(6, 1, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-06-28 16:33:32', '2025-06-28 18:33:32', 19, 16, 'active', '2025-05-27 00:33:32', '2025-05-27 00:33:32'),
(7, 2, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-07-14 16:33:32', '2025-07-14 18:33:32', 16, 22, 'active', '2025-05-27 00:33:32', '2025-05-27 00:33:32'),
(8, 2, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-06-12 16:33:32', '2025-06-12 18:33:32', 38, 30, 'active', '2025-05-27 00:33:32', '2025-05-27 00:33:32'),
(9, 2, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-06-17 16:33:32', '2025-06-17 18:33:32', 36, 13, 'active', '2025-05-27 00:33:32', '2025-05-27 00:33:32'),
(10, 3, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-07-24 16:33:32', '2025-07-24 18:33:32', 41, 25, 'active', '2025-05-27 00:33:32', '2025-05-27 00:33:32'),
(11, 3, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-06-22 16:33:32', '2025-06-22 18:33:32', 39, 28, 'active', '2025-05-27 00:33:32', '2025-05-27 00:33:32'),
(12, 3, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-07-13 16:33:32', '2025-07-13 18:33:32', 25, 27, 'active', '2025-05-27 00:33:32', '2025-05-27 00:33:32'),
(13, 4, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-07-18 16:33:32', '2025-07-18 18:33:32', 37, 12, 'active', '2025-05-27 00:33:32', '2025-05-27 00:33:32'),
(14, 4, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-07-23 16:33:32', '2025-07-23 18:33:32', 25, 23, 'active', '2025-05-27 00:33:32', '2025-05-27 00:33:32'),
(15, 4, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-06-10 16:33:32', '2025-06-10 18:33:32', 22, 27, 'active', '2025-05-27 00:33:32', '2025-05-27 00:33:32'),
(16, 5, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-07-20 16:33:32', '2025-07-20 18:33:32', 30, 22, 'active', '2025-05-27 00:33:32', '2025-05-27 00:33:32'),
(17, 5, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-06-11 16:33:32', '2025-06-11 18:33:32', 29, 17, 'active', '2025-05-27 00:33:32', '2025-05-27 00:33:32'),
(18, 1, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-07-14 16:33:58', '2025-07-14 18:33:58', 24, 23, 'active', '2025-05-27 00:33:58', '2025-05-27 00:33:58'),
(19, 1, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-06-06 16:33:58', '2025-06-06 18:33:58', 24, 21, 'active', '2025-05-27 00:33:58', '2025-05-27 00:33:58'),
(20, 2, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-06-18 16:33:58', '2025-06-18 18:33:58', 23, 23, 'active', '2025-05-27 00:33:58', '2025-05-27 00:33:58'),
(21, 2, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-05-30 16:33:58', '2025-05-30 18:33:58', 50, 16, 'active', '2025-05-27 00:33:58', '2025-05-27 00:33:58'),
(22, 3, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-06-05 16:33:58', '2025-06-05 18:33:58', 27, 18, 'active', '2025-05-27 00:33:58', '2025-05-27 00:33:58'),
(23, 4, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-07-15 16:33:58', '2025-07-15 18:33:58', 17, 12, 'active', '2025-05-27 00:33:58', '2025-05-27 00:33:58'),
(24, 4, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-07-25 16:33:58', '2025-07-25 18:33:58', 44, 28, 'active', '2025-05-27 00:33:58', '2025-05-27 00:33:58'),
(25, 4, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-06-22 16:33:58', '2025-06-22 18:33:58', 40, 17, 'active', '2025-05-27 00:33:58', '2025-05-27 00:33:58'),
(26, 5, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-06-20 16:33:58', '2025-06-20 18:33:58', 20, 27, 'active', '2025-05-27 00:33:58', '2025-05-27 00:33:58'),
(27, 5, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-06-16 16:33:58', '2025-06-16 18:33:58', 17, 23, 'active', '2025-05-27 00:33:58', '2025-05-27 00:33:58'),
(28, 5, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-07-25 16:33:58', '2025-07-25 18:33:58', 47, 10, 'active', '2025-05-27 00:33:58', '2025-05-27 00:33:58'),
(29, 1, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-06-21 16:35:36', '2025-06-21 18:35:36', 29, 28, 'active', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(30, 1, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-07-22 16:35:36', '2025-07-22 18:35:36', 44, 27, 'active', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(31, 1, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-07-14 16:35:36', '2025-07-14 18:35:36', 21, 15, 'active', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(32, 2, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-14 16:35:36', '2025-06-14 18:35:36', 38, 17, 'active', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(33, 3, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-06-08 16:35:36', '2025-06-08 18:35:36', 30, 28, 'active', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(34, 3, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-19 16:35:36', '2025-06-19 18:35:36', 18, 17, 'active', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(35, 4, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-06-26 16:35:36', '2025-06-26 18:35:36', 23, 20, 'active', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(36, 5, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-06-16 16:35:36', '2025-06-16 18:35:36', 29, 19, 'active', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(37, 6, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-06-18 16:35:36', '2025-06-18 18:35:36', 22, 13, 'active', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(38, 6, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-07-15 16:35:36', '2025-07-15 18:35:36', 48, 24, 'active', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(39, 6, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-05-27 16:35:36', '2025-05-27 18:35:36', 50, 27, 'active', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(40, 7, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-23 16:35:36', '2025-06-23 18:35:36', 15, 22, 'active', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(41, 7, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-06-30 16:35:36', '2025-06-30 18:35:36', 38, 12, 'active', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(42, 8, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-06-21 16:35:36', '2025-06-21 18:35:36', 29, 16, 'active', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(43, 9, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-07-22 16:35:36', '2025-07-22 18:35:36', 50, 12, 'active', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(44, 10, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-07-06 16:35:36', '2025-07-06 18:35:36', 42, 20, 'active', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(45, 10, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-07-20 16:35:36', '2025-07-20 18:35:36', 23, 30, 'active', '2025-05-27 00:35:36', '2025-05-27 00:35:36'),
(46, 1, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-19 16:35:57', '2025-06-19 18:35:57', 22, 12, 'active', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(47, 2, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-07-06 16:35:57', '2025-07-06 18:35:57', 39, 20, 'active', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(48, 3, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-07-18 16:35:57', '2025-07-18 18:35:57', 32, 28, 'active', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(49, 3, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-07-12 16:35:57', '2025-07-12 18:35:57', 25, 12, 'active', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(50, 4, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-07-06 16:35:57', '2025-07-06 18:35:57', 46, 14, 'active', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(51, 4, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-06-15 16:35:57', '2025-06-15 18:35:57', 25, 26, 'active', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(52, 4, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-07-11 16:35:57', '2025-07-11 18:35:57', 29, 23, 'active', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(53, 5, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-07-02 16:35:57', '2025-07-02 18:35:57', 26, 15, 'active', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(54, 6, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-06-27 16:35:57', '2025-06-27 18:35:57', 46, 17, 'active', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(55, 6, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-07-15 16:35:57', '2025-07-15 18:35:57', 21, 21, 'active', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(56, 7, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-07-05 16:35:57', '2025-07-05 18:35:57', 30, 26, 'active', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(57, 8, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-06-08 16:35:57', '2025-06-08 18:35:57', 27, 18, 'active', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(58, 8, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-06-18 16:35:57', '2025-06-18 18:35:57', 20, 23, 'active', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(59, 9, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-06-09 16:35:57', '2025-06-09 18:35:57', 37, 12, 'active', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(60, 9, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-18 16:35:57', '2025-06-18 18:35:57', 40, 24, 'active', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(61, 10, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-06-14 16:35:57', '2025-06-14 18:35:57', 32, 29, 'active', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(62, 11, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-07-13 16:35:57', '2025-07-13 18:35:57', 22, 17, 'active', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(63, 12, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-07-15 16:35:57', '2025-07-15 18:35:57', 25, 17, 'active', '2025-05-27 00:35:57', '2025-05-27 00:35:57'),
(64, 13, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-07-07 16:35:58', '2025-07-07 18:35:58', 31, 29, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(65, 13, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-06-11 16:35:58', '2025-06-11 18:35:58', 34, 29, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(66, 13, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-06-29 16:35:58', '2025-06-29 18:35:58', 19, 23, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(67, 14, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-07-15 16:35:58', '2025-07-15 18:35:58', 47, 16, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(68, 14, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-07-22 16:35:58', '2025-07-22 18:35:58', 29, 13, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(69, 15, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-06-06 16:35:58', '2025-06-06 18:35:58', 25, 29, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(70, 15, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-07-01 16:35:58', '2025-07-01 18:35:58', 26, 19, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(71, 15, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-06-30 16:35:58', '2025-06-30 18:35:58', 38, 26, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(72, 16, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-07-02 16:35:58', '2025-07-02 18:35:58', 47, 17, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(73, 16, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-06-03 16:35:58', '2025-06-03 18:35:58', 21, 13, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(74, 16, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-07-13 16:35:58', '2025-07-13 18:35:58', 18, 10, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(75, 17, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-07-22 16:35:58', '2025-07-22 18:35:58', 32, 30, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(76, 17, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-07-09 16:35:58', '2025-07-09 18:35:58', 41, 24, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(77, 17, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-07-14 16:35:58', '2025-07-14 18:35:58', 47, 14, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(78, 18, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-07-22 16:35:58', '2025-07-22 18:35:58', 24, 25, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(79, 19, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-06-20 16:35:58', '2025-06-20 18:35:58', 26, 28, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(80, 19, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-06-04 16:35:58', '2025-06-04 18:35:58', 43, 25, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(81, 20, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-06-01 16:35:58', '2025-06-01 18:35:58', 20, 15, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(82, 21, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-05-28 16:35:58', '2025-05-28 18:35:58', 39, 24, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(83, 21, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-06-24 16:35:58', '2025-06-24 18:35:58', 16, 24, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(84, 21, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-07-13 16:35:58', '2025-07-13 18:35:58', 48, 10, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(85, 22, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-06-24 16:35:58', '2025-06-24 18:35:58', 44, 13, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(86, 22, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-07-24 16:35:58', '2025-07-24 18:35:58', 30, 21, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(87, 22, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-06-05 16:35:58', '2025-06-05 18:35:58', 24, 19, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(88, 23, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-06-15 16:35:58', '2025-06-15 18:35:58', 45, 24, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(89, 24, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-07-23 16:35:58', '2025-07-23 18:35:58', 38, 30, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(90, 24, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-06-28 16:35:58', '2025-06-28 18:35:58', 31, 24, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(91, 25, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-07-19 16:35:58', '2025-07-19 18:35:58', 24, 18, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(92, 25, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-07-03 16:35:58', '2025-07-03 18:35:58', 26, 11, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(93, 26, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-12 16:35:58', '2025-06-12 18:35:58', 31, 11, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(94, 27, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-07-04 16:35:58', '2025-07-04 18:35:58', 41, 16, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(95, 28, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-07-10 16:35:58', '2025-07-10 18:35:58', 41, 13, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(96, 29, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-07-19 16:35:58', '2025-07-19 18:35:58', 19, 12, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(97, 29, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-07-24 16:35:58', '2025-07-24 18:35:58', 22, 18, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(98, 29, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-22 16:35:58', '2025-06-22 18:35:58', 42, 24, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(99, 30, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-07-03 16:35:58', '2025-07-03 18:35:58', 30, 21, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(100, 31, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-07-07 16:35:58', '2025-07-07 18:35:58', 31, 20, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(101, 32, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-06-20 16:35:58', '2025-06-20 18:35:58', 40, 28, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(102, 32, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-06-12 16:35:58', '2025-06-12 18:35:58', 19, 17, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(103, 33, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-07-11 16:35:58', '2025-07-11 18:35:58', 36, 17, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(104, 33, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-06-24 16:35:58', '2025-06-24 18:35:58', 33, 22, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(105, 33, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-29 16:35:58', '2025-06-29 18:35:58', 36, 11, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(106, 34, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-07-11 16:35:58', '2025-07-11 18:35:58', 46, 17, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(107, 34, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-05-29 16:35:58', '2025-05-29 18:35:58', 19, 16, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(108, 35, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-07-16 16:35:58', '2025-07-16 18:35:58', 26, 19, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(109, 35, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-06-18 16:35:58', '2025-06-18 18:35:58', 50, 18, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(110, 35, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-07-15 16:35:58', '2025-07-15 18:35:58', 26, 19, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(111, 36, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-15 16:35:58', '2025-06-15 18:35:58', 42, 17, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(112, 36, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-05-31 16:35:58', '2025-05-31 18:35:58', 18, 14, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(113, 37, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-07-07 16:35:58', '2025-07-07 18:35:58', 45, 18, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(114, 37, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-07-09 16:35:58', '2025-07-09 18:35:58', 40, 10, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(115, 38, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-06-12 16:35:58', '2025-06-12 18:35:58', 42, 12, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(116, 38, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-05-27 16:35:58', '2025-05-27 18:35:58', 48, 15, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(117, 38, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-06-04 16:35:58', '2025-06-04 18:35:58', 16, 21, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(118, 39, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-07-11 16:35:58', '2025-07-11 18:35:58', 36, 29, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(119, 39, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-05-30 16:35:58', '2025-05-30 18:35:58', 42, 22, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(120, 39, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-06-09 16:35:58', '2025-06-09 18:35:58', 15, 28, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(121, 40, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-06-12 16:35:58', '2025-06-12 18:35:58', 26, 22, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(122, 40, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-29 16:35:58', '2025-06-29 18:35:58', 27, 28, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(123, 40, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-07-12 16:35:58', '2025-07-12 18:35:58', 18, 23, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(124, 41, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-06-10 16:35:58', '2025-06-10 18:35:58', 27, 20, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(125, 41, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-06-25 16:35:58', '2025-06-25 18:35:58', 16, 14, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(126, 41, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-07-12 16:35:58', '2025-07-12 18:35:58', 41, 18, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(127, 42, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-07-01 16:35:58', '2025-07-01 18:35:58', 27, 13, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(128, 43, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-06-10 16:35:58', '2025-06-10 18:35:58', 34, 27, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(129, 43, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-07-09 16:35:58', '2025-07-09 18:35:58', 44, 17, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(130, 43, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-09 16:35:58', '2025-06-09 18:35:58', 18, 24, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(131, 44, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-06-12 16:35:58', '2025-06-12 18:35:58', 27, 30, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(132, 44, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-05-31 16:35:58', '2025-05-31 18:35:58', 18, 15, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(133, 44, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-07-08 16:35:58', '2025-07-08 18:35:58', 17, 22, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(134, 45, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-06-22 16:35:58', '2025-06-22 18:35:58', 15, 11, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(135, 45, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-06-21 16:35:58', '2025-06-21 18:35:58', 28, 21, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(136, 45, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-07-19 16:35:58', '2025-07-19 18:35:58', 27, 17, 'active', '2025-05-27 00:35:58', '2025-05-27 00:35:58'),
(137, 46, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-07-02 16:35:59', '2025-07-02 18:35:59', 45, 24, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(138, 46, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-06-14 16:35:59', '2025-06-14 18:35:59', 35, 26, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(139, 47, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-07-20 16:35:59', '2025-07-20 18:35:59', 30, 10, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(140, 47, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-07-17 16:35:59', '2025-07-17 18:35:59', 34, 30, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(141, 47, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-06-05 16:35:59', '2025-06-05 18:35:59', 17, 30, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(142, 48, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-07-09 16:35:59', '2025-07-09 18:35:59', 21, 21, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(143, 48, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-05-29 16:35:59', '2025-05-29 18:35:59', 39, 21, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(144, 49, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-11 16:35:59', '2025-06-11 18:35:59', 16, 13, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(145, 50, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-06-17 16:35:59', '2025-06-17 18:35:59', 32, 23, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(146, 50, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-06-25 16:35:59', '2025-06-25 18:35:59', 40, 27, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(147, 50, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-04 16:35:59', '2025-06-04 18:35:59', 22, 11, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(148, 51, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-06-04 16:35:59', '2025-06-04 18:35:59', 34, 30, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(149, 51, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-07-08 16:35:59', '2025-07-08 18:35:59', 45, 30, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(150, 52, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-05 16:35:59', '2025-06-05 18:35:59', 33, 11, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(151, 53, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-06-09 16:35:59', '2025-06-09 18:35:59', 29, 13, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(152, 54, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-05-31 16:35:59', '2025-05-31 18:35:59', 26, 13, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(153, 54, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-06-18 16:35:59', '2025-06-18 18:35:59', 21, 12, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(154, 55, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-07-24 16:35:59', '2025-07-24 18:35:59', 41, 21, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(155, 56, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-06-28 16:35:59', '2025-06-28 18:35:59', 17, 12, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(156, 56, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-06-17 16:35:59', '2025-06-17 18:35:59', 33, 21, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(157, 57, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-07-07 16:35:59', '2025-07-07 18:35:59', 26, 16, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(158, 58, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-07-12 16:35:59', '2025-07-12 18:35:59', 38, 21, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(159, 58, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-07-16 16:35:59', '2025-07-16 18:35:59', 38, 11, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(160, 59, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-07-04 16:35:59', '2025-07-04 18:35:59', 44, 28, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(161, 59, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-06-07 16:35:59', '2025-06-07 18:35:59', 44, 18, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(162, 60, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-06-02 16:35:59', '2025-06-02 18:35:59', 32, 21, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(163, 61, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-06-03 16:35:59', '2025-06-03 18:35:59', 44, 13, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(164, 62, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-07-16 16:35:59', '2025-07-16 18:35:59', 27, 12, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(165, 62, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-10 16:35:59', '2025-06-10 18:35:59', 26, 27, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(166, 62, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-07-13 16:35:59', '2025-07-13 18:35:59', 45, 26, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(167, 63, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-07-02 16:35:59', '2025-07-02 18:35:59', 38, 28, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(168, 63, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-23 16:35:59', '2025-06-23 18:35:59', 27, 16, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(169, 64, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-07-22 16:35:59', '2025-07-22 18:35:59', 48, 16, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(170, 65, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-06-07 16:35:59', '2025-06-07 18:35:59', 24, 30, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(171, 66, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-07-11 16:35:59', '2025-07-11 18:35:59', 40, 22, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(172, 66, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-07-03 16:35:59', '2025-07-03 18:35:59', 42, 13, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(173, 66, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-06-10 16:35:59', '2025-06-10 18:35:59', 40, 29, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(174, 67, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-07-03 16:35:59', '2025-07-03 18:35:59', 44, 14, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(175, 68, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-17 16:35:59', '2025-06-17 18:35:59', 34, 16, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(176, 69, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-02 16:35:59', '2025-06-02 18:35:59', 36, 17, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(177, 69, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-06-08 16:35:59', '2025-06-08 18:35:59', 45, 18, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(178, 70, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-06-06 16:35:59', '2025-06-06 18:35:59', 22, 22, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(179, 71, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-06-02 16:35:59', '2025-06-02 18:35:59', 16, 25, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(180, 72, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-07-05 16:35:59', '2025-07-05 18:35:59', 26, 21, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(181, 73, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-06-20 16:35:59', '2025-06-20 18:35:59', 23, 25, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(182, 74, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-06-27 16:35:59', '2025-06-27 18:35:59', 47, 13, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(183, 75, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-21 16:35:59', '2025-06-21 18:35:59', 26, 23, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(184, 75, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-06-17 16:35:59', '2025-06-17 18:35:59', 15, 20, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(185, 75, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-05-28 16:35:59', '2025-05-28 18:35:59', 37, 15, 'active', '2025-05-27 00:35:59', '2025-05-27 00:35:59'),
(186, 76, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-06-19 16:36:00', '2025-06-19 18:36:00', 33, 11, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(187, 76, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-06-25 16:36:00', '2025-06-25 18:36:00', 45, 26, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(188, 76, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-06-28 16:36:00', '2025-06-28 18:36:00', 35, 25, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(189, 77, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-06-09 16:36:00', '2025-06-09 18:36:00', 40, 28, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(190, 78, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-06 16:36:00', '2025-06-06 18:36:00', 21, 20, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(191, 79, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-07-13 16:36:00', '2025-07-13 18:36:00', 34, 11, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(192, 79, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-06-09 16:36:00', '2025-06-09 18:36:00', 27, 14, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(193, 80, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-23 16:36:00', '2025-06-23 18:36:00', 45, 24, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(194, 80, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-06-28 16:36:00', '2025-06-28 18:36:00', 45, 21, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(195, 81, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-06-15 16:36:00', '2025-06-15 18:36:00', 40, 18, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(196, 82, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-07-20 16:36:00', '2025-07-20 18:36:00', 24, 25, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(197, 82, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-07-09 16:36:00', '2025-07-09 18:36:00', 36, 27, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(198, 83, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-07-14 16:36:00', '2025-07-14 18:36:00', 46, 19, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(199, 84, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-25 16:36:00', '2025-06-25 18:36:00', 41, 13, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(200, 85, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-06-03 16:36:00', '2025-06-03 18:36:00', 46, 23, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(201, 86, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-05-28 16:36:00', '2025-05-28 18:36:00', 43, 28, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(202, 86, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-06-15 16:36:00', '2025-06-15 18:36:00', 37, 29, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(203, 87, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-06-14 16:36:00', '2025-06-14 18:36:00', 50, 24, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(204, 87, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-06-19 16:36:00', '2025-06-19 18:36:00', 22, 14, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(205, 88, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-06-08 16:36:00', '2025-06-08 18:36:00', 42, 11, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(206, 88, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-06-03 16:36:00', '2025-06-03 18:36:00', 45, 20, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(207, 89, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-06-24 16:36:00', '2025-06-24 18:36:00', 19, 18, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(208, 90, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-07-22 16:36:00', '2025-07-22 18:36:00', 15, 10, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(209, 90, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-07-16 16:36:00', '2025-07-16 18:36:00', 22, 14, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(210, 91, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-07-10 16:36:00', '2025-07-10 18:36:00', 24, 19, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(211, 92, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-07-24 16:36:00', '2025-07-24 18:36:00', 28, 14, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(212, 92, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-07-23 16:36:00', '2025-07-23 18:36:00', 23, 21, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(213, 92, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-07-03 16:36:00', '2025-07-03 18:36:00', 16, 26, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(214, 93, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-07 16:36:00', '2025-06-07 18:36:00', 49, 19, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(215, 93, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-07-19 16:36:00', '2025-07-19 18:36:00', 28, 22, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(216, 93, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-07-24 16:36:00', '2025-07-24 18:36:00', 28, 23, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(217, 94, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-06-06 16:36:00', '2025-06-06 18:36:00', 36, 18, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(218, 94, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-07-19 16:36:00', '2025-07-19 18:36:00', 50, 18, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(219, 95, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-07-13 16:36:00', '2025-07-13 18:36:00', 46, 15, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(220, 95, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-05-29 16:36:00', '2025-05-29 18:36:00', 19, 26, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(221, 96, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-06-25 16:36:00', '2025-06-25 18:36:00', 38, 23, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(222, 96, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-07-04 16:36:00', '2025-07-04 18:36:00', 34, 10, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(223, 96, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-06-08 16:36:00', '2025-06-08 18:36:00', 23, 11, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(224, 97, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-05-27 16:36:00', '2025-05-27 18:36:00', 50, 25, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(225, 97, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-07-06 16:36:00', '2025-07-06 18:36:00', 40, 16, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(226, 98, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-06-03 16:36:00', '2025-06-03 18:36:00', 47, 24, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(227, 98, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-07-24 16:36:00', '2025-07-24 18:36:00', 20, 11, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(228, 99, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-06-14 16:36:00', '2025-06-14 18:36:00', 44, 23, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00'),
(229, 100, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-07-09 16:36:00', '2025-07-09 18:36:00', 42, 25, 'active', '2025-05-27 00:36:00', '2025-05-27 00:36:00');

-- --------------------------------------------------------

--
-- Table structure for table `user_event_completions`
--

CREATE TABLE `user_event_completions` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `taskevent_id` int NOT NULL,
  `completed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Triggers `user_event_completions`
--
DELIMITER $$
CREATE TRIGGER `after_event_completion_log` AFTER INSERT ON `user_event_completions` FOR EACH ROW BEGIN 
  DECLARE event_name_val VARCHAR(255);
  DECLARE event_desc_val TEXT;
  DECLARE reward_xp_val INT;
  DECLARE reward_coins_val INT;
  
  SELECT event_name, event_description, reward_xp, reward_coins
  INTO event_name_val, event_desc_val, reward_xp_val, reward_coins_val
  FROM user_event 
  WHERE id = NEW.taskevent_id;
  
  INSERT INTO activity_log (
      user_id,
      activity_type,
      activity_details,
      log_timestamp
    )
  VALUES (
      NEW.user_id,
      'EVENT_COMPLETED',
      CONCAT('{"event_id":', NEW.taskevent_id, ',"event_name":"', REPLACE(IFNULL(event_name_val, ''), '"', '\"'), '","reward_xp":', IFNULL(reward_xp_val, 0), ',"reward_coins":', IFNULL(reward_coins_val, 0), '}'),
      NOW()
    );
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `user_inventory`
--

CREATE TABLE `user_inventory` (
  `inventory_id` int NOT NULL,
  `user_id` int NOT NULL,
  `item_id` int NOT NULL,
  `quantity` int DEFAULT '1',
  `acquired_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `user_inventory`
--

INSERT INTO `user_inventory` (`inventory_id`, `user_id`, `item_id`, `quantity`, `acquired_at`) VALUES
(1, 3, 4, 3, '2025-05-27 00:33:32'),
(2, 1, 2, 4, '2025-05-27 00:33:58'),
(3, 1, 4, 5, '2025-05-27 00:33:58'),
(4, 3, 3, 11, '2025-05-27 00:33:58'),
(5, 4, 2, 4, '2025-05-27 00:33:58'),
(6, 5, 2, 1, '2025-05-27 00:33:58'),
(7, 2, 3, 7, '2025-05-27 00:35:36'),
(8, 2, 1, 1, '2025-05-27 00:35:36'),
(9, 3, 1, 4, '2025-05-27 00:35:36'),
(10, 10, 4, 4, '2025-05-27 00:35:36'),
(11, 7, 2, 1, '2025-05-27 00:35:57'),
(12, 7, 3, 5, '2025-05-27 00:35:57'),
(13, 12, 4, 2, '2025-05-27 00:35:57'),
(14, 12, 2, 3, '2025-05-27 00:35:57'),
(15, 14, 4, 4, '2025-05-27 00:35:58'),
(16, 18, 2, 8, '2025-05-27 00:35:58'),
(17, 18, 4, 3, '2025-05-27 00:35:58'),
(18, 20, 3, 2, '2025-05-27 00:35:58'),
(19, 24, 2, 3, '2025-05-27 00:35:58'),
(20, 24, 1, 3, '2025-05-27 00:35:58'),
(21, 29, 4, 5, '2025-05-27 00:35:58'),
(22, 32, 2, 7, '2025-05-27 00:35:58'),
(23, 32, 1, 2, '2025-05-27 00:35:58'),
(24, 35, 3, 6, '2025-05-27 00:35:58'),
(25, 37, 4, 2, '2025-05-27 00:35:58'),
(26, 41, 2, 2, '2025-05-27 00:35:58'),
(27, 41, 4, 10, '2025-05-27 00:35:58'),
(28, 42, 2, 5, '2025-05-27 00:35:58'),
(29, 42, 1, 1, '2025-05-27 00:35:58'),
(30, 46, 2, 5, '2025-05-27 00:35:59'),
(31, 53, 4, 3, '2025-05-27 00:35:59'),
(32, 56, 2, 4, '2025-05-27 00:35:59'),
(33, 56, 1, 1, '2025-05-27 00:35:59'),
(34, 58, 4, 5, '2025-05-27 00:35:59'),
(35, 68, 4, 3, '2025-05-27 00:35:59'),
(36, 68, 1, 2, '2025-05-27 00:35:59'),
(37, 70, 4, 8, '2025-05-27 00:35:59'),
(38, 70, 2, 4, '2025-05-27 00:35:59'),
(39, 72, 4, 2, '2025-05-27 00:35:59'),
(40, 79, 2, 1, '2025-05-27 00:36:00'),
(41, 82, 4, 1, '2025-05-27 00:36:00'),
(42, 87, 2, 1, '2025-05-27 00:36:00'),
(43, 87, 1, 3, '2025-05-27 00:36:00'),
(44, 91, 2, 1, '2025-05-27 00:36:00'),
(45, 91, 4, 4, '2025-05-27 00:36:00'),
(46, 92, 1, 4, '2025-05-27 00:36:00'),
(47, 92, 2, 1, '2025-05-27 00:36:00'),
(48, 92, 3, 2, '2025-05-27 00:36:00'),
(49, 93, 2, 5, '2025-05-27 00:36:00'),
(50, 99, 4, 3, '2025-05-27 00:36:00'),
(52, 102, 1, 1, '2025-05-28 02:51:33');

--
-- Triggers `user_inventory`
--
DELIMITER $$
CREATE TRIGGER `after_inventory_insert` AFTER INSERT ON `user_inventory` FOR EACH ROW BEGIN
  DECLARE item_name_var VARCHAR(255);
  
  SELECT item_name INTO item_name_var
  FROM marketplace_items
  WHERE item_id = NEW.item_id;
  
  INSERT INTO activity_log (user_id, activity_type, activity_details)
  VALUES (
      NEW.user_id,
      'ITEM_PURCHASED',
      CONCAT('{"item_id":', NEW.item_id, ',"item_name":"', REPLACE(IFNULL(item_name_var, ''), '"', '\"'), '"}')
    );
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `user_items`
-- (See below for the actual view)
--
CREATE TABLE `user_items` (
`user_id` int
,`item_name` varchar(255)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `view_bad_habits_activity`
-- (See below for the actual view)
--
CREATE TABLE `view_bad_habits_activity` (
`log_id` int
,`user_id` int
,`activity_title` longtext
,`difficulty` longtext
,`category` longtext
,`coins` longtext
,`xp` longtext
,`log_timestamp` timestamp
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `view_daily_task_activity`
-- (See below for the actual view)
--
CREATE TABLE `view_daily_task_activity` (
`log_id` int
,`user_id` int
,`task_title` longtext
,`difficulty` longtext
,`category` longtext
,`coins` longtext
,`xp` longtext
,`log_timestamp` timestamp
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `view_event_activity`
-- (See below for the actual view)
--
CREATE TABLE `view_event_activity` (
`log_id` int
,`user_id` int
,`username` varchar(50)
,`event_id` longtext
,`event_name` longtext
,`event_description` longtext
,`coins` longtext
,`xp` longtext
,`completion_time` longtext
,`log_timestamp` timestamp
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `view_good_habits_activity`
-- (See below for the actual view)
--
CREATE TABLE `view_good_habits_activity` (
`log_id` int
,`user_id` int
,`activity_title` longtext
,`difficulty` longtext
,`category` longtext
,`coins` longtext
,`xp` longtext
,`log_timestamp` timestamp
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `view_poke_activity`
-- (See below for the actual view)
--
CREATE TABLE `view_poke_activity` (
`log_id` int
,`target_user_id` int
,`poker_user_id` longtext
,`poker_username` longtext
,`poke_timestamp` timestamp
,`target_username` varchar(50)
,`poker_username_from_users` varchar(50)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `view_task_activity`
-- (See below for the actual view)
--
CREATE TABLE `view_task_activity` (
`log_id` int
,`user_id` int
,`task_title` longtext
,`difficulty` longtext
,`category` longtext
,`coins` longtext
,`xp` longtext
,`log_timestamp` timestamp
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
-- Indexes for table `migrations`
--
ALTER TABLE `migrations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_migration` (`migration`);

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
  ADD UNIQUE KEY `unique_userstats_user` (`user_id`),
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
  MODIFY `log_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=677;

--
-- AUTO_INCREMENT for table `avatars`
--
ALTER TABLE `avatars`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `badhabits`
--
ALTER TABLE `badhabits`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `dailytasks`
--
ALTER TABLE `dailytasks`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=262;

--
-- AUTO_INCREMENT for table `goodhabits`
--
ALTER TABLE `goodhabits`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=413;

--
-- AUTO_INCREMENT for table `item_categories`
--
ALTER TABLE `item_categories`
  MODIFY `category_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `item_usage_history`
--
ALTER TABLE `item_usage_history`
  MODIFY `usage_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `journals`
--
ALTER TABLE `journals`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=358;

--
-- AUTO_INCREMENT for table `marketplace_items`
--
ALTER TABLE `marketplace_items`
  MODIFY `item_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `migrations`
--
ALTER TABLE `migrations`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=31;

--
-- AUTO_INCREMENT for table `streaks`
--
ALTER TABLE `streaks`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=511;

--
-- AUTO_INCREMENT for table `tasks`
--
ALTER TABLE `tasks`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=669;

--
-- AUTO_INCREMENT for table `test_data`
--
ALTER TABLE `test_data`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=103;

--
-- AUTO_INCREMENT for table `userstats`
--
ALTER TABLE `userstats`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=103;

--
-- AUTO_INCREMENT for table `user_active_boosts`
--
ALTER TABLE `user_active_boosts`
  MODIFY `boost_id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `user_event`
--
ALTER TABLE `user_event`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=230;

--
-- AUTO_INCREMENT for table `user_event_completions`
--
ALTER TABLE `user_event_completions`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `user_inventory`
--
ALTER TABLE `user_inventory`
  MODIFY `inventory_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=53;

-- --------------------------------------------------------

--
-- Structure for view `streaks_view`
--
DROP TABLE IF EXISTS `streaks_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `streaks_view`  AS SELECT `streaks`.`id` AS `id`, `streaks`.`user_id` AS `user_id`, `streaks`.`streak_type` AS `streak_type`, `streaks`.`current_streak` AS `current_streak`, `streaks`.`longest_streak` AS `longest_streak`, `streaks`.`last_streak_date` AS `last_streak_date`, `streaks`.`last_streak_date` AS `last_activity_date`, `streaks`.`next_expected_date` AS `next_expected_date` FROM `streaks` ;

-- --------------------------------------------------------

--
-- Structure for view `user_items`
--
DROP TABLE IF EXISTS `user_items`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `user_items`  AS SELECT `u`.`id` AS `user_id`, `mi`.`item_name` AS `item_name` FROM ((`users` `u` join `user_inventory` `ui` on((`u`.`id` = `ui`.`user_id`))) join `marketplace_items` `mi` on((`ui`.`item_id` = `mi`.`item_id`))) ;

-- --------------------------------------------------------

--
-- Structure for view `view_bad_habits_activity`
--
DROP TABLE IF EXISTS `view_bad_habits_activity`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_bad_habits_activity`  AS SELECT `a`.`log_id` AS `log_id`, `a`.`user_id` AS `user_id`, json_unquote(json_extract(`a`.`activity_details`,'$.title')) AS `activity_title`, json_unquote(json_extract(`a`.`activity_details`,'$.difficulty')) AS `difficulty`, json_unquote(json_extract(`a`.`activity_details`,'$.category')) AS `category`, json_unquote(json_extract(`a`.`activity_details`,'$.coins')) AS `coins`, json_unquote(json_extract(`a`.`activity_details`,'$.xp')) AS `xp`, `a`.`log_timestamp` AS `log_timestamp` FROM (`activity_log` `a` join `users` `u` on((`a`.`user_id` = `u`.`id`))) WHERE (`a`.`activity_type` = 'Bad Habit Logged') ;

-- --------------------------------------------------------

--
-- Structure for view `view_daily_task_activity`
--
DROP TABLE IF EXISTS `view_daily_task_activity`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_daily_task_activity`  AS SELECT `a`.`log_id` AS `log_id`, `a`.`user_id` AS `user_id`, json_unquote(json_extract(`a`.`activity_details`,'$.title')) AS `task_title`, json_unquote(json_extract(`a`.`activity_details`,'$.difficulty')) AS `difficulty`, json_unquote(json_extract(`a`.`activity_details`,'$.category')) AS `category`, json_unquote(json_extract(`a`.`activity_details`,'$.coins')) AS `coins`, json_unquote(json_extract(`a`.`activity_details`,'$.xp')) AS `xp`, `a`.`log_timestamp` AS `log_timestamp` FROM (`activity_log` `a` join `users` `u` on((`a`.`user_id` = `u`.`id`))) WHERE (`a`.`activity_type` = 'Daily Task Completed') ;

-- --------------------------------------------------------

--
-- Structure for view `view_event_activity`
--
DROP TABLE IF EXISTS `view_event_activity`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_event_activity`  AS SELECT `a`.`log_id` AS `log_id`, `a`.`user_id` AS `user_id`, `u`.`username` AS `username`, json_unquote(json_extract(`a`.`activity_details`,'$.event_id')) AS `event_id`, json_unquote(json_extract(`a`.`activity_details`,'$.event_name')) AS `event_name`, json_unquote(json_extract(`a`.`activity_details`,'$.event_description')) AS `event_description`, json_unquote(json_extract(`a`.`activity_details`,'$.reward_coins')) AS `coins`, json_unquote(json_extract(`a`.`activity_details`,'$.reward_xp')) AS `xp`, json_unquote(json_extract(`a`.`activity_details`,'$.completed_at')) AS `completion_time`, `a`.`log_timestamp` AS `log_timestamp` FROM (`activity_log` `a` join `users` `u` on((`a`.`user_id` = `u`.`id`))) WHERE (`a`.`activity_type` = 'Event Completed') ;

-- --------------------------------------------------------

--
-- Structure for view `view_good_habits_activity`
--
DROP TABLE IF EXISTS `view_good_habits_activity`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_good_habits_activity`  AS SELECT `a`.`log_id` AS `log_id`, `a`.`user_id` AS `user_id`, json_unquote(json_extract(`a`.`activity_details`,'$.title')) AS `activity_title`, json_unquote(json_extract(`a`.`activity_details`,'$.difficulty')) AS `difficulty`, json_unquote(json_extract(`a`.`activity_details`,'$.category')) AS `category`, json_unquote(json_extract(`a`.`activity_details`,'$.coins')) AS `coins`, json_unquote(json_extract(`a`.`activity_details`,'$.xp')) AS `xp`, `a`.`log_timestamp` AS `log_timestamp` FROM (`activity_log` `a` join `users` `u` on((`a`.`user_id` = `u`.`id`))) WHERE (`a`.`activity_type` = 'Good Habit Logged') ;

-- --------------------------------------------------------

--
-- Structure for view `view_poke_activity`
--
DROP TABLE IF EXISTS `view_poke_activity`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_poke_activity`  AS SELECT `a`.`log_id` AS `log_id`, `a`.`user_id` AS `target_user_id`, json_unquote(json_extract(`a`.`activity_details`,'$.poker_id')) AS `poker_user_id`, json_unquote(json_extract(`a`.`activity_details`,'$.poker_name')) AS `poker_username`, `a`.`log_timestamp` AS `poke_timestamp`, `u1`.`username` AS `target_username`, `u2`.`username` AS `poker_username_from_users` FROM ((`activity_log` `a` join `users` `u1` on((`a`.`user_id` = `u1`.`id`))) left join `users` `u2` on((json_unquote(json_extract(`a`.`activity_details`,'$.poker_id')) = `u2`.`id`))) WHERE (`a`.`activity_type` = 'User Poked') ;

-- --------------------------------------------------------

--
-- Structure for view `view_task_activity`
--
DROP TABLE IF EXISTS `view_task_activity`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_task_activity`  AS SELECT `a`.`log_id` AS `log_id`, `a`.`user_id` AS `user_id`, json_unquote(json_extract(`a`.`activity_details`,'$.title')) AS `task_title`, json_unquote(json_extract(`a`.`activity_details`,'$.difficulty')) AS `difficulty`, json_unquote(json_extract(`a`.`activity_details`,'$.category')) AS `category`, json_unquote(json_extract(`a`.`activity_details`,'$.coins')) AS `coins`, json_unquote(json_extract(`a`.`activity_details`,'$.xp')) AS `xp`, `a`.`log_timestamp` AS `log_timestamp` FROM (`activity_log` `a` join `users` `u` on((`a`.`user_id` = `u`.`id`))) WHERE (`a`.`activity_type` = 'Task Completed') ;

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
  ADD CONSTRAINT `fk_usage_inventory` FOREIGN KEY (`inventory_id`) REFERENCES `user_inventory` (`inventory_id`) ON DELETE SET NULL ON UPDATE CASCADE;

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
-- Constraints for table `user_active_boosts`
--
ALTER TABLE `user_active_boosts`
  ADD CONSTRAINT `fk_boost_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

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
  ADD CONSTRAINT `fk_inventory_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
