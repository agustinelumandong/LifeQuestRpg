-- phpMyAdmin SQL Dump
-- version 6.0.0-dev+20250328.9291a9ff8f
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: May 30, 2025 at 02:04 AM
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
            'poker_id', poker_user_id,
            'poker_name', poker_username
        ),
        NOW()
    );
    SELECT ROW_COUNT() AS success;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `UseInventoryItem` (IN `p_inventory_id` INT, IN `p_user_id` INT)   proc_label: BEGIN
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
        DECLARE v_current_quantity INT;
        
        DECLARE EXIT HANDLER FOR SQLEXCEPTION 
        BEGIN 
            GET DIAGNOSTICS CONDITION 1 v_error_message = MESSAGE_TEXT;
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
        SELECT i.item_id, i.quantity, m.item_type, m.effect_type, m.effect_value, m.item_name 
        INTO v_item_id, v_current_quantity, v_item_type, v_effect_type, v_effect_value, v_item_name
        FROM user_inventory i
        JOIN marketplace_items m ON i.item_id = m.item_id
        WHERE i.inventory_id = p_inventory_id AND i.user_id = p_user_id;
        
        IF v_item_id IS NULL THEN
            SELECT 'Item not found in your inventory' AS message;
            ROLLBACK;
            LEAVE proc_label;
        END IF;
        
        -- Process based on item type
        CASE v_item_type
            WHEN 'consumable' THEN 
                CASE v_effect_type
                    WHEN 'health' THEN 
                        -- Check if health is already at max
                        IF v_current_health >= 100 THEN
                            SELECT 'Your health is already at maximum' AS message;
                            ROLLBACK;
                            LEAVE proc_label;
                        END IF;
                        
                        -- Calculate new health value
                        SET v_new_health = LEAST(v_current_health + v_effect_value, 100);
                        UPDATE userstats SET health = v_new_health WHERE user_id = p_user_id;
                        SET v_effect_message = CONCAT('Restored ', (v_new_health - v_current_health), ' health points');
                        
                    WHEN 'xp' THEN
                        UPDATE userstats SET xp = xp + v_effect_value WHERE user_id = p_user_id;
                        SET v_effect_message = CONCAT('Gained ', v_effect_value, ' experience points');
                        
                    ELSE
                        SET v_effect_message = CONCAT('Consumable used with unknown effect type: ', v_effect_type);
                END CASE;
                
            WHEN 'boost' THEN 
                -- Check if boost is already active
                IF EXISTS (SELECT 1 FROM user_active_boosts WHERE user_id = p_user_id AND boost_type = v_effect_type AND expires_at > NOW()) THEN
                    SELECT 'This type of boost is already active' AS message;
                    ROLLBACK;
                    LEAVE proc_label;
                END IF;
                
                -- Add boost to active boosts
                INSERT INTO user_active_boosts (user_id, boost_type, boost_value, activated_at, expires_at)
                VALUES (p_user_id, v_effect_type, v_effect_value, NOW(), DATE_ADD(NOW(), INTERVAL 24 HOUR));
                SET v_effect_message = CONCAT('Activated a ', v_effect_value, '% boost for 24 hours');
                
            WHEN 'equipment' THEN
                SET v_effect_message = 'Item equipped successfully';
                
            ELSE
                SET v_effect_message = CONCAT('Unknown item type: ', v_item_type);
        END CASE;
        
        -- Handle quantity and logging properly for all item types
        IF v_item_type = 'consumable' THEN 
            -- Always log the usage FIRST with the actual inventory_id (before any deletion)
            INSERT INTO item_usage_history (inventory_id, effect_applied)
            VALUES (p_inventory_id, v_effect_message);
            
            IF v_current_quantity > 1 THEN 
                -- Reduce quantity by 1
                UPDATE user_inventory SET quantity = quantity - 1 WHERE inventory_id = p_inventory_id;
            ELSE 
                -- Delete the item if quantity is 1 or less
                DELETE FROM user_inventory WHERE inventory_id = p_inventory_id;
            END IF;
        ELSE 
            -- For non-consumable items, log the usage normally
            INSERT INTO item_usage_history (inventory_id, effect_applied)
            VALUES (p_inventory_id, v_effect_message);
        END IF;
        
        -- Return success message
        SELECT 'Item used successfully' AS message, v_effect_message AS effect;
        COMMIT;
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
(1, 3, 'Task Completed', '{\"xp\": 20, \"coins\": 10, \"title\": \"10k Steps\", \"task_id\": 1, \"category\": \"Physical Health\", \"difficulty\": \"medium\"}', '2025-05-28 11:39:17'),
(2, 1, 'User Login', '{\"message\":\"User logged in\",\"timestamp\":\"2025-05-28 13:37:37\"}', '2025-05-28 13:37:37'),
(3, 1, 'Task Completed', '{\"xp\": 10, \"coins\": 5, \"title\": \"haha\", \"task_id\": 2, \"category\": \"Physical Health\", \"difficulty\": \"easy\"}', '2025-05-28 13:37:59'),
(4, 1, 'Task Completed', '{\"xp\": 10, \"coins\": 5, \"title\": \"haha\", \"task_id\": 2, \"category\": \"Physical Health\", \"difficulty\": \"easy\"}', '2025-05-28 13:38:00'),
(5, 1, 'Task Completed', '{\"xp\": 10, \"coins\": 5, \"title\": \"haha\", \"task_id\": 2, \"category\": \"Physical Health\", \"difficulty\": \"easy\"}', '2025-05-28 13:38:01'),
(6, 1, 'Task Completed', '{\"xp\": 10, \"coins\": 5, \"title\": \"haha\", \"task_id\": 2, \"category\": \"Physical Health\", \"difficulty\": \"easy\"}', '2025-05-28 13:38:01'),
(7, 1, 'Task Completed', '{\"xp\": 10, \"coins\": 5, \"title\": \"haha\", \"task_id\": 2, \"category\": \"Physical Health\", \"difficulty\": \"easy\"}', '2025-05-28 13:38:02'),
(8, 1, 'Task Completed', '{\"xp\": 10, \"coins\": 5, \"title\": \"haha\", \"task_id\": 2, \"category\": \"Physical Health\", \"difficulty\": \"easy\"}', '2025-05-28 13:38:02'),
(9, 1, 'Task Completed', '{\"xp\": 10, \"coins\": 5, \"title\": \"haha\", \"task_id\": 2, \"category\": \"Physical Health\", \"difficulty\": \"easy\"}', '2025-05-28 13:38:03'),
(10, 1, 'Task Completed', '{\"xp\": 10, \"coins\": 5, \"title\": \"haha\", \"task_id\": 2, \"category\": \"Physical Health\", \"difficulty\": \"easy\"}', '2025-05-28 13:38:03'),
(11, 1, 'Task Completed', '{\"xp\": 10, \"coins\": 5, \"title\": \"haha\", \"task_id\": 2, \"category\": \"Physical Health\", \"difficulty\": \"easy\"}', '2025-05-28 13:38:04'),
(12, 3, 'User Poked', '{\"poker_id\": 1, \"poker_name\": \"cshan\"}', '2025-05-28 13:58:24'),
(13, 3, 'User Login', '{\"message\":\"User logged in\",\"timestamp\":\"2025-05-28 13:58:44\"}', '2025-05-28 13:58:44'),
(14, 1, 'User Login', '{\"message\":\"User logged in\",\"timestamp\":\"2025-05-28 14:01:07\"}', '2025-05-28 14:01:07'),
(15, 108, 'User Login', '{\"message\":\"New user registration and first login\",\"timestamp\":\"2025-05-28 14:07:54\"}', '2025-05-28 14:07:54'),
(16, 108, 'Daily Task Completed', '{\"xp\": 10, \"coins\": 5, \"title\": \"workout\", \"task_id\": 236, \"category\": \"Physical Health\", \"difficulty\": \"easy\"}', '2025-05-28 14:09:49'),
(17, 108, 'Good Habit Logged', '{\"xp\": 5, \"coins\": 5, \"title\": \"goodhabit\", \"task_id\": 367, \"category\": \"Mental Wellness\", \"difficulty\": \"easy\"}', '2025-05-28 14:10:34'),
(18, 108, 'Bad Habit Logged', '{\"xp\": 0, \"coins\": 0, \"title\": \"social media\", \"task_id\": 8, \"category\": \"Mental Wellness\", \"difficulty\": \"hard\"}', '2025-05-28 14:11:20'),
(19, 108, 'ITEM_PURCHASED', '{\"item_id\": 14, \"item_name\": \"hasdghas\"}', '2025-05-28 14:12:21'),
(20, 108, 'item_use', '{\"message\":\"Used item: hasdghas\"}', '2025-05-28 14:12:38'),
(21, 108, 'item_use', '{\"message\":\"Used item: hasdghas\"}', '2025-05-28 14:12:46'),
(22, 1, 'User Poked', '{\"poker_id\": 108, \"poker_name\": \"chansean28\"}', '2025-05-28 14:13:12'),
(23, 108, 'Event Completed', '{\"event_id\": 222, \"reward_xp\": 27, \"event_name\": \"Personal Goal Review\", \"completed_at\": \"2025-05-28 22:14:20.000000\", \"reward_coins\": 15, \"event_description\": \"Important event scheduled for personal or professional development.\"}', '2025-05-28 14:14:20');

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
(1, 'Warrior', 'assets/images/avatars/warrior1.png', 'warrior', '2025-05-16 04:29:15'),
(2, 'Mage', 'assets/images/avatars/mage1.png', 'mage', '2025-05-16 04:29:15'),
(3, 'Explorer', 'assets/images/avatars/explorer1.png', 'explorer', '2025-05-16 04:29:15'),
(4, 'Scholar', 'assets/images/avatars/scholar1.png', 'scholar', '2025-05-16 04:29:15');

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
(4, 1, 'hahasd', 'completed', 'hard', 'Mental Wellness', 0, 0, 0, '2025-05-28 02:55:55', '2025-05-28 02:55:57', NULL),
(5, 107, 'Sleeping Late watching tiktok', 'completed', 'hard', 'Physical Health', 0, 0, 0, '2025-05-28 06:08:16', '2025-05-28 06:50:53', NULL),
(6, 107, 'work 8 hours', 'completed', 'hard', 'Career / Studies', 0, 0, 0, '2025-05-28 06:59:06', '2025-05-28 06:59:08', NULL),
(7, 107, 'workout', 'pending', 'easy', 'Physical Health', 0, 0, 0, '2025-05-28 07:02:36', '2025-05-28 07:02:36', NULL),
(8, 108, 'social media', 'completed', 'hard', 'Mental Wellness', 0, 0, 0, '2025-05-28 14:11:15', '2025-05-28 14:11:20', NULL);

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
(1, 1, 'Daily Meal prep', 'completed', 'medium', 'Home Environment', 5, 7, '2025-05-28 02:57:27'),
(2, 1, 'Daily Clean living space', 'pending', 'hard', 'Home Environment', 8, 10, '2025-05-28 02:57:27'),
(3, 3, 'Daily Track expenses', 'pending', 'easy', 'Finance', 6, 6, '2025-05-28 02:57:27'),
(4, 3, 'Daily Pay bills on time', 'pending', 'hard', 'Finance', 7, 12, '2025-05-28 02:57:27'),
(5, 3, 'Daily Practice yoga', 'completed', 'easy', 'Physical Health', 4, 11, '2025-05-28 02:57:27'),
(6, 4, 'Daily Write thank you note', 'pending', 'medium', 'Relationships Social', 2, 9, '2025-05-28 02:57:27'),
(7, 4, 'Daily Do brain exercises', 'pending', 'medium', 'Mental Wellness', 7, 6, '2025-05-28 02:57:27'),
(8, 4, 'Daily Take online course', 'completed', 'hard', 'Career / Studies', 8, 15, '2025-05-28 02:57:27'),
(9, 5, 'Daily Work on portfolio', 'pending', 'medium', 'Career / Studies', 2, 8, '2025-05-28 02:57:27'),
(10, 5, 'Daily Reflect on progress', 'pending', 'easy', 'Personal Growth', 4, 11, '2025-05-28 02:57:27'),
(11, 5, 'Daily Stretch for 10 minutes', 'pending', 'medium', 'Physical Health', 7, 12, '2025-05-28 02:57:27'),
(12, 6, 'Daily Take vitamins', 'completed', 'hard', 'Physical Health', 8, 9, '2025-05-28 02:57:27'),
(13, 7, 'Daily Do brain exercises', 'completed', 'easy', 'Mental Wellness', 7, 5, '2025-05-28 02:57:27'),
(14, 7, 'Daily Learn something new', 'pending', 'hard', 'Personal Growth', 5, 11, '2025-05-28 02:57:27'),
(15, 8, 'Daily Plan future goals', 'pending', 'easy', 'Personal Growth', 2, 15, '2025-05-28 02:57:27'),
(16, 9, 'Daily Plan social activity', 'completed', 'hard', 'Relationships Social', 6, 10, '2025-05-28 02:57:27'),
(17, 9, 'Daily Research investments', 'completed', 'easy', 'Finance', 6, 12, '2025-05-28 02:57:27'),
(18, 10, 'Daily Take vitamins', 'pending', 'medium', 'Physical Health', 4, 14, '2025-05-28 02:57:27'),
(19, 10, 'Daily Practice guitar', 'pending', 'easy', 'Passion Hobbies', 6, 5, '2025-05-28 02:57:27'),
(20, 11, 'Daily Study programming', 'pending', 'hard', 'Career / Studies', 3, 12, '2025-05-28 02:57:27'),
(21, 11, 'Daily Pay bills on time', 'pending', 'medium', 'Finance', 2, 14, '2025-05-28 02:57:27'),
(22, 11, 'Daily Show appreciation', 'completed', 'hard', 'Relationships Social', 6, 7, '2025-05-28 02:57:27'),
(23, 12, 'Daily Read for 30 minutes', 'pending', 'easy', 'Mental Wellness', 6, 10, '2025-05-28 02:57:27'),
(24, 12, 'Daily Plan future goals', 'completed', 'easy', 'Personal Growth', 6, 13, '2025-05-28 02:57:27'),
(25, 13, 'Daily Review financial goals', 'completed', 'hard', 'Finance', 3, 10, '2025-05-28 02:57:27'),
(26, 13, 'Daily Show appreciation', 'completed', 'easy', 'Relationships Social', 7, 15, '2025-05-28 02:57:27'),
(27, 14, 'Daily Practice interview skills', 'completed', 'easy', 'Career / Studies', 3, 5, '2025-05-28 02:57:27'),
(28, 14, 'Daily Write gratitude list', 'pending', 'medium', 'Mental Wellness', 8, 9, '2025-05-28 02:57:27'),
(29, 15, 'Daily Take photos', 'completed', 'hard', 'Passion Hobbies', 4, 13, '2025-05-28 02:57:27'),
(30, 15, 'Daily Write in journal', 'pending', 'easy', 'Passion Hobbies', 5, 14, '2025-05-28 02:57:27'),
(31, 15, 'Daily Practice deep breathing', 'pending', 'hard', 'Mental Wellness', 6, 12, '2025-05-28 02:57:27'),
(32, 16, 'Daily Meditate for 10 minutes', 'pending', 'easy', 'Mental Wellness', 4, 12, '2025-05-28 02:57:27'),
(33, 16, 'Daily Organize workspace', 'completed', 'easy', 'Home Environment', 2, 10, '2025-05-28 02:57:27'),
(34, 16, 'Daily Water plants', 'pending', 'easy', 'Home Environment', 3, 9, '2025-05-28 02:57:27'),
(35, 17, 'Daily Do cardio workout', 'completed', 'medium', 'Physical Health', 7, 5, '2025-05-28 02:57:27'),
(36, 17, 'Daily Water plants', 'completed', 'medium', 'Home Environment', 7, 8, '2025-05-28 02:57:27'),
(37, 18, 'Daily Review financial goals', 'pending', 'hard', 'Finance', 4, 11, '2025-05-28 02:57:27'),
(38, 18, 'Daily Make new connections', 'completed', 'medium', 'Relationships Social', 8, 7, '2025-05-28 02:57:27'),
(39, 18, 'Daily Clean living space', 'pending', 'medium', 'Home Environment', 2, 9, '2025-05-28 02:57:27'),
(40, 19, 'Daily Practice interview skills', 'pending', 'hard', 'Career / Studies', 2, 8, '2025-05-28 02:57:27'),
(41, 19, 'Daily Do 20 push-ups', 'pending', 'easy', 'Physical Health', 4, 8, '2025-05-28 02:57:27'),
(42, 19, 'Daily Play board games', 'pending', 'medium', 'Passion Hobbies', 6, 7, '2025-05-28 02:57:27'),
(43, 20, 'Daily Practice a skill', 'pending', 'medium', 'Personal Growth', 5, 14, '2025-05-28 02:57:27'),
(44, 21, 'Daily Stretch for 10 minutes', 'pending', 'medium', 'Physical Health', 4, 14, '2025-05-28 02:57:27'),
(45, 21, 'Daily Declutter room', 'completed', 'hard', 'Home Environment', 2, 13, '2025-05-28 02:57:27'),
(46, 22, 'Daily Learn about finances', 'completed', 'hard', 'Finance', 7, 12, '2025-05-28 02:57:27'),
(47, 23, 'Daily Practice interview skills', 'completed', 'medium', 'Career / Studies', 8, 10, '2025-05-28 02:57:27'),
(48, 24, 'Daily Practice coding', 'pending', 'medium', 'Career / Studies', 4, 13, '2025-05-28 02:57:27'),
(49, 24, 'Daily Take vitamins', 'completed', 'hard', 'Physical Health', 3, 9, '2025-05-28 02:57:27'),
(50, 25, 'Daily Study programming', 'completed', 'easy', 'Career / Studies', 6, 7, '2025-05-28 02:57:27'),
(51, 26, 'Daily Garden for 30 minutes', 'completed', 'easy', 'Passion Hobbies', 5, 12, '2025-05-28 02:57:27'),
(52, 26, 'Daily Update resume', 'pending', 'hard', 'Career / Studies', 7, 6, '2025-05-28 02:57:27'),
(53, 27, 'Daily Review financial goals', 'completed', 'easy', 'Finance', 4, 9, '2025-05-28 02:57:27'),
(54, 27, 'Daily Set daily goals', 'completed', 'medium', 'Personal Growth', 7, 8, '2025-05-28 02:57:27'),
(55, 27, 'Daily Practice interview skills', 'pending', 'medium', 'Career / Studies', 5, 10, '2025-05-28 02:57:27'),
(56, 28, 'Daily Learn about finances', 'completed', 'easy', 'Finance', 7, 6, '2025-05-28 02:57:27'),
(57, 28, 'Daily Drink 8 glasses of water', 'completed', 'medium', 'Physical Health', 8, 10, '2025-05-28 02:57:27'),
(58, 28, 'Daily Practice active listening', 'pending', 'easy', 'Relationships Social', 2, 7, '2025-05-28 02:57:27'),
(59, 29, 'Daily Practice guitar', 'pending', 'medium', 'Passion Hobbies', 5, 12, '2025-05-28 02:57:27'),
(60, 29, 'Daily Work on art project', 'pending', 'hard', 'Passion Hobbies', 8, 7, '2025-05-28 02:57:27'),
(61, 29, 'Daily Do 20 push-ups', 'pending', 'hard', 'Physical Health', 4, 6, '2025-05-28 02:57:27'),
(62, 30, 'Daily Take online course', 'pending', 'medium', 'Career / Studies', 3, 14, '2025-05-28 02:57:27'),
(63, 30, 'Daily Set daily goals', 'pending', 'hard', 'Personal Growth', 8, 14, '2025-05-28 02:57:27'),
(64, 31, 'Daily Set daily goals', 'pending', 'easy', 'Personal Growth', 6, 5, '2025-05-28 02:57:27'),
(65, 31, 'Daily Practice interview skills', 'pending', 'medium', 'Career / Studies', 4, 11, '2025-05-28 02:57:27'),
(66, 32, 'Daily Write gratitude list', 'completed', 'hard', 'Mental Wellness', 3, 12, '2025-05-28 02:57:27'),
(67, 32, 'Daily Learn new hobby', 'pending', 'easy', 'Passion Hobbies', 5, 15, '2025-05-28 02:57:27'),
(68, 33, 'Daily Read self-help book', 'completed', 'easy', 'Personal Growth', 8, 5, '2025-05-28 02:57:27'),
(69, 33, 'Daily Read industry news', 'completed', 'easy', 'Career / Studies', 3, 11, '2025-05-28 02:57:27'),
(70, 34, 'Daily Resolve conflicts', 'pending', 'medium', 'Relationships Social', 6, 14, '2025-05-28 02:57:27'),
(71, 35, 'Daily Drink 8 glasses of water', 'pending', 'medium', 'Physical Health', 3, 15, '2025-05-28 02:57:27'),
(72, 35, 'Daily Read for 30 minutes', 'completed', 'hard', 'Mental Wellness', 4, 6, '2025-05-28 02:57:27'),
(73, 35, 'Daily Read industry news', 'pending', 'medium', 'Career / Studies', 3, 7, '2025-05-28 02:57:27'),
(74, 36, 'Daily Take online course', 'pending', 'hard', 'Career / Studies', 3, 7, '2025-05-28 02:57:27'),
(75, 36, 'Daily Listen to calming music', 'completed', 'hard', 'Mental Wellness', 4, 5, '2025-05-28 02:57:27'),
(76, 36, 'Daily Spend time with family', 'completed', 'hard', 'Relationships Social', 5, 13, '2025-05-28 02:57:27'),
(77, 37, 'Daily Update resume', 'pending', 'hard', 'Career / Studies', 7, 5, '2025-05-28 02:57:27'),
(78, 37, 'Daily Practice active listening', 'pending', 'easy', 'Relationships Social', 7, 5, '2025-05-28 02:57:27'),
(79, 37, 'Daily Plan future goals', 'completed', 'medium', 'Personal Growth', 6, 13, '2025-05-28 02:57:27'),
(80, 38, 'Daily Take online course', 'pending', 'hard', 'Career / Studies', 7, 11, '2025-05-28 02:57:27'),
(81, 39, 'Daily Take a mental health break', 'pending', 'easy', 'Mental Wellness', 2, 15, '2025-05-28 02:57:27'),
(82, 39, 'Daily Cut unnecessary expenses', 'pending', 'easy', 'Finance', 4, 8, '2025-05-28 02:57:27'),
(83, 39, 'Daily Take vitamins', 'pending', 'hard', 'Physical Health', 7, 15, '2025-05-28 02:57:27'),
(84, 40, 'Daily Research investments', 'pending', 'easy', 'Finance', 8, 11, '2025-05-28 02:57:27'),
(85, 40, 'Daily Research investments', 'pending', 'hard', 'Finance', 2, 6, '2025-05-28 02:57:27'),
(86, 40, 'Daily Update resume', 'completed', 'medium', 'Career / Studies', 6, 15, '2025-05-28 02:57:27'),
(87, 41, 'Daily Learn something new', 'completed', 'medium', 'Personal Growth', 3, 6, '2025-05-28 02:57:27'),
(88, 41, 'Daily Call a friend', 'pending', 'easy', 'Relationships Social', 5, 10, '2025-05-28 02:57:27'),
(89, 41, 'Daily Network with professionals', 'pending', 'easy', 'Career / Studies', 7, 13, '2025-05-28 02:57:27'),
(90, 42, 'Daily Practice a skill', 'completed', 'medium', 'Personal Growth', 7, 5, '2025-05-28 02:57:27'),
(91, 42, 'Daily Cut unnecessary expenses', 'completed', 'easy', 'Finance', 6, 8, '2025-05-28 02:57:27'),
(92, 43, 'Daily Write gratitude list', 'pending', 'hard', 'Mental Wellness', 5, 11, '2025-05-28 02:57:27'),
(93, 43, 'Daily Vacuum house', 'completed', 'easy', 'Home Environment', 4, 14, '2025-05-28 02:57:27'),
(94, 44, 'Daily Cut unnecessary expenses', 'pending', 'hard', 'Finance', 3, 7, '2025-05-28 02:57:28'),
(95, 45, 'Daily Review budget', 'completed', 'easy', 'Finance', 5, 14, '2025-05-28 02:57:28'),
(96, 45, 'Daily Cook new recipe', 'pending', 'medium', 'Passion Hobbies', 8, 9, '2025-05-28 02:57:28'),
(97, 46, 'Daily Learn something new', 'pending', 'hard', 'Personal Growth', 8, 11, '2025-05-28 02:57:28'),
(98, 47, 'Daily Take online course', 'completed', 'hard', 'Career / Studies', 7, 9, '2025-05-28 02:57:28'),
(99, 47, 'Daily Set daily goals', 'pending', 'easy', 'Personal Growth', 5, 5, '2025-05-28 02:57:28'),
(100, 48, 'Daily Research investments', 'completed', 'hard', 'Finance', 6, 15, '2025-05-28 02:57:28'),
(101, 48, 'Daily Take online course', 'pending', 'easy', 'Career / Studies', 2, 6, '2025-05-28 02:57:28'),
(102, 49, 'Daily Do 20 push-ups', 'pending', 'hard', 'Physical Health', 7, 13, '2025-05-28 02:57:28'),
(103, 49, 'Daily Drink 8 glasses of water', 'completed', 'hard', 'Physical Health', 8, 10, '2025-05-28 02:57:28'),
(104, 49, 'Daily Cut unnecessary expenses', 'pending', 'easy', 'Finance', 7, 9, '2025-05-28 02:57:28'),
(105, 50, 'Daily Resolve conflicts', 'pending', 'hard', 'Relationships Social', 2, 15, '2025-05-28 02:57:28'),
(106, 50, 'Daily Meditate for 10 minutes', 'pending', 'medium', 'Mental Wellness', 7, 14, '2025-05-28 02:57:28'),
(107, 50, 'Daily Review financial goals', 'completed', 'easy', 'Finance', 7, 8, '2025-05-28 02:57:28'),
(108, 51, 'Daily Set daily goals', 'pending', 'medium', 'Personal Growth', 8, 9, '2025-05-28 02:57:28'),
(109, 51, 'Daily Read self-help book', 'pending', 'medium', 'Personal Growth', 6, 5, '2025-05-28 02:57:28'),
(110, 52, 'Daily Practice guitar', 'pending', 'hard', 'Passion Hobbies', 3, 9, '2025-05-28 02:57:28'),
(111, 52, 'Daily Watch educational video', 'pending', 'hard', 'Personal Growth', 7, 9, '2025-05-28 02:57:28'),
(112, 52, 'Daily Resolve conflicts', 'completed', 'easy', 'Relationships Social', 8, 7, '2025-05-28 02:57:28'),
(113, 53, 'Daily Practice a skill', 'pending', 'medium', 'Personal Growth', 8, 7, '2025-05-28 02:57:28'),
(114, 53, 'Daily Review financial goals', 'completed', 'easy', 'Finance', 2, 13, '2025-05-28 02:57:28'),
(115, 53, 'Daily Take vitamins', 'pending', 'hard', 'Physical Health', 7, 12, '2025-05-28 02:57:28'),
(116, 54, 'Daily Practice yoga', 'completed', 'hard', 'Physical Health', 3, 14, '2025-05-28 02:57:28'),
(117, 54, 'Daily Play board games', 'completed', 'hard', 'Passion Hobbies', 8, 15, '2025-05-28 02:57:28'),
(118, 55, 'Daily Listen to calming music', 'pending', 'hard', 'Mental Wellness', 8, 5, '2025-05-28 02:57:28'),
(119, 55, 'Daily Study programming', 'pending', 'hard', 'Career / Studies', 8, 11, '2025-05-28 02:57:28'),
(120, 56, 'Daily Update resume', 'pending', 'medium', 'Career / Studies', 7, 10, '2025-05-28 02:57:28'),
(121, 56, 'Daily Do brain exercises', 'completed', 'easy', 'Mental Wellness', 4, 13, '2025-05-28 02:57:28'),
(122, 56, 'Daily Track expenses', 'pending', 'medium', 'Finance', 3, 6, '2025-05-28 02:57:28'),
(123, 57, 'Daily Learn about finances', 'pending', 'medium', 'Finance', 2, 12, '2025-05-28 02:57:28'),
(124, 58, 'Daily Practice mindfulness', 'pending', 'easy', 'Mental Wellness', 5, 6, '2025-05-28 02:57:28'),
(125, 58, 'Daily Practice guitar', 'completed', 'medium', 'Passion Hobbies', 3, 14, '2025-05-28 02:57:28'),
(126, 59, 'Daily Take online course', 'pending', 'hard', 'Career / Studies', 4, 14, '2025-05-28 02:57:28'),
(127, 60, 'Daily Take online course', 'pending', 'medium', 'Career / Studies', 5, 13, '2025-05-28 02:57:28'),
(128, 60, 'Daily Learn new hobby', 'pending', 'medium', 'Passion Hobbies', 4, 10, '2025-05-28 02:57:28'),
(129, 60, 'Daily Read self-help book', 'pending', 'easy', 'Personal Growth', 2, 14, '2025-05-28 02:57:28'),
(130, 61, 'Daily Write in journal', 'pending', 'easy', 'Passion Hobbies', 2, 12, '2025-05-28 02:57:28'),
(131, 61, 'Daily Practice deep breathing', 'completed', 'medium', 'Mental Wellness', 4, 5, '2025-05-28 02:57:28'),
(132, 62, 'Daily Take vitamins', 'pending', 'medium', 'Physical Health', 5, 12, '2025-05-28 02:57:28'),
(133, 62, 'Daily Research investments', 'pending', 'easy', 'Finance', 7, 8, '2025-05-28 02:57:28'),
(134, 63, 'Daily Organize workspace', 'completed', 'easy', 'Home Environment', 8, 13, '2025-05-28 02:57:28'),
(135, 63, 'Daily Write gratitude list', 'completed', 'hard', 'Mental Wellness', 3, 6, '2025-05-28 02:57:28'),
(136, 63, 'Daily Garden for 30 minutes', 'completed', 'easy', 'Passion Hobbies', 8, 10, '2025-05-28 02:57:28'),
(137, 64, 'Daily Call a friend', 'pending', 'easy', 'Relationships Social', 7, 9, '2025-05-28 02:57:28'),
(138, 64, 'Daily Practice deep breathing', 'completed', 'easy', 'Mental Wellness', 5, 5, '2025-05-28 02:57:28'),
(139, 64, 'Daily Practice interview skills', 'pending', 'medium', 'Career / Studies', 3, 11, '2025-05-28 02:57:28'),
(140, 65, 'Daily Show appreciation', 'pending', 'easy', 'Relationships Social', 5, 15, '2025-05-28 02:57:28'),
(141, 65, 'Daily Research investments', 'pending', 'medium', 'Finance', 3, 10, '2025-05-28 02:57:28'),
(142, 65, 'Daily Network with professionals', 'pending', 'easy', 'Career / Studies', 3, 8, '2025-05-28 02:57:28'),
(143, 66, 'Daily Listen to calming music', 'pending', 'hard', 'Mental Wellness', 7, 15, '2025-05-28 02:57:28'),
(144, 67, 'Daily Resolve conflicts', 'completed', 'medium', 'Relationships Social', 6, 8, '2025-05-28 02:57:28'),
(145, 68, 'Daily Drink 8 glasses of water', 'completed', 'easy', 'Physical Health', 3, 13, '2025-05-28 02:57:28'),
(146, 68, 'Daily Practice mindfulness', 'pending', 'medium', 'Mental Wellness', 7, 11, '2025-05-28 02:57:28'),
(147, 68, 'Daily Show appreciation', 'pending', 'easy', 'Relationships Social', 4, 8, '2025-05-28 02:57:28'),
(148, 69, 'Daily Write gratitude list', 'completed', 'easy', 'Mental Wellness', 8, 12, '2025-05-28 02:57:28'),
(149, 69, 'Daily Go for a 30-minute walk', 'pending', 'easy', 'Physical Health', 8, 7, '2025-05-28 02:57:28'),
(150, 69, 'Daily Write gratitude list', 'pending', 'easy', 'Mental Wellness', 4, 15, '2025-05-28 02:57:28'),
(151, 70, 'Daily Network with professionals', 'pending', 'easy', 'Career / Studies', 4, 15, '2025-05-28 02:57:28'),
(152, 71, 'Daily Practice coding', 'pending', 'hard', 'Career / Studies', 5, 11, '2025-05-28 02:57:28'),
(153, 71, 'Daily Meditate for 10 minutes', 'pending', 'hard', 'Mental Wellness', 4, 13, '2025-05-28 02:57:28'),
(154, 72, 'Daily Research investments', 'completed', 'hard', 'Finance', 8, 13, '2025-05-28 02:57:28'),
(155, 72, 'Daily Practice active listening', 'completed', 'hard', 'Relationships Social', 7, 8, '2025-05-28 02:57:28'),
(156, 72, 'Daily Practice active listening', 'pending', 'hard', 'Relationships Social', 6, 15, '2025-05-28 02:57:28'),
(157, 73, 'Daily Learn something new', 'completed', 'easy', 'Personal Growth', 6, 14, '2025-05-28 02:57:28'),
(158, 73, 'Daily Listen to calming music', 'completed', 'easy', 'Mental Wellness', 3, 7, '2025-05-28 02:57:28'),
(159, 73, 'Daily Practice yoga', 'completed', 'easy', 'Physical Health', 6, 6, '2025-05-28 02:57:28'),
(160, 74, 'Daily Study programming', 'completed', 'easy', 'Career / Studies', 7, 10, '2025-05-28 02:57:28'),
(161, 74, 'Daily Review financial goals', 'completed', 'hard', 'Finance', 4, 8, '2025-05-28 02:57:28'),
(162, 74, 'Daily Meditate for 10 minutes', 'pending', 'medium', 'Mental Wellness', 5, 12, '2025-05-28 02:57:28'),
(163, 75, 'Daily Organize workspace', 'completed', 'easy', 'Home Environment', 3, 7, '2025-05-28 02:57:28'),
(164, 75, 'Daily Stretch for 10 minutes', 'pending', 'easy', 'Physical Health', 7, 5, '2025-05-28 02:57:28'),
(165, 75, 'Daily Update resume', 'pending', 'hard', 'Career / Studies', 2, 12, '2025-05-28 02:57:28'),
(166, 76, 'Daily Track expenses', 'completed', 'easy', 'Finance', 6, 13, '2025-05-28 02:57:28'),
(167, 77, 'Daily Eat a healthy breakfast', 'pending', 'easy', 'Physical Health', 7, 10, '2025-05-28 02:57:28'),
(168, 77, 'Daily Go for a 30-minute walk', 'pending', 'medium', 'Physical Health', 7, 10, '2025-05-28 02:57:28'),
(169, 77, 'Daily Update resume', 'completed', 'medium', 'Career / Studies', 6, 6, '2025-05-28 02:57:28'),
(170, 78, 'Daily Resolve conflicts', 'pending', 'easy', 'Relationships Social', 6, 7, '2025-05-28 02:57:28'),
(171, 78, 'Daily Practice mindfulness', 'completed', 'hard', 'Mental Wellness', 4, 6, '2025-05-28 02:57:28'),
(172, 78, 'Daily Eat a healthy breakfast', 'pending', 'easy', 'Physical Health', 5, 13, '2025-05-28 02:57:28'),
(173, 79, 'Daily Practice coding', 'pending', 'easy', 'Career / Studies', 5, 8, '2025-05-28 02:57:28'),
(174, 79, 'Daily Call a friend', 'completed', 'hard', 'Relationships Social', 2, 13, '2025-05-28 02:57:28'),
(175, 80, 'Daily Spend time with family', 'pending', 'hard', 'Relationships Social', 2, 7, '2025-05-28 02:57:28'),
(176, 81, 'Daily Practice mindfulness', 'completed', 'medium', 'Mental Wellness', 2, 5, '2025-05-28 02:57:28'),
(177, 81, 'Daily Review budget', 'pending', 'medium', 'Finance', 5, 8, '2025-05-28 02:57:28'),
(178, 82, 'Daily Drink 8 glasses of water', 'pending', 'hard', 'Physical Health', 6, 5, '2025-05-28 02:57:28'),
(179, 82, 'Daily Save money', 'completed', 'medium', 'Finance', 8, 8, '2025-05-28 02:57:28'),
(180, 82, 'Daily Track expenses', 'pending', 'hard', 'Finance', 6, 13, '2025-05-28 02:57:28'),
(181, 83, 'Daily Network with professionals', 'pending', 'medium', 'Career / Studies', 3, 8, '2025-05-28 02:57:28'),
(182, 83, 'Daily Learn about finances', 'completed', 'hard', 'Finance', 7, 9, '2025-05-28 02:57:28'),
(183, 83, 'Daily Practice public speaking', 'pending', 'easy', 'Personal Growth', 8, 14, '2025-05-28 02:57:28'),
(184, 84, 'Daily Water plants', 'completed', 'medium', 'Home Environment', 4, 11, '2025-05-28 02:57:28'),
(185, 84, 'Daily Vacuum house', 'pending', 'medium', 'Home Environment', 3, 9, '2025-05-28 02:57:28'),
(186, 84, 'Daily Vacuum house', 'pending', 'hard', 'Home Environment', 7, 9, '2025-05-28 02:57:28'),
(187, 85, 'Daily Go for a 30-minute walk', 'pending', 'medium', 'Physical Health', 8, 12, '2025-05-28 02:57:28'),
(188, 85, 'Daily Network with professionals', 'pending', 'hard', 'Career / Studies', 8, 10, '2025-05-28 02:57:28'),
(189, 86, 'Daily Write thank you note', 'pending', 'easy', 'Relationships Social', 2, 14, '2025-05-28 02:57:28'),
(190, 86, 'Daily Save money', 'completed', 'easy', 'Finance', 2, 15, '2025-05-28 02:57:28'),
(191, 86, 'Daily Learn something new', 'pending', 'easy', 'Personal Growth', 5, 12, '2025-05-28 02:57:28'),
(192, 87, 'Daily Practice public speaking', 'pending', 'hard', 'Personal Growth', 5, 6, '2025-05-28 02:57:28'),
(193, 88, 'Daily Clean living space', 'completed', 'hard', 'Home Environment', 8, 13, '2025-05-28 02:57:28'),
(194, 88, 'Daily Practice public speaking', 'completed', 'easy', 'Personal Growth', 6, 6, '2025-05-28 02:57:28'),
(195, 88, 'Daily Take online course', 'completed', 'hard', 'Career / Studies', 8, 13, '2025-05-28 02:57:28'),
(196, 89, 'Daily Review financial goals', 'pending', 'hard', 'Finance', 5, 5, '2025-05-28 02:57:28'),
(197, 90, 'Daily Practice deep breathing', 'completed', 'easy', 'Mental Wellness', 4, 12, '2025-05-28 02:57:28'),
(198, 90, 'Daily Take a mental health break', 'pending', 'hard', 'Mental Wellness', 7, 14, '2025-05-28 02:57:28'),
(199, 90, 'Daily Drink 8 glasses of water', 'pending', 'hard', 'Physical Health', 8, 7, '2025-05-28 02:57:28'),
(200, 91, 'Daily Work on art project', 'pending', 'easy', 'Passion Hobbies', 5, 10, '2025-05-28 02:57:28'),
(201, 91, 'Daily Play board games', 'pending', 'hard', 'Passion Hobbies', 8, 15, '2025-05-28 02:57:28'),
(202, 92, 'Daily Practice guitar', 'completed', 'medium', 'Passion Hobbies', 8, 6, '2025-05-28 02:57:28'),
(203, 92, 'Daily Garden for 30 minutes', 'pending', 'hard', 'Passion Hobbies', 7, 8, '2025-05-28 02:57:28'),
(204, 92, 'Daily Pay bills on time', 'completed', 'easy', 'Finance', 7, 10, '2025-05-28 02:57:28'),
(205, 93, 'Daily Resolve conflicts', 'pending', 'hard', 'Relationships Social', 3, 9, '2025-05-28 02:57:28'),
(206, 94, 'Daily Practice coding', 'pending', 'easy', 'Career / Studies', 3, 12, '2025-05-28 02:57:28'),
(207, 95, 'Daily Track expenses', 'completed', 'medium', 'Finance', 5, 8, '2025-05-28 02:57:28'),
(208, 96, 'Daily Cook new recipe', 'completed', 'hard', 'Passion Hobbies', 7, 11, '2025-05-28 02:57:28'),
(209, 96, 'Daily Practice public speaking', 'pending', 'easy', 'Personal Growth', 5, 14, '2025-05-28 02:57:28'),
(210, 96, 'Daily Practice a skill', 'pending', 'hard', 'Personal Growth', 4, 8, '2025-05-28 02:57:28'),
(211, 97, 'Daily Plan social activity', 'pending', 'hard', 'Relationships Social', 7, 12, '2025-05-28 02:57:28'),
(212, 97, 'Daily Meditate for 10 minutes', 'pending', 'easy', 'Mental Wellness', 2, 9, '2025-05-28 02:57:28'),
(213, 97, 'Daily Organize workspace', 'completed', 'easy', 'Home Environment', 3, 13, '2025-05-28 02:57:28'),
(214, 98, 'Daily Meal prep', 'completed', 'easy', 'Home Environment', 7, 6, '2025-05-28 02:57:28'),
(215, 98, 'Daily Call a friend', 'pending', 'medium', 'Relationships Social', 5, 13, '2025-05-28 02:57:28'),
(216, 99, 'Daily Spend time with family', 'completed', 'hard', 'Relationships Social', 3, 6, '2025-05-28 02:57:28'),
(217, 99, 'Daily Clean living space', 'pending', 'easy', 'Home Environment', 6, 5, '2025-05-28 02:57:28'),
(218, 99, 'Daily Practice a skill', 'pending', 'medium', 'Personal Growth', 3, 14, '2025-05-28 02:57:28'),
(219, 100, 'Daily Read for 30 minutes', 'pending', 'easy', 'Mental Wellness', 3, 14, '2025-05-28 02:57:28'),
(220, 100, 'Daily Set daily goals', 'pending', 'easy', 'Personal Growth', 3, 12, '2025-05-28 02:57:28'),
(221, 101, 'Daily Plan future goals', 'pending', 'medium', 'Personal Growth', 4, 13, '2025-05-28 02:57:28'),
(222, 101, 'Daily Read self-help book', 'pending', 'hard', 'Personal Growth', 6, 10, '2025-05-28 02:57:28'),
(223, 101, 'Daily Write thank you note', 'pending', 'easy', 'Relationships Social', 2, 14, '2025-05-28 02:57:28'),
(224, 102, 'Daily Do laundry', 'completed', 'easy', 'Home Environment', 7, 9, '2025-05-28 02:57:28'),
(225, 103, 'Daily Meditate for 10 minutes', 'completed', 'hard', 'Mental Wellness', 4, 13, '2025-05-28 02:57:28'),
(226, 103, 'Daily Plan future goals', 'pending', 'medium', 'Personal Growth', 2, 6, '2025-05-28 02:57:28'),
(227, 103, 'Daily Practice guitar', 'pending', 'easy', 'Passion Hobbies', 2, 10, '2025-05-28 02:57:28'),
(228, 104, 'Daily Do cardio workout', 'completed', 'medium', 'Physical Health', 8, 8, '2025-05-28 02:57:28'),
(229, 105, 'Daily Practice guitar', 'completed', 'hard', 'Passion Hobbies', 4, 10, '2025-05-28 02:57:28'),
(230, 105, 'Daily Spend time with family', 'pending', 'medium', 'Relationships Social', 4, 12, '2025-05-28 02:57:28'),
(231, 105, 'Daily Write gratitude list', 'pending', 'easy', 'Mental Wellness', 7, 13, '2025-05-28 02:57:28'),
(232, 106, 'Daily Reflect on progress', 'completed', 'easy', 'Personal Growth', 2, 15, '2025-05-28 02:57:28'),
(233, 106, 'Daily Do 20 push-ups', 'pending', 'easy', 'Physical Health', 8, 14, '2025-05-28 02:57:28'),
(234, 106, 'Daily Write gratitude list', 'pending', 'hard', 'Mental Wellness', 4, 9, '2025-05-28 02:57:28'),
(235, 107, 'gagag', 'pending', 'easy', 'Physical Health', 5, 10, '2025-05-28 06:45:56'),
(236, 108, 'workout', 'completed', 'easy', 'Physical Health', 5, 10, '2025-05-28 14:09:44');

