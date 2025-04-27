<?php

namespace App\Models;

use App\Core\Model;

class UserStats Extends Model {

    protected static $table = 'userstats';

    public function createUserStats(array $data)
    {
        return self::$db->query("INSERT INTO userStats (user_id, xp, level, hearts) VALUES (:user_id, :xp, :level, :hearts)")
            ->bind($data)
            ->execute();
    }

    public function getByUserId ($user_id){
        return self::$db->query("
        SELECT  userstats.id, userstats.xp, userstats.level, userstats.hearts, userstats.hearts, 
        userstats.physicalHealth, userstats.mentalWellness, userstats.personalGrowth, userstats.careerStudies,
        userstats.finance, userstats.homeEnvironment, userstats.relationshipsSocial, userstats.passionHobbies
        FROM userstats
        INNER JOIN users ON users.id = userstats.user_id
        WHERE userstats.user_id = ? ")
        ->bind([1=>$user_id])
        ->execute()
        ->fetch();
    }

    public function addXp ($user_id, $xpReward){
        $userstats = $this->getByUserId($user_id);

        $newxp = $userstats['xp'] + $xpReward;
        $level = $userstats['level'];
        $xpThreshold = $userstats['level'] * 100;

        if($newxp >= $xpThreshold){
            $level++;
            $newxp -= $xpThreshold;
        }

        return $this->update($userstats['id'],[
            'xp' => $newxp,
            'level' => $level
        ]);

    }

    public function addSp($user_id, $category, $difficulty) {
        $userStats = $this->getByUserId($user_id);

        $categoryColumns = [
            'Physical Health' => 'physicalHealth',
            'Mental Wellness' => 'mentalWellness',
            'Personal Growth' => 'personalGrowth',
            'Career / Studies' => 'careerStudies',
            'Finance' => 'finance',
            'Home Environment' => 'homeEnvironment',
            'Relationships Social' => 'relationshipsSocial',
            'Passion Hobbies' => 'passionHobbies',
        ];

        $difficultyPoints = [
            'easy' => 1,
            'medium' => 2,
            'hard' => 3,
        ];

        $columnName = $categoryColumns[$category] ?? null;

        if(!$columnName){
            return false;
        } 

        $points = $difficultyPoints[$difficulty] ?? 1;

        $newStats = ($userStats[$columnName] ?? 0 ) + $points;

        return $this->update($userStats['id'],[
            $columnName => $newStats
        ]);
    }

    public function minusHeart ($user_id) {
        $user = $this->getByUserId($user_id);
    
        if(!$user){
          return false;
        }
    
        $newHeart = $user['hearts'] - 1;
    
        $updated =  $this->update($user['id'], [
          'hearts' => $newHeart
        ]);

        if($updated && $newHeart <= 0) {
            $this->resetStatsPunishment($user_id);
            $_SESSION['warning' ] = 'Your hearts reached zero! All stat have been reset to 5.';
        }   

      }

      public function resetStatsPunishment ($user_id){
            $user = $this->getByUserId($user_id);

            if(!$user){
                return false;
            }

            if($user['hearts'] <= 0) {
                return $this->update($user['id'], [
                    'physicalHealth' => 5,
                    'mentalWellness' => 5,
                    'personalGrowth' => 5,
                    'careerStudies' => 5,
                    'finance' => 5,
                    'homeEnvironment' => 5,
                    'relationShipsSocial' => 5,
                    'passionHobbies' => 5,
                    'hearts' => 10,
                    'level' => 1,
                    'xp' => 0
                ]);
            }


      }

}
?>