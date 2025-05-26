<?php
/**
 * LifeQuestRPG Migration Manager
 * 
 * A consolidated script to manage all migration-related tasks
 * 
 * Usage:
 *   php migrations.php [command] [args]
 * 
 * Commands:
 *   create [name]   - Create a new migration file
 *   run             - Run all pending migrations
 *   status          - Show migration status
 *   init            - Create the database and run migrations
 *   help            - Show this help message
 */

if (php_sapi_name() !== 'cli') {
    die('This script must be run from the command line.');
}

// Process command line arguments
$command = $argv[1] ?? 'help';
$args = array_slice($argv, 2);

switch ($command) {
    case 'create':
        createMigration($args[0] ?? null);
        break;
        
    case 'run':
        runMigrations();
        break;
        
    case 'status':
        showStatus();
        break;
        
    case 'init':
        initDatabase();
        break;
        
    case 'help':
    default:
        showHelp();
        break;
}

/**
 * Create a new migration file
 */
function createMigration($description) {
    if (!$description) {
        die("Error: Migration description is required.\nUsage: php migrations.php create \"migration_description\"\n");
    }
    
    // Migration file path
    $migrationsPath = __DIR__ . '/database/migrations/';
    
    // Sanitize description for filename
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
}

/**
 * Run migrations using the migrate.php script
 */
function runMigrations() {
    $output = null;
    $return_var = null;
    
    echo "Running migrations...\n";
    
    // Execute the migration script
    passthru('php migrate.php run', $return_var);
    
    // Additional processing if needed
    if ($return_var !== 0) {
        echo "❌ Migration failed with error code {$return_var}\n";
    }
}

/**
 * Show migration status using the migrate.php script
 */
function showStatus() {
    $output = null;
    $return_var = null;
    
    // Execute the migration status script
    passthru('php migrate.php status', $return_var);
    
    // Additional processing if needed
    if ($return_var !== 0) {
        echo "❌ Status check failed with error code {$return_var}\n";
    }
}

/**
 * Initialize the database and run migrations
 */
function initDatabase() {
    echo "📦 Initializing LifeQuestRPG Database\n";
    echo "====================================\n\n";
    
    // Step 1: Create database
    echo "Step 1: Creating database...\n";
    passthru('php create_database.php');
    echo "\n";
    
    // Step 2: Run migrations
    echo "Step 2: Running migrations...\n";
    passthru('php migrate.php run');
    echo "\n";
    
    echo "✅ Database initialization complete!\n";
}

/**
 * Show help information
 */
function showHelp() {
    echo <<<HELP
LifeQuestRPG Migration Manager
=============================

Usage:
  php migrations.php [command] [args]

Commands:
  create [name]   - Create a new migration file
  run             - Run all pending migrations
  status          - Show migration status
  init            - Create the database and run migrations
  help            - Show this help message

Examples:
  php migrations.php create "add_settings_table"
  php migrations.php run
  php migrations.php status
  php migrations.php init

HELP;
}
