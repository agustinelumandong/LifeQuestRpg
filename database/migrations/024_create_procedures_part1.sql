-- Create stored procedures
DELIMITER $$ -- Procedure for logging pokes
CREATE DEFINER = `root` @`localhost` PROCEDURE `log_poke` (
  IN `target_user_id` INT,
  IN `poker_user_id` INT,
  IN `poker_username` VARCHAR(255)
) BEGIN
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
      'poker_id',
      poker_user_id,
      'poker_name',
      poker_username
    ),
    NOW()
  );
SELECT ROW_COUNT() AS success;
END $$ -- Procedure for purchasing marketplace items
CREATE DEFINER = `root` @`localhost` PROCEDURE `PurchaseMarketplaceItem` (IN `p_user_id` INT, IN `p_item_id` INT) proc: BEGIN
DECLARE v_item_price DECIMAL(10, 2);
DECLARE v_user_coins INT;
DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK;
SELECT 'Transaction failed' AS message;
END;
START TRANSACTION;
-- Validate item existence
IF NOT EXISTS(
  SELECT 1
  FROM `marketplace_items`
  WHERE `item_id` = p_item_id
) THEN
SELECT 'Item not found' AS message;
ROLLBACK;
LEAVE proc;
END IF;
-- Get pricing info
SELECT `item_price` INTO v_item_price
FROM `marketplace_items`
WHERE `item_id` = p_item_id;
-- Check user balance
SELECT `coins` INTO v_user_coins
FROM `users`
WHERE `id` = p_user_id;
-- Validate funds
IF v_user_coins < v_item_price THEN
SELECT 'Insufficient coins' AS message;
ROLLBACK;
LEAVE proc;
END IF;
-- Check existing ownership
IF EXISTS(
  SELECT 1
  FROM `user_inventory`
  WHERE `user_id` = p_user_id
    AND `item_id` = p_item_id
) THEN
SELECT 'Item already owned' AS message;
ROLLBACK;
LEAVE proc;
END IF;
-- Execute transaction
UPDATE `users`
SET `coins` = `coins` - v_item_price
WHERE `id` = p_user_id;
INSERT INTO `user_inventory`(`user_id`, `item_id`)
VALUES(p_user_id, p_item_id);
COMMIT;
SELECT 'Purchase successful!' AS message;
END $$ DELIMITER;