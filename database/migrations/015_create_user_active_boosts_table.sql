-- Create user_active_boosts table
CREATE TABLE `user_active_boosts` (
  `boost_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `boost_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `boost_value` int NOT NULL,
  `activated_at` datetime NOT NULL,
  `expires_at` datetime NOT NULL,
  PRIMARY KEY (`boost_id`),
  KEY `idx_user_boosts` (`user_id`),
  CONSTRAINT `fk_boost_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;