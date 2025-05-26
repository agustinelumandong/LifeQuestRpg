<?php
/**
 * Run remaining complex migrations
 * 
 * This script executes the remaining migrations that contain 
 * complex SQL with DELIMITER directives using the mysql command.
 */

// Database connection details
$host = 'localhost';
$username = 'root';
$password = '';
$database = 'lifequestrpg';

// Connect to the database to mark migrations as completed
try {
    $pdo = new PDO("mysql:host=$host;dbname=$database", $username, $password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION
    ]);
    
    echo "Connected to database $database\n";
    
    // List of complex migrations with triggers and procedures
    $complexMigrations = [
        '022_create_triggers.sql',
        '023_create_inventory_triggers.sql',
        '024_create_procedures_part1.sql',
        '025_create_use_inventory_procedure.sql'
    ];
    
    // Execute each migration using mysql command
    foreach ($complexMigrations as $migration) {
        $filePath = __DIR__ . '/database/migrations/' . $migration;
        
        if (!file_exists($filePath)) {
            echo "⚠️ Migration file not found: $filePath\n";
            continue;
        }
        
        echo "⏳ Running migration: $migration...\n";
        
        // Execute the SQL file using mysql command
        $command = "mysql -u $username -h $host $database < \"$filePath\"";
        if (!empty($password)) {
            $command = "mysql -u $username -p\"$password\" -h $host $database < \"$filePath\"";
        }
        
        $output = [];
        $returnVar = 0;
        
        exec($command, $output, $returnVar);
        
        if ($returnVar !== 0) {
            echo "❌ Failed to execute migration: $migration\n";
            echo "Error output: " . implode("\n", $output) . "\n";
            exit(1);
        }
        
        // Mark migration as completed
        $migrationName = basename($migration, '.sql');
        
        try {
            $stmt = $pdo->prepare("INSERT INTO migrations (migration) VALUES (?)");
            $stmt->execute([$migrationName]);
            echo "✅ Migration $migration executed and marked as completed\n";
        } catch (PDOException $e) {
            echo "⚠️ Failed to mark migration as completed: " . $e->getMessage() . "\n";
        }
    }
    
    // Run the last simple migration using the standard migrator
    echo "\n⏳ Running remaining simple migrations...\n";
    exec("php migrate.php run", $output, $returnVar);
    
    if ($returnVar !== 0) {
        echo "❌ Failed to execute remaining migrations\n";
    } else {
        echo "✅ All migrations completed successfully\n";
    }
    
} catch (PDOException $e) {
    die("❌ Database error: " . $e->getMessage() . "\n");
}
