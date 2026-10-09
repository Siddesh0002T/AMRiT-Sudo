<?php
// ========================================================
// BlueMesh Institutional API: Database Configuration & Auto-Migrate
// ========================================================

if (php_sapi_name() !== 'cli') {
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET, POST, OPTIONS, DELETE, PUT');
    header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');

    if (isset($_SERVER['REQUEST_METHOD']) && $_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        http_response_code(200);
        exit(0);
    }

    header('Content-Type: application/json; charset=UTF-8');
}

$db_host = '127.0.0.1';
$db_port = '3306';
$db_name = 'bluemesh_db';
$db_user = 'root';
$db_pass = 'root'; // default for local MySQL installation; fallback below

$pdo = null;

// Try with primary password, then empty password
$passwords_to_try = [$db_pass, ''];

foreach ($passwords_to_try as $pass) {
    try {
        $dsn = "mysql:host={$db_host};port={$db_port};charset=utf8mb4";
        $pdo = new PDO($dsn, $db_user, $pass, [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        ]);
        $db_pass = $pass;
        break;
    } catch (PDOException $e) {
        // try next
    }
}

if (!$pdo) {
    echo json_encode([
        'success' => false,
        'error' => 'Database connection failed. Please ensure MySQL is running in XAMPP or Windows services with username root.'
    ]);
    exit(1);
}

// Auto-create database & tables if needed
try {
    $pdo->exec("CREATE DATABASE IF NOT EXISTS `{$db_name}` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;");
    $pdo->exec("USE `{$db_name}`;");

    // Check if admins table or patrol_beacons table exists; if not, import database_schema.sql
    $stmt = $pdo->query("SHOW TABLES LIKE 'admins'");
    $bStmt = $pdo->query("SHOW TABLES LIKE 'patrol_beacons'");
    if ($stmt->rowCount() === 0 || $bStmt->rowCount() === 0) {
        $sqlFile = __DIR__ . '/database_schema.sql';
        if (file_exists($sqlFile)) {
            $sqlContent = file_get_contents($sqlFile);
            $pdo->exec($sqlContent);
        }
    }
} catch (Exception $e) {
    // If table creation fails, output error
    error_log("Schema auto-init warning: " . $e->getMessage());
}

function getJsonInput() {
    $raw = file_get_contents('php://input');
    if (empty($raw)) {
        return $_POST;
    }
    $decoded = json_decode($raw, true);
    return is_array($decoded) ? array_merge($_POST, $decoded) : $_POST;
}
