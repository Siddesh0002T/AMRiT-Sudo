<?php
// ========================================================
// BlueMesh Institutional API: Core Controller
// ========================================================

require_once __DIR__ . '/db_config.php';
require_once __DIR__ . '/mail_helper.php';

$action = $_GET['action'] ?? $_POST['action'] ?? '';
$input = getJsonInput();

switch ($action) {

    // ====================================================
    // 1. ADMIN ACTIONS (Login: admin / admin)
    // ====================================================
    case 'admin_login':
        $username = trim($input['username'] ?? '');
        $password = trim($input['password'] ?? '');

        // Rule: username "admin" and password "admin"
        if ($username === 'admin' && $password === 'admin') {
            echo json_encode([
                'success' => true,
                'role' => 'admin',
                'user' => [
                    'id' => 1,
                    'username' => 'admin',
                    'name' => 'System Administrator'
                ],
                'message' => 'Admin login successful.'
            ]);
            exit(0);
        }

        // Check in admins table
        $stmt = $pdo->prepare("SELECT * FROM admins WHERE username = ? LIMIT 1");
        $stmt->execute([$username]);
        $admin = $stmt->fetch();

        if ($admin && ($admin['password'] === $password || password_verify($password, $admin['password']))) {
            echo json_encode([
                'success' => true,
                'role' => 'admin',
                'user' => [
                    'id' => $admin['id'],
                    'username' => $admin['username'],
                    'name' => $admin['name']
                ]
            ]);
        } else {
            http_response_code(401);
            echo json_encode(['success' => false, 'error' => 'Invalid admin credentials. Use admin / admin.']);
        }
        break;

    // Admin creates staff account
    case 'create_staff':
        $username = trim($input['username'] ?? '');
        $password = trim($input['password'] ?? '');
        $name = trim($input['name'] ?? '');
        $email = trim($input['email'] ?? '');
        $phone = trim($input['phone'] ?? '');
        $department = trim($input['department'] ?? 'Computer Science');
        $role = trim($input['role'] ?? 'Faculty');

        if (empty($username) || empty($password) || empty($name)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'Username, password and name are required.']);
            exit(0);
        }

        try {
            $stmt = $pdo->prepare("
                INSERT INTO staff (username, password, name, email, phone, department, role)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ");
            $stmt->execute([$username, $password, $name, $email, $phone, $department, $role]);
            echo json_encode(['success' => true, 'message' => 'Staff created successfully.', 'id' => $pdo->lastInsertId()]);
        } catch (PDOException $e) {
            http_response_code(409);
            echo json_encode(['success' => false, 'error' => 'Staff username already exists or error: ' . $e->getMessage()]);
        }
        break;

    case 'get_staff':
        $stmt = $pdo->query("SELECT id, username, name, email, phone, department, role, created_at FROM staff ORDER BY id DESC");
        $staff = $stmt->fetchAll();
        echo json_encode(['success' => true, 'staff' => $staff]);
        break;

    case 'delete_staff':
        $id = $input['id'] ?? null;
        if ($id) {
            $stmt = $pdo->prepare("DELETE FROM staff WHERE id = ?");
            $stmt->execute([$id]);
            echo json_encode(['success' => true, 'message' => 'Staff deleted.']);
        } else {
            echo json_encode(['success' => false, 'error' => 'Missing staff id']);
        }
        break;

    // ====================================================
    // 2. STAFF ACTIONS (Login & Management)
    // ====================================================
    case 'staff_login':
        $username = trim($input['username'] ?? '');
        $password = trim($input['password'] ?? '');

        if (empty($username) || empty($password)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'Please enter username and password.']);
            exit(0);
        }

        // Search by username OR email (case-insensitive & trimmed)
        $stmt = $pdo->prepare("
            SELECT * FROM staff 
            WHERE LOWER(TRIM(username)) = LOWER(?) 
               OR LOWER(TRIM(email)) = LOWER(?) 
            LIMIT 1
        ");
        $stmt->execute([$username, $username]);
        $staff = $stmt->fetch();

        if ($staff) {
            $dbPass = trim($staff['password']);
            if ($dbPass === $password || 
                $dbPass === trim($input['password'] ?? '') || 
                password_verify($password, $dbPass) || 
                strtolower($dbPass) === strtolower($password)) {
                echo json_encode([
                    'success' => true,
                    'role' => 'staff',
                    'user' => [
                        'id' => $staff['id'],
                        'username' => $staff['username'],
                        'name' => $staff['name'],
                        'email' => $staff['email'],
                        'department' => $staff['department']
                    ]
                ]);
                exit(0);
            }
        }

        http_response_code(401);
        echo json_encode(['success' => false, 'error' => 'Invalid staff credentials.']);
        break;

    // ====================================================
    // 3. STUDENT MANAGEMENT (Staff creates students)
    // ====================================================
    case 'create_student':
        $roll = strtoupper(trim($input['roll_number'] ?? ''));
        $name = trim($input['name'] ?? '');
        $section = trim($input['class_section'] ?? 'A');
        $email = trim($input['email'] ?? '');
        $phone = trim($input['phone'] ?? '');
        $fingerprint = isset($input['is_fingerprint_registered']) ? (int)$input['is_fingerprint_registered'] : 1;
        $parentName = trim($input['parent_name'] ?? '');
        $parentEmail = trim($input['parent_email'] ?? '');
        $parentPhone = trim($input['parent_phone'] ?? '');

        if (empty($roll) || empty($name)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'Roll number and name are required.']);
            exit(0);
        }

        try {
            $stmt = $pdo->prepare("
                INSERT INTO students (roll_number, name, class_section, email, phone, is_fingerprint_registered, parent_name, parent_email, parent_phone)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE 
                    name = VALUES(name),
                    class_section = VALUES(class_section),
                    email = VALUES(email),
                    phone = VALUES(phone),
                    is_fingerprint_registered = VALUES(is_fingerprint_registered),
                    parent_name = VALUES(parent_name),
                    parent_email = VALUES(parent_email),
                    parent_phone = VALUES(parent_phone)
            ");
            $stmt->execute([$roll, $name, $section, $email, $phone, $fingerprint, $parentName, $parentEmail, $parentPhone]);

            // Auto-create parent entry if parent email or name is provided
            if (!empty($parentEmail) || !empty($parentName)) {
                $pUsername = 'parent_' . strtolower(preg_replace('/[^a-zA-Z0-9]/', '', $roll));
                $pPass = 'parent123';
                $pStmt = $pdo->prepare("
                    INSERT INTO parents (username, password, parent_name, email, phone, student_roll_number)
                    VALUES (?, ?, ?, ?, ?, ?)
                    ON DUPLICATE KEY UPDATE parent_name = VALUES(parent_name), email = VALUES(email), phone = VALUES(phone)
                ");
                $pStmt->execute([$pUsername, $pPass, $parentName ?: 'Parent of ' . $name, $parentEmail, $parentPhone, $roll]);
            }

            echo json_encode(['success' => true, 'message' => 'Student saved successfully.']);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['success' => false, 'error' => $e->getMessage()]);
        }
        break;

    case 'get_students':
        $stmt = $pdo->query("SELECT * FROM students ORDER BY roll_number ASC");
        $students = $stmt->fetchAll();
        echo json_encode(['success' => true, 'students' => $students]);
        break;

    case 'delete_student':
        $roll = trim($input['roll_number'] ?? '');
        if ($roll) {
            $stmt = $pdo->prepare("DELETE FROM students WHERE roll_number = ?");
            $stmt->execute([$roll]);
            echo json_encode(['success' => true, 'message' => 'Student deleted.']);
        } else {
            echo json_encode(['success' => false, 'error' => 'Missing roll number']);
        }
        break;

    // ====================================================
    // 4. GUARD MANAGEMENT & PATROL EXPLORE ZONES
    // ====================================================
    case 'create_guard':
        $username = trim($input['username'] ?? '');
        $password = trim($input['password'] ?? '');
        $name = trim($input['name'] ?? '');
        $phone = trim($input['phone'] ?? '');
        $zone = trim($input['assigned_zone'] ?? 'ZONE-A');

        if (empty($username) || empty($password) || empty($name)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'Guard username, password, and name are required.']);
            exit(0);
        }

        try {
            $stmt = $pdo->prepare("
                INSERT INTO guards (username, password, name, phone, assigned_zone, status)
                VALUES (?, ?, ?, ?, ?, 'idle')
                ON DUPLICATE KEY UPDATE 
                    name = VALUES(name),
                    password = VALUES(password),
                    phone = VALUES(phone),
                    assigned_zone = VALUES(assigned_zone)
            ");
            $stmt->execute([$username, $password, $name, $phone, $zone]);
            echo json_encode(['success' => true, 'message' => 'Guard created successfully.']);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['success' => false, 'error' => $e->getMessage()]);
        }
        break;

    case 'get_guards':
        $stmt = $pdo->query("SELECT id, username, name, phone, assigned_zone, status, battery_pct, last_ping_at, created_at FROM guards ORDER BY id DESC");
        $guards = $stmt->fetchAll();
        echo json_encode(['success' => true, 'guards' => $guards]);
        break;

    case 'guard_login':
        $username = trim($input['username'] ?? '');
        $password = trim($input['password'] ?? '');

        $stmt = $pdo->prepare("SELECT * FROM guards WHERE username = ? LIMIT 1");
        $stmt->execute([$username]);
        $guard = $stmt->fetch();

        if ($guard && ($guard['password'] === $password || password_verify($password, $guard['password']))) {
            echo json_encode([
                'success' => true,
                'role' => 'guard',
                'guard' => [
                    'id' => $guard['id'],
                    'username' => $guard['username'],
                    'name' => $guard['name'],
                    'assigned_zone' => $guard['assigned_zone'],
                    'status' => $guard['status']
                ]
            ]);
        } else {
            http_response_code(401);
            echo json_encode(['success' => false, 'error' => 'Invalid guard credentials.']);
        }
        break;

    // Guard Patrol Telemetry Ping & Explore Zone Warning Check
    case 'guard_patrol_ping':
        $guardUsername = trim($input['username'] ?? '');
        $currentZone = trim($input['current_zone'] ?? 'ZONE-A');
        $status = trim($input['status'] ?? 'patrolling'); // 'patrolling', 'warning_deviation', 'warning_inactive'
        $isInZone = isset($input['is_in_zone']) ? (bool)$input['is_in_zone'] : true;
        $battery = (int)($input['battery'] ?? 100);
        $rssi = (int)($input['rssi'] ?? -60);
        $message = trim($input['message'] ?? '');

        // Fetch guard to check assigned zone
        $stmt = $pdo->prepare("SELECT * FROM guards WHERE username = ?");
        $stmt->execute([$guardUsername]);
        $guard = $stmt->fetch();

        $isWarning = 0;
        $warningReason = '';

        if (!$guard) {
            echo json_encode(['success' => false, 'error' => 'Guard not found']);
            exit(0);
        }

        // Zone violation check: if guard is outside their assigned zone
        if (!$isInZone || ($guard['assigned_zone'] !== $currentZone && !empty($guard['assigned_zone']))) {
            $isWarning = 1;
            $status = 'warning_deviation';
            $warningReason = "⚠️ ZONE VIOLATION: Guard {$guard['name']} is outside assigned zone ({$guard['assigned_zone']}) in {$currentZone}!";
        }

        if ($status === 'warning_inactive') {
            $isWarning = 1;
            $warningReason = "⚠️ INACTIVITY ALERT: Guard {$guard['name']} has been stationary too long in {$currentZone}!";
        }

        // Update guard table
        $updateStmt = $pdo->prepare("
            UPDATE guards 
            SET status = ?, last_ping_at = NOW(), battery_pct = ? 
            WHERE username = ?
        ");
        $updateStmt->execute([$status, $battery, $guardUsername]);

        // Insert into patrol logs
        $logStmt = $pdo->prepare("
            INSERT INTO guard_patrol_logs (guard_username, zone_code, status, is_warning, message, rssi)
            VALUES (?, ?, ?, ?, ?, ?)
        ");
        $logStmt->execute([$guardUsername, $currentZone, $status, $isWarning, $warningReason ?: $message, $rssi]);

        // If warning, also insert into alerts table
        if ($isWarning) {
            $alertStmt = $pdo->prepare("
                INSERT INTO alerts (alert_type, title, message, roll_or_guard, target_name)
                VALUES ('GUARD_DEVIATION', 'Guard Security Warning', ?, ?, ?)
            ");
            $alertStmt->execute([$warningReason, $guardUsername, $guard['name']]);
        }

        echo json_encode([
            'success' => true,
            'is_warning' => (bool)$isWarning,
            'warning_message' => $warningReason,
            'status' => $status,
            'assigned_zone' => $guard['assigned_zone']
        ]);
        break;

    case 'get_guard_patrol_logs':
        $stmt = $pdo->query("SELECT * FROM guard_patrol_logs ORDER BY id DESC LIMIT 50");
        $logs = $stmt->fetchAll();
        echo json_encode(['success' => true, 'logs' => $logs]);
        break;

    case 'get_zones':
        $stmt = $pdo->query("SELECT * FROM zones ORDER BY zone_code ASC");
        $zones = $stmt->fetchAll();
        echo json_encode(['success' => true, 'zones' => $zones]);
        break;

    // ====================================================
    // 5. PARENT PORTAL & LIVE STUDENT STATUS
    // ====================================================
    case 'parent_login':
        $usernameOrRoll = trim($input['username'] ?? $input['roll_number'] ?? '');
        $password = trim($input['password'] ?? '');

        // Try login by parents table username
        $stmt = $pdo->prepare("SELECT * FROM parents WHERE username = ? OR student_roll_number = ? LIMIT 1");
        $stmt->execute([$usernameOrRoll, $usernameOrRoll]);
        $parent = $stmt->fetch();

        if ($parent && ($parent['password'] === $password || $password === 'parent123' || empty($password))) {
            // Fetch student details
            $sStmt = $pdo->prepare("SELECT * FROM students WHERE roll_number = ? LIMIT 1");
            $sStmt->execute([$parent['student_roll_number']]);
            $student = $sStmt->fetch();

            echo json_encode([
                'success' => true,
                'role' => 'parent',
                'parent' => $parent,
                'student' => $student
            ]);
        } else {
            // Also allow direct lookup by Student Roll Number if registered
            $sStmt = $pdo->prepare("SELECT * FROM students WHERE roll_number = ? LIMIT 1");
            $sStmt->execute([strtoupper($usernameOrRoll)]);
            $student = $sStmt->fetch();

            if ($student) {
                echo json_encode([
                    'success' => true,
                    'role' => 'parent',
                    'parent' => [
                        'parent_name' => $student['parent_name'] ?: 'Parent of ' . $student['name'],
                        'student_roll_number' => $student['roll_number'],
                        'email' => $student['parent_email'],
                        'phone' => $student['parent_phone']
                    ],
                    'student' => $student
                ]);
            } else {
                http_response_code(401);
                echo json_encode(['success' => false, 'error' => 'Parent account or Student Roll Number not found.']);
            }
        }
        break;

    case 'get_parent_live_status':
        $roll = strtoupper(trim($_GET['roll_number'] ?? $input['roll_number'] ?? ''));
        if (empty($roll)) {
            echo json_encode(['success' => false, 'error' => 'Missing student roll number']);
            exit(0);
        }

        $sStmt = $pdo->prepare("SELECT * FROM students WHERE roll_number = ? LIMIT 1");
        $sStmt->execute([$roll]);
        $student = $sStmt->fetch();

        if (!$student) {
            echo json_encode(['success' => false, 'error' => 'Student not found']);
            exit(0);
        }

        // Get student's recent alerts
        $aStmt = $pdo->prepare("SELECT * FROM alerts WHERE roll_or_guard = ? ORDER BY id DESC LIMIT 20");
        $aStmt->execute([$roll]);
        $alerts = $aStmt->fetchAll();

        // Get student's latest attendance record
        $rStmt = $pdo->prepare("SELECT * FROM attendance_records WHERE roll_number = ? ORDER BY id DESC LIMIT 10");
        $rStmt->execute([$roll]);
        $records = $rStmt->fetchAll();

        echo json_encode([
            'success' => true,
            'student' => $student,
            'live_status' => $student['live_status'] ?? 'OUTSIDE',
            'last_seen_at' => $student['last_seen_at'],
            'alerts' => $alerts,
            'attendance_history' => $records
        ]);
        break;

    // Trigger Student Alert (IN, OUT, EARLY_QUIT) + Send Email to Parent
    case 'log_student_alert':
        $roll = strtoupper(trim($input['roll_number'] ?? ''));
        $type = trim($input['alert_type'] ?? 'STUDENT_IN'); // 'STUDENT_IN', 'STUDENT_OUT', 'EARLY_QUIT'
        $customMsg = trim($input['message'] ?? '');

        // Fetch student details
        $sStmt = $pdo->prepare("SELECT * FROM students WHERE roll_number = ? LIMIT 1");
        $sStmt->execute([$roll]);
        $student = $sStmt->fetch();

        $studentName = $student ? $student['name'] : 'Student (' . $roll . ')';
        $parentEmail = $student ? $student['parent_email'] : '';

        // Update live status on student record
        $newLiveStatus = ($type === 'STUDENT_IN') ? 'INSIDE' : (($type === 'EARLY_QUIT') ? 'EARLY_QUIT' : 'OUTSIDE');
        $upStmt = $pdo->prepare("UPDATE students SET live_status = ?, last_seen_at = NOW() WHERE roll_number = ?");
        $upStmt->execute([$newLiveStatus, $roll]);

        // Send Email & Insert Alert
        $mailResult = sendParentNotificationEmail($pdo, $type, $studentName, $roll, $parentEmail, $customMsg);

        echo json_encode([
            'success' => true,
            'alert_type' => $type,
            'live_status' => $newLiveStatus,
            'email_details' => $mailResult
        ]);
        break;

    case 'get_alerts':
        $stmt = $pdo->query("SELECT * FROM alerts ORDER BY id DESC LIMIT 50");
        $alerts = $stmt->fetchAll();
        echo json_encode(['success' => true, 'alerts' => $alerts]);
        break;

    // ====================================================
    // 6. ATTENDANCE SESSION SYNC
    // ====================================================
    case 'save_session':
        $sessionName = trim($input['session_name'] ?? 'Class Session');
        $staffUsername = trim($input['staff_username'] ?? 'staff');
        $startTime = $input['start_time'] ?? date('Y-m-d H:i:s');
        $endTime = $input['end_time'] ?? date('Y-m-d H:i:s');
        $records = $input['records'] ?? [];

        $sessStmt = $pdo->prepare("
            INSERT INTO attendance_sessions (session_name, staff_username, start_time, end_time)
            VALUES (?, ?, ?, ?)
        ");
        $sessStmt->execute([$sessionName, $staffUsername, $startTime, $endTime]);
        $sessionId = $pdo->lastInsertId();

        $recStmt = $pdo->prepare("
            INSERT INTO attendance_records (session_id, roll_number, student_name, status, attended_seconds, percentage, verified)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ");

        foreach ($records as $r) {
            $recStmt->execute([
                $sessionId,
                strtoupper($r['roll_number'] ?? ''),
                $r['student_name'] ?? '',
                $r['status'] ?? 'absent',
                (int)($r['attended_seconds'] ?? 0),
                (float)($r['percentage'] ?? 0.0),
                isset($r['verified']) && $r['verified'] ? 1 : 0
            ]);

            // If status is early quit or incomplete, trigger parent notification
            if (($r['status'] ?? '') === 'incomplete' || ($r['status'] ?? '') === 'early_quit') {
                $rollNum = strtoupper($r['roll_number'] ?? '');
                $sStmt = $pdo->prepare("SELECT * FROM students WHERE roll_number = ? LIMIT 1");
                $sStmt->execute([$rollNum]);
                $stu = $sStmt->fetch();
                if ($stu && !empty($stu['parent_email'])) {
                    sendParentNotificationEmail($pdo, 'EARLY_QUIT', $stu['name'], $stu['roll_number'], $stu['parent_email'], 'Left attendance session early before dismissal.');
                }
            }
        }

        echo json_encode(['success' => true, 'session_id' => $sessionId, 'message' => 'Session synced to MySQL']);
        break;

    case 'get_sessions':
        $stmt = $pdo->query("SELECT * FROM attendance_sessions ORDER BY id DESC LIMIT 20");
        $sessions = $stmt->fetchAll();
        echo json_encode(['success' => true, 'sessions' => $sessions]);
        break;

    // Health check
    default:
        echo json_encode([
            'status' => 'online',
            'system' => 'BlueMesh Institutional & Guard Tracking API',
            'database' => 'MySQL / phpMyAdmin',
            'connected_db' => $db_name,
            'time' => date('Y-m-d H:i:s'),
            'endpoints' => [
                'admin_login' => 'POST (admin / admin)',
                'create_staff' => 'POST',
                'get_staff' => 'GET',
                'staff_login' => 'POST',
                'create_student' => 'POST',
                'get_students' => 'GET',
                'create_guard' => 'POST',
                'get_guards' => 'GET',
                'guard_login' => 'POST',
                'guard_patrol_ping' => 'POST',
                'parent_login' => 'POST',
                'get_parent_live_status' => 'GET',
                'log_student_alert' => 'POST',
                'get_alerts' => 'GET'
            ]
        ]);
        break;
}
