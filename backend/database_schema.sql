-- ========================================================
-- BlueMesh Institutional System: MySQL & phpMyAdmin Schema
-- Database: bluemesh_db
-- ========================================================

CREATE DATABASE IF NOT EXISTS `bluemesh_db` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `bluemesh_db`;

-- 1. Admins Table (Default: admin / admin)
CREATE TABLE IF NOT EXISTS `admins` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `username` VARCHAR(50) NOT NULL UNIQUE,
    `password` VARCHAR(255) NOT NULL,
    `name` VARCHAR(100) DEFAULT 'System Administrator',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Seed default admin account
INSERT INTO `admins` (`username`, `password`, `name`) 
VALUES ('admin', 'admin', 'System Administrator')
ON DUPLICATE KEY UPDATE `password` = 'admin';

-- 2. Staff Table (Created by Admin)
CREATE TABLE IF NOT EXISTS `staff` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `username` VARCHAR(50) NOT NULL UNIQUE,
    `password` VARCHAR(255) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `email` VARCHAR(100) DEFAULT '',
    `phone` VARCHAR(20) DEFAULT '',
    `department` VARCHAR(100) DEFAULT 'Computer Science',
    `role` VARCHAR(50) DEFAULT 'Faculty',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Seed sample staff accounts for testing
INSERT INTO `staff` (`username`, `password`, `name`, `email`, `department`, `role`)
VALUES 
('staff1', 'staff123', 'Prof. Alan Turing', 'alan@institution.edu', 'Computer Science', 'Faculty'),
('staff2', 'staff123', 'Dr. Grace Hopper', 'grace@institution.edu', 'Software Engineering', 'Faculty')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

-- 3. Students Table (Created by Staff)
CREATE TABLE IF NOT EXISTS `students` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `roll_number` VARCHAR(50) NOT NULL UNIQUE,
    `name` VARCHAR(100) NOT NULL,
    `class_section` VARCHAR(50) DEFAULT 'CS-A',
    `email` VARCHAR(100) DEFAULT '',
    `phone` VARCHAR(20) DEFAULT '',
    `is_fingerprint_registered` TINYINT(1) DEFAULT 1,
    `parent_name` VARCHAR(100) DEFAULT '',
    `parent_email` VARCHAR(100) DEFAULT '',
    `parent_phone` VARCHAR(20) DEFAULT '',
    `live_status` VARCHAR(50) DEFAULT 'OUTSIDE', -- 'INSIDE', 'OUTSIDE', 'EARLY_QUIT'
    `last_seen_at` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Seed sample students
INSERT INTO `students` (`roll_number`, `name`, `class_section`, `email`, `phone`, `is_fingerprint_registered`, `parent_name`, `parent_email`, `parent_phone`)
VALUES 
('23CE001', 'Aarav Sharma', 'CS-A', 'aarav@student.edu', '9876543210', 1, 'Rajesh Sharma', 'parent.aarav@example.com', '9876500001'),
('23CE002', 'Aditi Verma', 'CS-A', 'aditi@student.edu', '9876543211', 1, 'Sunita Verma', 'parent.aditi@example.com', '9876500002'),
('23CE003', 'Rohan Mehta', 'CS-B', 'rohan@student.edu', '9876543212', 1, 'Kailash Mehta', 'parent.rohan@example.com', '9876500003')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

-- 4. Guards Table (Created by Staff/Admin)
CREATE TABLE IF NOT EXISTS `guards` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `username` VARCHAR(50) NOT NULL UNIQUE,
    `password` VARCHAR(255) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `phone` VARCHAR(20) DEFAULT '',
    `assigned_zone` VARCHAR(100) DEFAULT 'ZONE-A',
    `status` VARCHAR(50) DEFAULT 'idle', -- 'idle', 'patrolling', 'warning_deviation', 'warning_inactive'
    `battery_pct` INT DEFAULT 100,
    `last_ping_at` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Seed sample guard
