-- Create user_event_completions table
CREATE TABLE `user_event_completions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `taskevent_id` int NOT NULL,
  `completed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_user_event_completions_user` (`user_id`),
  KEY `fk_user_event_completions_id` (`taskevent_id`),
  CONSTRAINT `fk_user_event_completions_id` FOREIGN KEY (`taskevent_id`) REFERENCES `user_event` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_user_event_completions_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;