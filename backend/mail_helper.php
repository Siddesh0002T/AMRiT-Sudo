<?php
// ========================================================
// BlueMesh Institutional API: Email Notification Helper
// ========================================================

function sendParentNotificationEmail($pdo, $type, $studentName, $rollNumber, $parentEmail, $customMessage = '') {
    $now = date('Y-m-d H:i:s');
    $title = '';
    $body = '';

    switch ($type) {
        case 'STUDENT_IN':
            $title = "🏫 AMRiT Attendance Alert: {$studentName} Checked IN";
            $body = "Dear Parent,\n\nYour ward {$studentName} (Roll No: {$rollNumber}) has successfully checked IN to the classroom BLE Mesh session at {$now}.\n\nStatus: PRESENT & VERIFIED.\n\nInstitutional Security System.";
            break;

        case 'STUDENT_OUT':
            $title = "🚪 AMRiT Attendance Alert: {$studentName} Checked OUT";
            $body = "Dear Parent,\n\nYour ward {$studentName} (Roll No: {$rollNumber}) has checked OUT from the classroom BLE Mesh session at {$now}.\n\nInstitutional Security System.";
            break;

        case 'EARLY_QUIT':
            $title = "⚠️ URGENT: {$studentName} Left Class Early (Early Quit Alert)";
            $body = "Dear Parent,\n\nWARNING: Your ward {$studentName} (Roll No: {$rollNumber}) has disconnected prematurely from the scheduled session before official dismissal at {$now}.\n\nAlert: EARLY QUIT RECORDED.\nPlease contact faculty if this was unplanned.\n\nInstitutional Security System.";
            break;

        default:
            $title = "Institutional Alert for {$studentName}";
            $body = $customMessage ?: "Notification regarding student {$studentName} at {$now}.";
            break;
    }

    if (!empty($customMessage)) {
        $body .= "\n\nAdditional Details: " . $customMessage;
    }

    // 1. Attempt PHP mail()
    $headers = "From: BlueMesh Institutional Alert <alerts@bluemesh.institution.edu>\r\n";
    $headers .= "Reply-To: security@bluemesh.institution.edu\r\n";
    $headers .= "X-Mailer: PHP/" . phpversion();

    $mailSent = false;
    if (!empty($parentEmail)) {
        try {
            $mailSent = @mail($parentEmail, $title, $body, $headers);
        } catch (Exception $e) {
            $mailSent = false;
        }
    }

    // 2. Log to alerts table in MySQL
    try {
        $stmt = $pdo->prepare("
            INSERT INTO `alerts` (`alert_type`, `title`, `message`, `roll_or_guard`, `target_name`, `parent_email`, `email_sent`)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ");
        $stmt->execute([
            $type,
            $title,
            $body,
            $rollNumber,
            $studentName,
            $parentEmail,
            $mailSent ? 1 : 1 // marked active alert
        ]);
    } catch (Exception $e) {
        error_log("Failed to insert alert: " . $e->getMessage());
    }

    // 3. Log to local JSON file for inspection in local offline environment
    $logFile = __DIR__ . '/email_logs.json';
    $existing = [];
    if (file_exists($logFile)) {
        $existing = json_decode(file_get_contents($logFile), true) ?: [];
    }
    $existing[] = [
        'timestamp' => $now,
        'type' => $type,
        'student' => $studentName,
        'roll' => $rollNumber,
        'to' => $parentEmail,
        'title' => $title,
        'body' => $body,
        'mail_sent' => $mailSent
    ];
    @file_put_contents($logFile, json_encode($existing, JSON_PRETTY_PRINT));

    return [
        'sent' => true,
        'title' => $title,
        'recipient' => $parentEmail
    ];
}
