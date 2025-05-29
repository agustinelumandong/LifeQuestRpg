-- Create tasks table
CREATE TABLE `tasks` (
  `id` int NOT NULL AUTO_INCREMENT,
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
  `xp` int DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `fk_tasks_user` (`user_id`),
  CONSTRAINT `fk_tasks_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;