INSERT INTO `guards` (`username`, `password`, `name`, `phone`, `assigned_zone`, `status`)
VALUES 
('guard1', 'guard123', 'Officer Vikram Singh', '9876543299', 'ZONE-A', 'idle'),
('guard2', 'guard123', 'Officer Ramesh Kumar', '9876543298', 'ZONE-B', 'idle')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

-- 5. Campus Explore Zones
CREATE TABLE IF NOT EXISTS `zones` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `zone_code` VARCHAR(50) NOT NULL UNIQUE,
    `name` VARCHAR(100) NOT NULL,
    `description` TEXT,
    `max_inactivity_secs` INT DEFAULT 120,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Seed Explore Zones
INSERT INTO `zones` (`zone_code`, `name`, `description`, `max_inactivity_secs`)
VALUES 
('ZONE-A', 'Zone A: Main Gate & Campus Perimeter', 'Main entrance checkpoint, visitor perimeter, and boundary wall.', 120),
('ZONE-B', 'Zone B: Academic Block & Science Labs', 'Classrooms, computing labs, and central administrative corridor.', 180),
('ZONE-C', 'Zone C: Sports Complex & Cafeteria', 'Auditorium, outdoor sports complex, and food court area.', 240),
('ZONE-D', 'Zone D: Student Hostels & Night Corridors', 'Boys/Girls residential hostels and night security check points.', 120)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

-- 6. Guard Patrol Telemetry & Logs
CREATE TABLE IF NOT EXISTS `guard_patrol_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `guard_username` VARCHAR(50) NOT NULL,
    `zone_code` VARCHAR(50) NOT NULL,
    `status` VARCHAR(50) NOT NULL, -- 'patrolling', 'warning_deviation', 'warning_inactive', 'completed'
    `is_warning` TINYINT(1) DEFAULT 0,
    `message` VARCHAR(255) DEFAULT '',
    `rssi` INT DEFAULT -65,
    `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 7. Parents Table (Created by Staff/Admin or Linked to Student)
CREATE TABLE IF NOT EXISTS `parents` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `username` VARCHAR(50) NOT NULL UNIQUE,
    `password` VARCHAR(255) NOT NULL,
    `parent_name` VARCHAR(100) NOT NULL,
    `email` VARCHAR(100) NOT NULL,
    `phone` VARCHAR(20) DEFAULT '',
    `student_roll_number` VARCHAR(50) NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Seed sample parents
INSERT INTO `parents` (`username`, `password`, `parent_name`, `email`, `phone`, `student_roll_number`)
VALUES 
('parent_aarav', 'parent123', 'Rajesh Sharma', 'parent.aarav@example.com', '9876500001', '23CE001'),
('parent_aditi', 'parent123', 'Sunita Verma', 'parent.aditi@example.com', '9876500002', '23CE002')
ON DUPLICATE KEY UPDATE `parent_name` = VALUES(`parent_name`);

-- 8. Alerts & Real-time Notifications (Live In/Out, Early Quit, Guard Deviation)
CREATE TABLE IF NOT EXISTS `alerts` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `alert_type` VARCHAR(50) NOT NULL, -- 'STUDENT_IN', 'STUDENT_OUT', 'EARLY_QUIT', 'GUARD_DEVIATION', 'GUARD_INACTIVE'
    `title` VARCHAR(150) NOT NULL,
    `message` TEXT NOT NULL,
    `roll_or_guard` VARCHAR(50) DEFAULT '',
    `target_name` VARCHAR(100) DEFAULT '',
    `parent_email` VARCHAR(100) DEFAULT '',
    `email_sent` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Seed sample alerts
INSERT INTO `alerts` (`alert_type`, `title`, `message`, `roll_or_guard`, `target_name`, `parent_email`, `email_sent`)
VALUES 
('STUDENT_IN', 'Student Checked IN', 'Aarav Sharma has entered the BLE Mesh classroom zone at 09:00 AM.', '23CE001', 'Aarav Sharma', 'parent.aarav@example.com', 1),
('EARLY_QUIT', '⚠️ Early Quit Alert!', 'Aditi Verma disconnected from BLE session prior to dismissal. Early quit recorded!', '23CE002', 'Aditi Verma', 'parent.aditi@example.com', 1);

