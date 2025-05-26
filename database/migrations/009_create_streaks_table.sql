-- Create streaks table
CREATE TABLE `streaks` (
  `id` int NOT NULL AUTO_INCREMENT,
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
  `next_expected_date` date DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_streaks_user` (`user_id`),
  CONSTRAINT `fk_streaks_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;