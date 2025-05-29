<?php

namespace App\Models;

use App\Core\Auth;
use App\Core\Model;
use App\Core\Paginator;

class ActivityLog extends Model
{
    protected static $table = 'activity_log';

    /**
     * Summary of getRecentActivities
     * @param mixed $userId
     */
    public function getRecentActivities($userId)
    {
        return self::$db->query(
            "SELECT log_id, user_id, task_title, difficulty, category, coins, xp, log_timestamp 
            FROM view_task_activity WHERE user_id = ?
            UNION ALL
            SELECT log_id, user_id, task_title, difficulty, category, coins, xp, log_timestamp 
            FROM view_daily_task_activity WHERE user_id = ?
            UNION ALL
            SELECT log_id, user_id, activity_title AS task_title, difficulty, category, coins, xp, log_timestamp 
            FROM view_good_habits_activity WHERE user_id = ?
            UNION ALL
            SELECT log_id, user_id, activity_title AS task_title, difficulty, category, coins, xp, log_timestamp 
            FROM view_bad_habits_activity WHERE user_id = ?
            UNION ALL
            SELECT 
                log_id, 
                target_user_id AS user_id, 
                CAST(CONCAT(poker_username, ' poked you') AS CHAR) AS task_title, 
                CAST('NA' AS CHAR) AS difficulty, 
                CAST('Social' AS CHAR) AS category, 
                CAST('0' AS CHAR) AS coins, 
                CAST('0' AS CHAR) AS xp, 
                poke_timestamp AS log_timestamp 
            FROM view_poke_activity 
            WHERE target_user_id = ?
            UNION ALL
            SELECT 
                log_id, 
                user_id, 
                event_name AS task_title, 
                CAST('NA' AS CHAR) AS difficulty, 
                CAST('Social' AS CHAR) AS category,
                coins, 
                xp, 
                log_timestamp
            FROM view_event_activity
            WHERE user_id = ?
            ORDER BY log_timestamp DESC"
        )
            ->bind([1 => $userId, 2 => $userId, 3 => $userId, 4 => $userId, 5 => $userId, 6 => $userId])
            ->execute()
            ->fetchAll();
    }

