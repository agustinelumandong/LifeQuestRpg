<?php
/**
 * LifeQuestRPG Migration Creator
 * 
 * This script helps create new SQL migration files with proper sequential numbering.
 * Usage: php create_migration.php "migration_description"
 * Example: php create_migration.php "add_settings_table"
 */

// Migration file path
$migrationsPath = __DIR__ . '/database/migrations/';

// Get migration description from command line argument
$description = $argv[1] ?? null;

if (!$description) {
    die("Error: Migration description is required.\nUsage: php create_migration.php \"migration_description\"\n");
}

// Sanitize description for filename (remove special chars, convert spaces to underscores)
$sanitizedDesc = preg_replace('/[^a-z0-9_]+/', '_', strtolower($description));
$sanitizedDesc = trim($sanitizedDesc, '_');

// Get the next migration number
$files = glob($migrationsPath . '*.sql');
$nextNumber = 1;

if (!empty($files)) {
    $numbers = [];
    foreach ($files as $file) {
        $filename = basename($file);
        if (preg_match('/^(\d+)_/', $filename, $matches)) {
            $numbers[] = (int)$matches[1];
        }
    }
    
    if (!empty($numbers)) {
        $nextNumber = max($numbers) + 1;
    }
}

// Format number with leading zeros
$formattedNumber = str_pad($nextNumber, 3, '0', STR_PAD_LEFT);

// Create the new migration filename
$migrationFilename = "{$formattedNumber}_{$sanitizedDesc}.sql";
$migrationPath = $migrationsPath . $migrationFilename;

// Create the migration file with a template
$template = <<<SQL
-- Migration: {$description}
-- Created: " . date('Y-m-d H:i:s') . "

-- Write your SQL statements here
-- Example:
-- CREATE TABLE `example` (
--   `id` int NOT NULL AUTO_INCREMENT,
--   `name` varchar(255) NOT NULL,
--   `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
--   PRIMARY KEY (`id`)
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SQL;

if (file_put_contents($migrationPath, $template)) {
    echo "✅ Migration file created successfully: {$migrationFilename}\n";
} else {
    echo "❌ Failed to create migration file.\n";
}
