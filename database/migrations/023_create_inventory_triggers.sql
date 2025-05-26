-- Create inventory and event completion triggers
DELIMITER $$ -- Trigger for inventory item purchases
CREATE TRIGGER `after_inventory_insert`
AFTER
INSERT ON `user_inventory` FOR EACH ROW BEGIN
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
END $$ -- Trigger for event completion logging
CREATE TRIGGER `after_event_completion_log`
AFTER
INSERT ON `user_event_completions` FOR EACH ROW BEGIN -- Get event details from user_event table
DECLARE event_name_val VARCHAR(255);
DECLARE event_desc_val TEXT;
DECLARE reward_xp_val INT;
DECLARE reward_coins_val INT;
SELECT event_name,
  event_description,
  reward_xp,
  reward_coins INTO event_name_val,
  event_desc_val,
  reward_xp_val,
  reward_coins_val
FROM user_event
WHERE id = NEW.taskevent_id;
-- Insert into activity log
INSERT INTO activity_log (
    user_id,
    activity_type,
    activity_details,
    log_timestamp
  )
VALUES (
    NEW.user_id,
    'Event Completed',
    JSON_OBJECT(
      'event_id',
      NEW.taskevent_id,
      'event_name',
      event_name_val,
      'event_description',
      event_desc_val,
      'reward_xp',
      reward_xp_val,
      'reward_coins',
      reward_coins_val,
      'completed_at',
      NEW.completed_at
    ),
    NEW.completed_at
  );
END $$ DELIMITER;