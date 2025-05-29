-- Create userstats table
CREATE TABLE `userstats` (
  `id` int NOT NULL AUTO_INCREMENT,
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
  `passionHobbies` int DEFAULT '5',
  PRIMARY KEY (`id`),
  KEY `fk_userstats_user` (`user_id`),
  KEY `fk_userstats_avatar` (`avatar_id`),
  CONSTRAINT `fk_userstats_avatar` FOREIGN KEY (`avatar_id`) REFERENCES `avatars` (`id`),
  CONSTRAINT `fk_userstats_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;