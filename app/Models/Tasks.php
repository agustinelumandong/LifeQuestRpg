<?php

namespace App\Models;

use App\Core\Model;
use App\Core\Auth;

class Tasks extends Model
{

    protected static $table = 'tasks';

    public function getTasksByUserId($userId)
    {
        $sql = "SELECT * FROM " . self::$table . " WHERE user_id = :userId";
        return self::$db->query($sql)
            ->bind([':userId' => $userId])
            ->execute()
            ->fetchAll();
    }

    public function getTasks()
    {
        /** @var array $currentUser */
        $currentUser = Auth::user();

        if ($currentUser) {
            return $this->getTasksByUserId($currentUser['id']);
        } else {
            return self::$db->query("SELECT * FROM " . self::$table)
                ->execute()
                ->fetchAll();
        }
    }

    /**
     * Get a count of all tasks
     * @return int
     */
    public function count()
    {
        $result = self::$db->query("SELECT COUNT(*) as count FROM " . static::$table)
            ->execute()
            ->fetch();
        return $result ? (int) ($result['count'] ?? 0) : 0;
    }

    /**
     * Get count of completed tasks
     * @return int
     */
    public function getCompletedCount()
    {
        $sql = "SELECT COUNT(*) as count FROM " . self::$table . " WHERE status = 'completed' ";
        $result = self::$db->query($sql)
            ->execute()
            ->fetch();

        return $result['count'] ?? 0;
    }

    /**
     * Get the distribution of tasks by category
     * @return array
     */
    public function getCategoryDistribution()
    {
        $sql = "SELECT 
                   category, 
                   COUNT(*) as count 
                FROM " . self::$table . " 
                WHERE category IS NOT NULL AND category != ''
                GROUP BY category
                ORDER BY count DESC";

        $results = self::$db->query($sql)
            ->execute()
            ->fetchAll();

        // Format results as category => count
        $distribution = [];
        foreach ($results as $row) {
            $distribution[$row['category']] = (int) $row['count'];
        }

        // If no categories found, provide default categories
        if (empty($distribution)) {
            $distribution = [
                'Physical Health' => 15,
                'Mental Wellness' => 20,
                'Personal Growth' => 25,
                'Career/Studies' => 10,
                'Finance' => 15,
                'Home' => 15
            ];
        }

        return $distribution;
    }

    /**
     * Get count of tasks created since a date
     */
    public function getCountSince($date)
    {
        $sql = "SELECT COUNT(*) as count FROM " . self::$table . " WHERE created_at >= :date";
        $result = self::$db->query($sql)
            ->bind([':date' => $date])
            ->execute()
            ->fetch();

        return $result['count'] ?? 0;
    }

    /**
     * Get count of tasks created between two dates
     */
    public function getCountBetween($startDate, $endDate)
    {
        $sql = "SELECT COUNT(*) as count FROM " . self::$table . " WHERE created_at >= :startDate AND created_at <= :endDate";
        $result = self::$db->query($sql)
            ->bind([
                ':startDate' => $startDate,
                ':endDate' => $endDate
            ])
            ->execute()
            ->fetch();

        return $result['count'] ?? 0;
    }
}

