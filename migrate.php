<?php

/**
 * LifeQuestRPG Migration System
 * 
 * Usage:
 * php migrate.php run     - Execute pending migrations
 * php migrate.php status  - Show migration status
 * php migrate.php help    - Show help
 */

class Migration {
    private $pdo;
    private $migrationsPath;
    
    public function __construct() {
        $this->migrationsPath = __DIR__ . '/database/migrations/';
        $this->initializeDatabase();
        $this->createMigrationsTable();
    }    private function initializeDatabase() {
        try {
            // Get database credentials from config file
            if (file_exists(__DIR__ . '/config/database.php')) {
                // Use simple include instead of requiring Helpers class
                $configFile = file_get_contents(__DIR__ . '/config/database.php');
                
                // Set default values
                $host = 'localhost';
                $dbname = 'lifequestrpg';
                $username = 'root';
                $password = '';
            } else {
                // Fallback to default values if config file doesn't exist
                $host = 'localhost';
                $dbname = 'lifequestrpg';
                $username = 'root';
                $password = '';
            }
            
            $dsn = "mysql:host={$host};dbname={$dbname};charset=utf8mb4";
            $this->pdo = new PDO(
                $dsn,
                $username,
                $password,
                [
                    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
                ]
            );
            
            echo "Connected to database: {$dbname} on {$host}\n";
        } catch (PDOException $e) {
            die("Database connection failed: " . $e->getMessage() . "\n");
        }
    }
    
    private function createMigrationsTable() {
        $sql = "CREATE TABLE IF NOT EXISTS migrations (
            id INT AUTO_INCREMENT PRIMARY KEY,
            migration VARCHAR(255) NOT NULL,
            executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY unique_migration (migration)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";
        
        $this->pdo->exec($sql);
    }
    
    public function run() {
        $migrations = $this->getPendingMigrations();
        
        if (empty($migrations)) {
            echo "✅ No pending migrations.\n";
            return;
        }
        
        echo "🚀 Found " . count($migrations) . " pending migration(s):\n";
        foreach ($migrations as $migration) {
            echo "   - {$migration}\n";
        }
        echo "\n";
        
        foreach ($migrations as $migration) {
            echo "⏳ Running migration: {$migration}... ";
            try {
                $this->executeMigration($migration);
                echo "✅ COMPLETED\n";
            } catch (Exception $e) {
                echo "❌ FAILED\n";
                echo "Error: " . $e->getMessage() . "\n";
                return;
            }
        }
        
        echo "\n🎉 All migrations completed successfully!\n";
    }
    
    private function getPendingMigrations() {
        // Get all migration files
        $files = glob($this->migrationsPath . '*.sql');
        if (!$files) {
            return [];
        }
        
        $migrations = array_map(function($file) {
            return basename($file, '.sql');
        }, $files);
        
        sort($migrations);
        
        // Get executed migrations
        $stmt = $this->pdo->query("SELECT migration FROM migrations ORDER BY migration");
        $executed = $stmt->fetchAll(PDO::FETCH_COLUMN);
        
        // Return pending migrations
        return array_diff($migrations, $executed);
    }
      private function executeMigration($migration) {
        $filePath = $this->migrationsPath . $migration . '.sql';
        
        if (!file_exists($filePath)) {
            throw new Exception("Migration file not found: {$filePath}");
        }
        
        $sql = file_get_contents($filePath);
        
        if (empty(trim($sql))) {
            throw new Exception("Migration file is empty: {$migration}");
        }
        
        // Handle multiple statements
        $statements = $this->splitSqlStatements($sql);
        
        try {
            // Execute each statement individually without transaction
            foreach ($statements as $statement) {
                $trimmed = trim($statement);
                if (!empty($trimmed)) {
                    $this->pdo->exec($trimmed);
                }
            }
            
            // Record migration as executed
            $stmt = $this->pdo->prepare("INSERT INTO migrations (migration) VALUES (?)");
            $stmt->execute([$migration]);
            
        } catch (Exception $e) {
            throw new Exception("Migration '{$migration}' failed: " . $e->getMessage());
        }
    }    private function splitSqlStatements($sql) {
        // Remove SQL comments
        $sql = preg_replace('/--.*$/m', '', $sql);
        $sql = preg_replace('/\/\*.*?\*\//s', '', $sql);
        
        // Handle DELIMITER directives
        if (stripos($sql, 'DELIMITER') !== false) {
            // For files with DELIMITER, just return the entire SQL
            // so it can be executed as a whole
            return [$sql];
        }
        
        // Simple statement splitting based on semicolons
        $statements = [];
        $parts = explode(';', $sql);
        
        foreach ($parts as $part) {
            $trimmedPart = trim($part);
            if (!empty($trimmedPart)) {
                $statements[] = $trimmedPart;
            }
        }
        
        return $statements;
    }
    
    public function status() {
        $allFiles = glob($this->migrationsPath . '*.sql');
        $allMigrations = [];
        
        if ($allFiles) {
            $allMigrations = array_map(function($file) {
                return basename($file, '.sql');
            }, $allFiles);
            sort($allMigrations);
        }
        
        $stmt = $this->pdo->query("SELECT migration, executed_at FROM migrations ORDER BY migration");
        $executed = $stmt->fetchAll(PDO::FETCH_KEY_PAIR);
        
        echo "📊 Migration Status:\n";
        echo str_repeat("=", 50) . "\n";
        
        if (empty($allMigrations)) {
            echo "No migration files found.\n";
            return;
        }
        
        foreach ($allMigrations as $migration) {
            if (isset($executed[$migration])) {
                echo "✅ [EXECUTED] {$migration} (at {$executed[$migration]})\n";
            } else {
                echo "⏳ [PENDING]  {$migration}\n";
            }
        }
        
        $pendingCount = count($allMigrations) - count($executed);
        echo str_repeat("-", 50) . "\n";
        echo "Total: " . count($allMigrations) . " migrations\n";
        echo "Executed: " . count($executed) . " migrations\n";
        echo "Pending: {$pendingCount} migrations\n";
    }
    
    public function help() {
        echo "LifeQuestRPG Migration System\n";
        echo str_repeat("=", 30) . "\n";
        echo "Usage: php migrate.php [command]\n\n";
        echo "Commands:\n";
        echo "  run     Execute all pending migrations\n";
        echo "  status  Show migration status\n";
        echo "  help    Show this help message\n\n";
        echo "Migration files should be placed in: database/migrations/\n";
        echo "File naming convention: 001_description.sql, 002_description.sql, etc.\n";
    }
}

// CLI handling
if (php_sapi_name() === 'cli') {
    $command = $argv[1] ?? 'help';
    
    try {
        $migration = new Migration();
        
        switch ($command) {
            case 'run':
                $migration->run();
                break;
            case 'status':
                $migration->status();
                break;
            case 'help':
            default:
                $migration->help();
                break;
        }
    } catch (Exception $e) {
        echo "❌ Error: " . $e->getMessage() . "\n";
        exit(1);
    }
} else {
    echo "This script must be run from the command line.\n";
    exit(1);
}
