<?php
/**
 * Run SQL file with custom delimiters
 * 
 * This script runs SQL files that contain DELIMITER directives,
 * such as those with triggers or stored procedures.
 * 
 * Usage: php run_sql_with_delimiters.php <file_path>
 */

if ($argc < 2) {
    die("Usage: php run_sql_with_delimiters.php <file_path>\n");
}

$filePath = $argv[1];

if (!file_exists($filePath)) {
    die("Error: File not found: $filePath\n");
}

// Default database values
$host = 'localhost';
$username = 'root';
$password = '';
$database = 'lifequestrpg';

try {
    // Connect to database
    $pdo = new PDO("mysql:host=$host;dbname=$database", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "Connected to database $database\n";
    
    // Read SQL file
    $sql = file_get_contents($filePath);
    
    // Split SQL into statements considering DELIMITER
    $statements = extractStatementsWithDelimiter($sql);
    
    // Execute each statement
    foreach ($statements as $statement) {
        if (!empty(trim($statement))) {
            echo "Executing statement...\n";
            $pdo->exec($statement);
            echo "✅ Success\n";
        }
    }
    
    echo "✅ SQL file executed successfully\n";
    
    // Now mark the migration as completed in the migrations table
    $migrationName = basename($filePath, '.sql');
    $pdo->exec("INSERT INTO migrations (migration) VALUES ('$migrationName')");
    echo "✅ Migration '$migrationName' marked as completed\n";
    
} catch (PDOException $e) {
    die("❌ Database error: " . $e->getMessage() . "\n");
}

/**
 * Extract SQL statements from a string containing DELIMITER directives
 */
function extractStatementsWithDelimiter($sql) {
    // Remove comments
    $sql = preg_replace('/--.*$/m', '', $sql);
    $sql = preg_replace('/\/\*.*?\*\//s', '', $sql);
    
    // Split by DELIMITER directive
    $parts = preg_split('/DELIMITER\s+([^\s]+)/i', $sql, -1, PREG_SPLIT_DELIM_CAPTURE);
    
    $statements = [];
    
    // The first part is before any DELIMITER directive, using default delimiter ';'
    if (!empty(trim($parts[0]))) {
        $stmts = explode(';', $parts[0]);
        foreach ($stmts as $stmt) {
            if (!empty(trim($stmt))) {
                $statements[] = trim($stmt);
            }
        }
    }
    
    // Process the remaining parts
    for ($i = 1; $i < count($parts); $i += 2) {
        if ($i + 1 >= count($parts)) {
            break;
        }
        
        $delimiter = $parts[$i];
        $content = $parts[$i + 1];
        
        // Split by the custom delimiter
        $stmts = explode($delimiter, $content);
        
        foreach ($stmts as $stmt) {
            if (!empty(trim($stmt))) {
                // Add the statement, including the DELIMITER directive
                $statements[] = "DELIMITER " . $delimiter . "\n" . trim($stmt) . $delimiter . "\nDELIMITER ;";
            }
        }
    }
    
    return $statements;
}