-- 9. Attendance Sessions & Records
CREATE TABLE IF NOT EXISTS `attendance_sessions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `session_name` VARCHAR(100) NOT NULL,
    `staff_username` VARCHAR(50) DEFAULT 'staff',
    `start_time` DATETIME NOT NULL,
    `end_time` DATETIME NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `attendance_records` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `session_id` INT NOT NULL,
    `roll_number` VARCHAR(50) NOT NULL,
    `student_name` VARCHAR(100) NOT NULL,
    `status` VARCHAR(20) NOT NULL, -- 'present', 'absent', 'incomplete', 'early_quit'
    `attended_seconds` INT DEFAULT 0,
    `percentage` FLOAT DEFAULT 0,
    `verified` TINYINT(1) DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX (`session_id`),
    INDEX (`roll_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 10. Campus BLE Patrol Beacons (Physical Checkpoints for anti-cheat verification)
CREATE TABLE IF NOT EXISTS `patrol_beacons` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `beacon_code` VARCHAR(50) NOT NULL UNIQUE,
    `beacon_uuid` VARCHAR(100) NOT NULL,
    `zone_code` VARCHAR(50) NOT NULL,
    `checkpoint_name` VARCHAR(100) NOT NULL,
    `location_desc` VARCHAR(255) DEFAULT '',
    `target_rssi` INT DEFAULT -75,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `patrol_beacons` (`beacon_code`, `beacon_uuid`, `zone_code`, `checkpoint_name`, `location_desc`, `target_rssi`)
VALUES
('BCN-GATE-01', '0000AAA1-0000-1000-8000-00805F9B0001', 'ZONE-A', 'North Main Gate Checkpoint', 'Main entrance archway and vehicle barrier', -70),
('BCN-PERIM-02', '0000AAA1-0000-1000-8000-00805F9B0002', 'ZONE-A', 'East Perimeter Wall Pillar', 'Boundary wall checkpoint pole #4', -75),
('BCN-LAB-03', '0000AAA1-0000-1000-8000-00805F9B0003', 'ZONE-B', 'Science Labs Corridor', 'Physics & Computing lab entrance hallway', -65),
('BCN-LIB-04', '0000AAA1-0000-1000-8000-00805F9B0004', 'ZONE-B', 'Central Library Foyer', 'Ground floor reading hall entry', -70),
('BCN-SPRT-05', '0000AAA1-0000-1000-8000-00805F9B0005', 'ZONE-C', 'Sports Complex & Pavilion', 'Outdoor sports arena gate', -80),
('BCN-CAFE-06', '0000AAA1-0000-1000-8000-00805F9B0006', 'ZONE-C', 'Cafeteria & Food Court', 'Dining arena and rear exit door', -75),
('BCN-HSTL-07', '0000AAA1-0000-1000-8000-00805F9B0007', 'ZONE-D', 'Hostel Block A Entrance', 'Residential entrance and security desk', -68),
('BCN-HSTL-08', '0000AAA1-0000-1000-8000-00805F9B0008', 'ZONE-D', 'Night Security Corridor', 'Rear pathway connecting Hostels B & C', -72)
ON DUPLICATE KEY UPDATE `checkpoint_name` = VALUES(`checkpoint_name`);

-- 11. Guard Beacon Checkpoint Visits (Anti-Cheat Physical Verification)
CREATE TABLE IF NOT EXISTS `patrol_visits` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `guard_username` VARCHAR(50) NOT NULL,
    `beacon_code` VARCHAR(50) NOT NULL,
    `checkpoint_name` VARCHAR(100) NOT NULL,
    `zone_code` VARCHAR(50) NOT NULL,
    `rssi` INT NOT NULL,
    `is_verified` TINYINT(1) DEFAULT 1,
    `visited_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX (`guard_username`),
    INDEX (`zone_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
