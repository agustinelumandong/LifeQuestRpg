-- Create badhabits table
CREATE TABLE `badhabits` (
  `id` int NOT NULL AUTO_INCREMENT,
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
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_badhabits_user` (`user_id`),
  CONSTRAINT `fk_badhabits_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;