--
-- Triggers `dailytasks`
--
DELIMITER $$
CREATE TRIGGER `after_dailytask_completion` AFTER UPDATE ON `dailytasks` FOR EACH ROW BEGIN
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
(1, 1, 'Meal prep', 'easy', 'Home Environment', 'pending', 9, 19, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(2, 1, 'Planning', 'easy', 'Personal Growth', 'pending', 9, 18, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(3, 3, 'Bill management', 'easy', 'Finance', 'pending', 8, 9, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(4, 3, 'Expense tracking', 'easy', 'Finance', 'pending', 4, 13, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(5, 3, 'Expense tracking', 'medium', 'Finance', 'pending', 9, 10, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(6, 4, 'Skill practice', 'medium', 'Personal Growth', 'pending', 10, 19, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(7, 4, 'Budget review', 'medium', 'Finance', 'pending', 8, 20, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(8, 4, 'Exercise routine', 'medium', 'Physical Health', 'pending', 10, 15, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(9, 4, 'Appreciation', 'easy', 'Relationships Social', 'pending', 2, 19, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(10, 4, 'Expense tracking', 'easy', 'Finance', 'pending', 9, 11, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(11, 5, 'Code practice', 'easy', 'Career / Studies', 'pending', 10, 12, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(12, 5, 'Goal setting', 'medium', 'Personal Growth', 'pending', 7, 17, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(13, 5, 'Drink water', 'medium', 'Physical Health', 'pending', 6, 16, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(14, 5, 'Expense tracking', 'easy', 'Finance', 'pending', 10, 8, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(15, 6, 'Decluttering', 'easy', 'Home Environment', 'pending', 3, 6, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(16, 6, 'Decluttering', 'medium', 'Home Environment', 'pending', 4, 15, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(17, 6, 'Study session', 'easy', 'Career / Studies', 'pending', 5, 19, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(18, 7, 'Portfolio work', 'medium', 'Career / Studies', 'pending', 4, 11, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(19, 7, 'Expense tracking', 'easy', 'Finance', 'pending', 7, 6, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(20, 8, 'Communication', 'easy', 'Relationships Social', 'pending', 4, 7, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(21, 8, 'Expense tracking', 'easy', 'Finance', 'pending', 9, 20, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(22, 8, 'Daily check-in', 'medium', 'Relationships Social', 'pending', 6, 14, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(23, 8, 'Bill management', 'easy', 'Finance', 'pending', 3, 8, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(24, 8, 'Study session', 'easy', 'Career / Studies', 'pending', 8, 16, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(25, 9, 'Study session', 'medium', 'Career / Studies', 'pending', 5, 13, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(26, 9, 'Saving habit', 'easy', 'Finance', 'pending', 10, 12, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(27, 9, 'Daily learning', 'medium', 'Personal Growth', 'pending', 3, 14, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(28, 9, 'Daily check-in', 'medium', 'Relationships Social', 'pending', 4, 5, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(29, 9, 'Exercise routine', 'easy', 'Physical Health', 'pending', 2, 14, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(30, 10, 'Expense tracking', 'easy', 'Finance', 'pending', 7, 12, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(31, 10, 'Code practice', 'medium', 'Career / Studies', 'pending', 7, 20, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(32, 10, 'Drink water', 'medium', 'Physical Health', 'pending', 5, 19, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(33, 10, 'Expense tracking', 'medium', 'Finance', 'pending', 2, 20, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(34, 11, 'Daily learning', 'medium', 'Personal Growth', 'pending', 4, 8, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(35, 11, 'Maintenance', 'medium', 'Home Environment', 'pending', 6, 17, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(36, 11, 'Daily learning', 'medium', 'Personal Growth', 'pending', 6, 13, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(37, 11, 'Creative time', 'easy', 'Passion Hobbies', 'pending', 5, 13, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(38, 11, 'Hobby practice', 'easy', 'Passion Hobbies', 'pending', 2, 7, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(39, 12, 'Music practice', 'medium', 'Passion Hobbies', 'pending', 6, 18, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(40, 12, 'Appreciation', 'easy', 'Relationships Social', 'pending', 10, 18, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(41, 12, 'Study session', 'easy', 'Career / Studies', 'pending', 4, 18, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(42, 13, 'Skill practice', 'easy', 'Personal Growth', 'pending', 3, 20, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(43, 13, 'Saving habit', 'medium', 'Finance', 'pending', 6, 5, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(44, 13, 'Take vitamins', 'easy', 'Physical Health', 'pending', 10, 15, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(45, 13, 'Creative time', 'medium', 'Passion Hobbies', 'pending', 3, 13, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(46, 13, 'Skill practice', 'medium', 'Personal Growth', 'pending', 2, 11, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(47, 14, 'Goal setting', 'easy', 'Personal Growth', 'pending', 9, 13, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(48, 14, 'Hobby practice', 'medium', 'Passion Hobbies', 'pending', 9, 15, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(49, 14, 'Fun activity', 'easy', 'Passion Hobbies', 'pending', 2, 5, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(50, 15, 'Planning', 'medium', 'Personal Growth', 'pending', 3, 20, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(51, 15, 'Expense tracking', 'easy', 'Finance', 'pending', 2, 7, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(52, 16, 'Financial learning', 'easy', 'Finance', 'pending', 8, 13, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(53, 16, 'Organization', 'easy', 'Home Environment', 'pending', 6, 10, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(54, 17, 'Art creation', 'easy', 'Passion Hobbies', 'pending', 10, 9, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(55, 17, 'Self reflection', 'medium', 'Personal Growth', 'pending', 3, 10, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(56, 17, 'Hobby practice', 'easy', 'Passion Hobbies', 'pending', 4, 11, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(57, 17, 'Appreciation', 'medium', 'Relationships Social', 'pending', 3, 15, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(58, 17, 'Maintenance', 'easy', 'Home Environment', 'pending', 4, 14, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(59, 18, 'Gratitude practice', 'easy', 'Mental Wellness', 'pending', 2, 6, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(60, 18, 'Daily learning', 'medium', 'Personal Growth', 'pending', 2, 19, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(61, 19, 'Saving habit', 'easy', 'Finance', 'pending', 7, 11, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(62, 19, 'Gratitude practice', 'medium', 'Mental Wellness', 'pending', 2, 20, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(63, 19, 'Saving habit', 'medium', 'Finance', 'pending', 6, 19, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(64, 20, 'Self reflection', 'easy', 'Personal Growth', 'pending', 3, 5, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(65, 20, 'Goal setting', 'medium', 'Personal Growth', 'pending', 8, 19, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(66, 21, 'Drink water', 'easy', 'Physical Health', 'pending', 6, 13, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(67, 21, 'Goal setting', 'medium', 'Personal Growth', 'pending', 3, 13, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(68, 21, 'Self reflection', 'medium', 'Personal Growth', 'pending', 9, 7, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(69, 21, 'Take vitamins', 'medium', 'Physical Health', 'pending', 7, 9, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(70, 21, 'Saving habit', 'easy', 'Finance', 'pending', 2, 13, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(71, 22, 'Saving habit', 'medium', 'Finance', 'pending', 2, 9, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(72, 22, 'Mindfulness', 'easy', 'Mental Wellness', 'pending', 2, 16, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(73, 23, 'Exercise routine', 'medium', 'Physical Health', 'pending', 8, 17, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(74, 23, 'Portfolio work', 'medium', 'Career / Studies', 'pending', 9, 20, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(75, 23, 'Organization', 'easy', 'Home Environment', 'pending', 10, 6, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(76, 23, 'Financial learning', 'medium', 'Finance', 'pending', 8, 12, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(77, 24, 'Morning stretch', 'easy', 'Physical Health', 'pending', 3, 9, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(78, 24, 'Meal prep', 'easy', 'Home Environment', 'pending', 6, 8, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(79, 24, 'Organization', 'easy', 'Home Environment', 'pending', 3, 15, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(80, 24, 'Financial learning', 'easy', 'Finance', 'pending', 6, 6, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(81, 25, 'Expense tracking', 'medium', 'Finance', 'pending', 4, 15, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(82, 25, 'Communication', 'medium', 'Relationships Social', 'pending', 8, 8, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(83, 25, 'Maintenance', 'easy', 'Home Environment', 'pending', 5, 10, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(84, 26, 'Appreciation', 'medium', 'Relationships Social', 'pending', 6, 12, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(85, 26, 'Daily check-in', 'easy', 'Relationships Social', 'pending', 8, 5, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(86, 26, 'Daily meditation', 'easy', 'Mental Wellness', 'pending', 7, 8, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(87, 26, 'Organization', 'medium', 'Home Environment', 'pending', 9, 10, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(88, 27, 'Financial learning', 'easy', 'Finance', 'pending', 8, 14, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(89, 27, 'Room cleaning', 'medium', 'Home Environment', 'pending', 9, 16, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(90, 27, 'Creative time', 'medium', 'Passion Hobbies', 'pending', 10, 10, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(91, 27, 'Connection', 'easy', 'Relationships Social', 'pending', 2, 7, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(92, 27, 'Expense tracking', 'easy', 'Finance', 'pending', 6, 13, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(93, 28, 'Meal prep', 'medium', 'Home Environment', 'pending', 8, 9, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(94, 28, 'Appreciation', 'easy', 'Relationships Social', 'pending', 3, 11, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(95, 28, 'Budget review', 'medium', 'Finance', 'pending', 10, 18, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(96, 28, 'Decluttering', 'easy', 'Home Environment', 'pending', 8, 17, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(97, 29, 'Connection', 'easy', 'Relationships Social', 'pending', 3, 14, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(98, 29, 'Mindfulness', 'easy', 'Mental Wellness', 'pending', 9, 15, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(99, 29, 'Art creation', 'medium', 'Passion Hobbies', 'pending', 3, 12, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(100, 29, 'Daily check-in', 'medium', 'Relationships Social', 'pending', 5, 11, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(101, 29, 'Hobby practice', 'medium', 'Passion Hobbies', 'pending', 2, 17, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(102, 30, 'Art creation', 'medium', 'Passion Hobbies', 'pending', 8, 18, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(103, 30, 'Portfolio work', 'easy', 'Career / Studies', 'pending', 4, 12, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(104, 30, 'Fun activity', 'easy', 'Passion Hobbies', 'pending', 2, 7, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(105, 30, 'Connection', 'easy', 'Relationships Social', 'pending', 7, 18, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(106, 30, 'Meal prep', 'medium', 'Home Environment', 'pending', 10, 8, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(107, 31, 'Journaling', 'medium', 'Mental Wellness', 'pending', 6, 6, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(108, 31, 'Appreciation', 'medium', 'Relationships Social', 'pending', 9, 7, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(109, 32, 'Take vitamins', 'medium', 'Physical Health', 'pending', 10, 18, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(110, 32, 'Expense tracking', 'medium', 'Finance', 'pending', 7, 11, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(111, 32, 'Portfolio work', 'easy', 'Career / Studies', 'pending', 9, 14, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(112, 33, 'Music practice', 'medium', 'Passion Hobbies', 'pending', 5, 6, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(113, 33, 'Expense tracking', 'medium', 'Finance', 'pending', 4, 13, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(114, 33, 'Decluttering', 'easy', 'Home Environment', 'pending', 4, 8, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(115, 34, 'Connection', 'easy', 'Relationships Social', 'pending', 8, 16, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(116, 34, 'Fun activity', 'easy', 'Passion Hobbies', 'pending', 9, 12, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(117, 35, 'Maintenance', 'easy', 'Home Environment', 'pending', 2, 8, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(118, 35, 'Saving habit', 'easy', 'Finance', 'pending', 7, 5, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(119, 35, 'Connection', 'medium', 'Relationships Social', 'pending', 7, 13, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(120, 35, 'Room cleaning', 'easy', 'Home Environment', 'pending', 7, 17, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(121, 35, 'Decluttering', 'easy', 'Home Environment', 'pending', 4, 16, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(122, 36, 'Learning', 'medium', 'Career / Studies', 'pending', 7, 13, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(123, 36, 'Saving habit', 'medium', 'Finance', 'pending', 8, 6, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(124, 36, 'Take vitamins', 'medium', 'Physical Health', 'pending', 6, 14, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(125, 37, 'Appreciation', 'medium', 'Relationships Social', 'pending', 7, 18, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(126, 37, 'Connection', 'medium', 'Relationships Social', 'pending', 2, 12, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(127, 38, 'Maintenance', 'medium', 'Home Environment', 'pending', 6, 16, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(128, 38, 'Journaling', 'easy', 'Mental Wellness', 'pending', 2, 18, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(129, 38, 'Daily walk', 'medium', 'Physical Health', 'pending', 6, 8, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(130, 39, 'Fun activity', 'easy', 'Passion Hobbies', 'pending', 5, 12, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(131, 39, 'Quality time', 'easy', 'Relationships Social', 'pending', 10, 5, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(132, 39, 'Planning', 'easy', 'Personal Growth', 'pending', 9, 15, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(133, 40, 'Connection', 'medium', 'Relationships Social', 'pending', 2, 5, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(134, 40, 'Study session', 'easy', 'Career / Studies', 'pending', 7, 10, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(135, 41, 'Art creation', 'medium', 'Passion Hobbies', 'pending', 10, 19, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(136, 41, 'Goal setting', 'medium', 'Personal Growth', 'pending', 7, 7, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(137, 42, 'Quality time', 'medium', 'Relationships Social', 'pending', 7, 9, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(138, 42, 'Organization', 'medium', 'Home Environment', 'pending', 8, 17, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(139, 42, 'Organization', 'medium', 'Home Environment', 'pending', 4, 14, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(140, 42, 'Exercise routine', 'easy', 'Physical Health', 'pending', 6, 5, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(141, 42, 'Decluttering', 'easy', 'Home Environment', 'pending', 2, 11, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(142, 43, 'Room cleaning', 'easy', 'Home Environment', 'pending', 4, 12, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(143, 43, 'Planning', 'medium', 'Personal Growth', 'pending', 10, 13, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(144, 43, 'Creative time', 'medium', 'Passion Hobbies', 'pending', 9, 16, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(145, 43, 'Saving habit', 'medium', 'Finance', 'pending', 7, 19, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(146, 43, 'Skill building', 'easy', 'Career / Studies', 'pending', 10, 16, '2025-05-28 02:57:27', '2025-05-28 02:57:27', NULL),
(147, 44, 'Daily check-in', 'easy', 'Relationships Social', 'pending', 9, 10, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(148, 44, 'Planning', 'easy', 'Personal Growth', 'pending', 10, 14, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(149, 45, 'Meal prep', 'medium', 'Home Environment', 'pending', 2, 10, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(150, 45, 'Connection', 'easy', 'Relationships Social', 'pending', 9, 8, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(151, 46, 'Quality time', 'medium', 'Relationships Social', 'pending', 8, 14, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(152, 46, 'Meal prep', 'medium', 'Home Environment', 'pending', 3, 5, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(153, 46, 'Creative time', 'easy', 'Passion Hobbies', 'pending', 5, 5, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(154, 47, 'Daily walk', 'easy', 'Physical Health', 'pending', 2, 16, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(155, 47, 'Planning', 'medium', 'Personal Growth', 'pending', 3, 15, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(156, 48, 'Gratitude practice', 'easy', 'Mental Wellness', 'pending', 8, 19, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(157, 48, 'Hobby practice', 'easy', 'Passion Hobbies', 'pending', 5, 14, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(158, 48, 'Goal setting', 'medium', 'Personal Growth', 'pending', 7, 5, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(159, 48, 'Expense tracking', 'medium', 'Finance', 'pending', 6, 14, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(160, 48, 'Creative time', 'medium', 'Passion Hobbies', 'pending', 2, 17, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(161, 49, 'Appreciation', 'easy', 'Relationships Social', 'pending', 5, 14, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(162, 49, 'Daily learning', 'medium', 'Personal Growth', 'pending', 10, 13, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(163, 49, 'Skill building', 'medium', 'Career / Studies', 'pending', 7, 17, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(164, 49, 'Hobby practice', 'easy', 'Passion Hobbies', 'pending', 6, 18, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(165, 50, 'Planning', 'easy', 'Personal Growth', 'pending', 6, 6, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(166, 50, 'Portfolio work', 'easy', 'Career / Studies', 'pending', 4, 8, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(167, 50, 'Morning stretch', 'medium', 'Physical Health', 'pending', 6, 13, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(168, 50, 'Daily meditation', 'medium', 'Mental Wellness', 'pending', 4, 15, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(169, 50, 'Creative time', 'easy', 'Passion Hobbies', 'pending', 5, 15, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(170, 51, 'Daily walk', 'easy', 'Physical Health', 'pending', 10, 20, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(171, 51, 'Maintenance', 'medium', 'Home Environment', 'pending', 7, 20, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(172, 51, 'Communication', 'medium', 'Relationships Social', 'pending', 5, 17, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(173, 51, 'Exercise routine', 'medium', 'Physical Health', 'pending', 5, 15, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(174, 51, 'Exercise routine', 'easy', 'Physical Health', 'pending', 4, 7, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(175, 52, 'Creative time', 'medium', 'Passion Hobbies', 'pending', 2, 5, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(176, 52, 'Appreciation', 'medium', 'Relationships Social', 'pending', 10, 14, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(177, 52, 'Journaling', 'easy', 'Mental Wellness', 'pending', 5, 7, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(178, 52, 'Reading habit', 'easy', 'Mental Wellness', 'pending', 6, 12, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(179, 52, 'Hobby practice', 'medium', 'Passion Hobbies', 'pending', 6, 8, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(180, 53, 'Room cleaning', 'medium', 'Home Environment', 'pending', 10, 9, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(181, 53, 'Daily meditation', 'medium', 'Mental Wellness', 'pending', 10, 19, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(182, 53, 'Hobby practice', 'easy', 'Passion Hobbies', 'pending', 8, 20, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(183, 53, 'Fun activity', 'easy', 'Passion Hobbies', 'pending', 4, 6, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(184, 53, 'Financial learning', 'medium', 'Finance', 'pending', 6, 16, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(185, 54, 'Quality time', 'medium', 'Relationships Social', 'pending', 6, 20, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(186, 54, 'Creative time', 'medium', 'Passion Hobbies', 'pending', 10, 11, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(187, 55, 'Mindfulness', 'easy', 'Mental Wellness', 'pending', 10, 18, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(188, 55, 'Decluttering', 'easy', 'Home Environment', 'pending', 4, 18, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(189, 56, 'Bill management', 'easy', 'Finance', 'pending', 5, 12, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(190, 56, 'Communication', 'medium', 'Relationships Social', 'pending', 7, 7, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(191, 56, 'Art creation', 'medium', 'Passion Hobbies', 'pending', 2, 8, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(192, 57, 'Appreciation', 'easy', 'Relationships Social', 'pending', 8, 11, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(193, 57, 'Portfolio work', 'medium', 'Career / Studies', 'pending', 8, 14, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(194, 57, 'Goal setting', 'easy', 'Personal Growth', 'pending', 3, 13, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(195, 58, 'Expense tracking', 'medium', 'Finance', 'pending', 5, 10, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(196, 58, 'Goal setting', 'medium', 'Personal Growth', 'pending', 6, 15, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(197, 58, 'Skill building', 'easy', 'Career / Studies', 'pending', 7, 9, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(198, 58, 'Creative time', 'easy', 'Passion Hobbies', 'pending', 10, 7, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(199, 59, 'Creative time', 'medium', 'Passion Hobbies', 'pending', 4, 12, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(200, 59, 'Appreciation', 'medium', 'Relationships Social', 'pending', 9, 16, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(201, 59, 'Journaling', 'medium', 'Mental Wellness', 'pending', 6, 7, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(202, 60, 'Skill practice', 'medium', 'Personal Growth', 'pending', 4, 7, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(203, 60, 'Self reflection', 'medium', 'Personal Growth', 'pending', 5, 15, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(204, 61, 'Planning', 'medium', 'Personal Growth', 'pending', 8, 11, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(205, 61, 'Connection', 'easy', 'Relationships Social', 'pending', 5, 9, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(206, 61, 'Gratitude practice', 'easy', 'Mental Wellness', 'pending', 3, 19, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(207, 61, 'Daily learning', 'medium', 'Personal Growth', 'pending', 5, 11, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(208, 62, 'Portfolio work', 'easy', 'Career / Studies', 'pending', 5, 12, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(209, 62, 'Room cleaning', 'medium', 'Home Environment', 'pending', 5, 13, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(210, 62, 'Daily check-in', 'easy', 'Relationships Social', 'pending', 10, 10, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(211, 63, 'Daily learning', 'easy', 'Personal Growth', 'pending', 3, 5, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(212, 63, 'Gratitude practice', 'medium', 'Mental Wellness', 'pending', 8, 9, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(213, 64, 'Saving habit', 'medium', 'Finance', 'pending', 4, 14, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(214, 64, 'Code practice', 'medium', 'Career / Studies', 'pending', 3, 5, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(215, 64, 'Connection', 'medium', 'Relationships Social', 'pending', 2, 19, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(216, 64, 'Financial learning', 'easy', 'Finance', 'pending', 10, 19, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(217, 65, 'Hobby practice', 'easy', 'Passion Hobbies', 'pending', 5, 18, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(218, 65, 'Fun activity', 'medium', 'Passion Hobbies', 'pending', 6, 11, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(219, 65, 'Music practice', 'medium', 'Passion Hobbies', 'pending', 3, 15, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(220, 66, 'Portfolio work', 'medium', 'Career / Studies', 'pending', 5, 14, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(221, 66, 'Room cleaning', 'medium', 'Home Environment', 'pending', 8, 5, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(222, 66, 'Budget review', 'easy', 'Finance', 'pending', 2, 13, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(223, 66, 'Skill building', 'medium', 'Career / Studies', 'pending', 5, 17, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(224, 66, 'Saving habit', 'easy', 'Finance', 'pending', 2, 12, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(225, 67, 'Maintenance', 'medium', 'Home Environment', 'pending', 5, 15, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(226, 67, 'Art creation', 'medium', 'Passion Hobbies', 'pending', 5, 16, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(227, 67, 'Morning stretch', 'easy', 'Physical Health', 'pending', 4, 14, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(228, 67, 'Music practice', 'medium', 'Passion Hobbies', 'pending', 5, 9, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(229, 68, 'Self reflection', 'easy', 'Personal Growth', 'pending', 9, 14, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(230, 68, 'Portfolio work', 'easy', 'Career / Studies', 'pending', 5, 15, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(231, 69, 'Maintenance', 'easy', 'Home Environment', 'pending', 9, 18, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(232, 69, 'Music practice', 'easy', 'Passion Hobbies', 'pending', 9, 5, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(233, 69, 'Creative time', 'medium', 'Passion Hobbies', 'pending', 5, 5, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(234, 70, 'Reading habit', 'easy', 'Mental Wellness', 'pending', 7, 15, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(235, 70, 'Organization', 'easy', 'Home Environment', 'pending', 4, 18, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(236, 70, 'Goal setting', 'medium', 'Personal Growth', 'pending', 3, 9, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(237, 70, 'Morning stretch', 'medium', 'Physical Health', 'pending', 6, 13, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(238, 71, 'Bill management', 'easy', 'Finance', 'pending', 10, 10, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(239, 71, 'Reading habit', 'medium', 'Mental Wellness', 'pending', 7, 14, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(240, 71, 'Expense tracking', 'easy', 'Finance', 'pending', 8, 12, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(241, 72, 'Exercise routine', 'easy', 'Physical Health', 'pending', 4, 18, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(242, 72, 'Exercise routine', 'medium', 'Physical Health', 'pending', 9, 13, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(243, 72, 'Organization', 'easy', 'Home Environment', 'pending', 8, 6, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(244, 72, 'Portfolio work', 'medium', 'Career / Studies', 'pending', 3, 18, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(245, 73, 'Exercise routine', 'easy', 'Physical Health', 'pending', 6, 18, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(246, 73, 'Drink water', 'easy', 'Physical Health', 'pending', 3, 10, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(247, 74, 'Morning stretch', 'easy', 'Physical Health', 'pending', 10, 10, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(248, 74, 'Self reflection', 'medium', 'Personal Growth', 'pending', 4, 6, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(249, 75, 'Expense tracking', 'easy', 'Finance', 'pending', 3, 9, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(250, 75, 'Skill building', 'easy', 'Career / Studies', 'pending', 2, 15, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(251, 75, 'Music practice', 'easy', 'Passion Hobbies', 'pending', 6, 7, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(252, 75, 'Hobby practice', 'medium', 'Passion Hobbies', 'pending', 4, 17, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(253, 76, 'Gratitude practice', 'easy', 'Mental Wellness', 'pending', 3, 14, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(254, 76, 'Connection', 'easy', 'Relationships Social', 'pending', 3, 12, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(255, 76, 'Budget review', 'medium', 'Finance', 'pending', 6, 6, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(256, 76, 'Daily check-in', 'easy', 'Relationships Social', 'pending', 10, 9, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(257, 76, 'Decluttering', 'medium', 'Home Environment', 'pending', 9, 6, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(258, 77, 'Appreciation', 'medium', 'Relationships Social', 'pending', 10, 18, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(259, 77, 'Exercise routine', 'easy', 'Physical Health', 'pending', 7, 8, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(260, 77, 'Fun activity', 'easy', 'Passion Hobbies', 'pending', 8, 20, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(261, 78, 'Drink water', 'medium', 'Physical Health', 'pending', 6, 10, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(262, 78, 'Code practice', 'medium', 'Career / Studies', 'pending', 6, 20, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(263, 79, 'Organization', 'medium', 'Home Environment', 'pending', 10, 18, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(264, 79, 'Drink water', 'easy', 'Physical Health', 'pending', 9, 9, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(265, 79, 'Hobby practice', 'medium', 'Passion Hobbies', 'pending', 2, 18, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(266, 79, 'Music practice', 'medium', 'Passion Hobbies', 'pending', 9, 8, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(267, 80, 'Quality time', 'medium', 'Relationships Social', 'pending', 2, 16, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(268, 80, 'Saving habit', 'easy', 'Finance', 'pending', 2, 19, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(269, 80, 'Fun activity', 'easy', 'Passion Hobbies', 'pending', 8, 7, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(270, 81, 'Mindfulness', 'medium', 'Mental Wellness', 'pending', 7, 19, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(271, 81, 'Morning stretch', 'easy', 'Physical Health', 'pending', 2, 17, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(272, 82, 'Organization', 'easy', 'Home Environment', 'pending', 6, 15, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(273, 82, 'Daily learning', 'medium', 'Personal Growth', 'pending', 3, 17, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(274, 82, 'Journaling', 'medium', 'Mental Wellness', 'pending', 7, 18, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(275, 82, 'Daily meditation', 'medium', 'Mental Wellness', 'pending', 4, 12, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(276, 82, 'Skill practice', 'medium', 'Personal Growth', 'pending', 5, 20, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(277, 83, 'Reading habit', 'easy', 'Mental Wellness', 'pending', 7, 11, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(278, 83, 'Decluttering', 'easy', 'Home Environment', 'pending', 6, 16, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(279, 84, 'Expense tracking', 'easy', 'Finance', 'pending', 3, 12, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(280, 84, 'Portfolio work', 'medium', 'Career / Studies', 'pending', 6, 20, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(281, 84, 'Goal setting', 'medium', 'Personal Growth', 'pending', 5, 8, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(282, 84, 'Organization', 'medium', 'Home Environment', 'pending', 9, 9, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(283, 85, 'Goal setting', 'easy', 'Personal Growth', 'pending', 3, 6, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(284, 85, 'Decluttering', 'easy', 'Home Environment', 'pending', 9, 5, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(285, 85, 'Meal prep', 'medium', 'Home Environment', 'pending', 7, 12, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(286, 86, 'Organization', 'easy', 'Home Environment', 'pending', 10, 15, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(287, 86, 'Drink water', 'medium', 'Physical Health', 'pending', 9, 20, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(288, 86, 'Mindfulness', 'easy', 'Mental Wellness', 'pending', 5, 16, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(289, 87, 'Connection', 'medium', 'Relationships Social', 'pending', 7, 8, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(290, 87, 'Organization', 'easy', 'Home Environment', 'pending', 9, 11, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(291, 87, 'Morning stretch', 'medium', 'Physical Health', 'pending', 6, 11, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(292, 87, 'Organization', 'medium', 'Home Environment', 'pending', 7, 8, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(293, 88, 'Skill practice', 'medium', 'Personal Growth', 'pending', 6, 9, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(294, 88, 'Daily check-in', 'easy', 'Relationships Social', 'pending', 4, 6, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(295, 88, 'Connection', 'medium', 'Relationships Social', 'pending', 3, 19, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(296, 89, 'Hobby practice', 'medium', 'Passion Hobbies', 'pending', 4, 10, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(297, 89, 'Creative time', 'medium', 'Passion Hobbies', 'pending', 7, 17, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(298, 90, 'Skill practice', 'easy', 'Personal Growth', 'pending', 2, 5, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(299, 90, 'Code practice', 'easy', 'Career / Studies', 'pending', 8, 9, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(300, 90, 'Planning', 'medium', 'Personal Growth', 'pending', 5, 19, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(301, 91, 'Communication', 'medium', 'Relationships Social', 'pending', 5, 8, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(302, 91, 'Morning stretch', 'medium', 'Physical Health', 'pending', 4, 15, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(303, 92, 'Communication', 'medium', 'Relationships Social', 'pending', 7, 12, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(304, 92, 'Connection', 'easy', 'Relationships Social', 'pending', 10, 14, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(305, 92, 'Expense tracking', 'easy', 'Finance', 'pending', 7, 12, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(306, 92, 'Study session', 'easy', 'Career / Studies', 'pending', 7, 10, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(307, 93, 'Planning', 'easy', 'Personal Growth', 'pending', 4, 19, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(308, 93, 'Morning stretch', 'medium', 'Physical Health', 'pending', 7, 17, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(309, 93, 'Journaling', 'easy', 'Mental Wellness', 'pending', 4, 18, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(310, 93, 'Expense tracking', 'easy', 'Finance', 'pending', 7, 6, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(311, 94, 'Music practice', 'easy', 'Passion Hobbies', 'pending', 7, 18, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(312, 94, 'Daily learning', 'medium', 'Personal Growth', 'pending', 6, 13, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(313, 94, 'Daily walk', 'easy', 'Physical Health', 'pending', 5, 18, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(314, 94, 'Goal setting', 'medium', 'Personal Growth', 'pending', 2, 20, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(315, 95, 'Portfolio work', 'easy', 'Career / Studies', 'pending', 5, 13, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(316, 95, 'Expense tracking', 'medium', 'Finance', 'pending', 4, 19, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(317, 95, 'Morning stretch', 'easy', 'Physical Health', 'pending', 4, 5, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(318, 95, 'Creative time', 'easy', 'Passion Hobbies', 'pending', 5, 5, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(319, 95, 'Gratitude practice', 'medium', 'Mental Wellness', 'pending', 5, 18, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(320, 96, 'Financial learning', 'medium', 'Finance', 'pending', 8, 14, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(321, 96, 'Organization', 'medium', 'Home Environment', 'pending', 9, 13, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(322, 96, 'Communication', 'medium', 'Relationships Social', 'pending', 2, 15, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(323, 97, 'Connection', 'medium', 'Relationships Social', 'pending', 5, 5, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(324, 97, 'Creative time', 'medium', 'Passion Hobbies', 'pending', 10, 19, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(325, 97, 'Study session', 'easy', 'Career / Studies', 'pending', 7, 9, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(326, 98, 'Skill building', 'medium', 'Career / Studies', 'pending', 4, 11, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(327, 98, 'Daily meditation', 'easy', 'Mental Wellness', 'pending', 9, 9, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(328, 99, 'Study session', 'easy', 'Career / Studies', 'pending', 10, 16, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(329, 99, 'Music practice', 'medium', 'Passion Hobbies', 'pending', 6, 12, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(330, 99, 'Maintenance', 'medium', 'Home Environment', 'pending', 3, 5, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(331, 99, 'Art creation', 'easy', 'Passion Hobbies', 'pending', 3, 16, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(332, 99, 'Learning', 'easy', 'Career / Studies', 'pending', 6, 10, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(333, 100, 'Daily learning', 'medium', 'Personal Growth', 'pending', 9, 10, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(334, 100, 'Journaling', 'easy', 'Mental Wellness', 'pending', 4, 18, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(335, 100, 'Goal setting', 'easy', 'Personal Growth', 'pending', 9, 16, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(336, 100, 'Exercise routine', 'medium', 'Physical Health', 'pending', 7, 17, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(337, 100, 'Music practice', 'medium', 'Passion Hobbies', 'pending', 6, 12, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(338, 101, 'Learning', 'easy', 'Career / Studies', 'pending', 6, 13, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(339, 101, 'Maintenance', 'easy', 'Home Environment', 'pending', 3, 17, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(340, 101, 'Communication', 'medium', 'Relationships Social', 'pending', 8, 11, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(341, 101, 'Appreciation', 'medium', 'Relationships Social', 'pending', 4, 20, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(342, 101, 'Saving habit', 'easy', 'Finance', 'pending', 9, 13, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(343, 102, 'Morning stretch', 'medium', 'Physical Health', 'pending', 2, 19, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(344, 102, 'Goal setting', 'medium', 'Personal Growth', 'pending', 5, 7, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(345, 102, 'Hobby practice', 'easy', 'Passion Hobbies', 'pending', 2, 12, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(346, 102, 'Room cleaning', 'easy', 'Home Environment', 'pending', 2, 11, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(347, 102, 'Daily walk', 'easy', 'Physical Health', 'pending', 3, 15, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(348, 103, 'Art creation', 'easy', 'Passion Hobbies', 'pending', 2, 12, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(349, 103, 'Appreciation', 'easy', 'Relationships Social', 'pending', 8, 7, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(350, 103, 'Reading habit', 'easy', 'Mental Wellness', 'pending', 5, 11, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(351, 103, 'Quality time', 'easy', 'Relationships Social', 'pending', 6, 10, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(352, 103, 'Art creation', 'easy', 'Passion Hobbies', 'pending', 5, 9, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(353, 104, 'Creative time', 'medium', 'Passion Hobbies', 'pending', 7, 15, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(354, 104, 'Financial learning', 'medium', 'Finance', 'pending', 8, 5, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(355, 104, 'Daily check-in', 'easy', 'Relationships Social', 'pending', 7, 5, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(356, 104, 'Financial learning', 'medium', 'Finance', 'pending', 8, 18, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(357, 105, 'Daily walk', 'medium', 'Physical Health', 'pending', 9, 12, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(358, 105, 'Daily meditation', 'easy', 'Mental Wellness', 'pending', 10, 9, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(359, 105, 'Connection', 'easy', 'Relationships Social', 'pending', 8, 5, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(360, 105, 'Planning', 'easy', 'Personal Growth', 'pending', 10, 10, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(361, 106, 'Planning', 'medium', 'Personal Growth', 'pending', 4, 19, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(362, 106, 'Exercise routine', 'medium', 'Physical Health', 'pending', 7, 13, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(363, 106, 'Creative time', 'medium', 'Passion Hobbies', 'pending', 2, 20, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(364, 106, 'Skill practice', 'easy', 'Personal Growth', 'pending', 9, 13, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(365, 106, 'Morning stretch', 'easy', 'Physical Health', 'pending', 7, 9, '2025-05-28 02:57:28', '2025-05-28 02:57:28', NULL),
(366, 107, 'Study Java', 'medium', 'Career / Studies', 'completed', 10, 10, '2025-05-28 06:06:52', '2025-05-28 06:07:34', NULL),
(367, 108, 'goodhabit', 'easy', 'Mental Wellness', 'completed', 5, 5, '2025-05-28 14:10:29', '2025-05-28 14:10:34', NULL);

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
(1, 'Consumables', 'Items that can be used once for immediate effects', '/assets/images/marketplace/icons/consumable.png'),
(2, 'Equipment', 'Items that provide passive benefits when equipped', '/assets/images/marketplace/icons/equipment.png'),
(3, 'Collectibles', 'Rare items with special effects or cosmetic value', '/assets/images/marketplace/icons/collectible.png'),
(4, 'Boosts', 'Items that provide temporary buffs to stats or rewards', '/assets/images/marketplace/icons/boost.png');

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
(1, 3, '2025-05-20 14:17:33', 'Activated xp_multiplier boost of 25%'),
(2, 3, '2025-05-20 14:17:40', 'Activated xp_multiplier boost of 25%'),
(3, 3, '2025-05-20 14:17:41', 'Activated xp_multiplier boost of 25%'),
(5, 4, '2025-05-24 09:02:09', 'Item equipped successfully'),
(12, 3, '2025-05-24 10:02:50', 'Activated a 25% boost for 24 hours'),
(13, 4, '2025-05-24 10:03:01', 'Item equipped successfully'),
(15, 3, '2025-05-24 10:08:16', 'Activated a 25% boost for 24 hours'),
(17, 3, '2025-05-24 10:09:12', 'Activated a 25% boost for 24 hours'),
(18, 4, '2025-05-24 10:09:21', 'Item equipped successfully'),
(25, 3, '2025-05-24 10:49:37', 'Activated a 25% boost for 24 hours'),
(28, 4, '2025-05-24 12:36:28', 'Item equipped successfully'),
(29, 3, '2025-05-24 12:36:32', 'Activated a 25% boost for 24 hours'),
(38, 4, '2025-05-24 14:59:13', 'Item equipped successfully'),
(39, 3, '2025-05-24 14:59:35', 'Activated a 25% boost for 24 hours'),
(42, 3, '2025-05-24 15:07:18', 'Activated a 25% boost for 24 hours'),
(53, 4, '2025-05-24 15:49:07', 'Item equipped successfully'),
(63, NULL, '2025-05-25 00:38:06', 'Restored 10 health points'),
(64, NULL, '2025-05-25 00:39:07', 'Restored 10 health points'),
(65, 4, '2025-05-25 00:39:36', 'Item equipped successfully'),
(66, NULL, '2025-05-25 00:54:28', 'Consumable used with unknown effect type: xp_multiplier'),
(67, 11, '2025-05-25 00:57:13', 'Activated a 1% boost for 24 hours'),
(68, NULL, '2025-05-25 01:55:55', 'Consumable used with unknown effect type: xp_multiplier'),
(69, NULL, '2025-05-25 01:56:02', 'Restored 10 health points'),
(70, NULL, '2025-05-25 01:56:49', 'Restored 10 health points'),
(71, NULL, '2025-05-25 04:52:26', 'Consumable used with unknown effect type: xp_multiplier'),
(72, 4, '2025-05-25 04:52:42', 'Item equipped successfully'),
(73, NULL, '2025-05-25 07:50:42', 'Consumable used with unknown effect type: xp_multiplier'),
(74, NULL, '2025-05-25 07:50:46', 'Consumable used with unknown effect type: completion_bonus'),
(75, NULL, '2025-05-25 07:50:51', 'Restored 10 health points'),
(76, NULL, '2025-05-25 08:12:04', 'Consumable used with unknown effect type: completion_bonus'),
(77, NULL, '2025-05-25 09:45:51', 'Restored 1 health points'),
(78, NULL, '2025-05-25 09:46:24', 'Consumable used with unknown effect type: completion_bonus'),
(79, NULL, '2025-05-25 10:32:36', 'Restored 10 health points'),
(80, NULL, '2025-05-25 10:32:44', 'Consumable used with unknown effect type: xp_multiplier'),
(81, NULL, '2025-05-25 10:34:04', 'Restored 10 health points'),
(82, NULL, '2025-05-25 10:34:09', 'Restored 10 health points'),
(83, NULL, '2025-05-25 10:35:48', 'Restored 10 health points'),
(84, NULL, '2025-05-25 10:35:53', 'Restored 10 health points'),
(85, NULL, '2025-05-25 10:36:02', 'Restored 10 health points'),
(86, NULL, '2025-05-25 10:36:23', 'Consumable used with unknown effect type: xp_multiplier'),
(87, NULL, '2025-05-25 10:36:28', 'Consumable used with unknown effect type: xp_multiplier'),
(88, NULL, '2025-05-25 10:36:32', 'Consumable used with unknown effect type: xp_multiplier'),
(89, NULL, '2025-05-25 10:45:47', 'Consumable used with unknown effect type: completion_bonus'),
(94, NULL, '2025-05-25 11:01:11', 'Restored 10 health points'),
(95, NULL, '2025-05-25 11:03:36', 'Consumable used with unknown effect type: xp_multiplier'),
(96, NULL, '2025-05-25 11:04:40', 'Consumable used with unknown effect type: completion_bonus'),
(97, NULL, '2025-05-25 11:13:00', 'Restored 1 health points'),
(98, 10, '2025-05-25 11:20:12', 'Activated a 1% boost for 24 hours'),
(99, NULL, '2025-05-25 11:20:19', 'Restored 10 health points'),
(100, NULL, '2025-05-25 11:20:25', 'Restored 8 health points'),
(101, 4, '2025-05-26 01:41:39', 'Item equipped successfully'),
(102, NULL, '2025-05-26 01:44:03', 'Restored 10 health points'),
(103, NULL, '2025-05-26 01:44:08', 'Restored 10 health points'),
(104, NULL, '2025-05-26 01:44:12', 'Restored 10 health points'),
(105, NULL, '2025-05-26 01:44:17', 'Restored 10 health points'),
(106, NULL, '2025-05-26 01:44:22', 'Restored 10 health points'),
(107, NULL, '2025-05-26 01:44:26', 'Restored 10 health points'),
(108, NULL, '2025-05-26 01:44:30', 'Restored 10 health points'),
(109, NULL, '2025-05-26 01:44:34', 'Restored 10 health points'),
(110, NULL, '2025-05-26 01:44:38', 'Restored 10 health points'),
(111, 33, '2025-05-26 01:44:55', 'Restored 9 health points'),
(112, 33, '2025-05-28 02:56:09', 'Restored 10 health points'),
(113, NULL, '2025-05-28 06:12:24', 'Restored 10 health points'),
(114, NULL, '2025-05-28 14:12:38', 'Restored 1 health points'),
(115, NULL, '2025-05-28 14:12:46', 'Restored 1 health points');

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
(1, 1, 'How did I step out of my comfort zone?', 'Today I reflected on: How did I step out of my comfort zone?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-27', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(2, 1, 'What positive habit did I maintain?', 'Today I reflected on: What positive habit did I maintain?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-05', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(3, 3, 'What relationships did I nurture today?', 'Today I reflected on: What relationships did I nurture today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-11', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(4, 3, 'What positive habit did I maintain?', 'Today I reflected on: What positive habit did I maintain?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-30', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(5, 4, 'What inspired me today?', 'Today I reflected on: What inspired me today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-25', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(6, 4, 'What relationships did I nurture today?', 'Today I reflected on: What relationships did I nurture today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-23', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(7, 4, 'How did I contribute to my community?', 'Today I reflected on: How did I contribute to my community?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-01', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(8, 4, 'What did I learn about myself today?', 'Today I reflected on: What did I learn about myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-18', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(9, 4, 'What are three things I\'m grateful for today?', 'Today I reflected on: What are three things I\'m grateful for today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-28', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(10, 5, 'What inspired me today?', 'Today I reflected on: What inspired me today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-28', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(11, 5, 'What positive habit did I maintain?', 'Today I reflected on: What positive habit did I maintain?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-24', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(12, 5, 'What challenge did I overcome today?', 'Today I reflected on: What challenge did I overcome today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-04', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(13, 6, 'What moment made me smile today?', 'Today I reflected on: What moment made me smile today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-24', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(14, 7, 'What positive impact did I make today?', 'Today I reflected on: What positive impact did I make today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-11', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(15, 7, 'How did I contribute to my community?', 'Today I reflected on: How did I contribute to my community?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-26', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(16, 7, 'How did I manage stress today?', 'Today I reflected on: How did I manage stress today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-28', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(17, 8, 'What healthy choice did I make?', 'Today I reflected on: What healthy choice did I make?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-24', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(18, 8, 'What creative activity did I do?', 'Today I reflected on: What creative activity did I do?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-18', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(19, 8, 'What goal am I working towards?', 'Today I reflected on: What goal am I working towards?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-28', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(20, 9, 'What inspired me today?', 'Today I reflected on: What inspired me today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-12', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(21, 10, 'How did I take care of myself today?', 'Today I reflected on: How did I take care of myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-02', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(22, 10, 'What skill did I practice today?', 'Today I reflected on: What skill did I practice today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-25', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(23, 10, 'What inspired me today?', 'Today I reflected on: What inspired me today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-28', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(24, 10, 'What challenge did I overcome today?', 'Today I reflected on: What challenge did I overcome today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-18', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(25, 11, 'What positive impact did I make today?', 'Today I reflected on: What positive impact did I make today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-14', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(26, 11, 'How did I contribute to my community?', 'Today I reflected on: How did I contribute to my community?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-11', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(27, 12, 'What book or article influenced me?', 'Today I reflected on: What book or article influenced me?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-11', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(28, 12, 'What relationships did I nurture today?', 'Today I reflected on: What relationships did I nurture today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-07', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(29, 13, 'How did I practice mindfulness today?', 'Today I reflected on: How did I practice mindfulness today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-27', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(30, 14, 'What challenge did I overcome today?', 'Today I reflected on: What challenge did I overcome today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-17', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(31, 14, 'How did I practice mindfulness today?', 'Today I reflected on: How did I practice mindfulness today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-28', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(32, 14, 'What new perspective did I gain today?', 'Today I reflected on: What new perspective did I gain today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-17', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(33, 15, 'How did I take care of myself today?', 'Today I reflected on: How did I take care of myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-06', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(34, 15, 'What positive habit did I maintain?', 'Today I reflected on: What positive habit did I maintain?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-05', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(35, 15, 'How did I grow as a person today?', 'Today I reflected on: How did I grow as a person today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-04', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(36, 15, 'What positive habit did I maintain?', 'Today I reflected on: What positive habit did I maintain?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-23', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(37, 16, 'What positive habit did I maintain?', 'Today I reflected on: What positive habit did I maintain?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-12', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(38, 16, 'What healthy choice did I make?', 'Today I reflected on: What healthy choice did I make?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-11', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(39, 17, 'How did I grow as a person today?', 'Today I reflected on: How did I grow as a person today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-28', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(40, 17, 'What moment made me smile today?', 'Today I reflected on: What moment made me smile today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-22', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(41, 17, 'What inspired me today?', 'Today I reflected on: What inspired me today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-01', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(42, 17, 'What are three things I\'m grateful for today?', 'Today I reflected on: What are three things I\'m grateful for today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-21', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(43, 18, 'What goal am I working towards?', 'Today I reflected on: What goal am I working towards?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-26', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(44, 18, 'How did I step out of my comfort zone?', 'Today I reflected on: How did I step out of my comfort zone?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-24', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(45, 18, 'What creative activity did I do?', 'Today I reflected on: What creative activity did I do?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-13', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(46, 19, 'How did I contribute to my community?', 'Today I reflected on: How did I contribute to my community?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-15', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(47, 19, 'How did I take care of myself today?', 'Today I reflected on: How did I take care of myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-16', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(48, 19, 'How did I contribute to my community?', 'Today I reflected on: How did I contribute to my community?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-13', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(49, 20, 'How did I take care of myself today?', 'Today I reflected on: How did I take care of myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-20', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(50, 20, 'What challenge did I overcome today?', 'Today I reflected on: What challenge did I overcome today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-28', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(51, 20, 'What book or article influenced me?', 'Today I reflected on: What book or article influenced me?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-16', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(52, 20, 'What did I learn about myself today?', 'Today I reflected on: What did I learn about myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-28', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(53, 20, 'What inspired me today?', 'Today I reflected on: What inspired me today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-03', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(54, 21, 'What relationships did I nurture today?', 'Today I reflected on: What relationships did I nurture today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-14', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(55, 21, 'What are three things I\'m grateful for today?', 'Today I reflected on: What are three things I\'m grateful for today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-12', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(56, 21, 'How did I practice mindfulness today?', 'Today I reflected on: How did I practice mindfulness today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-16', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(57, 22, 'What challenge did I overcome today?', 'Today I reflected on: What challenge did I overcome today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-09', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(58, 22, 'How did I practice mindfulness today?', 'Today I reflected on: How did I practice mindfulness today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-23', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(59, 22, 'What moment made me smile today?', 'Today I reflected on: What moment made me smile today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-20', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(60, 22, 'What challenge did I overcome today?', 'Today I reflected on: What challenge did I overcome today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-26', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(61, 23, 'How did I step out of my comfort zone?', 'Today I reflected on: How did I step out of my comfort zone?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-17', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(62, 23, 'What relationships did I nurture today?', 'Today I reflected on: What relationships did I nurture today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-15', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(63, 24, 'What challenge did I overcome today?', 'Today I reflected on: What challenge did I overcome today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-25', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(64, 24, 'What moment made me smile today?', 'Today I reflected on: What moment made me smile today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-02', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(65, 24, 'What new perspective did I gain today?', 'Today I reflected on: What new perspective did I gain today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-10', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(66, 24, 'What healthy choice did I make?', 'Today I reflected on: What healthy choice did I make?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-16', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(67, 24, 'What healthy choice did I make?', 'Today I reflected on: What healthy choice did I make?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-09', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(68, 25, 'What creative activity did I do?', 'Today I reflected on: What creative activity did I do?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-16', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(69, 25, 'What inspired me today?', 'Today I reflected on: What inspired me today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-28', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(70, 25, 'What new perspective did I gain today?', 'Today I reflected on: What new perspective did I gain today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-28', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(71, 26, 'How did I contribute to my community?', 'Today I reflected on: How did I contribute to my community?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-06', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(72, 26, 'What are three things I\'m grateful for today?', 'Today I reflected on: What are three things I\'m grateful for today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-12', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(73, 26, 'What skill did I practice today?', 'Today I reflected on: What skill did I practice today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-01', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(74, 26, 'What relationships did I nurture today?', 'Today I reflected on: What relationships did I nurture today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-09', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(75, 27, 'How did I grow as a person today?', 'Today I reflected on: How did I grow as a person today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-23', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(76, 27, 'What are three things I\'m grateful for today?', 'Today I reflected on: What are three things I\'m grateful for today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-11', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(77, 27, 'How did I take care of myself today?', 'Today I reflected on: How did I take care of myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-03', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(78, 27, 'What skill did I practice today?', 'Today I reflected on: What skill did I practice today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-16', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(79, 27, 'What new perspective did I gain today?', 'Today I reflected on: What new perspective did I gain today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-10', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(80, 28, 'What positive habit did I maintain?', 'Today I reflected on: What positive habit did I maintain?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-28', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(81, 28, 'How did I manage stress today?', 'Today I reflected on: How did I manage stress today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-12', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(82, 28, 'What positive habit did I maintain?', 'Today I reflected on: What positive habit did I maintain?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-13', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(83, 28, 'What new perspective did I gain today?', 'Today I reflected on: What new perspective did I gain today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-23', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(84, 28, 'What goal am I working towards?', 'Today I reflected on: What goal am I working towards?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-29', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(85, 29, 'How did I practice mindfulness today?', 'Today I reflected on: How did I practice mindfulness today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-12', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(86, 30, 'What relationships did I nurture today?', 'Today I reflected on: What relationships did I nurture today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-09', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(87, 30, 'What healthy choice did I make?', 'Today I reflected on: What healthy choice did I make?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-05', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(88, 31, 'How did I take care of myself today?', 'Today I reflected on: How did I take care of myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-18', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(89, 31, 'What skill did I practice today?', 'Today I reflected on: What skill did I practice today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-15', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(90, 32, 'What new perspective did I gain today?', 'Today I reflected on: What new perspective did I gain today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-15', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(91, 32, 'What relationships did I nurture today?', 'Today I reflected on: What relationships did I nurture today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-10', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(92, 32, 'What creative activity did I do?', 'Today I reflected on: What creative activity did I do?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-09', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(93, 32, 'What creative activity did I do?', 'Today I reflected on: What creative activity did I do?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-24', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(94, 32, 'How did I take care of myself today?', 'Today I reflected on: How did I take care of myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-14', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(95, 33, 'How did I step out of my comfort zone?', 'Today I reflected on: How did I step out of my comfort zone?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-11', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(96, 33, 'What goal am I working towards?', 'Today I reflected on: What goal am I working towards?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-01', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(97, 33, 'What positive impact did I make today?', 'Today I reflected on: What positive impact did I make today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-26', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(98, 33, 'What positive impact did I make today?', 'Today I reflected on: What positive impact did I make today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-21', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(99, 34, 'What skill did I practice today?', 'Today I reflected on: What skill did I practice today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-25', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(100, 34, 'What book or article influenced me?', 'Today I reflected on: What book or article influenced me?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-28', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(101, 34, 'What creative activity did I do?', 'Today I reflected on: What creative activity did I do?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-07', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(102, 35, 'How did I take care of myself today?', 'Today I reflected on: How did I take care of myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-05', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(103, 35, 'What moment made me smile today?', 'Today I reflected on: What moment made me smile today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-24', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(104, 35, 'What skill did I practice today?', 'Today I reflected on: What skill did I practice today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-04', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(105, 35, 'What inspired me today?', 'Today I reflected on: What inspired me today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-22', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(106, 35, 'What healthy choice did I make?', 'Today I reflected on: What healthy choice did I make?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-19', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(107, 36, 'What did I learn about myself today?', 'Today I reflected on: What did I learn about myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-20', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(108, 37, 'What inspired me today?', 'Today I reflected on: What inspired me today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-11', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(109, 37, 'How did I take care of myself today?', 'Today I reflected on: How did I take care of myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-06', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(110, 37, 'How did I practice mindfulness today?', 'Today I reflected on: How did I practice mindfulness today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-21', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(111, 37, 'What positive habit did I maintain?', 'Today I reflected on: What positive habit did I maintain?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-18', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(112, 37, 'What skill did I practice today?', 'Today I reflected on: What skill did I practice today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-03', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(113, 38, 'What are three things I\'m grateful for today?', 'Today I reflected on: What are three things I\'m grateful for today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-22', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(114, 38, 'What healthy choice did I make?', 'Today I reflected on: What healthy choice did I make?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-13', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(115, 38, 'What new perspective did I gain today?', 'Today I reflected on: What new perspective did I gain today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-06', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(116, 39, 'What positive habit did I maintain?', 'Today I reflected on: What positive habit did I maintain?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-28', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(117, 40, 'What healthy choice did I make?', 'Today I reflected on: What healthy choice did I make?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-06', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(118, 41, 'What skill did I practice today?', 'Today I reflected on: What skill did I practice today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-17', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(119, 41, 'What goal am I working towards?', 'Today I reflected on: What goal am I working towards?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-09', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(120, 41, 'What relationships did I nurture today?', 'Today I reflected on: What relationships did I nurture today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-06', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(121, 41, 'How did I grow as a person today?', 'Today I reflected on: How did I grow as a person today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-24', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(122, 42, 'What positive impact did I make today?', 'Today I reflected on: What positive impact did I make today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-11', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(123, 42, 'What did I learn about myself today?', 'Today I reflected on: What did I learn about myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-11', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(124, 42, 'What healthy choice did I make?', 'Today I reflected on: What healthy choice did I make?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-29', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(125, 42, 'How did I manage stress today?', 'Today I reflected on: How did I manage stress today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-11', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(126, 43, 'What creative activity did I do?', 'Today I reflected on: What creative activity did I do?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-24', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(127, 44, 'What book or article influenced me?', 'Today I reflected on: What book or article influenced me?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-05', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(128, 45, 'How did I manage stress today?', 'Today I reflected on: How did I manage stress today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-17', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(129, 45, 'What positive habit did I maintain?', 'Today I reflected on: What positive habit did I maintain?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-11', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(130, 45, 'What moment made me smile today?', 'Today I reflected on: What moment made me smile today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-11', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(131, 46, 'How did I step out of my comfort zone?', 'Today I reflected on: How did I step out of my comfort zone?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-22', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(132, 46, 'What moment made me smile today?', 'Today I reflected on: What moment made me smile today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-09', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(133, 46, 'What positive habit did I maintain?', 'Today I reflected on: What positive habit did I maintain?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-24', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(134, 46, 'How did I practice mindfulness today?', 'Today I reflected on: How did I practice mindfulness today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-15', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(135, 46, 'What are three things I\'m grateful for today?', 'Today I reflected on: What are three things I\'m grateful for today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-16', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(136, 47, 'What moment made me smile today?', 'Today I reflected on: What moment made me smile today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-29', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(137, 48, 'What are three things I\'m grateful for today?', 'Today I reflected on: What are three things I\'m grateful for today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-17', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(138, 48, 'How did I practice mindfulness today?', 'Today I reflected on: How did I practice mindfulness today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-01', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(139, 48, 'How did I step out of my comfort zone?', 'Today I reflected on: How did I step out of my comfort zone?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-27', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(140, 48, 'How did I manage stress today?', 'Today I reflected on: How did I manage stress today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-25', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(141, 48, 'How did I practice mindfulness today?', 'Today I reflected on: How did I practice mindfulness today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-13', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(142, 49, 'What creative activity did I do?', 'Today I reflected on: What creative activity did I do?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-11', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(143, 49, 'What positive habit did I maintain?', 'Today I reflected on: What positive habit did I maintain?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-16', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(144, 50, 'What skill did I practice today?', 'Today I reflected on: What skill did I practice today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-27', '2025-05-28 02:57:28', '2025-05-28 02:57:28');
INSERT INTO `journals` (`id`, `user_id`, `title`, `content`, `date`, `created_at`, `updated_at`) VALUES
(145, 50, 'How did I grow as a person today?', 'Today I reflected on: How did I grow as a person today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-24', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(146, 50, 'What skill did I practice today?', 'Today I reflected on: What skill did I practice today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-23', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(147, 51, 'What did I learn about myself today?', 'Today I reflected on: What did I learn about myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-03', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(148, 51, 'What creative activity did I do?', 'Today I reflected on: What creative activity did I do?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-29', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(149, 51, 'What new perspective did I gain today?', 'Today I reflected on: What new perspective did I gain today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-30', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(150, 52, 'What relationships did I nurture today?', 'Today I reflected on: What relationships did I nurture today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-24', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(151, 52, 'What healthy choice did I make?', 'Today I reflected on: What healthy choice did I make?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-28', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(152, 53, 'What positive impact did I make today?', 'Today I reflected on: What positive impact did I make today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-03', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(153, 53, 'What book or article influenced me?', 'Today I reflected on: What book or article influenced me?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-23', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(154, 53, 'What moment made me smile today?', 'Today I reflected on: What moment made me smile today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-14', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(155, 53, 'How did I grow as a person today?', 'Today I reflected on: How did I grow as a person today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-15', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(156, 53, 'What creative activity did I do?', 'Today I reflected on: What creative activity did I do?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-11', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(157, 54, 'How did I grow as a person today?', 'Today I reflected on: How did I grow as a person today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-04', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(158, 54, 'What are three things I\'m grateful for today?', 'Today I reflected on: What are three things I\'m grateful for today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-30', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(159, 54, 'How did I grow as a person today?', 'Today I reflected on: How did I grow as a person today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-13', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(160, 54, 'How did I practice mindfulness today?', 'Today I reflected on: How did I practice mindfulness today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-22', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(161, 54, 'What creative activity did I do?', 'Today I reflected on: What creative activity did I do?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-11', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(162, 55, 'What challenge did I overcome today?', 'Today I reflected on: What challenge did I overcome today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-10', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(163, 55, 'What positive habit did I maintain?', 'Today I reflected on: What positive habit did I maintain?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-18', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(164, 55, 'What inspired me today?', 'Today I reflected on: What inspired me today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-13', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(165, 55, 'How did I step out of my comfort zone?', 'Today I reflected on: How did I step out of my comfort zone?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-14', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(166, 56, 'How did I practice mindfulness today?', 'Today I reflected on: How did I practice mindfulness today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-05', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(167, 56, 'What are three things I\'m grateful for today?', 'Today I reflected on: What are three things I\'m grateful for today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-12', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(168, 56, 'What new perspective did I gain today?', 'Today I reflected on: What new perspective did I gain today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-24', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(169, 56, 'What inspired me today?', 'Today I reflected on: What inspired me today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-02', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(170, 57, 'What relationships did I nurture today?', 'Today I reflected on: What relationships did I nurture today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-12', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(171, 58, 'What inspired me today?', 'Today I reflected on: What inspired me today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-30', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(172, 58, 'What inspired me today?', 'Today I reflected on: What inspired me today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-28', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(173, 58, 'How did I step out of my comfort zone?', 'Today I reflected on: How did I step out of my comfort zone?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-10', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(174, 58, 'How did I grow as a person today?', 'Today I reflected on: How did I grow as a person today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-30', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(175, 59, 'What moment made me smile today?', 'Today I reflected on: What moment made me smile today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-28', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(176, 59, 'What creative activity did I do?', 'Today I reflected on: What creative activity did I do?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-14', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(177, 59, 'What goal am I working towards?', 'Today I reflected on: What goal am I working towards?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-20', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(178, 60, 'What inspired me today?', 'Today I reflected on: What inspired me today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-25', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(179, 60, 'How did I practice mindfulness today?', 'Today I reflected on: How did I practice mindfulness today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-09', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(180, 61, 'What did I learn about myself today?', 'Today I reflected on: What did I learn about myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-12', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(181, 61, 'What challenge did I overcome today?', 'Today I reflected on: What challenge did I overcome today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-24', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(182, 61, 'What positive habit did I maintain?', 'Today I reflected on: What positive habit did I maintain?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-01', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(183, 62, 'What moment made me smile today?', 'Today I reflected on: What moment made me smile today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-26', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(184, 62, 'How did I take care of myself today?', 'Today I reflected on: How did I take care of myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-04', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(185, 62, 'How did I step out of my comfort zone?', 'Today I reflected on: How did I step out of my comfort zone?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-25', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(186, 62, 'What skill did I practice today?', 'Today I reflected on: What skill did I practice today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-03', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(187, 62, 'How did I manage stress today?', 'Today I reflected on: How did I manage stress today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-29', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(188, 63, 'What goal am I working towards?', 'Today I reflected on: What goal am I working towards?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-28', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(189, 63, 'What new perspective did I gain today?', 'Today I reflected on: What new perspective did I gain today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-12', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(190, 64, 'What book or article influenced me?', 'Today I reflected on: What book or article influenced me?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-17', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(191, 64, 'How did I grow as a person today?', 'Today I reflected on: How did I grow as a person today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-12', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(192, 65, 'What positive habit did I maintain?', 'Today I reflected on: What positive habit did I maintain?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-28', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(193, 65, 'What relationships did I nurture today?', 'Today I reflected on: What relationships did I nurture today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-05', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(194, 66, 'How did I practice mindfulness today?', 'Today I reflected on: How did I practice mindfulness today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-29', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(195, 66, 'What did I learn about myself today?', 'Today I reflected on: What did I learn about myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-25', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(196, 66, 'What inspired me today?', 'Today I reflected on: What inspired me today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-03', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(197, 67, 'What did I learn about myself today?', 'Today I reflected on: What did I learn about myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-07', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(198, 67, 'How did I grow as a person today?', 'Today I reflected on: How did I grow as a person today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-19', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(199, 68, 'What positive habit did I maintain?', 'Today I reflected on: What positive habit did I maintain?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-28', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(200, 68, 'What skill did I practice today?', 'Today I reflected on: What skill did I practice today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-20', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(201, 69, 'What positive impact did I make today?', 'Today I reflected on: What positive impact did I make today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-03', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(202, 70, 'What positive impact did I make today?', 'Today I reflected on: What positive impact did I make today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-10', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(203, 70, 'What are three things I\'m grateful for today?', 'Today I reflected on: What are three things I\'m grateful for today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-15', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(204, 71, 'How did I take care of myself today?', 'Today I reflected on: How did I take care of myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-12', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(205, 71, 'What positive habit did I maintain?', 'Today I reflected on: What positive habit did I maintain?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-08', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(206, 71, 'What positive impact did I make today?', 'Today I reflected on: What positive impact did I make today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-10', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(207, 71, 'What healthy choice did I make?', 'Today I reflected on: What healthy choice did I make?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-12', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(208, 71, 'How did I take care of myself today?', 'Today I reflected on: How did I take care of myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-10', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(209, 72, 'What creative activity did I do?', 'Today I reflected on: What creative activity did I do?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-01', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(210, 72, 'What inspired me today?', 'Today I reflected on: What inspired me today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-13', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(211, 72, 'What challenge did I overcome today?', 'Today I reflected on: What challenge did I overcome today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-09', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(212, 72, 'What goal am I working towards?', 'Today I reflected on: What goal am I working towards?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-09', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(213, 72, 'What moment made me smile today?', 'Today I reflected on: What moment made me smile today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-12', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(214, 73, 'What positive habit did I maintain?', 'Today I reflected on: What positive habit did I maintain?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-18', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(215, 73, 'How did I step out of my comfort zone?', 'Today I reflected on: How did I step out of my comfort zone?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-07', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(216, 73, 'What positive impact did I make today?', 'Today I reflected on: What positive impact did I make today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-27', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(217, 73, 'What skill did I practice today?', 'Today I reflected on: What skill did I practice today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-30', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(218, 74, 'How did I step out of my comfort zone?', 'Today I reflected on: How did I step out of my comfort zone?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-27', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(219, 74, 'What are three things I\'m grateful for today?', 'Today I reflected on: What are three things I\'m grateful for today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-22', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(220, 74, 'How did I grow as a person today?', 'Today I reflected on: How did I grow as a person today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-10', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(221, 74, 'How did I take care of myself today?', 'Today I reflected on: How did I take care of myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-06', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(222, 74, 'What inspired me today?', 'Today I reflected on: What inspired me today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-29', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(223, 75, 'What skill did I practice today?', 'Today I reflected on: What skill did I practice today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-17', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(224, 75, 'How did I take care of myself today?', 'Today I reflected on: How did I take care of myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-21', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(225, 75, 'What inspired me today?', 'Today I reflected on: What inspired me today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-28', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(226, 76, 'How did I step out of my comfort zone?', 'Today I reflected on: How did I step out of my comfort zone?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-28', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(227, 76, 'What did I learn about myself today?', 'Today I reflected on: What did I learn about myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-20', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(228, 76, 'What positive impact did I make today?', 'Today I reflected on: What positive impact did I make today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-04', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(229, 77, 'What are three things I\'m grateful for today?', 'Today I reflected on: What are three things I\'m grateful for today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-14', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(230, 77, 'What did I learn about myself today?', 'Today I reflected on: What did I learn about myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-22', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(231, 77, 'How did I manage stress today?', 'Today I reflected on: How did I manage stress today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-28', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(232, 77, 'What creative activity did I do?', 'Today I reflected on: What creative activity did I do?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-03', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(233, 77, 'What are three things I\'m grateful for today?', 'Today I reflected on: What are three things I\'m grateful for today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-02', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(234, 78, 'What positive impact did I make today?', 'Today I reflected on: What positive impact did I make today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-14', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(235, 78, 'How did I grow as a person today?', 'Today I reflected on: How did I grow as a person today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-28', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(236, 79, 'How did I manage stress today?', 'Today I reflected on: How did I manage stress today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-22', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(237, 79, 'How did I step out of my comfort zone?', 'Today I reflected on: How did I step out of my comfort zone?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-01', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(238, 80, 'How did I contribute to my community?', 'Today I reflected on: How did I contribute to my community?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-26', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(239, 80, 'What creative activity did I do?', 'Today I reflected on: What creative activity did I do?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-02', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(240, 81, 'What challenge did I overcome today?', 'Today I reflected on: What challenge did I overcome today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-17', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(241, 81, 'How did I step out of my comfort zone?', 'Today I reflected on: How did I step out of my comfort zone?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-02', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(242, 81, 'What did I learn about myself today?', 'Today I reflected on: What did I learn about myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-19', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(243, 82, 'What skill did I practice today?', 'Today I reflected on: What skill did I practice today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-14', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(244, 82, 'What positive impact did I make today?', 'Today I reflected on: What positive impact did I make today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-16', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(245, 82, 'What skill did I practice today?', 'Today I reflected on: What skill did I practice today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-09', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(246, 82, 'What new perspective did I gain today?', 'Today I reflected on: What new perspective did I gain today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-23', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(247, 82, 'What positive impact did I make today?', 'Today I reflected on: What positive impact did I make today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-13', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(248, 83, 'How did I manage stress today?', 'Today I reflected on: How did I manage stress today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-13', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(249, 83, 'How did I grow as a person today?', 'Today I reflected on: How did I grow as a person today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-01', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(250, 84, 'What new perspective did I gain today?', 'Today I reflected on: What new perspective did I gain today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-10', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(251, 84, 'What creative activity did I do?', 'Today I reflected on: What creative activity did I do?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-22', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(252, 84, 'What book or article influenced me?', 'Today I reflected on: What book or article influenced me?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-18', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(253, 84, 'What moment made me smile today?', 'Today I reflected on: What moment made me smile today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-23', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(254, 85, 'What goal am I working towards?', 'Today I reflected on: What goal am I working towards?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-10', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(255, 86, 'What skill did I practice today?', 'Today I reflected on: What skill did I practice today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-07', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(256, 86, 'What moment made me smile today?', 'Today I reflected on: What moment made me smile today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-01', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(257, 87, 'What healthy choice did I make?', 'Today I reflected on: What healthy choice did I make?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-26', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(258, 88, 'What positive habit did I maintain?', 'Today I reflected on: What positive habit did I maintain?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-14', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(259, 89, 'How did I manage stress today?', 'Today I reflected on: How did I manage stress today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-01', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(260, 89, 'What book or article influenced me?', 'Today I reflected on: What book or article influenced me?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-13', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(261, 90, 'What positive habit did I maintain?', 'Today I reflected on: What positive habit did I maintain?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-10', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(262, 90, 'What goal am I working towards?', 'Today I reflected on: What goal am I working towards?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-08', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(263, 90, 'What creative activity did I do?', 'Today I reflected on: What creative activity did I do?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-17', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(264, 90, 'How did I contribute to my community?', 'Today I reflected on: How did I contribute to my community?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-18', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(265, 91, 'What positive impact did I make today?', 'Today I reflected on: What positive impact did I make today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-25', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(266, 92, 'How did I grow as a person today?', 'Today I reflected on: How did I grow as a person today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-16', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(267, 92, 'What challenge did I overcome today?', 'Today I reflected on: What challenge did I overcome today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-02', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(268, 92, 'What positive habit did I maintain?', 'Today I reflected on: What positive habit did I maintain?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-23', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(269, 92, 'What creative activity did I do?', 'Today I reflected on: What creative activity did I do?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-12', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(270, 92, 'What relationships did I nurture today?', 'Today I reflected on: What relationships did I nurture today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-28', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(271, 93, 'What inspired me today?', 'Today I reflected on: What inspired me today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-21', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(272, 93, 'How did I manage stress today?', 'Today I reflected on: How did I manage stress today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-10', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(273, 94, 'What positive habit did I maintain?', 'Today I reflected on: What positive habit did I maintain?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-12', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(274, 95, 'What relationships did I nurture today?', 'Today I reflected on: What relationships did I nurture today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-28', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(275, 95, 'What moment made me smile today?', 'Today I reflected on: What moment made me smile today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-03', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(276, 95, 'What book or article influenced me?', 'Today I reflected on: What book or article influenced me?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-04-28', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(277, 96, 'What positive impact did I make today?', 'Today I reflected on: What positive impact did I make today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-05', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(278, 96, 'What goal am I working towards?', 'Today I reflected on: What goal am I working towards?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-22', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(279, 96, 'What did I learn about myself today?', 'Today I reflected on: What did I learn about myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-06', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(280, 97, 'How did I manage stress today?', 'Today I reflected on: How did I manage stress today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-09', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(281, 97, 'What relationships did I nurture today?', 'Today I reflected on: What relationships did I nurture today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-09', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(282, 97, 'What did I learn about myself today?', 'Today I reflected on: What did I learn about myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-19', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(283, 97, 'What goal am I working towards?', 'Today I reflected on: What goal am I working towards?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-26', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(284, 98, 'What did I learn about myself today?', 'Today I reflected on: What did I learn about myself today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-28', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(285, 98, 'What new perspective did I gain today?', 'Today I reflected on: What new perspective did I gain today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-23', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(286, 99, 'What healthy choice did I make?', 'Today I reflected on: What healthy choice did I make?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-25', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(287, 99, 'How did I contribute to my community?', 'Today I reflected on: How did I contribute to my community?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-20', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(288, 99, 'What inspired me today?', 'Today I reflected on: What inspired me today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-20', '2025-05-28 02:57:28', '2025-05-28 02:57:28');
INSERT INTO `journals` (`id`, `user_id`, `title`, `content`, `date`, `created_at`, `updated_at`) VALUES
(289, 100, 'What moment made me smile today?', 'Today I reflected on: What moment made me smile today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-03', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(290, 101, 'What creative activity did I do?', 'Today I reflected on: What creative activity did I do?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-16', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(291, 101, 'How did I step out of my comfort zone?', 'Today I reflected on: How did I step out of my comfort zone?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-17', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(292, 101, 'What relationships did I nurture today?', 'Today I reflected on: What relationships did I nurture today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-17', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(293, 101, 'How did I step out of my comfort zone?', 'Today I reflected on: How did I step out of my comfort zone?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-07', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(294, 101, 'What relationships did I nurture today?', 'Today I reflected on: What relationships did I nurture today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-09', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(295, 102, 'What creative activity did I do?', 'Today I reflected on: What creative activity did I do?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-24', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(296, 103, 'How did I manage stress today?', 'Today I reflected on: How did I manage stress today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-25', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(297, 103, 'How did I grow as a person today?', 'Today I reflected on: How did I grow as a person today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-08', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(298, 103, 'What relationships did I nurture today?', 'Today I reflected on: What relationships did I nurture today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-11', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(299, 104, 'How did I step out of my comfort zone?', 'Today I reflected on: How did I step out of my comfort zone?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-13', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(300, 104, 'What relationships did I nurture today?', 'Today I reflected on: What relationships did I nurture today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-25', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(301, 105, 'What book or article influenced me?', 'Today I reflected on: What book or article influenced me?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-12', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(302, 105, 'What relationships did I nurture today?', 'Today I reflected on: What relationships did I nurture today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-22', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(303, 106, 'What relationships did I nurture today?', 'Today I reflected on: What relationships did I nurture today?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-28', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(304, 106, 'What creative activity did I do?', 'Today I reflected on: What creative activity did I do?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-05', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(305, 106, 'How did I step out of my comfort zone?', 'Today I reflected on: How did I step out of my comfort zone?\n\nI feel grateful for the opportunities I\'ve had to grow and learn. Each day brings new challenges and victories. I\'m committed to continuing my personal development journey.', '2025-05-25', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(306, 107, 'my jogg', '<p>it was fun and i managed to get 2km</p>', '2025-05-28', '2025-05-28 06:24:28', '2025-05-28 06:24:28'),
(307, 108, 'jpournal', '<p>jpounfal123</p>', '2025-05-28', '2025-05-28 14:11:54', '2025-05-28 14:11:54');

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
(1, 'test2', 'angas', 0.00, '', NULL, 'collectible', NULL, NULL, NULL, NULL, 'available'),
(2, 'hahah', 'ha', 12.00, '', NULL, 'collectible', NULL, NULL, NULL, NULL, 'available'),
(3, 'gaga', 'gagaga', 12.00, '', NULL, 'collectible', NULL, NULL, NULL, NULL, 'available'),
(4, 'Health Potion', 'Restores 10 health points immediately', 50.00, '/assets/images/marketplace/health_potion.png', 1, 'consumable', 'health', 10, NULL, NULL, 'available'),
(5, 'XP Booster', 'Increases XP gain by 25% for 24 hours', 100.00, '/assets/images/marketplace/xp_booster.png', 4, 'boost', 'xp_multiplier', 25, NULL, NULL, 'available'),
(6, 'Focus Crystal', 'Increases focus by 5 points when equipped', 75.00, '/assets/images/marketplace/focus_crystal.png', 2, 'equipment', 'focus', 5, NULL, NULL, 'available'),
(7, 'Golden Trophy', 'A rare collectible that grants special profile badge', 200.00, '/assets/images/marketplace/golden_trophy.png', 3, 'collectible', 'badge', 1, NULL, NULL, 'available'),
(8, 'haha', 'haha', 2.00, '', 1, 'consumable', 'xp_multiplier', 12, 1, 1, 'available'),
(9, 'wasd', 'wads', 1.00, '', 4, 'boost', 'xp_multiplier', 1, NULL, NULL, 'available'),
(10, 'hahasdasd', 'dsadas', 1.00, '', 4, 'collectible', 'coin_multiplier', 1, NULL, NULL, 'available'),
(11, 'gaga', 'gagaag', 2421.00, '', 3, 'equipment', 'xp_multiplier', 123, NULL, NULL, 'available'),
(12, 'sfas', 'fsafa', 31.00, '', 4, 'collectible', 'coin_multiplier', 2, NULL, NULL, 'available'),
(13, 'dfxcvz', 'xcvz', 12.00, '', 3, 'consumable', 'completion_bonus', 12, NULL, NULL, 'available'),
(14, 'hasdghas', 'afhsdghasdg', 1.00, '', 4, 'consumable', 'health', 1, NULL, NULL, 'available');

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
(1, 1, 'check_in', 1, 8, '2025-05-28 02:54:41', NULL),
(2, 1, 'task_completion', 1, 1, '2025-05-28 13:37:59', NULL),
(3, 1, 'dailtask_completion', 0, 0, '2025-05-16 04:34:10', NULL),
(4, 1, 'GoodHabits_completion', 0, 0, '2025-05-16 04:34:10', NULL),
(5, 1, 'journal_writing', 0, 0, '2025-05-16 04:34:10', NULL),
(6, 2, 'check_in', 1, 4, '2025-05-28 03:08:12', NULL),
(7, 2, 'task_completion', 0, 0, '2025-05-16 19:33:17', NULL),
(8, 2, 'dailtask_completion', 0, 0, '2025-05-16 19:33:17', NULL),
(9, 2, 'GoodHabits_completion', 0, 0, '2025-05-16 19:33:17', NULL),
(10, 2, 'journal_writing', 0, 0, '2025-05-16 19:33:17', NULL),
(11, 3, 'check_in', 1, 1, '2025-05-28 05:41:54', NULL),
(12, 3, 'task_completion', 1, 1, '2025-05-28 11:26:31', NULL),
(13, 3, 'dailtask_completion', 0, 0, '2025-05-16 19:36:07', NULL),
(14, 3, 'GoodHabits_completion', 0, 0, '2025-05-16 19:36:07', NULL),
(15, 3, 'journal_writing', 0, 0, '2025-05-16 19:36:07', NULL),
(16, 4, 'check_in', 1, 1, '2025-05-19 08:57:39', NULL),
(17, 4, 'task_completion', 0, 0, '2025-05-17 10:04:51', NULL),
(18, 4, 'dailtask_completion', 0, 0, '2025-05-17 10:04:51', NULL),
(19, 4, 'GoodHabits_completion', 0, 0, '2025-05-17 10:04:51', NULL),
(20, 4, 'journal_writing', 0, 0, '2025-05-17 10:04:51', NULL),
(21, 5, 'check_in', 0, 0, '2025-05-18 06:34:20', NULL),
(22, 5, 'task_completion', 0, 0, '2025-05-18 06:34:20', NULL),
(23, 5, 'dailtask_completion', 0, 0, '2025-05-18 06:34:20', NULL),
(24, 5, 'GoodHabits_completion', 0, 0, '2025-05-18 06:34:20', NULL),
(25, 5, 'journal_writing', 0, 0, '2025-05-18 06:34:20', NULL),
(26, 6, 'check_in', 0, 0, '2025-05-26 01:49:36', NULL),
(27, 6, 'task_completion', 0, 0, '2025-05-26 01:49:36', NULL),
(28, 6, 'dailtask_completion', 0, 0, '2025-05-26 01:49:36', NULL),
(29, 6, 'GoodHabits_completion', 0, 0, '2025-05-26 01:49:36', NULL),
(30, 6, 'journal_writing', 0, 0, '2025-05-26 01:49:36', NULL),
(31, 7, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(32, 7, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(33, 7, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(34, 7, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(35, 7, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(36, 8, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(37, 8, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(38, 8, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(39, 8, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(40, 8, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(41, 9, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(42, 9, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(43, 9, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(44, 9, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(45, 9, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(46, 10, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(47, 10, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(48, 10, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(49, 10, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(50, 10, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(51, 11, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(52, 11, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(53, 11, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(54, 11, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(55, 11, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(56, 12, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(57, 12, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(58, 12, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(59, 12, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(60, 12, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(61, 13, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(62, 13, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(63, 13, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(64, 13, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(65, 13, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(66, 14, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(67, 14, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(68, 14, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(69, 14, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(70, 14, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(71, 15, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(72, 15, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(73, 15, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(74, 15, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(75, 15, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(76, 16, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(77, 16, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(78, 16, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(79, 16, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(80, 16, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(81, 17, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(82, 17, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(83, 17, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(84, 17, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(85, 17, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(86, 18, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(87, 18, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(88, 18, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(89, 18, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(90, 18, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(91, 19, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(92, 19, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(93, 19, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(94, 19, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(95, 19, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(96, 20, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(97, 20, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(98, 20, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(99, 20, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(100, 20, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(101, 21, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(102, 21, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(103, 21, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(104, 21, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(105, 21, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(106, 22, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(107, 22, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(108, 22, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(109, 22, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(110, 22, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(111, 23, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(112, 23, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(113, 23, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(114, 23, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(115, 23, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(116, 24, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(117, 24, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(118, 24, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(119, 24, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(120, 24, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(121, 25, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(122, 25, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(123, 25, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(124, 25, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(125, 25, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(126, 26, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(127, 26, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(128, 26, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(129, 26, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(130, 26, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(131, 27, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(132, 27, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(133, 27, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(134, 27, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(135, 27, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(136, 28, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(137, 28, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(138, 28, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(139, 28, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(140, 28, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(141, 29, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(142, 29, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(143, 29, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(144, 29, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(145, 29, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(146, 30, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(147, 30, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(148, 30, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(149, 30, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(150, 30, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(151, 31, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(152, 31, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(153, 31, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(154, 31, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(155, 31, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(156, 32, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(157, 32, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(158, 32, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(159, 32, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(160, 32, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(161, 33, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(162, 33, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(163, 33, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(164, 33, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(165, 33, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(166, 34, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(167, 34, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(168, 34, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(169, 34, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(170, 34, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(171, 35, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(172, 35, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(173, 35, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(174, 35, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(175, 35, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(176, 36, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(177, 36, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(178, 36, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(179, 36, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(180, 36, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(181, 37, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(182, 37, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(183, 37, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(184, 37, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(185, 37, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(186, 38, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(187, 38, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(188, 38, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(189, 38, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(190, 38, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(191, 39, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(192, 39, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(193, 39, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(194, 39, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(195, 39, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(196, 40, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(197, 40, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(198, 40, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(199, 40, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(200, 40, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(201, 41, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(202, 41, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(203, 41, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(204, 41, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(205, 41, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(206, 42, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(207, 42, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(208, 42, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(209, 42, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(210, 42, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(211, 43, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(212, 43, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(213, 43, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(214, 43, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(215, 43, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(216, 44, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(217, 44, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(218, 44, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(219, 44, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(220, 44, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(221, 45, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(222, 45, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(223, 45, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(224, 45, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(225, 45, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(226, 46, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(227, 46, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(228, 46, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(229, 46, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(230, 46, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(231, 47, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(232, 47, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(233, 47, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(234, 47, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(235, 47, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(236, 48, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(237, 48, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(238, 48, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(239, 48, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(240, 48, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(241, 49, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(242, 49, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(243, 49, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(244, 49, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(245, 49, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(246, 50, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(247, 50, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(248, 50, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(249, 50, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(250, 50, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(251, 51, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(252, 51, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(253, 51, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(254, 51, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(255, 51, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(256, 52, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(257, 52, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(258, 52, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(259, 52, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(260, 52, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(261, 53, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(262, 53, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(263, 53, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(264, 53, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(265, 53, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(266, 54, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(267, 54, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(268, 54, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(269, 54, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(270, 54, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(271, 55, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(272, 55, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(273, 55, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(274, 55, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(275, 55, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(276, 56, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(277, 56, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(278, 56, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(279, 56, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(280, 56, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(281, 57, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(282, 57, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(283, 57, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(284, 57, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(285, 57, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(286, 58, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(287, 58, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(288, 58, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(289, 58, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(290, 58, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(291, 59, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(292, 59, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(293, 59, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(294, 59, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(295, 59, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(296, 60, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(297, 60, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(298, 60, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(299, 60, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(300, 60, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(301, 61, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(302, 61, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(303, 61, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(304, 61, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(305, 61, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(306, 62, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(307, 62, 'task_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(308, 62, 'dailtask_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(309, 62, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:18', NULL),
(310, 62, 'journal_writing', 0, 0, '2025-05-28 02:57:18', NULL),
(311, 63, 'check_in', 0, 0, '2025-05-28 02:57:18', NULL),
(312, 63, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(313, 63, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(314, 63, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(315, 63, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(316, 64, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(317, 64, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(318, 64, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(319, 64, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(320, 64, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(321, 65, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(322, 65, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(323, 65, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(324, 65, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(325, 65, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(326, 66, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(327, 66, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(328, 66, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(329, 66, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(330, 66, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(331, 67, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(332, 67, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(333, 67, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(334, 67, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(335, 67, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(336, 68, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(337, 68, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(338, 68, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(339, 68, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(340, 68, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(341, 69, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(342, 69, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(343, 69, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(344, 69, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(345, 69, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(346, 70, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(347, 70, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(348, 70, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(349, 70, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(350, 70, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(351, 71, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(352, 71, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(353, 71, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(354, 71, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(355, 71, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(356, 72, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(357, 72, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(358, 72, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(359, 72, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(360, 72, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(361, 73, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(362, 73, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(363, 73, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(364, 73, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(365, 73, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(366, 74, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(367, 74, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(368, 74, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(369, 74, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(370, 74, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(371, 75, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(372, 75, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(373, 75, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(374, 75, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(375, 75, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(376, 76, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(377, 76, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(378, 76, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(379, 76, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(380, 76, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(381, 77, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(382, 77, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(383, 77, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(384, 77, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(385, 77, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(386, 78, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(387, 78, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(388, 78, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(389, 78, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(390, 78, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(391, 79, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(392, 79, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(393, 79, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(394, 79, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(395, 79, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(396, 80, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(397, 80, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(398, 80, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(399, 80, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(400, 80, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(401, 81, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(402, 81, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(403, 81, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(404, 81, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(405, 81, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(406, 82, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(407, 82, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(408, 82, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(409, 82, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(410, 82, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(411, 83, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(412, 83, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(413, 83, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(414, 83, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(415, 83, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(416, 84, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(417, 84, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(418, 84, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(419, 84, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(420, 84, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(421, 85, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(422, 85, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(423, 85, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(424, 85, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(425, 85, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(426, 86, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(427, 86, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(428, 86, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(429, 86, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(430, 86, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(431, 87, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(432, 87, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(433, 87, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(434, 87, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(435, 87, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(436, 88, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(437, 88, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(438, 88, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(439, 88, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(440, 88, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(441, 89, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(442, 89, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(443, 89, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(444, 89, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(445, 89, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(446, 90, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(447, 90, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(448, 90, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(449, 90, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(450, 90, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(451, 91, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(452, 91, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(453, 91, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(454, 91, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(455, 91, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(456, 92, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(457, 92, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(458, 92, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(459, 92, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(460, 92, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(461, 93, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(462, 93, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(463, 93, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(464, 93, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(465, 93, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(466, 94, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(467, 94, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(468, 94, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(469, 94, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(470, 94, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(471, 95, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(472, 95, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(473, 95, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(474, 95, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(475, 95, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(476, 96, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(477, 96, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(478, 96, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(479, 96, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(480, 96, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(481, 97, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(482, 97, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(483, 97, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(484, 97, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(485, 97, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(486, 98, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(487, 98, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(488, 98, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(489, 98, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(490, 98, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(491, 99, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(492, 99, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(493, 99, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(494, 99, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(495, 99, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(496, 100, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(497, 100, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(498, 100, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(499, 100, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(500, 100, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(501, 101, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(502, 101, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(503, 101, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(504, 101, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(505, 101, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(506, 102, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(507, 102, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(508, 102, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(509, 102, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(510, 102, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(511, 103, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(512, 103, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(513, 103, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(514, 103, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(515, 103, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(516, 104, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(517, 104, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(518, 104, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(519, 104, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(520, 104, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(521, 105, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(522, 105, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(523, 105, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(524, 105, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(525, 105, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(526, 106, 'check_in', 0, 0, '2025-05-28 02:57:19', NULL),
(527, 106, 'task_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(528, 106, 'dailtask_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(529, 106, 'GoodHabits_completion', 0, 0, '2025-05-28 02:57:19', NULL),
(530, 106, 'journal_writing', 0, 0, '2025-05-28 02:57:19', NULL),
(531, 107, 'check_in', 0, 0, '2025-05-28 05:59:02', NULL),
(532, 107, 'task_completion', 0, 0, '2025-05-28 05:59:02', NULL),
(533, 107, 'dailtask_completion', 0, 0, '2025-05-28 05:59:02', NULL),
(534, 107, 'GoodHabits_completion', 0, 0, '2025-05-28 05:59:02', NULL),
(535, 107, 'journal_writing', 0, 0, '2025-05-28 05:59:02', NULL),
(536, 108, 'check_in', 0, 0, '2025-05-28 14:07:54', NULL),
(537, 108, 'task_completion', 0, 0, '2025-05-28 14:07:54', NULL),
(538, 108, 'dailtask_completion', 0, 0, '2025-05-28 14:07:54', NULL),
(539, 108, 'GoodHabits_completion', 0, 0, '2025-05-28 14:07:54', NULL),
(540, 108, 'journal_writing', 0, 0, '2025-05-28 14:07:54', NULL);

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
(1, 3, '10k Steps', 'completed', 'medium', 'Physical Health', 10, 20),
(2, 1, 'haha', 'completed', 'easy', 'Physical Health', 5, 10),
(3, 108, 'homework', 'pending', 'hard', 'Career / Studies', 15, 30);

--
-- Triggers `tasks`
--
DELIMITER $$
CREATE TRIGGER `after_task_completion` AFTER UPDATE ON `tasks` FOR EACH ROW BEGIN
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
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `test_data`
--

CREATE TABLE `test_data` (
  `id` int NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` text,
  `category` varchar(50) DEFAULT NULL,
  `price` decimal(10,2) DEFAULT NULL,
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
(1, 'sean@test.com', 'cshan', '$2y$12$gBAi1irBLrd608bjSEdlDeJcVUiAVj1j3tnazkuFl.9LZRY6A/iqi', 'sean agustine lumandong esparagoza', 'user', '2025-05-16 04:34:10', '2025-05-28 13:51:35', 249, 0, 1, 1, 1, 'light', 'default'),
(2, 'admin@test.com', 'admins', '$2y$12$aKcAhRRF0BDCzLC5aPPWzekYgP4o1Uvz4K9Hqfj6RWFAY3g1K55fO', 'admin', 'admin', '2025-05-16 19:33:17', '2025-05-28 03:08:12', 45, 0, 1, 1, 1, 'light', 'default'),
(3, 'marvin@test.com', 'marvin', '$2y$12$TJkI38.fHsrGikN.sy2QnOKKvrKsLUB72hN3QSAH53a4Yt1wtjA.2', 'marvin', 'user', '2025-05-16 19:36:07', '2025-05-28 11:39:17', 366, 0, 1, 1, 1, 'dark', 'default'),
(4, 'bady@test.com', 'bady', '$2y$12$Q18lWoFuY8o0wJvYJDbPU.kpUs64S8zL5JdIpWqKsI4vCqoLYXyXS', 'Bady Sinco', 'user', '2025-05-17 10:04:51', '2025-05-19 08:57:39', 17, 0, 1, 1, 1, 'light', 'default'),
(5, 'has@test.com', 'has', '$2y$12$LZLeJSAV1v0CIs/lmMc2KePBs7zSUsoHBrF7aL93MWtAvRlrg0TTu', 'hahaha', 'user', '2025-05-17 22:34:20', '2025-05-18 06:34:20', 0, 0, 1, 1, 1, 'light', 'default'),
(6, 'haha@gmail.com', 'hahass', '$2y$12$2uubua3xSJbG3blDHIm/B.VFWoH5w8jRxyS3bR/TJRcL.JwYDInoq', 'hahaha', 'user', '2025-05-25 17:49:36', '2025-05-26 01:49:36', 0, 0, 1, 1, 1, 'light', 'default'),
(7, 'daniel.ortiz62@yahoo.com', 'danielortiz861', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Daniel Ortiz', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 47, 1, 1, 1, 1, 'light', 'default'),
(8, 'nicholas.peterson91@example.com', 'nicholaspeterson189', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Nicholas Peterson', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 60, 1, 1, 1, 1, 'light', 'default'),
(9, 'raymond.torres63@hotmail.com', 'raymondtorres492', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Raymond Torres', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 76, 1, 1, 1, 1, 'light', 'default'),
(10, 'lisa.morgan76@example.com', 'lisamorgan764', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Lisa Morgan', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 67, 1, 1, 1, 1, 'light', 'default'),
(11, 'ronald.jones39@gmail.com', 'ronaldjones772', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Ronald Jones', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 60, 1, 1, 1, 1, 'light', 'default'),
(12, 'nancy.brooks65@outlook.com', 'nancybrooks183', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Nancy Brooks', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 29, 1, 1, 1, 1, 'light', 'default'),
(13, 'nicholas.nelson82@yahoo.com', 'nicholasnelson147', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Nicholas Nelson', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 54, 1, 1, 1, 1, 'light', 'default'),
(14, 'deborah.garcia76@test.com', 'deborahgarcia738', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Deborah Garcia', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 19, 1, 1, 1, 1, 'light', 'default'),
(15, 'laura.harris66@outlook.com', 'lauraharris277', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Laura Harris', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 95, 1, 1, 1, 1, 'light', 'default'),
(16, 'jessica.adams47@gmail.com', 'jessicaadams605', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Jessica Adams', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 34, 1, 1, 1, 1, 'light', 'default'),
(17, 'joshua.reed72@hotmail.com', 'joshuareed909', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Joshua Reed', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 46, 1, 1, 1, 1, 'light', 'default'),
(18, 'carol.watson47@hotmail.com', 'carolwatson908', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Carol Watson', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 52, 1, 1, 1, 1, 'light', 'default'),
(19, 'ruth.collins70@example.com', 'ruthcollins475', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Ruth Collins', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 58, 1, 1, 1, 1, 'light', 'default'),
(20, 'scott.flores71@hotmail.com', 'scottflores146', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Scott Flores', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 89, 1, 1, 1, 1, 'light', 'default'),
(21, 'matthew.brooks15@hotmail.com', 'matthewbrooks462', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Matthew Brooks', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 69, 1, 1, 1, 1, 'light', 'default'),
(22, 'daniel.parker89@hotmail.com', 'danielparker956', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Daniel Parker', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 14, 1, 1, 1, 1, 'light', 'default'),
(23, 'raymond.perez49@example.com', 'raymondperez279', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Raymond Perez', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 29, 1, 1, 1, 1, 'light', 'default'),
(24, 'tyler.young73@test.com', 'tyleryoung497', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Tyler Young', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 78, 1, 1, 1, 1, 'light', 'default'),
(25, 'betty.rodriguez19@yahoo.com', 'bettyrodriguez365', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Betty Rodriguez', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 11, 1, 1, 1, 1, 'light', 'default'),
(26, 'john.walker41@yahoo.com', 'johnwalker219', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'John Walker', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 21, 1, 1, 1, 1, 'light', 'default'),
(27, 'alexander.martinez49@outlook.com', 'alexandermartinez616', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Alexander Martinez', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 10, 1, 1, 1, 1, 'light', 'default'),
(28, 'david.wood19@yahoo.com', 'davidwood111', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'David Wood', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 15, 1, 1, 1, 1, 'light', 'default'),
(29, 'nancy.moore90@test.com', 'nancymoore603', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Nancy Moore', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 97, 1, 1, 1, 1, 'light', 'default'),
(30, 'ronald.kelly59@yahoo.com', 'ronaldkelly357', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Ronald Kelly', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 62, 1, 1, 1, 1, 'light', 'default'),
(31, 'jennifer.stewart35@test.com', 'jenniferstewart584', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Jennifer Stewart', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 86, 1, 1, 1, 1, 'light', 'default'),
(32, 'daniel.kim79@yahoo.com', 'danielkim559', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Daniel Kim', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 75, 1, 1, 1, 1, 'light', 'default'),
(33, 'jacob.wilson15@example.com', 'jacobwilson198', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Jacob Wilson', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 41, 1, 1, 1, 1, 'light', 'default'),
(34, 'brian.morales35@test.com', 'brianmorales578', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Brian Morales', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 86, 1, 1, 1, 1, 'light', 'default'),
(35, 'sarah.phillips98@test.com', 'sarahphillips295', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Sarah Phillips', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 61, 1, 1, 1, 1, 'light', 'default'),
(36, 'patricia.james91@test.com', 'patriciajames856', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Patricia James', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 56, 1, 1, 1, 1, 'light', 'default'),
(37, 'frank.carter24@yahoo.com', 'frankcarter794', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Frank Carter', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 44, 1, 1, 1, 1, 'light', 'default'),
(38, 'sandra.brooks78@yahoo.com', 'sandrabrooks280', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Sandra Brooks', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 40, 1, 1, 1, 1, 'light', 'default'),
(39, 'richard.mendoza23@outlook.com', 'richardmendoza422', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Richard Mendoza', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 10, 1, 1, 1, 1, 'light', 'default'),
(40, 'helen.taylor83@gmail.com', 'helentaylor729', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Helen Taylor', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 70, 1, 1, 1, 1, 'light', 'default'),
(41, 'sharon.brooks74@hotmail.com', 'sharonbrooks918', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Sharon Brooks', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 24, 1, 1, 1, 1, 'light', 'default'),
(42, 'olivia.evans76@yahoo.com', 'oliviaevans801', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Olivia Evans', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 85, 1, 1, 1, 1, 'light', 'default'),
(43, 'george.gutierrez83@outlook.com', 'georgegutierrez949', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'George Gutierrez', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 32, 1, 1, 1, 1, 'light', 'default'),
(44, 'james.nguyen71@hotmail.com', 'jamesnguyen488', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'James Nguyen', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 1, 1, 1, 1, 1, 'light', 'default'),
(45, 'tyler.ward63@example.com', 'tylerward246', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Tyler Ward', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 63, 1, 1, 1, 1, 'light', 'default'),
(46, 'paul.collins49@outlook.com', 'paulcollins499', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Paul Collins', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 61, 1, 1, 1, 1, 'light', 'default'),
(47, 'joshua.moore13@test.com', 'joshuamoore256', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Joshua Moore', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 35, 1, 1, 1, 1, 'light', 'default'),
(48, 'ronald.watson85@yahoo.com', 'ronaldwatson843', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Ronald Watson', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 7, 1, 1, 1, 1, 'light', 'default'),
(49, 'ronald.howard43@yahoo.com', 'ronaldhoward101', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Ronald Howard', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 21, 1, 1, 1, 1, 'light', 'default'),
(50, 'olivia.scott19@gmail.com', 'oliviascott469', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Olivia Scott', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 36, 1, 1, 1, 1, 'light', 'default'),
(51, 'matthew.campbell68@hotmail.com', 'matthewcampbell311', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Matthew Campbell', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 69, 1, 1, 1, 1, 'light', 'default'),
(52, 'ruth.anderson17@test.com', 'ruthanderson800', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Ruth Anderson', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 52, 1, 1, 1, 1, 'light', 'default'),
(53, 'donna.edwards73@yahoo.com', 'donnaedwards331', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Donna Edwards', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 87, 1, 1, 1, 1, 'light', 'default'),
(54, 'frank.cox43@hotmail.com', 'frankcox653', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Frank Cox', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 49, 1, 1, 1, 1, 'light', 'default'),
(55, 'jessica.clark14@gmail.com', 'jessicaclark295', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Jessica Clark', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 55, 1, 1, 1, 1, 'light', 'default'),
(56, 'kimberly.martin26@yahoo.com', 'kimberlymartin983', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Kimberly Martin', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 4, 1, 1, 1, 1, 'light', 'default'),
(57, 'patricia.martinez47@test.com', 'patriciamartinez753', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Patricia Martinez', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 37, 1, 1, 1, 1, 'light', 'default'),
(58, 'richard.ramos66@example.com', 'richardramos633', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Richard Ramos', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 11, 1, 1, 1, 1, 'light', 'default'),
(59, 'laura.clark82@outlook.com', 'lauraclark996', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Laura Clark', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 31, 1, 1, 1, 1, 'light', 'default'),
(60, 'donald.martin18@yahoo.com', 'donaldmartin757', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Donald Martin', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 51, 1, 1, 1, 1, 'light', 'default'),
(61, 'sharon.clark56@example.com', 'sharonclark642', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Sharon Clark', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 49, 1, 1, 1, 1, 'light', 'default'),
(62, 'william.morales51@gmail.com', 'williammorales520', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'William Morales', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 86, 1, 1, 1, 1, 'light', 'default'),
(63, 'charles.kelly65@gmail.com', 'charleskelly157', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Charles Kelly', 'user', '2025-05-28 02:57:18', '2025-05-28 02:57:18', 95, 1, 1, 1, 1, 'light', 'default'),
(64, 'richard.anderson60@yahoo.com', 'richardanderson950', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Richard Anderson', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 31, 1, 1, 1, 1, 'light', 'default'),
(65, 'lisa.rogers99@example.com', 'lisarogers245', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Lisa Rogers', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 7, 1, 1, 1, 1, 'light', 'default'),
(66, 'donna.perez24@outlook.com', 'donnaperez938', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Donna Perez', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 56, 1, 1, 1, 1, 'light', 'default'),
(67, 'lisa.harris88@yahoo.com', 'lisaharris713', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Lisa Harris', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 72, 1, 1, 1, 1, 'light', 'default'),
(68, 'nancy.stewart16@hotmail.com', 'nancystewart379', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Nancy Stewart', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 99, 1, 1, 1, 1, 'light', 'default'),
(69, 'scott.chavez19@yahoo.com', 'scottchavez443', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Scott Chavez', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 66, 1, 1, 1, 1, 'light', 'default'),
(70, 'betty.roberts69@example.com', 'bettyroberts938', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Betty Roberts', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 24, 1, 1, 1, 1, 'light', 'default'),
(71, 'katherine.campbell29@hotmail.com', 'katherinecampbell433', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Katherine Campbell', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 50, 1, 1, 1, 1, 'light', 'default'),
(72, 'alexander.kelly75@yahoo.com', 'alexanderkelly269', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Alexander Kelly', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 96, 1, 1, 1, 1, 'light', 'default'),
(73, 'angela.ward99@hotmail.com', 'angelaward176', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Angela Ward', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 35, 1, 1, 1, 1, 'light', 'default'),
(74, 'tyler.baker92@gmail.com', 'tylerbaker199', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Tyler Baker', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 52, 1, 1, 1, 1, 'light', 'default'),
(75, 'timothy.gonzalez39@example.com', 'timothygonzalez513', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Timothy Gonzalez', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 94, 1, 1, 1, 1, 'light', 'default'),
(76, 'lisa.roberts44@test.com', 'lisaroberts643', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Lisa Roberts', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 7, 1, 1, 1, 1, 'light', 'default'),
(77, 'joseph.lewis16@example.com', 'josephlewis804', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Joseph Lewis', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 95, 1, 1, 1, 1, 'light', 'default'),
(78, 'donna.anderson81@example.com', 'donnaanderson388', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Donna Anderson', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 84, 1, 1, 1, 1, 'light', 'default'),
(79, 'anna.martinez36@outlook.com', 'annamartinez439', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Anna Martinez', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 24, 1, 1, 1, 1, 'light', 'default'),
(80, 'brian.chavez70@yahoo.com', 'brianchavez368', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Brian Chavez', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 97, 1, 1, 1, 1, 'light', 'default'),
(81, 'paul.baker95@gmail.com', 'paulbaker583', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Paul Baker', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 32, 1, 1, 1, 1, 'light', 'default'),
(82, 'frank.collins19@test.com', 'frankcollins250', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Frank Collins', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 2, 1, 1, 1, 1, 'light', 'default'),
(83, 'ruth.johnson32@outlook.com', 'ruthjohnson411', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Ruth Johnson', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 46, 1, 1, 1, 1, 'light', 'default'),
(84, 'sarah.bennett89@yahoo.com', 'sarahbennett919', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Sarah Bennett', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 97, 1, 1, 1, 1, 'light', 'default'),
(85, 'jessica.flores79@hotmail.com', 'jessicaflores883', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Jessica Flores', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 37, 1, 1, 1, 1, 'light', 'default'),
(86, 'jennifer.reyes38@test.com', 'jenniferreyes967', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Jennifer Reyes', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 2, 1, 1, 1, 1, 'light', 'default'),
(87, 'kimberly.campbell55@gmail.com', 'kimberlycampbell703', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Kimberly Campbell', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 39, 1, 1, 1, 1, 'light', 'default'),
(88, 'sarah.cox47@yahoo.com', 'sarahcox818', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Sarah Cox', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 47, 1, 1, 1, 1, 'light', 'default'),
(89, 'katherine.martinez84@gmail.com', 'katherinemartinez857', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Katherine Martinez', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 53, 1, 1, 1, 1, 'light', 'default'),
(90, 'frank.chavez22@hotmail.com', 'frankchavez899', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Frank Chavez', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 22, 1, 1, 1, 1, 'light', 'default'),
(91, 'patrick.parker97@hotmail.com', 'patrickparker801', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Patrick Parker', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 17, 1, 1, 1, 1, 'light', 'default'),
(92, 'kimberly.rodriguez10@hotmail.com', 'kimberlyrodriguez543', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Kimberly Rodriguez', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 27, 1, 1, 1, 1, 'light', 'default'),
(93, 'betty.robinson66@outlook.com', 'bettyrobinson213', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Betty Robinson', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 59, 1, 1, 1, 1, 'light', 'default'),
(94, 'lisa.diaz46@hotmail.com', 'lisadiaz456', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Lisa Diaz', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 80, 1, 1, 1, 1, 'light', 'default'),
(95, 'emma.parker40@gmail.com', 'emmaparker702', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Emma Parker', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 57, 1, 1, 1, 1, 'light', 'default'),
(96, 'angela.reed50@gmail.com', 'angelareed108', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Angela Reed', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 77, 1, 1, 1, 1, 'light', 'default'),
(97, 'linda.bennett98@example.com', 'lindabennett462', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Linda Bennett', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 23, 1, 1, 1, 1, 'light', 'default'),
(98, 'jeffrey.cooper14@example.com', 'jeffreycooper255', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Jeffrey Cooper', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 32, 1, 1, 1, 1, 'light', 'default'),
(99, 'charles.lewis87@test.com', 'charleslewis920', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Charles Lewis', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 100, 1, 1, 1, 1, 'light', 'default'),
(100, 'shirley.hill81@hotmail.com', 'shirleyhill898', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Shirley Hill', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 0, 1, 1, 1, 1, 'light', 'default'),
(101, 'scott.young86@test.com', 'scottyoung784', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Scott Young', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 1, 1, 1, 1, 1, 'light', 'default'),
(102, 'deborah.cooper77@test.com', 'deborahcooper115', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Deborah Cooper', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 67, 1, 1, 1, 1, 'light', 'default'),
(103, 'gregory.diaz34@yahoo.com', 'gregorydiaz148', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Gregory Diaz', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 66, 1, 1, 1, 1, 'light', 'default'),
(104, 'sarah.torres21@example.com', 'sarahtorres382', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Sarah Torres', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 0, 1, 1, 1, 1, 'light', 'default'),
(105, 'donna.brown97@hotmail.com', 'donnabrown303', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Donna Brown', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 11, 1, 1, 1, 1, 'light', 'default'),
(106, 'aaron.morris27@outlook.com', 'aaronmorris317', '$2y$12$j2C05Br6K8LOfYCNRx.ESOtzRcBd/pUM4rQrSYNciUUbkO1Qm0qIG', 'Aaron Morris', 'user', '2025-05-28 02:57:19', '2025-05-28 02:57:19', 19, 1, 1, 1, 1, 'light', 'default'),
(107, 'gean@gmail.com', 'Spiderman', '$2y$12$50I2QgPIHjVQFY9NvAAO2eKruc1mWV2T0gElfEaLwehfxp4//pR9C', 'gean', 'user', '2025-05-28 05:59:02', '2025-05-28 06:43:36', 85, 0, 1, 1, 1, 'light', 'default'),
(108, 'sean@gmail.com', 'chansean28', '$2y$12$oHzAyf4LmY6IEwRQ3JSC8OR1yVRIwDXlhY5TJFKwaNA3A7/jDxpBW', 'Sean Esparagozaa', 'user', '2025-05-28 14:07:54', '2025-05-28 14:14:20', 23, 0, 1, 1, 1, 'light', 'default');

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
(1, 1, 5, 162, 100, 4, 'Learn to Code', 114, 5, 5, 5, 5, 5, 5, 5),
(3, 3, 4, 78, 100, 1, '123', 58, 5, 11, 5, 5, 5, 5, 5),
(4, 2, 1, 72, 100, 4, 'admin', 5, 5, 5, 5, 5, 5, 5, 5),
(5, 4, 1, 10, 100, 3, 'master my master', 5, 5, 5, 5, 5, 5, 5, 5),
(6, 5, 1, 0, 100, 1, 'Become the best version of myself', 5, 5, 5, 5, 5, 5, 5, 5),
(7, 6, 1, 0, 100, 1, 'Become the best version of myself', 5, 5, 5, 5, 5, 5, 5, 5),
(8, 7, 1, 27, 100, 2, 'Start my own business', 11, 27, 29, 18, 24, 7, 26, 31),
(9, 8, 1, 136, 100, 1, 'Improve my public speaking skills', 19, 19, 22, 25, 6, 28, 10, 28),
(10, 9, 1, 193, 100, 3, 'Master a new language fluently', 22, 31, 23, 6, 32, 31, 25, 20),
(11, 10, 1, 7, 100, 4, 'Learn data science and machine learning', 16, 19, 19, 23, 14, 18, 14, 5),
(12, 11, 1, 43, 100, 1, 'Become financially independent', 12, 22, 9, 12, 6, 11, 18, 30),
(13, 12, 1, 8, 100, 2, 'Complete a degree', 25, 7, 30, 7, 18, 24, 21, 27),
(14, 13, 1, 38, 100, 3, 'Build a mobile app', 10, 28, 7, 23, 17, 23, 32, 8),
(15, 14, 1, 70, 100, 4, 'Start my own business', 20, 26, 27, 31, 11, 16, 24, 9),
(16, 15, 1, 64, 100, 3, 'Complete a degree', 26, 33, 28, 6, 24, 31, 26, 33),
(17, 16, 1, 186, 100, 1, 'Improve mental health and mindfulness', 30, 24, 20, 5, 27, 26, 15, 9),
(18, 17, 1, 14, 100, 4, 'Get fit and lose 20 pounds', 7, 26, 8, 16, 7, 33, 6, 6),
(19, 18, 1, 101, 100, 3, 'Get fit and lose 20 pounds', 31, 20, 6, 12, 27, 29, 13, 13),
(20, 19, 1, 3, 100, 2, 'Build meaningful relationships', 22, 21, 8, 24, 32, 10, 31, 15),
(21, 20, 1, 128, 100, 1, 'Become a better leader', 18, 33, 12, 15, 12, 15, 8, 23),
(22, 21, 1, 61, 100, 2, 'Learn to play guitar', 23, 11, 8, 31, 8, 14, 10, 25),
(23, 22, 1, 103, 100, 2, 'Travel to 10 different countries', 27, 19, 10, 15, 30, 11, 23, 26),
(24, 23, 1, 107, 100, 3, 'Learn data science and machine learning', 23, 17, 33, 7, 13, 19, 13, 23),
(25, 24, 1, 154, 100, 3, 'Start my own business', 30, 14, 20, 10, 15, 13, 33, 25),
(26, 25, 1, 173, 100, 2, 'Learn digital marketing', 17, 26, 9, 10, 27, 22, 5, 14),
(27, 26, 1, 98, 100, 4, 'Learn to code and become a software developer', 14, 28, 28, 19, 10, 17, 31, 29),
(28, 27, 1, 76, 100, 4, 'Master cooking skills', 15, 25, 7, 5, 31, 19, 27, 23),
(29, 28, 1, 176, 100, 4, 'Save $10,000 for emergency fund', 11, 13, 6, 16, 14, 32, 17, 6),
(30, 29, 1, 116, 100, 3, 'Complete a degree', 25, 9, 6, 11, 24, 31, 30, 25),
(31, 30, 1, 161, 100, 1, 'Start my own business', 24, 28, 18, 8, 25, 10, 16, 17),
(32, 31, 1, 136, 100, 4, 'Learn photography', 33, 19, 28, 14, 14, 27, 5, 7),
(33, 32, 1, 161, 100, 1, 'Complete a degree', 32, 14, 9, 12, 8, 28, 30, 11),
(34, 33, 1, 5, 100, 4, 'Learn data science and machine learning', 5, 11, 22, 30, 21, 30, 31, 32),
(35, 34, 1, 79, 100, 1, 'Run a marathon', 23, 8, 25, 8, 10, 23, 16, 33),
(36, 35, 1, 109, 100, 3, 'Build meaningful relationships', 5, 5, 28, 16, 10, 31, 15, 24),
(37, 36, 1, 191, 100, 4, 'Learn to code and become a software developer', 22, 19, 29, 13, 25, 33, 20, 18),
(38, 37, 1, 50, 100, 3, 'Run a marathon', 14, 7, 20, 32, 26, 15, 16, 29),
(39, 38, 1, 63, 100, 2, 'Build meaningful relationships', 14, 20, 5, 10, 28, 29, 14, 23),
(40, 39, 1, 171, 100, 3, 'Get fit and lose 20 pounds', 22, 5, 8, 32, 32, 12, 17, 23),
(41, 40, 1, 14, 100, 3, 'Improve my public speaking skills', 23, 12, 31, 12, 19, 11, 24, 16),
(42, 41, 1, 66, 100, 2, 'Master time management', 33, 29, 32, 6, 30, 8, 32, 24),
(43, 42, 1, 159, 100, 4, 'Get fit and lose 20 pounds', 27, 21, 25, 7, 33, 5, 17, 13),
(44, 43, 1, 148, 100, 2, 'Save $10,000 for emergency fund', 21, 12, 28, 29, 20, 20, 5, 19),
(45, 44, 1, 69, 100, 1, 'Write a novel', 7, 33, 7, 22, 27, 13, 32, 17),
(46, 45, 1, 155, 100, 4, 'Improve mental health and mindfulness', 24, 20, 7, 32, 26, 12, 10, 5),
(47, 46, 1, 161, 100, 1, 'Learn digital marketing', 9, 8, 6, 5, 29, 21, 16, 28),
(48, 47, 1, 35, 100, 4, 'Run a marathon', 11, 30, 15, 24, 6, 10, 7, 7),
(49, 48, 1, 180, 100, 2, 'Run a marathon', 6, 24, 22, 17, 33, 9, 5, 33),
(50, 49, 1, 28, 100, 1, 'Learn to code and become a software developer', 8, 26, 10, 13, 25, 11, 24, 18),
(51, 50, 1, 193, 100, 4, 'Learn photography', 11, 33, 17, 26, 32, 27, 30, 13),
(52, 51, 1, 32, 100, 4, 'Start a YouTube channel', 28, 15, 33, 6, 5, 29, 29, 30),
(53, 52, 1, 78, 100, 4, 'Master cooking skills', 32, 33, 25, 10, 33, 8, 27, 7),
(54, 53, 1, 29, 100, 3, 'Learn to code and become a software developer', 27, 32, 16, 11, 13, 32, 16, 29),
(55, 54, 1, 76, 100, 2, 'Start a YouTube channel', 30, 31, 8, 5, 28, 5, 18, 18),
(56, 55, 1, 5, 100, 1, 'Read 50 books this year', 6, 12, 8, 23, 9, 5, 29, 11),
(57, 56, 1, 53, 100, 1, 'Start my own business', 19, 9, 31, 11, 24, 8, 15, 12),
(58, 57, 1, 89, 100, 3, 'Start a YouTube channel', 16, 12, 7, 22, 6, 6, 19, 5),
(59, 58, 1, 15, 100, 1, 'Read 50 books this year', 32, 20, 10, 18, 16, 31, 30, 30),
(60, 59, 1, 5, 100, 2, 'Learn to play guitar', 7, 14, 14, 11, 19, 28, 30, 22),
(61, 60, 1, 198, 100, 4, 'Become financially independent', 33, 7, 29, 23, 7, 7, 32, 13),
(62, 61, 1, 129, 100, 4, 'Learn photography', 25, 9, 16, 29, 10, 27, 16, 31),
(63, 62, 1, 89, 100, 2, 'Travel to 10 different countries', 33, 30, 7, 20, 10, 33, 33, 22),
(64, 63, 1, 125, 100, 4, 'Master time management', 20, 16, 23, 21, 11, 10, 5, 20),
(65, 64, 1, 91, 100, 2, 'Improve my public speaking skills', 7, 14, 18, 25, 27, 21, 29, 18),
(66, 65, 1, 51, 100, 3, 'Read 50 books this year', 12, 18, 17, 26, 18, 32, 19, 5),
(67, 66, 1, 101, 100, 3, 'Build meaningful relationships', 33, 19, 19, 32, 23, 9, 23, 27),
(68, 67, 1, 47, 100, 1, 'Run a marathon', 27, 28, 33, 13, 7, 14, 27, 26),
(69, 68, 1, 121, 100, 3, 'Master cooking skills', 9, 11, 9, 5, 19, 26, 8, 31),
(70, 69, 1, 19, 100, 2, 'Learn to code and become a software developer', 21, 26, 24, 6, 11, 26, 32, 24),
(71, 70, 1, 44, 100, 4, 'Save $10,000 for emergency fund', 19, 22, 9, 9, 15, 16, 10, 24),
(72, 71, 1, 149, 100, 2, 'Learn to play guitar', 7, 11, 31, 9, 8, 7, 15, 33),
(73, 72, 1, 182, 100, 3, 'Learn data science and machine learning', 17, 11, 10, 31, 33, 8, 22, 27),
(74, 73, 1, 29, 100, 3, 'Save $10,000 for emergency fund', 28, 6, 19, 29, 27, 15, 30, 24),
(75, 74, 1, 52, 100, 2, 'Travel to 10 different countries', 15, 27, 5, 23, 12, 29, 33, 19),
(76, 75, 1, 88, 100, 2, 'Learn to code and become a software developer', 13, 11, 29, 10, 28, 19, 11, 7),
(77, 76, 1, 13, 100, 4, 'Write a novel', 28, 25, 20, 20, 18, 22, 12, 22),
(78, 77, 1, 135, 100, 4, 'Get fit and lose 20 pounds', 23, 13, 32, 29, 12, 21, 18, 16),
(79, 78, 1, 152, 100, 3, 'Build meaningful relationships', 23, 15, 26, 6, 6, 26, 33, 8),
(80, 79, 1, 173, 100, 3, 'Master time management', 21, 20, 24, 7, 9, 7, 13, 12),
(81, 80, 1, 145, 100, 3, 'Start my own business', 17, 12, 6, 21, 11, 6, 19, 30),
(82, 81, 1, 167, 100, 1, 'Improve mental health and mindfulness', 17, 11, 30, 22, 7, 29, 19, 12),
(83, 82, 1, 16, 100, 1, 'Become financially independent', 18, 11, 20, 33, 29, 19, 11, 14),
(84, 83, 1, 171, 100, 1, 'Master time management', 12, 9, 15, 31, 14, 16, 31, 16),
(85, 84, 1, 75, 100, 3, 'Build a mobile app', 6, 24, 32, 19, 12, 27, 12, 15),
(86, 85, 1, 141, 100, 4, 'Become financially independent', 26, 21, 28, 28, 13, 32, 33, 18),
(87, 86, 1, 145, 100, 3, 'Improve my public speaking skills', 25, 14, 25, 24, 20, 19, 16, 25),
(88, 87, 1, 17, 100, 1, 'Improve work-life balance', 10, 31, 20, 14, 19, 26, 6, 23),
(89, 88, 1, 89, 100, 3, 'Learn to code and become a software developer', 12, 12, 12, 19, 14, 22, 10, 16),
(90, 89, 1, 34, 100, 2, 'Master time management', 7, 9, 16, 22, 10, 24, 5, 21),
(91, 90, 1, 188, 100, 4, 'Learn to code and become a software developer', 12, 28, 29, 16, 18, 25, 12, 5),
(92, 91, 1, 34, 100, 2, 'Save $10,000 for emergency fund', 7, 17, 30, 11, 29, 28, 26, 18),
(93, 92, 1, 152, 100, 2, 'Improve work-life balance', 6, 13, 15, 26, 17, 10, 6, 6),
(94, 93, 1, 166, 100, 2, 'Write a novel', 26, 30, 20, 25, 27, 18, 29, 14),
(95, 94, 1, 179, 100, 4, 'Build a mobile app', 7, 14, 18, 8, 10, 30, 15, 22),
(96, 95, 1, 99, 100, 4, 'Build meaningful relationships', 29, 7, 29, 28, 8, 17, 17, 10),
(97, 96, 1, 161, 100, 1, 'Become a better leader', 9, 15, 25, 20, 24, 12, 30, 18),
(98, 97, 1, 129, 100, 4, 'Learn to code and become a software developer', 31, 30, 24, 14, 33, 5, 26, 16),
(99, 98, 1, 37, 100, 1, 'Run a marathon', 13, 18, 7, 9, 20, 16, 32, 13),
(100, 99, 1, 160, 100, 1, 'Improve work-life balance', 23, 8, 32, 22, 8, 28, 6, 27),
(101, 100, 1, 126, 100, 3, 'Run a marathon', 10, 32, 21, 18, 15, 6, 15, 17),
(102, 101, 1, 144, 100, 4, 'Master cooking skills', 18, 14, 20, 20, 30, 33, 23, 8),
(103, 102, 1, 141, 100, 3, 'Learn photography', 18, 17, 26, 14, 15, 6, 24, 16),
(104, 103, 1, 169, 100, 1, 'Learn data science and machine learning', 22, 12, 29, 7, 16, 21, 28, 8),
(105, 104, 1, 156, 100, 4, 'Save $10,000 for emergency fund', 25, 8, 16, 5, 13, 6, 22, 8),
(106, 105, 1, 47, 100, 1, 'Improve work-life balance', 22, 5, 12, 31, 31, 5, 28, 14),
(107, 106, 1, 27, 100, 2, 'Learn digital marketing', 11, 7, 20, 7, 25, 15, 33, 20),
(108, 107, 2, 202, 40, 4, 'Workout', 30, 5, 5, 7, 5, 5, 5, 5),
(109, 108, 1, 30, 92, 4, 'Learn to Code', 6, 6, 5, 5, 5, 5, 5, 5);

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

--
-- Dumping data for table `user_active_boosts`
--

INSERT INTO `user_active_boosts` (`boost_id`, `user_id`, `boost_type`, `boost_value`, `activated_at`, `expires_at`) VALUES
(4, 3, 'xp_multiplier', 1, '2025-05-25 08:57:13', '2025-05-26 08:57:13'),
(5, 1, 'xp_multiplier', 1, '2025-05-25 19:20:12', '2025-05-26 19:20:12');

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
  `status` enum('active','inactive') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `user_event`
--

INSERT INTO `user_event` (`id`, `user_id`, `event_name`, `event_description`, `start_date`, `end_date`, `reward_xp`, `reward_coins`, `status`, `created_at`, `updated_at`) VALUES
(1, 2, 'OPLAN TULI', 'mag pa tuli', '2025-05-17 16:00:00', '2025-05-17 16:00:00', 10, 10, 'inactive', '2025-05-16 19:39:17', '2025-05-28 03:14:19'),
(2, 2, 'OPLAN TULIs', 'mag pa tulidasdasd', '2025-05-20 09:37:17', '2025-05-19 16:00:00', 12, 12, 'inactive', '2025-05-18 02:54:01', '2025-05-20 09:37:17'),
(3, 2, 'testing', 'test', '2025-05-28 03:14:10', '2025-05-20 16:00:00', 12, 12, 'inactive', '2025-05-18 05:58:31', '2025-05-28 03:14:10'),
(4, 2, 'sda', 'sda', '2025-05-28 03:14:10', '2025-05-20 16:00:00', 1, 1, 'inactive', '2025-05-20 09:37:17', '2025-05-28 03:14:10'),
(5, 1, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-06-05 18:57:27', '2025-06-05 20:57:27', 36, 24, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(6, 1, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-07-19 18:57:27', '2025-07-19 20:57:27', 24, 29, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(7, 1, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-07-02 18:57:27', '2025-07-02 20:57:27', 48, 28, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(8, 3, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-05-30 18:57:27', '2025-05-30 20:57:27', 35, 24, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(9, 3, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-12 18:57:27', '2025-06-12 20:57:27', 45, 11, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(10, 4, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-06-07 18:57:27', '2025-06-07 20:57:27', 18, 11, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(11, 4, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-07-02 18:57:27', '2025-07-02 20:57:27', 50, 19, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(12, 5, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-06-09 18:57:27', '2025-06-09 20:57:27', 29, 24, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(13, 6, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-05 18:57:27', '2025-06-05 20:57:27', 41, 11, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(14, 7, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-24 18:57:27', '2025-06-24 20:57:27', 27, 23, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(15, 7, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-20 18:57:27', '2025-06-20 20:57:27', 36, 25, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(16, 7, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-06-07 18:57:27', '2025-06-07 20:57:27', 24, 25, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(17, 8, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-07-06 18:57:27', '2025-07-06 20:57:27', 32, 30, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(18, 8, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-07-20 18:57:27', '2025-07-20 20:57:27', 45, 10, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(19, 8, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-16 18:57:27', '2025-06-16 20:57:27', 39, 16, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(20, 9, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-07-09 18:57:27', '2025-07-09 20:57:27', 22, 12, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(21, 9, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-07-06 18:57:27', '2025-07-06 20:57:27', 23, 24, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(22, 10, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-07-11 18:57:27', '2025-07-11 20:57:27', 32, 26, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(23, 10, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-07-02 18:57:27', '2025-07-02 20:57:27', 36, 25, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(24, 11, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-07-14 18:57:27', '2025-07-14 20:57:27', 49, 13, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(25, 11, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-07-19 18:57:27', '2025-07-19 20:57:27', 21, 12, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(26, 11, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-06-25 18:57:27', '2025-06-25 20:57:27', 43, 24, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(27, 12, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-07-06 18:57:27', '2025-07-06 20:57:27', 46, 27, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(28, 12, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-07-17 18:57:27', '2025-07-17 20:57:27', 44, 22, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(29, 12, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-06-07 18:57:27', '2025-06-07 20:57:27', 18, 27, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(30, 13, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-06-28 18:57:27', '2025-06-28 20:57:27', 48, 26, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(31, 14, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-06-03 18:57:27', '2025-06-03 20:57:27', 15, 23, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(32, 14, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-06-18 18:57:27', '2025-06-18 20:57:27', 41, 22, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(33, 14, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-07-19 18:57:27', '2025-07-19 20:57:27', 25, 23, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(34, 15, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-06-20 18:57:27', '2025-06-20 20:57:27', 25, 29, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(35, 15, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-06-17 18:57:27', '2025-06-17 20:57:27', 15, 24, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(36, 16, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-07-13 18:57:27', '2025-07-13 20:57:27', 26, 10, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(37, 16, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-07-18 18:57:27', '2025-07-18 20:57:27', 25, 18, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(38, 17, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-06-22 18:57:27', '2025-06-22 20:57:27', 42, 23, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(39, 18, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-07-09 18:57:27', '2025-07-09 20:57:27', 43, 25, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(40, 19, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-07-26 18:57:27', '2025-07-26 20:57:27', 33, 22, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(41, 19, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-07-19 18:57:27', '2025-07-19 20:57:27', 39, 20, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(42, 19, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-06-07 18:57:27', '2025-06-07 20:57:27', 23, 24, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(43, 20, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-07-03 18:57:27', '2025-07-03 20:57:27', 17, 20, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(44, 20, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-06-02 18:57:27', '2025-06-02 20:57:27', 40, 26, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(45, 20, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-06-20 18:57:27', '2025-06-20 20:57:27', 41, 30, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(46, 21, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-06-10 18:57:27', '2025-06-10 20:57:27', 43, 12, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(47, 21, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-07-16 18:57:27', '2025-07-16 20:57:27', 50, 22, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(48, 21, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-21 18:57:27', '2025-06-21 20:57:27', 46, 30, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(49, 22, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-06-03 18:57:27', '2025-06-03 20:57:27', 38, 28, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(50, 22, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-07-01 18:57:27', '2025-07-01 20:57:27', 17, 13, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(51, 23, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-06-06 18:57:27', '2025-06-06 20:57:27', 28, 25, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(52, 23, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-07-03 18:57:27', '2025-07-03 20:57:27', 15, 22, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(53, 23, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-06-12 18:57:27', '2025-06-12 20:57:27', 37, 16, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(54, 24, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-07-26 18:57:27', '2025-07-26 20:57:27', 21, 29, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(55, 25, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-07-19 18:57:27', '2025-07-19 20:57:27', 37, 19, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(56, 26, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-06-11 18:57:27', '2025-06-11 20:57:27', 21, 18, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(57, 26, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-07-14 18:57:27', '2025-07-14 20:57:27', 16, 26, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(58, 26, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-22 18:57:27', '2025-06-22 20:57:27', 37, 24, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(59, 27, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-22 18:57:27', '2025-06-22 20:57:27', 27, 11, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(60, 27, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-06-30 18:57:27', '2025-06-30 20:57:27', 31, 12, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(61, 28, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-07-08 18:57:27', '2025-07-08 20:57:27', 42, 20, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(62, 28, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-02 18:57:27', '2025-06-02 20:57:27', 42, 25, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(63, 29, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-06-06 18:57:27', '2025-06-06 20:57:27', 15, 21, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(64, 30, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-06-21 18:57:27', '2025-06-21 20:57:27', 17, 18, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(65, 30, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-09 18:57:27', '2025-06-09 20:57:27', 23, 20, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(66, 31, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-06-16 18:57:27', '2025-06-16 20:57:27', 30, 28, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(67, 32, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-07-26 18:57:27', '2025-07-26 20:57:27', 33, 14, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(68, 32, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-07-19 18:57:27', '2025-07-19 20:57:27', 38, 23, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(69, 32, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-07-02 18:57:27', '2025-07-02 20:57:27', 32, 21, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(70, 33, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-07-16 18:57:27', '2025-07-16 20:57:27', 43, 28, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(71, 33, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-05-28 18:57:27', '2025-05-28 20:57:27', 24, 23, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(72, 33, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-06-24 18:57:27', '2025-06-24 20:57:27', 44, 26, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(73, 34, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-06-25 18:57:27', '2025-06-25 20:57:27', 46, 12, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(74, 34, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-07-09 18:57:27', '2025-07-09 20:57:27', 29, 28, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(75, 34, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-07-16 18:57:27', '2025-07-16 20:57:27', 18, 30, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(76, 35, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-06-25 18:57:27', '2025-06-25 20:57:27', 23, 19, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(77, 35, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-06-23 18:57:27', '2025-06-23 20:57:27', 42, 10, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(78, 36, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-06-24 18:57:27', '2025-06-24 20:57:27', 33, 13, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(79, 36, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-06-02 18:57:27', '2025-06-02 20:57:27', 30, 23, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(80, 36, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-06-08 18:57:27', '2025-06-08 20:57:27', 25, 13, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(81, 37, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-07-03 18:57:27', '2025-07-03 20:57:27', 40, 13, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(82, 38, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-07-14 18:57:27', '2025-07-14 20:57:27', 43, 23, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(83, 38, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-07-25 18:57:27', '2025-07-25 20:57:27', 25, 15, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(84, 39, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-06-28 18:57:27', '2025-06-28 20:57:27', 38, 15, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(85, 40, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-07-17 18:57:27', '2025-07-17 20:57:27', 42, 24, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(86, 40, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-27 18:57:27', '2025-06-27 20:57:27', 50, 18, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(87, 40, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-06-22 18:57:27', '2025-06-22 20:57:27', 40, 26, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(88, 41, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-06-14 18:57:27', '2025-06-14 20:57:27', 24, 28, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(89, 41, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-06-30 18:57:27', '2025-06-30 20:57:27', 15, 11, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(90, 42, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-06-06 18:57:27', '2025-06-06 20:57:27', 22, 15, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(91, 42, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-07-20 18:57:27', '2025-07-20 20:57:27', 15, 12, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(92, 43, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-06-29 18:57:27', '2025-06-29 20:57:27', 50, 29, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(93, 43, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-07-20 18:57:27', '2025-07-20 20:57:27', 47, 25, 'active', '2025-05-28 02:57:27', '2025-05-28 02:57:27'),
(94, 44, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-07-05 18:57:28', '2025-07-05 20:57:28', 22, 17, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(95, 44, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-06-07 18:57:28', '2025-06-07 20:57:28', 17, 29, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(96, 45, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-07-09 18:57:28', '2025-07-09 20:57:28', 33, 25, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(97, 45, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-06-09 18:57:28', '2025-06-09 20:57:28', 28, 25, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(98, 45, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-07-04 18:57:28', '2025-07-04 20:57:28', 26, 30, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(99, 46, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-07-25 18:57:28', '2025-07-25 20:57:28', 26, 22, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(100, 46, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-06-14 18:57:28', '2025-06-14 20:57:28', 48, 15, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(101, 46, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-30 18:57:28', '2025-06-30 20:57:28', 33, 26, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(102, 47, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-06-07 18:57:28', '2025-06-07 20:57:28', 24, 24, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(103, 47, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-06-25 18:57:28', '2025-06-25 20:57:28', 49, 17, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(104, 48, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-06-04 18:57:28', '2025-06-04 20:57:28', 40, 22, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(105, 49, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-06-06 18:57:28', '2025-06-06 20:57:28', 25, 30, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(106, 50, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-06-26 18:57:28', '2025-06-26 20:57:28', 28, 25, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(107, 51, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-06-02 18:57:28', '2025-06-02 20:57:28', 26, 30, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(108, 51, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-06-17 18:57:28', '2025-06-17 20:57:28', 25, 17, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(109, 51, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-06-10 18:57:28', '2025-06-10 20:57:28', 15, 26, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(110, 52, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-07-05 18:57:28', '2025-07-05 20:57:28', 24, 18, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(111, 53, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-06-18 18:57:28', '2025-06-18 20:57:28', 45, 19, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(112, 53, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-05 18:57:28', '2025-06-05 20:57:28', 45, 28, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(113, 54, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-05-28 18:57:28', '2025-05-28 20:57:28', 32, 10, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(114, 55, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-06-02 18:57:28', '2025-06-02 20:57:28', 34, 25, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(115, 55, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-07-04 18:57:28', '2025-07-04 20:57:28', 28, 23, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(116, 56, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-05-31 18:57:28', '2025-05-31 20:57:28', 24, 29, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(117, 56, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-06-03 18:57:28', '2025-06-03 20:57:28', 46, 22, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(118, 56, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-06-30 18:57:28', '2025-06-30 20:57:28', 16, 13, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(119, 57, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-07-20 18:57:28', '2025-07-20 20:57:28', 32, 15, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(120, 57, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-12 18:57:28', '2025-06-12 20:57:28', 33, 14, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(121, 58, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-06-21 18:57:28', '2025-06-21 20:57:28', 38, 14, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(122, 59, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-07-22 18:57:28', '2025-07-22 20:57:28', 45, 18, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(123, 60, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-07-26 18:57:28', '2025-07-26 20:57:28', 33, 14, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(124, 61, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-21 18:57:28', '2025-06-21 20:57:28', 42, 29, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(125, 61, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-05-28 18:57:28', '2025-05-28 20:57:28', 38, 10, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(126, 61, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-06-22 18:57:28', '2025-06-22 20:57:28', 22, 27, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(127, 62, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-07-03 18:57:28', '2025-07-03 20:57:28', 32, 18, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(128, 62, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-06-04 18:57:28', '2025-06-04 20:57:28', 38, 20, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(129, 62, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-07-08 18:57:28', '2025-07-08 20:57:28', 37, 27, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(130, 63, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-06-12 18:57:28', '2025-06-12 20:57:28', 36, 28, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(131, 63, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-06-25 18:57:28', '2025-06-25 20:57:28', 21, 23, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(132, 63, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-07-08 18:57:28', '2025-07-08 20:57:28', 45, 18, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(133, 64, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-07-22 18:57:28', '2025-07-22 20:57:28', 42, 20, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(134, 64, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-06-02 18:57:28', '2025-06-02 20:57:28', 27, 26, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(135, 64, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-05-28 18:57:28', '2025-05-28 20:57:28', 28, 27, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(136, 65, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-07-09 18:57:28', '2025-07-09 20:57:28', 43, 11, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(137, 66, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-26 18:57:28', '2025-06-26 20:57:28', 30, 12, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(138, 67, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-06-02 18:57:28', '2025-06-02 20:57:28', 20, 25, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(139, 67, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-07-07 18:57:28', '2025-07-07 20:57:28', 41, 21, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(140, 67, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-07-11 18:57:28', '2025-07-11 20:57:28', 17, 20, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(141, 68, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-07 18:57:28', '2025-06-07 20:57:28', 41, 19, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(142, 68, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-07-19 18:57:28', '2025-07-19 20:57:28', 31, 28, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(143, 69, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-07-21 18:57:28', '2025-07-21 20:57:28', 41, 14, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(144, 69, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-07-03 18:57:28', '2025-07-03 20:57:28', 43, 28, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(145, 70, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-06-14 18:57:28', '2025-06-14 20:57:28', 31, 29, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(146, 71, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-06-24 18:57:28', '2025-06-24 20:57:28', 36, 17, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(147, 71, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-07-04 18:57:28', '2025-07-04 20:57:28', 40, 10, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(148, 71, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-07-11 18:57:28', '2025-07-11 20:57:28', 32, 21, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(149, 72, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-07-04 18:57:28', '2025-07-04 20:57:28', 18, 20, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(150, 72, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-06-21 18:57:28', '2025-06-21 20:57:28', 41, 30, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(151, 72, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-06-11 18:57:28', '2025-06-11 20:57:28', 15, 24, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(152, 73, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-07-13 18:57:28', '2025-07-13 20:57:28', 21, 26, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(153, 74, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-07-18 18:57:28', '2025-07-18 20:57:28', 23, 23, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(154, 74, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-07-05 18:57:28', '2025-07-05 20:57:28', 50, 26, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(155, 75, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-07-24 18:57:28', '2025-07-24 20:57:28', 25, 16, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(156, 75, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-07-10 18:57:28', '2025-07-10 20:57:28', 33, 18, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(157, 75, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-07-07 18:57:28', '2025-07-07 20:57:28', 18, 23, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(158, 76, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-06-04 18:57:28', '2025-06-04 20:57:28', 20, 30, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(159, 76, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-07-17 18:57:28', '2025-07-17 20:57:28', 35, 11, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(160, 77, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-07-15 18:57:28', '2025-07-15 20:57:28', 16, 20, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(161, 77, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-07-04 18:57:28', '2025-07-04 20:57:28', 36, 28, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(162, 78, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-07-20 18:57:28', '2025-07-20 20:57:28', 41, 11, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(163, 78, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-07-17 18:57:28', '2025-07-17 20:57:28', 47, 13, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(164, 79, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-07-04 18:57:28', '2025-07-04 20:57:28', 42, 15, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(165, 80, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-12 18:57:28', '2025-06-12 20:57:28', 42, 22, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(166, 80, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-05-30 18:57:28', '2025-05-30 20:57:28', 26, 28, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(167, 81, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-06-06 18:57:28', '2025-06-06 20:57:28', 43, 19, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(168, 81, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-06-23 18:57:28', '2025-06-23 20:57:28', 24, 22, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(169, 81, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-07-20 18:57:28', '2025-07-20 20:57:28', 48, 23, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(170, 82, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-06-30 18:57:28', '2025-06-30 20:57:28', 22, 12, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(171, 82, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-07-08 18:57:28', '2025-07-08 20:57:28', 49, 16, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(172, 82, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-05 18:57:28', '2025-06-05 20:57:28', 48, 23, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(173, 83, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-28 18:57:28', '2025-06-28 20:57:28', 46, 27, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(174, 83, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-07-21 18:57:28', '2025-07-21 20:57:28', 50, 19, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(175, 83, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-21 18:57:28', '2025-06-21 20:57:28', 24, 12, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(176, 84, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-07-26 18:57:28', '2025-07-26 20:57:28', 30, 12, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(177, 84, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-06-27 18:57:28', '2025-06-27 20:57:28', 19, 29, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(178, 84, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-06-09 18:57:28', '2025-06-09 20:57:28', 23, 29, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(179, 85, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-06-13 18:57:28', '2025-06-13 20:57:28', 39, 22, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(180, 85, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-16 18:57:28', '2025-06-16 20:57:28', 15, 17, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(181, 86, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-05-30 18:57:28', '2025-05-30 20:57:28', 41, 29, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(182, 86, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-10 18:57:28', '2025-06-10 20:57:28', 16, 20, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(183, 86, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-06-27 18:57:28', '2025-06-27 20:57:28', 22, 13, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(184, 87, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-05-28 18:57:28', '2025-05-28 20:57:28', 37, 13, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(185, 87, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-06-29 18:57:28', '2025-06-29 20:57:28', 17, 12, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(186, 88, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-07-15 18:57:28', '2025-07-15 20:57:28', 32, 21, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(187, 88, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-21 18:57:28', '2025-06-21 20:57:28', 16, 28, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(188, 88, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-07-02 18:57:28', '2025-07-02 20:57:28', 19, 29, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(189, 89, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-06-04 18:57:28', '2025-06-04 20:57:28', 16, 12, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(190, 90, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-06-07 18:57:28', '2025-06-07 20:57:28', 44, 21, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(191, 90, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-06-30 18:57:28', '2025-06-30 20:57:28', 30, 19, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(192, 90, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-05-28 18:57:28', '2025-05-28 20:57:28', 32, 22, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(193, 91, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-06-19 18:57:28', '2025-06-19 20:57:28', 21, 23, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(194, 91, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-06-03 18:57:28', '2025-06-03 20:57:28', 44, 16, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(195, 91, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-07-24 18:57:28', '2025-07-24 20:57:28', 16, 25, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(196, 92, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-06-15 18:57:28', '2025-06-15 20:57:28', 19, 13, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(197, 92, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-06-27 18:57:28', '2025-06-27 20:57:28', 37, 17, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(198, 92, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-19 18:57:28', '2025-06-19 20:57:28', 26, 21, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(199, 93, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-07-14 18:57:28', '2025-07-14 20:57:28', 19, 24, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(200, 93, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-07-16 18:57:28', '2025-07-16 20:57:28', 17, 15, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(201, 94, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-07-02 18:57:28', '2025-07-02 20:57:28', 35, 24, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(202, 94, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-06-03 18:57:28', '2025-06-03 20:57:28', 17, 26, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(203, 94, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-06-11 18:57:28', '2025-06-11 20:57:28', 28, 16, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(204, 95, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-07-14 18:57:28', '2025-07-14 20:57:28', 48, 13, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(205, 96, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-05-29 18:57:28', '2025-05-29 20:57:28', 39, 29, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(206, 97, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-07-23 18:57:28', '2025-07-23 20:57:28', 28, 28, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(207, 97, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-07-12 18:57:28', '2025-07-12 20:57:28', 29, 27, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(208, 97, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-06-12 18:57:28', '2025-06-12 20:57:28', 31, 28, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(209, 98, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-06-06 18:57:28', '2025-06-06 20:57:28', 17, 16, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(210, 98, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-06-19 18:57:28', '2025-06-19 20:57:28', 21, 11, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(211, 98, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-06-04 18:57:28', '2025-06-04 20:57:28', 27, 12, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(212, 99, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-06-04 18:57:28', '2025-06-04 20:57:28', 15, 30, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(213, 99, 'Team Meeting', 'Important event scheduled for personal or professional development.', '2025-06-22 18:57:28', '2025-06-22 20:57:28', 38, 18, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(214, 100, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-06-27 18:57:28', '2025-06-27 20:57:28', 18, 19, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(215, 101, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-06-12 18:57:28', '2025-06-12 20:57:28', 29, 19, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(216, 102, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-06-29 18:57:28', '2025-06-29 20:57:28', 24, 14, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(217, 103, 'Health Checkup', 'Important event scheduled for personal or professional development.', '2025-07-07 18:57:28', '2025-07-07 20:57:28', 50, 19, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(218, 104, 'Social Meetup', 'Important event scheduled for personal or professional development.', '2025-07-24 18:57:28', '2025-07-24 20:57:28', 31, 23, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(219, 104, 'Skill Practice Session', 'Important event scheduled for personal or professional development.', '2025-07-22 18:57:28', '2025-07-22 20:57:28', 49, 21, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(220, 105, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-06-13 18:57:28', '2025-06-13 20:57:28', 45, 28, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(221, 106, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-06-01 18:57:28', '2025-06-01 20:57:28', 49, 12, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(222, 106, 'Personal Goal Review', 'Important event scheduled for personal or professional development.', '2025-07-20 18:57:28', '2025-07-20 20:57:28', 27, 15, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28'),
(223, 106, 'Learning Workshop', 'Important event scheduled for personal or professional development.', '2025-06-26 18:57:28', '2025-06-26 20:57:28', 28, 26, 'active', '2025-05-28 02:57:28', '2025-05-28 02:57:28');

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
-- Dumping data for table `user_event_completions`
--

INSERT INTO `user_event_completions` (`id`, `user_id`, `taskevent_id`, `completed_at`) VALUES
(2, 3, 1, '2025-05-16 19:54:57'),
(3, 3, 1, '2025-05-16 20:06:01'),
(4, 3, 1, '2025-05-16 20:12:30'),
(5, 1, 1, '2025-05-17 04:42:29'),
(6, 4, 1, '2025-05-17 10:05:25'),
(7, 3, 71, '2025-05-28 05:58:05'),
(8, 108, 222, '2025-05-28 14:14:20');

--
-- Triggers `user_event_completions`
--
DELIMITER $$
CREATE TRIGGER `after_event_completion_log` AFTER INSERT ON `user_event_completions` FOR EACH ROW BEGIN
    -- Get event details from user_event table
    DECLARE event_name_val VARCHAR(255);
    DECLARE event_desc_val TEXT;
    DECLARE reward_xp_val INT;
    DECLARE reward_coins_val INT;
    
    SELECT event_name, event_description, reward_xp, reward_coins 
    INTO event_name_val, event_desc_val, reward_xp_val, reward_coins_val
    FROM user_event 
    WHERE id = NEW.taskevent_id;
    
    -- Insert into activity log
    INSERT INTO activity_log (user_id, activity_type, activity_details, log_timestamp)
    VALUES (
        NEW.user_id,
        'Event Completed',
        JSON_OBJECT(
            'event_id', NEW.taskevent_id,
            'event_name', event_name_val,
            'event_description', event_desc_val,
            'reward_xp', reward_xp_val,
            'reward_coins', reward_coins_val,
            'completed_at', NEW.completed_at
        ),
        NEW.completed_at
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
(1, 1, 1, 5, '2025-05-25 09:30:36'),
(2, 1, 2, 1, '2025-05-25 09:30:36'),
(3, 1, 5, 2, '2025-05-25 09:30:36'),
(4, 1, 6, 1, '2025-05-25 09:30:36'),
(5, 1, 7, 1, '2025-05-25 09:30:36'),
(6, 1, 3, 1, '2025-05-25 09:30:36'),
(10, 1, 9, 3, '2025-05-25 09:30:36'),
(11, 3, 9, 1, '2025-05-25 09:30:36'),
(15, 1, 10, 1, '2025-05-25 09:30:36'),
(18, 1, 12, 1, '2025-05-25 09:30:36'),
(30, 3, 1, 1, '2025-05-25 11:11:14'),
(33, 1, 4, 3, '2025-05-26 01:44:47'),
(34, 3, 11, 3, '2025-05-28 02:57:27'),
(35, 8, 10, 2, '2025-05-28 02:57:27'),
(36, 9, 10, 5, '2025-05-28 02:57:27'),
(37, 9, 5, 2, '2025-05-28 02:57:27'),
(38, 11, 10, 1, '2025-05-28 02:57:27'),
(39, 11, 5, 1, '2025-05-28 02:57:27'),
(40, 11, 9, 1, '2025-05-28 02:57:27'),
(41, 15, 7, 3, '2025-05-28 02:57:27'),
(42, 15, 2, 2, '2025-05-28 02:57:27'),
(43, 15, 3, 2, '2025-05-28 02:57:27'),
(44, 16, 13, 2, '2025-05-28 02:57:27'),
(45, 16, 3, 5, '2025-05-28 02:57:27'),
(46, 16, 8, 3, '2025-05-28 02:57:27'),
(47, 17, 12, 1, '2025-05-28 02:57:27'),
(48, 28, 9, 5, '2025-05-28 02:57:27'),
(49, 28, 1, 1, '2025-05-28 02:57:27'),
(50, 28, 4, 2, '2025-05-28 02:57:27'),
(51, 29, 13, 5, '2025-05-28 02:57:27'),
(52, 29, 6, 1, '2025-05-28 02:57:27'),
(53, 29, 1, 2, '2025-05-28 02:57:27'),
(54, 33, 12, 3, '2025-05-28 02:57:27'),
(55, 35, 7, 5, '2025-05-28 02:57:27'),
(56, 38, 11, 2, '2025-05-28 02:57:27'),
(57, 38, 7, 5, '2025-05-28 02:57:27'),
(58, 38, 12, 5, '2025-05-28 02:57:27'),
(59, 39, 13, 3, '2025-05-28 02:57:27'),
(60, 41, 11, 1, '2025-05-28 02:57:27'),
(61, 41, 12, 5, '2025-05-28 02:57:27'),
(62, 41, 10, 3, '2025-05-28 02:57:27'),
(63, 43, 3, 4, '2025-05-28 02:57:27'),
(64, 43, 11, 4, '2025-05-28 02:57:27'),
(65, 43, 7, 5, '2025-05-28 02:57:27'),
(66, 44, 7, 1, '2025-05-28 02:57:28'),
(67, 44, 9, 2, '2025-05-28 02:57:28'),
(68, 44, 2, 3, '2025-05-28 02:57:28'),
(69, 47, 2, 4, '2025-05-28 02:57:28'),
(70, 53, 2, 1, '2025-05-28 02:57:28'),
(71, 58, 11, 2, '2025-05-28 02:57:28'),
(72, 58, 3, 4, '2025-05-28 02:57:28'),
(73, 60, 11, 2, '2025-05-28 02:57:28'),
(74, 61, 12, 1, '2025-05-28 02:57:28'),
(75, 70, 10, 5, '2025-05-28 02:57:28'),
(76, 72, 14, 5, '2025-05-28 02:57:28'),
(77, 72, 3, 1, '2025-05-28 02:57:28'),
(78, 72, 11, 3, '2025-05-28 02:57:28'),
(79, 73, 2, 1, '2025-05-28 02:57:28'),
(80, 73, 13, 4, '2025-05-28 02:57:28'),
(81, 79, 1, 3, '2025-05-28 02:57:28'),
(82, 79, 8, 3, '2025-05-28 02:57:28'),
(83, 81, 10, 4, '2025-05-28 02:57:28'),
(84, 81, 6, 5, '2025-05-28 02:57:28'),
(85, 81, 3, 4, '2025-05-28 02:57:28'),
(86, 85, 9, 5, '2025-05-28 02:57:28'),
(87, 91, 8, 2, '2025-05-28 02:57:28'),
(88, 91, 11, 4, '2025-05-28 02:57:28'),
(89, 97, 5, 5, '2025-05-28 02:57:28'),
(90, 97, 3, 1, '2025-05-28 02:57:28'),
(91, 98, 7, 1, '2025-05-28 02:57:28'),
(92, 98, 13, 4, '2025-05-28 02:57:28'),
(93, 100, 13, 2, '2025-05-28 02:57:28'),
(94, 100, 3, 5, '2025-05-28 02:57:28'),
(95, 100, 11, 3, '2025-05-28 02:57:28'),
(96, 104, 13, 5, '2025-05-28 02:57:28'),
(97, 104, 14, 5, '2025-05-28 02:57:28'),
(98, 105, 6, 3, '2025-05-28 02:57:28');

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
    JSON_OBJECT(
      'item_id',
      NEW.item_id,
      'item_name',
      item_name_var
    )
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
  ADD KEY `idx_activity_time` (`log_timestamp`),
  ADD KEY `idx_activity_user_time` (`user_id`,`log_timestamp`);

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
  ADD KEY `fk_inventory_item` (`item_id`),
  ADD KEY `idx_inventory_user_item` (`user_id`,`item_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `activity_log`
--
ALTER TABLE `activity_log`
  MODIFY `log_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=24;

--
-- AUTO_INCREMENT for table `avatars`
--
ALTER TABLE `avatars`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `badhabits`
--
ALTER TABLE `badhabits`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `dailytasks`
--
ALTER TABLE `dailytasks`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=237;

--
-- AUTO_INCREMENT for table `goodhabits`
--
ALTER TABLE `goodhabits`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=368;

--
-- AUTO_INCREMENT for table `item_categories`
--
ALTER TABLE `item_categories`
  MODIFY `category_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `item_usage_history`
--
ALTER TABLE `item_usage_history`
  MODIFY `usage_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=116;

--
-- AUTO_INCREMENT for table `journals`
--
ALTER TABLE `journals`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=308;

--
-- AUTO_INCREMENT for table `marketplace_items`
--
ALTER TABLE `marketplace_items`
  MODIFY `item_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT for table `streaks`
--
ALTER TABLE `streaks`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=541;

--
-- AUTO_INCREMENT for table `tasks`
--
ALTER TABLE `tasks`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `test_data`
--
ALTER TABLE `test_data`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=109;

--
-- AUTO_INCREMENT for table `userstats`
--
ALTER TABLE `userstats`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=110;

--
-- AUTO_INCREMENT for table `user_active_boosts`
--
ALTER TABLE `user_active_boosts`
  MODIFY `boost_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `user_event`
--
ALTER TABLE `user_event`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=224;

--
-- AUTO_INCREMENT for table `user_event_completions`
--
ALTER TABLE `user_event_completions`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `user_inventory`
--
ALTER TABLE `user_inventory`
  MODIFY `inventory_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=101;

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

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