    public function getAllActivities($userId, $page = 1, $perPage = 10, $orderBy = 'log_timestamp', $direction = 'DESC')
    {
        // Calculate offset for pagination
        $offset = ($page - 1) * $perPage;

        // The query with LIMIT and ORDER BY for pagination
        return self::$db->query(
            "SELECT * FROM (
                SELECT log_id, user_id, task_title, difficulty, category, coins, xp, log_timestamp 
                FROM view_task_activity WHERE user_id = ?
                UNION ALL
                SELECT log_id, user_id, task_title, difficulty, category, coins, xp, log_timestamp 
                FROM view_daily_task_activity WHERE user_id = ?
                UNION ALL                SELECT log_id, user_id, activity_title AS task_title, difficulty, category, coins, xp, log_timestamp 
                FROM view_good_habits_activity WHERE user_id = ?
                UNION ALL           
                SELECT log_id, user_id, activity_title AS task_title, difficulty, category, coins, xp, log_timestamp 
                FROM view_bad_habits_activity WHERE user_id = ?
                UNION ALL
                SELECT 
                    log_id, 
                    target_user_id AS user_id, 
                    CAST(CONCAT(poker_username, ' poked you') AS CHAR) AS task_title, 
                    CAST('NA' AS CHAR) AS difficulty, 
                    CAST('Social' AS CHAR) AS category, 
                    CAST('0' AS CHAR) AS coins, 
                    CAST('0' AS CHAR) AS xp, 
                    poke_timestamp AS log_timestamp 
                FROM view_poke_activity 
                WHERE target_user_id = ?
                UNION ALL
                SELECT 
                log_id, 
                user_id, 
                event_name AS task_title, 
                CAST('NA' AS CHAR) AS difficulty,  
                CAST('Social' AS CHAR) AS category,
                coins, 
                xp, 
                log_timestamp
            FROM view_event_activity
            WHERE user_id = ?
            ) AS combined_activities
            ORDER BY {$orderBy} {$direction}
            LIMIT ?, ?"
        )
            ->bind([
                1 => $userId,
                2 => $userId,
                3 => $userId,
                4 => $userId,
                5 => $userId,
                6 => $userId,
                7 => $offset,
                8 => $perPage
            ])
            ->execute()
            ->fetchAll();
    }


    public function paginates($userId, $page = 1, $perPage = 10, $orderBy = 'log_timestamp', $direction = 'DESC')
    {
        // Validate page and perPage
        $page = max(1, (int) $page);
        $perPage = max(1, (int) $perPage);

        // Get the total count for pagination
        $total = self::$db->query(
            "SELECT COUNT(*) as total FROM (
                SELECT log_id FROM view_task_activity WHERE user_id = ?
                UNION ALL
                SELECT log_id FROM view_daily_task_activity WHERE user_id = ?
                UNION ALL
                SELECT log_id FROM view_good_habits_activity WHERE user_id = ?
                UNION ALL
                SELECT log_id FROM view_bad_habits_activity WHERE user_id = ?
                UNION ALL
                SELECT log_id FROM view_poke_activity 
                WHERE target_user_id = ?
                UNION ALL
                SELECT log_id FROM view_event_activity WHERE user_id = ?
            ) AS count_query"
        )
            ->bind(
                [
                    1 => $userId,
                    2 => $userId,
                    3 => $userId,
                    4 => $userId,
                    5 => $userId,
                    6 => $userId
                ]
            )
            ->execute()
            ->fetch();

        // Get the paginated data
        $items = $this->getAllActivities($userId, $page, $perPage, $orderBy, $direction);

        // Create and return the paginator
        $paginator = new Paginator($perPage);
        return $paginator->setData($items, $total['total'] ?? 0)
            ->setPage($page)
            ->setOrderBy($orderBy, $direction)
            ->setTheme('game');
    }

    public function logPoke($targetUserId, $pokerUserId, $pokerUsername)
    {
        // Use the stored procedure log_poke
        $result = self::$db->query("CALL log_poke(?, ?, ?)")
            ->bind([1 => $targetUserId, 2 => $pokerUserId, 3 => $pokerUsername])
            ->execute()
            ->fetchAll();

        // Check if the procedure returned success
        return isset($result[0]['success']) && $result[0]['success'] > 0;
    }    /**
         * Log a user activity
         * @param int $userId
         * @param string $activityType
         * @param string|array $activityDetails JSON string or array to convert to JSON
         * @ return bool|int
         */
    public function logActivity($userId, $activityType, $activityDetails = null)
    {
        // Ensure activity details is valid JSON
        if ($activityDetails !== null) {
            if (!is_string($activityDetails) || !$this->isValidJson($activityDetails)) {
                // If it's not valid JSON, convert it to JSON
                $activityDetails = is_array($activityDetails) ?
                    json_encode($activityDetails) :
                    json_encode(['message' => (string) $activityDetails]);
            }
        } else {
            // Provide a default valid JSON object if null
            $activityDetails = json_encode(['timestamp' => date('Y-m-d H:i:s')]);
        }

        return self::$db->query("INSERT INTO " . static::$table . " (user_id, activity_type, activity_details) 
                               VALUES (?, ?, ?)")
            ->bind([
                1 => $userId,
                2 => $activityType,
                3 => $activityDetails
            ])
            ->execute();
    }

    /**
     * Check if a string is valid JSON
     * @param string $string
     * @return bool
     */
    private function isValidJson($string)
    {
        if (!is_string($string))
            return false;
        json_decode($string);
        return (json_last_error() == JSON_ERROR_NONE);
    }

    /**
     * Get recent activity logs
     * @param int $limit
     * @return array
     */
    public function getRecent($limit = 10)
    {
        $sql = "SELECT * FROM " . self::$table . " ORDER BY log_timestamp DESC LIMIT :limit";
        return self::$db->query($sql)
            ->bind([':limit' => $limit])
            ->execute()
            ->fetchAll();
    }

    /**
     * Get recent activities for a user
     *
     * @param int $userId User ID to get activities for
     * @param int $limit Number of records to return
     * @return array Recent user activities
     */


    /**
     * Get count of active users since a given date
     *
     * @param string $date Date to count active users since
     * @return int Count of active users
     */
    public function getActiveUserCountSince($date)
    {
        $sql = "SELECT COUNT(DISTINCT user_id) as count FROM " . self::$table . " WHERE log_timestamp >= :date";
        $result = self::$db->query($sql)
            ->bind([':date' => $date])
            ->execute()
            ->fetch();

        return $result['count'] ?? 0;
    }

    /**
     * Get daily user activity count for the last 30 days
     *
     * @return array Daily user counts
     */
    public function getDailyUserCountLast30Days()
    {
        $sql = "SELECT 
                   DATE(log_timestamp) as date, 
                   COUNT(DISTINCT user_id) as count 
                FROM " . self::$table . " 
                WHERE log_timestamp >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
                GROUP BY DATE(log_timestamp)
                ORDER BY DATE(log_timestamp)";

        return self::$db->query($sql)
            ->execute()
            ->fetchAll();
    }
}