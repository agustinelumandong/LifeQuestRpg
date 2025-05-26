DROP PROCEDURE IF EXISTS UseInventoryItem;
DELIMITER $$ CREATE DEFINER = `root` @`localhost` PROCEDURE `UseInventoryItem`(IN `p_inventory_id` INT, IN `p_user_id` INT) proc_label: BEGIN
DECLARE v_item_id INT;
DECLARE v_item_type VARCHAR(50);
DECLARE v_effect_type VARCHAR(50);
DECLARE v_effect_value INT;
DECLARE v_effect_message VARCHAR(255);
DECLARE v_userstats_count INT;
DECLARE v_item_name VARCHAR(255);
DECLARE v_current_health INT;
DECLARE v_error_message VARCHAR(255);
DECLARE v_new_health INT;
DECLARE v_current_quantity INT;
DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN GET DIAGNOSTICS CONDITION 1 v_error_message = MESSAGE_TEXT;
ROLLBACK;
SELECT CONCAT('SQL Error: ', v_error_message) AS message;
END;
START TRANSACTION;
-- Check if userstats exists for the user
SELECT COUNT(*) INTO v_userstats_count
FROM userstats
WHERE user_id = p_user_id;
IF v_userstats_count = 0 THEN
SELECT 'No userstats row found for this user' AS message;
ROLLBACK;
LEAVE proc_label;
END IF;
-- Get current health for health-related items
SELECT health INTO v_current_health
FROM userstats
WHERE user_id = p_user_id;
-- Verify inventory item exists and belongs to the user
SELECT i.item_id,
    i.quantity,
    m.item_type,
    m.effect_type,
    m.effect_value,
    m.item_name INTO v_item_id,
    v_current_quantity,
    v_item_type,
    v_effect_type,
    v_effect_value,
    v_item_name
FROM user_inventory i
    JOIN marketplace_items m ON i.item_id = m.item_id
WHERE i.inventory_id = p_inventory_id
    AND i.user_id = p_user_id;
IF v_item_id IS NULL THEN
SELECT 'Item not found in your inventory' AS message;
ROLLBACK;
LEAVE proc_label;
END IF;
-- Process based on item type
CASE
    v_item_type
    WHEN 'consumable' THEN CASE
        v_effect_type
        WHEN 'health' THEN -- Check if health is already at max
        IF v_current_health >= 100 THEN
        SELECT 'Your health is already at maximum' AS message;
ROLLBACK;
LEAVE proc_label;
END IF;
-- Calculate new health value
SET v_new_health = LEAST(v_current_health + v_effect_value, 100);
UPDATE userstats
SET health = v_new_health
WHERE user_id = p_user_id;
SET v_effect_message = CONCAT(
        'Restored ',
        (v_new_health - v_current_health),
        ' health points'
    );
WHEN 'xp' THEN
UPDATE userstats
SET xp = xp + v_effect_value
WHERE user_id = p_user_id;
SET v_effect_message = CONCAT('Gained ', v_effect_value, ' experience points');
ELSE
SET v_effect_message = CONCAT(
        'Consumable used with unknown effect type: ',
        v_effect_type
    );
END CASE
;
WHEN 'boost' THEN -- Check if boost is already active
IF EXISTS (
    SELECT 1
    FROM user_active_boosts
    WHERE user_id = p_user_id
        AND boost_type = v_effect_type
        AND expires_at > NOW()
) THEN
SELECT 'This type of boost is already active' AS message;
ROLLBACK;
LEAVE proc_label;
END IF;
-- Add boost to active boosts
INSERT INTO user_active_boosts (
        user_id,
        boost_type,
        boost_value,
        activated_at,
        expires_at
    )
VALUES (
        p_user_id,
        v_effect_type,
        v_effect_value,
        NOW(),
        DATE_ADD(NOW(), INTERVAL 24 HOUR)
    );
SET v_effect_message = CONCAT(
        'Activated a ',
        v_effect_value,
        '% boost for 24 hours'
    );
WHEN 'equipment' THEN
SET v_effect_message = 'Item equipped successfully';
ELSE
SET v_effect_message = CONCAT('Unknown item type: ', v_item_type);
END CASE
;
-- Handle quantity and logging properly for all item types
IF v_item_type = 'consumable' THEN -- Always log the usage FIRST with the actual inventory_id (before any deletion)
INSERT INTO item_usage_history (inventory_id, effect_applied)
VALUES (p_inventory_id, v_effect_message);
IF v_current_quantity > 1 THEN -- Reduce quantity by 1
UPDATE user_inventory
SET quantity = quantity - 1
WHERE inventory_id = p_inventory_id;
ELSE -- Delete the item if quantity is 1 or less
DELETE FROM user_inventory
WHERE inventory_id = p_inventory_id;
END IF;
ELSE -- For non-consumable items, log the usage normally
INSERT INTO item_usage_history (inventory_id, effect_applied)
VALUES (p_inventory_id, v_effect_message);
END IF;
-- Return success message
SELECT 'Item used successfully' AS message,
    v_effect_message AS effect;
COMMIT;
END $$ DELIMITER;