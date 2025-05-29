-- Create database triggers for activity logging
DELIMITER $$ -- Trigger for task completion
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
      'xp',
      NEW.xp,
      'coins',
      NEW.coins
    ),
    NOW()
  );
END IF;
END $$ -- Trigger for daily task completion
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
      'xp',
      NEW.xp,
      'coins',
      NEW.coins
    ),
    NOW()
  );
END IF;
END $$ -- Trigger for good habits completion
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
    'Good Habit Completed',
    JSON_OBJECT(
      'habit_id',
      NEW.id,
      'title',
      NEW.title,
      'difficulty',
      NEW.difficulty,
      'category',
      NEW.category,
      'xp',
      NEW.xp,
      'coins',
      NEW.coins
    ),
    NOW()
  );
END IF;
END $$ -- Trigger for bad habits completion
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
    'Bad Habit Avoided',
    JSON_OBJECT(
      'habit_id',
      NEW.id,
      'title',
      NEW.title,
      'difficulty',
      NEW.difficulty,
      'category',
      NEW.category,
      'xp',
      NEW.xp,
      'coins',
      NEW.coins
    ),
    NOW()
  );
END IF;
END $$ DELIMITER;