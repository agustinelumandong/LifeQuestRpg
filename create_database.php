<?php
/**
 * LifeQuestRPG Database Creator
 * 
 * This script ensures the database exists before running migrations.
 * Usage: php create_database.php
 */

// Default database values
$host = 'localhost';
$username = 'root';
$password = '';
$database = 'lifequestrpg';
$charset = 'utf8mb4';

try {
    // Connect without specifying a database
    $pdo = new PDO("mysql:host={$host}", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Check if database exists
    $stmt = $pdo->query("SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '{$database}'");
    $databaseExists = $stmt->fetchColumn();
    
    if (!$databaseExists) {
        // Create the database
        $pdo->exec("CREATE DATABASE `{$database}` DEFAULT CHARACTER SET {$charset} COLLATE {$charset}_unicode_ci");
        echo "✅ Database '{$database}' created successfully!\n";
    } else {
        echo "✅ Database '{$database}' already exists.\n";
    }
    
    echo "You can now run migrations with: php migrate.php run\n";
    
} catch (PDOException $e) {
    die("❌ Database error: " . $e->getMessage() . "\n");
}
