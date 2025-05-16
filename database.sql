-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Apr 29, 2025 at 04:30 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `mvc`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `PurchaseMarketplaceItem` (IN `p_user_id` INT, IN `p_item_id` INT)   proc: BEGIN
  DECLARE v_item_price DECIMAL(10, 2);
  DECLARE v_user_coins INT;
  
  DECLARE EXIT HANDLER FOR SQLEXCEPTION 
  BEGIN 
    ROLLBACK;
    SELECT 'Transaction failed' AS message;
  END;
  
  START TRANSACTION;
  
  -- Validate item existence
  IF NOT EXISTS (
    SELECT 1
    FROM `marketplace_items`
    WHERE `item_id` = p_item_id
  ) THEN 
    ROLLBACK;
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
  IF v_user_coins < v_item_price THEN 
    ROLLBACK;
    SELECT 'Insufficient coins' AS message;
    LEAVE proc;
  END IF;
  
  -- Check existing ownership
  IF EXISTS (
    SELECT 1
    FROM `user_inventory`
    WHERE `user_id` = p_user_id
      AND `item_id` = p_item_id
  ) THEN 
    ROLLBACK;
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
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `activity_log`
--

CREATE TABLE `activity_log` (
  `log_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `activity_type` varchar(50) NOT NULL,
  `activity_details` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`activity_details`)),
  `log_timestamp` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `activity_log`
--

INSERT INTO `activity_log` (`log_id`, `user_id`, `activity_type`, `activity_details`, `log_timestamp`) VALUES
(4, 6, 'Task Completed', '{\"task_id\": 1, \"title\": \"Cardio\", \"difficulty\": \"medium\", \"category\": \"Physical Health\", \"coins\": 10, \"xp\": 20}', '2025-04-28 03:14:03'),
(5, 6, 'Task Completed', '{\"task_id\": 1, \"title\": \"take a bath\", \"difficulty\": \"easy\", \"category\": \"Physical Health\", \"coins\": 5, \"xp\": 10}', '2025-04-28 04:40:41'),
(6, 6, 'Daily Task Completed', '{\"task_id\": 2, \"title\": \"sleep\", \"difficulty\": \"easy\", \"category\": \"Personal Growth\", \"coins\": 5, \"xp\": 10}', '2025-04-28 04:47:21'),
(7, 6, 'Daily Task Completed', '{\"task_id\": 3, \"title\": \"l\", \"difficulty\": \"easy\", \"category\": \"Physical Health\", \"coins\": 5, \"xp\": 10}', '2025-04-28 05:06:46'),
(8, 6, 'Task Completed', '{\"task_id\": 2, \"title\": \"asd\", \"difficulty\": \"easy\", \"category\": \"Physical Health\", \"coins\": 5, \"xp\": 10}', '2025-04-28 05:20:14'),
(9, 6, 'Task Completed', '{\"task_id\": 3, \"title\": \"wash dishes\", \"difficulty\": \"easy\", \"category\": \"Home Environment\", \"coins\": 5, \"xp\": 10}', '2025-04-28 05:36:40'),
(10, 6, 'Habit Logged', '{\"task_id\": 1, \"title\": \"signal \", \"difficulty\": \"easy\", \"category\": \"Physical Health\", \"coins\": 5, \"xp\": 10}', '2025-04-28 09:40:12'),
(11, 6, 'Bad Habit Logged', '{\"task_id\": 1, \"title\": \"Play\", \"difficulty\": \"medium\", \"category\": \"Mental Wellness\", \"coins\": 0, \"xp\": 0}', '2025-04-28 21:11:00'),
(12, 6, 'Bad Habit Logged', '{\"task_id\": 1, \"title\": \"Play\", \"difficulty\": \"medium\", \"category\": \"Mental Wellness\", \"coins\": 0, \"xp\": 0}', '2025-04-28 21:14:21'),
(13, 6, 'Bad Habit Logged', '{\"task_id\": 1, \"title\": \"Play\", \"difficulty\": \"medium\", \"category\": \"Mental Wellness\", \"coins\": 0, \"xp\": 0}', '2025-04-28 21:14:44'),
(14, 6, 'Bad Habit Logged', '{\"task_id\": 1, \"title\": \"Play\", \"difficulty\": \"medium\", \"category\": \"Mental Wellness\", \"coins\": 0, \"xp\": 0}', '2025-04-28 21:15:48'),
(15, 6, 'Bad Habit Logged', '{\"task_id\": 1, \"title\": \"Play\", \"difficulty\": \"medium\", \"category\": \"Mental Wellness\", \"coins\": 0, \"xp\": 0}', '2025-04-28 21:21:40'),
(16, 6, 'Bad Habit Logged', '{\"task_id\": 1, \"title\": \"Play\", \"difficulty\": \"medium\", \"category\": \"Mental Wellness\", \"coins\": 0, \"xp\": 0}', '2025-04-28 21:28:52'),
(17, 6, 'Habit Logged', '{\"task_id\": 1, \"title\": \"signal \", \"difficulty\": \"easy\", \"category\": \"Physical Health\", \"coins\": 5, \"xp\": 10}', '2025-04-28 21:41:44'),
(18, 6, 'Good Habit Logged', '{\"task_id\": 1, \"title\": \"signal \", \"difficulty\": \"easy\", \"category\": \"Physical Health\", \"coins\": 5, \"xp\": 10}', '2025-04-28 21:41:44'),
(19, 6, 'Daily Task Completed', '{\"task_id\": 1, \"title\": \"take a bath\", \"difficulty\": \"easy\", \"category\": \"Physical Health\", \"coins\": 5, \"xp\": 10}', '2025-04-28 23:59:58'),
(20, 6, 'Bad Habit Logged', '{\"task_id\": 1, \"title\": \"Play\", \"difficulty\": \"medium\", \"category\": \"Mental Wellness\", \"coins\": 0, \"xp\": 0}', '2025-04-29 00:07:25');

-- --------------------------------------------------------

--
-- Table structure for table `badhabits`
--

CREATE TABLE `badhabits` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `status` enum('pending','completed') NOT NULL DEFAULT 'pending',
  `difficulty` enum('easy','medium','hard') NOT NULL,
  `category` enum('Physical Health','Mental Wellness','Personal Growth','Career / Studies','Finance','Home Environment','Relationships Social','Passion Hobbies') NOT NULL,
  `coins` int(11) NOT NULL,
  `xp` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `badhabits`
--

INSERT INTO `badhabits` (`id`, `user_id`, `title`, `status`, `difficulty`, `category`, `coins`, `xp`) VALUES
(1, 6, 'Play', 'completed', 'medium', 'Mental Wellness', 0, 0);

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
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `status` enum('pending','completed') DEFAULT 'pending',
  `difficulty` enum('easy','medium','hard') NOT NULL,
  `category` enum('Physical Health','Mental Wellness','Personal Growth','Career / Studies','Finance','Home Environment','Relationships Social','Passion Hobbies') NOT NULL,
  `coins` int(11) DEFAULT 0,
  `xp` int(11) DEFAULT 0,
  `last_reset` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `dailytasks`
--

INSERT INTO `dailytasks` (`id`, `user_id`, `title`, `status`, `difficulty`, `category`, `coins`, `xp`, `last_reset`) VALUES
(1, 6, 'take a bath', 'completed', 'easy', 'Physical Health', 5, 10, '2025-04-28 23:59:54'),
(2, 6, 'sleep', 'pending', 'easy', 'Personal Growth', 5, 10, '2025-04-28 23:59:54'),
(3, 6, 'l', 'pending', 'easy', 'Physical Health', 5, 10, '2025-04-28 23:59:54');

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
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `difficulty` enum('easy','medium','hard') NOT NULL,
  `category` enum('Physical Health','Mental Wellness','Personal Growth','Career / Studies','Finance','Home Environment','Relationships Social','Passion Hobbies') NOT NULL,
  `status` enum('pending','completed') NOT NULL DEFAULT 'pending',
  `coins` int(11) DEFAULT 0,
  `xp` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `goodhabits`
--

INSERT INTO `goodhabits` (`id`, `user_id`, `title`, `difficulty`, `category`, `status`, `coins`, `xp`) VALUES
(1, 6, 'signal ', 'easy', 'Physical Health', 'completed', 5, 10);

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
DELIMITER $$
CREATE TRIGGER `after_goodhabits_completion` AFTER UPDATE ON `goodhabits` FOR EACH ROW BEGIN
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        INSERT INTO activity_log (
            user_id,
            activity_type,
            activity_details,
            log_timestamp
        )
        VALUES (
            NEW.user_id,
            'Habit Logged',
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
-- Table structure for table `marketplace_items`
--

CREATE TABLE `marketplace_items` (
  `item_id` int(11) NOT NULL,
  `item_name` varchar(255) NOT NULL,
  `item_description` text DEFAULT NULL,
  `item_price` decimal(10,2) NOT NULL,
  `image_url` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `streaks`
--

CREATE TABLE `streaks` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `streak_type` enum('check_in','task_completion') NOT NULL,
  `current_streak` int(11) NOT NULL DEFAULT 0,
  `longest_streak` int(11) NOT NULL DEFAULT 0,
  `last_streak_date` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `tasks`
--

CREATE TABLE `tasks` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `status` enum('pending','completed') DEFAULT 'pending',
  `difficulty` enum('easy','medium','hard') DEFAULT 'easy',
  `category` enum('Physical Health','Mental Wellness','Personal Growth','Career / Studies','Finance','Home Environment','Relationships Social','Passion Hobbies') NOT NULL,
  `coins` int(11) DEFAULT 0,
  `xp` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `tasks`
--

INSERT INTO `tasks` (`id`, `user_id`, `title`, `status`, `difficulty`, `category`, `coins`, `xp`) VALUES
(1, 6, 'Cardio a', 'completed', 'medium', 'Physical Health', 10, 20),
(2, 6, 'asd', 'completed', 'easy', 'Physical Health', 5, 10),
(3, 6, 'wash dishes', 'completed', 'easy', 'Home Environment', 5, 10);

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
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `role` enum('admin','user') DEFAULT 'user',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `coins` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `email`, `password`, `name`, `role`, `created_at`, `updated_at`, `coins`) VALUES
(1, 'marvin@test.com', '$2y$10$lsVLw4lN4/AySO9Cz8lKrOLLje2Kt3P9WejHsUhXl9MqJpVWgAhEK', 'Marvin', 'user', '2025-04-27 16:19:10', '2025-04-27 16:19:10', 0),
(3, 'sean@test.com', '$2y$10$AWBTVQjxQ9Lm8Ds/3bRKbeGklavES6PmY/wtW3lvKoCFK1rEl.dri', 'sean', 'user', '2025-04-27 16:32:25', '2025-04-27 16:32:25', 0),
(4, 'inuyasha@test.com', '$2y$10$AjopOMvLtuUCH03I0ENJlOAOB3pwQt/QR3nBPw7DxXiZmc.uw7FBu', 'Inuyasha', 'user', '2025-04-27 16:52:07', '2025-04-27 16:52:07', 0),
(5, 'pacia@gmail.com', '$2y$10$pCS0hz.i17SXB9ESASIx4uppJyxrxmrwEHcZuZZhpNRpFrSGi1gNy', 'pacia', 'user', '2025-04-27 16:54:29', '2025-04-27 16:54:29', 0),
(6, 'kenth@gmail.com', '$2y$10$JfIE0jznFZKRESp62XwMquOu/yX8iTyuK18Hq8ku0Otdx/W.NDPCe', 'kenth', 'user', '2025-04-27 16:55:19', '2025-04-28 23:59:58', 25),
(7, 'qwerty@test.com', '$2y$10$542cXT5fb8Dqhknce9exD.pqyl02U/8NBXbVB5TexctBypBet8pJ6', 'qwerty', 'user', '2025-04-28 11:24:53', '2025-04-28 11:24:53', 0);

-- --------------------------------------------------------

--
-- Table structure for table `userstats`
--

CREATE TABLE `userstats` (
  `id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `level` int(11) NOT NULL,
  `xp` int(11) NOT NULL,
  `health` int(11) DEFAULT 3,
  `physicalHealth` int(11) DEFAULT 5,
  `mentalWellness` int(11) DEFAULT 5,
  `personalGrowth` int(11) DEFAULT 5,
  `careerStudies` int(11) DEFAULT 5,
  `finance` int(11) DEFAULT 5,
  `homeEnvironment` int(11) DEFAULT 5,
  `relationshipsSocial` int(11) DEFAULT 5,
  `passionHobbies` int(11) DEFAULT 5
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `userstats`
--

INSERT INTO `userstats` (`id`, `user_id`, `level`, `xp`, `health`, `physicalHealth`, `mentalWellness`, `personalGrowth`, `careerStudies`, `finance`, `homeEnvironment`, `relationshipsSocial`, `passionHobbies`) VALUES
(1, 6, 2, 40, 60, 16, 5, 6, 5, 7, 6, 5, 5),
(2, 7, 1, 0, 100, 5, 5, 5, 5, 5, 5, 5, 5);

-- --------------------------------------------------------

--
-- Table structure for table `user_event`
--

CREATE TABLE `user_event` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `event_name` varchar(255) NOT NULL,
  `event_description` text NOT NULL,
  `start_date` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `end_date` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `reward_xp` int(11) NOT NULL DEFAULT 0,
  `reward_coins` int(11) NOT NULL DEFAULT 0,
  `status` enum('active','inactive') DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `user_event_completions`
--

CREATE TABLE `user_event_completions` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `event_name` varchar(255) NOT NULL,
  `completed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `user_inventory`
--

CREATE TABLE `user_inventory` (
  `inventory_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `item_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
-- Stand-in structure for view `view_bad_habits_activity`
-- (See below for the actual view)
--
CREATE TABLE `view_bad_habits_activity` (
`log_id` int(11)
,`user_id` int(11)
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
`log_id` int(11)
,`user_id` int(11)
,`task_title` longtext
,`difficulty` longtext
,`category` longtext
,`coins` longtext
,`xp` longtext
,`log_timestamp` timestamp
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `view_good_habits_activity`
-- (See below for the actual view)
--
CREATE TABLE `view_good_habits_activity` (
`log_id` int(11)
,`user_id` int(11)
,`activity_title` longtext
,`difficulty` longtext
,`category` longtext
,`coins` longtext
,`xp` longtext
,`log_timestamp` timestamp
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `view_task_activity`
-- (See below for the actual view)
--
CREATE TABLE `view_task_activity` (
`log_id` int(11)
,`user_id` int(11)
,`task_title` longtext
,`difficulty` longtext
,`category` longtext
,`coins` longtext
,`xp` longtext
,`log_timestamp` timestamp
);

-- --------------------------------------------------------

--
-- Structure for view `view_bad_habits_activity`
--
DROP TABLE IF EXISTS `view_bad_habits_activity`;

CREATE ALGORITHM=UNDEFINED DEFINER=`` SQL SECURITY DEFINER VIEW `view_bad_habits_activity`  AS SELECT `a`.`log_id` AS `log_id`, `a`.`user_id` AS `user_id`, json_unquote(json_extract(`a`.`activity_details`,'$.title')) AS `activity_title`, json_unquote(json_extract(`a`.`activity_details`,'$.difficulty')) AS `difficulty`, json_unquote(json_extract(`a`.`activity_details`,'$.category')) AS `category`, json_unquote(json_extract(`a`.`activity_details`,'$.coins')) AS `coins`, json_unquote(json_extract(`a`.`activity_details`,'$.xp')) AS `xp`, `a`.`log_timestamp` AS `log_timestamp` FROM (`activity_log` `a` join `users` `u` on(`a`.`user_id` = `u`.`id`)) WHERE `a`.`activity_type` = 'Bad Habit Logged' ;

-- --------------------------------------------------------

--
-- Structure for view `view_daily_task_activity`
--
DROP TABLE IF EXISTS `view_daily_task_activity`;

CREATE ALGORITHM=UNDEFINED DEFINER=`` SQL SECURITY DEFINER VIEW `view_daily_task_activity`  AS SELECT `a`.`log_id` AS `log_id`, `a`.`user_id` AS `user_id`, json_unquote(json_extract(`a`.`activity_details`,'$.title')) AS `task_title`, json_unquote(json_extract(`a`.`activity_details`,'$.difficulty')) AS `difficulty`, json_unquote(json_extract(`a`.`activity_details`,'$.category')) AS `category`, json_unquote(json_extract(`a`.`activity_details`,'$.coins')) AS `coins`, json_unquote(json_extract(`a`.`activity_details`,'$.xp')) AS `xp`, `a`.`log_timestamp` AS `log_timestamp` FROM (`activity_log` `a` join `users` `u` on(`a`.`user_id` = `u`.`id`)) WHERE `a`.`activity_type` = 'Daily Task Completed' ;

-- --------------------------------------------------------

--
-- Structure for view `view_good_habits_activity`
--
DROP TABLE IF EXISTS `view_good_habits_activity`;

CREATE ALGORITHM=UNDEFINED DEFINER=`` SQL SECURITY DEFINER VIEW `view_good_habits_activity`  AS SELECT `a`.`log_id` AS `log_id`, `a`.`user_id` AS `user_id`, json_unquote(json_extract(`a`.`activity_details`,'$.title')) AS `activity_title`, json_unquote(json_extract(`a`.`activity_details`,'$.difficulty')) AS `difficulty`, json_unquote(json_extract(`a`.`activity_details`,'$.category')) AS `category`, json_unquote(json_extract(`a`.`activity_details`,'$.coins')) AS `coins`, json_unquote(json_extract(`a`.`activity_details`,'$.xp')) AS `xp`, `a`.`log_timestamp` AS `log_timestamp` FROM (`activity_log` `a` join `users` `u` on(`a`.`user_id` = `u`.`id`)) WHERE `a`.`activity_type` = 'Good Habit Logged' ;

-- --------------------------------------------------------

--
-- Structure for view `view_task_activity`
--
DROP TABLE IF EXISTS `view_task_activity`;

CREATE ALGORITHM=UNDEFINED DEFINER=`` SQL SECURITY DEFINER VIEW `view_task_activity`  AS SELECT `a`.`log_id` AS `log_id`, `a`.`user_id` AS `user_id`, json_unquote(json_extract(`a`.`activity_details`,'$.title')) AS `task_title`, json_unquote(json_extract(`a`.`activity_details`,'$.difficulty')) AS `difficulty`, json_unquote(json_extract(`a`.`activity_details`,'$.category')) AS `category`, json_unquote(json_extract(`a`.`activity_details`,'$.coins')) AS `coins`, json_unquote(json_extract(`a`.`activity_details`,'$.xp')) AS `xp`, `a`.`log_timestamp` AS `log_timestamp` FROM (`activity_log` `a` join `users` `u` on(`a`.`user_id` = `u`.`id`)) WHERE `a`.`activity_type` = 'Task Completed' ;

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
-- Indexes for table `badhabits`
--
ALTER TABLE `badhabits`
  ADD PRIMARY KEY (`id`);

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
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `marketplace_items`
--
ALTER TABLE `marketplace_items`
  ADD PRIMARY KEY (`item_id`);

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
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indexes for table `userstats`
--
ALTER TABLE `userstats`
  ADD PRIMARY KEY (`id`);

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
  ADD KEY `fk_user_event_completions_user` (`user_id`);

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
  MODIFY `log_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- AUTO_INCREMENT for table `badhabits`
--
ALTER TABLE `badhabits`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `dailytasks`
--
ALTER TABLE `dailytasks`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `goodhabits`
--
ALTER TABLE `goodhabits`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `marketplace_items`
--
ALTER TABLE `marketplace_items`
  MODIFY `item_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `streaks`
--
ALTER TABLE `streaks`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tasks`
--
ALTER TABLE `tasks`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `userstats`
--
ALTER TABLE `userstats`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `user_event`
--
ALTER TABLE `user_event`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `user_event_completions`
--
ALTER TABLE `user_event_completions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `user_inventory`
--
ALTER TABLE `user_inventory`
  MODIFY `inventory_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `activity_log`
--
ALTER TABLE `activity_log`
  ADD CONSTRAINT `fk_log_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `dailytasks`
--
ALTER TABLE `dailytasks`
  ADD CONSTRAINT `fk_dailytasks_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

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
-- Constraints for table `user_event`
--
ALTER TABLE `user_event`
  ADD CONSTRAINT `fk_user_event_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_event_completions`
--
ALTER TABLE `user_event_completions`
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


CREATE TABLE `journals` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `content` longtext NOT NULL,
  `date` date NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `fk_journals_user` (`user_id`),
  CONSTRAINT `fk_journals_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;