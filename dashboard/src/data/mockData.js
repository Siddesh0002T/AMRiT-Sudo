// Initial data mirroring bluemesh_db schema & SQL seeds

export const initialAdmins = [
  {
    id: 1,
    username: 'admin',
    name: 'System Administrator',
    created_at: '2026-10-09 08:00:00'
  }
];

export const initialStaff = [
  {
    id: 1,
    username: 'staff1',
    name: 'Prof. Alan Turing',
    email: 'alan@institution.edu',
    phone: '+91 98765 43201',
    department: 'Computer Science',
    role: 'Faculty Head',
    created_at: '2026-10-09 08:30:00'
  },
  {
    id: 2,
    username: 'staff2',
    name: 'Dr. Grace Hopper',
    email: 'grace@institution.edu',
    phone: '+91 98765 43202',
    department: 'Software Engineering',
    role: 'Faculty & Lab Director',
    created_at: '2026-10-09 08:35:00'
  },
  {
    id: 3,
    username: 'staff3',
    name: 'Dr. Claude Shannon',
    email: 'shannon@institution.edu',
    phone: '+91 98765 43203',
    department: 'Information Science',
    role: 'Associate Professor',
    created_at: '2026-10-09 09:15:00'
  }
];

export const initialStudents = [
  {
    id: 1,
    roll_number: '23CE001',
    name: 'Aarav Sharma',
    class_section: 'CS-A',
    email: 'aarav@student.edu',
    phone: '9876543210',
    is_fingerprint_registered: 1,
    parent_name: 'Rajesh Sharma',
    parent_email: 'parent.aarav@example.com',
    parent_phone: '9876500001',
    live_status: 'INSIDE',
    last_seen_at: '2026-10-09 09:00:00',
    created_at: '2026-10-09 08:00:00'
  },
  {
    id: 2,
    roll_number: '23CE002',
    name: 'Aditi Verma',
    class_section: 'CS-A',
    email: 'aditi@student.edu',
    phone: '9876543211',
    is_fingerprint_registered: 1,
    parent_name: 'Sunita Verma',
    parent_email: 'parent.aditi@example.com',
    parent_phone: '9876500002',
    live_status: 'EARLY_QUIT',
    last_seen_at: '2026-10-09 10:14:22',
    created_at: '2026-10-09 08:00:00'
  },
  {
    id: 3,
    roll_number: '23CE003',
    name: 'Rohan Mehta',
    class_section: 'CS-B',
    email: 'rohan@student.edu',
    phone: '9876543212',
    is_fingerprint_registered: 1,
    parent_name: 'Kailash Mehta',
    parent_email: 'parent.rohan@example.com',
    parent_phone: '9876500003',
    live_status: 'OUTSIDE',
    last_seen_at: '2026-10-09 07:45:10',
    created_at: '2026-10-09 08:00:00'
  },
  {
    id: 4,
    roll_number: '23CE004',
    name: 'Diya Patel',
    class_section: 'CS-B',
    email: 'diya@student.edu',
    phone: '9876543213',
    is_fingerprint_registered: 1,
    parent_name: 'Vikram Patel',
    parent_email: 'parent.diya@example.com',
    parent_phone: '9876500004',
    live_status: 'INSIDE',
    last_seen_at: '2026-10-09 08:55:00',
    created_at: '2026-10-09 08:00:00'
  },
  {
    id: 5,
    roll_number: '23CE005',
    name: 'Kabir Sengupta',
    class_section: 'CS-A',
    email: 'kabir@student.edu',
    phone: '9876543214',
    is_fingerprint_registered: 0,
    parent_name: 'Ananya Sengupta',
    parent_email: 'parent.kabir@example.com',
    parent_phone: '9876500005',
    live_status: 'OUTSIDE',
    last_seen_at: null,
    created_at: '2026-10-09 08:00:00'
  }
];

export const initialGuards = [
  {
    id: 1,
    username: 'guard1',
    name: 'Officer Vikram Singh',
    phone: '9876543299',
    assigned_zone: 'ZONE-A',
    status: 'patrolling',
    battery_pct: 94,
    last_ping_at: '2026-10-09 10:45:00',
    created_at: '2026-10-09 07:00:00'
  },
  {
    id: 2,
    username: 'guard2',
    name: 'Officer Ramesh Kumar',
    phone: '9876543298',
    assigned_zone: 'ZONE-B',
    status: 'idle',
    battery_pct: 82,
    last_ping_at: '2026-10-09 10:30:15',
    created_at: '2026-10-09 07:00:00'
  },
  {
    id: 3,
    username: 'guard3',
    name: 'Officer Anjali Sharma',
    phone: '9876543297',
    assigned_zone: 'ZONE-C',
    status: 'warning_deviation',
    battery_pct: 68,
    last_ping_at: '2026-10-09 10:52:40',
    created_at: '2026-10-09 07:00:00'
  }
];

export const initialZones = [
  {
    id: 1,
    zone_code: 'ZONE-A',
    name: 'Zone A: Main Gate & Campus Perimeter',
    description: 'Main entrance checkpoint, visitor perimeter, and boundary wall.',
    max_inactivity_secs: 120,
    created_at: '2026-10-09 06:00:00'
  },
  {
    id: 2,
    zone_code: 'ZONE-B',
    name: 'Zone B: Academic Block & Science Labs',
    description: 'Classrooms, computing labs, and central administrative corridor.',
    max_inactivity_secs: 180,
    created_at: '2026-10-09 06:00:00'
  },
  {
    id: 3,
    zone_code: 'ZONE-C',
    name: 'Zone C: Sports Complex & Cafeteria',
    description: 'Auditorium, outdoor sports complex, and food court area.',
    max_inactivity_secs: 240,
    created_at: '2026-10-09 06:00:00'
  },
  {
    id: 4,
    zone_code: 'ZONE-D',
    name: 'Zone D: Student Hostels & Night Corridors',
    description: 'Boys/Girls residential hostels and night security check points.',
    max_inactivity_secs: 120,
    created_at: '2026-10-09 06:00:00'
  }
];

export const initialBeacons = [
  {
    id: 1,
    beacon_code: 'BCN-GATE-01',
    beacon_uuid: '0000AAA1-0000-1000-8000-00805F9B0001',
    zone_code: 'ZONE-A',
    checkpoint_name: 'North Main Gate Checkpoint',
    location_desc: 'Main entrance archway and vehicle barrier',
    target_rssi: -70,
    created_at: '2026-10-09 06:30:00'
  },
  {
    id: 2,
    beacon_code: 'BCN-PERIM-02',
    beacon_uuid: '0000AAA1-0000-1000-8000-00805F9B0002',
    zone_code: 'ZONE-A',
    checkpoint_name: 'East Perimeter Wall Pillar',
    location_desc: 'Boundary wall checkpoint pole #4',
    target_rssi: -75,
    created_at: '2026-10-09 06:30:00'
  },
  {
    id: 3,
    beacon_code: 'BCN-LAB-03',
    beacon_uuid: '0000AAA1-0000-1000-8000-00805F9B0003',
    zone_code: 'ZONE-B',
    checkpoint_name: 'Science Labs Corridor',
    location_desc: 'Physics & Computing lab entrance hallway',
    target_rssi: -65,
    created_at: '2026-10-09 06:30:00'
  },
  {
    id: 4,
    beacon_code: 'BCN-LIB-04',
    beacon_uuid: '0000AAA1-0000-1000-8000-00805F9B0004',
    zone_code: 'ZONE-B',
    checkpoint_name: 'Central Library Foyer',
    location_desc: 'Ground floor reading hall entry',
    target_rssi: -70,
    created_at: '2026-10-09 06:30:00'
  },
  {
    id: 5,
    beacon_code: 'BCN-SPRT-05',
    beacon_uuid: '0000AAA1-0000-1000-8000-00805F9B0005',
    zone_code: 'ZONE-C',
    checkpoint_name: 'Sports Complex & Pavilion',
    location_desc: 'Outdoor sports arena gate',
    target_rssi: -80,
    created_at: '2026-10-09 06:30:00'
  },
  {
    id: 6,
    beacon_code: 'BCN-CAFE-06',
    beacon_uuid: '0000AAA1-0000-1000-8000-00805F9B0006',
    zone_code: 'ZONE-C',
    checkpoint_name: 'Cafeteria & Food Court',
    location_desc: 'Dining arena and rear exit door',
    target_rssi: -75,
    created_at: '2026-10-09 06:30:00'
  },
  {
    id: 7,
    beacon_code: 'BCN-HSTL-07',
    beacon_uuid: '0000AAA1-0000-1000-8000-00805F9B0007',
    zone_code: 'ZONE-D',
    checkpoint_name: 'Hostel Block A Entrance',
    location_desc: 'Residential entrance and security desk',
    target_rssi: -68,
    created_at: '2026-10-09 06:30:00'
  },
  {
    id: 8,
    beacon_code: 'BCN-HSTL-08',
    beacon_uuid: '0000AAA1-0000-1000-8000-00805F9B0008',
    zone_code: 'ZONE-D',
    checkpoint_name: 'Night Security Corridor',
    location_desc: 'Rear pathway connecting Hostels B & C',
    target_rssi: -72,
    created_at: '2026-10-09 06:30:00'
  }
];

export const initialPatrolLogs = [
  {
    id: 1,
    guard_username: 'guard1',
    zone_code: 'ZONE-A',
    status: 'patrolling',
    is_warning: 0,
    message: 'Physical checkpoint verified via Bluetooth beacon BCN-GATE-01 (North Main Gate Checkpoint)',
    rssi: -66,
    timestamp: '2026-10-09 10:45:12'
  },
  {
    id: 2,
    guard_username: 'guard3',
    zone_code: 'ZONE-C',
    status: 'warning_deviation',
    is_warning: 1,
    message: '⚠️ ZONE VIOLATION: Guard Officer Anjali Sharma is outside assigned zone (ZONE-C) in ZONE-B!',
    rssi: -78,
    timestamp: '2026-10-09 10:52:40'
  },
  {
    id: 3,
    guard_username: 'guard2',
    zone_code: 'ZONE-B',
    status: 'patrolling',
    is_warning: 0,
    message: 'Checkpoint verified at Science Labs Corridor',
    rssi: -62,
    timestamp: '2026-10-09 10:30:15'
  }
];

export const initialPatrolVisits = [
  {
    id: 1,
    guard_username: 'guard1',
    guard_name: 'Officer Vikram Singh',
    assigned_zone: 'ZONE-A',
    beacon_code: 'BCN-GATE-01',
    checkpoint_name: 'North Main Gate Checkpoint',
    zone_code: 'ZONE-A',
    rssi: -66,
    is_verified: 1,
    visited_at: '2026-10-09 10:45:12'
  },
  {
    id: 2,
    guard_username: 'guard1',
    guard_name: 'Officer Vikram Singh',
    assigned_zone: 'ZONE-A',
    beacon_code: 'BCN-PERIM-02',
    checkpoint_name: 'East Perimeter Wall Pillar',
    zone_code: 'ZONE-A',
    rssi: -73,
    is_verified: 1,
    visited_at: '2026-10-09 10:15:30'
  },
  {
    id: 3,
    guard_username: 'guard2',
    guard_name: 'Officer Ramesh Kumar',
    assigned_zone: 'ZONE-B',
    beacon_code: 'BCN-LAB-03',
    checkpoint_name: 'Science Labs Corridor',
    zone_code: 'ZONE-B',
    rssi: -62,
    is_verified: 1,
    visited_at: '2026-10-09 10:30:15'
  }
];

export const initialParents = [
  {
    id: 1,
    username: 'parent_aarav',
    parent_name: 'Rajesh Sharma',
    email: 'parent.aarav@example.com',
    phone: '9876500001',
    student_roll_number: '23CE001',
    created_at: '2026-10-09 08:00:00'
  },
  {
    id: 2,
    username: 'parent_aditi',
    parent_name: 'Sunita Verma',
    email: 'parent.aditi@example.com',
    phone: '9876500002',
    student_roll_number: '23CE002',
    created_at: '2026-10-09 08:00:00'
  },
  {
    id: 3,
    username: 'parent_rohan',
    parent_name: 'Kailash Mehta',
    email: 'parent.rohan@example.com',
    phone: '9876500003',
    student_roll_number: '23CE003',
    created_at: '2026-10-09 08:00:00'
  }
];

export const initialAlerts = [
  {
    id: 1,
    alert_type: 'STUDENT_IN',
    title: 'Student Checked IN',
    message: 'Aarav Sharma has entered the BLE Mesh classroom zone at 09:00 AM.',
    roll_or_guard: '23CE001',
    target_name: 'Aarav Sharma',
    parent_email: 'parent.aarav@example.com',
    email_sent: 1,
    created_at: '2026-10-09 09:00:00'
  },
  {
    id: 2,
    alert_type: 'EARLY_QUIT',
    title: '⚠️ Early Quit Alert!',
    message: 'Aditi Verma disconnected from BLE session prior to dismissal. Early quit recorded!',
    roll_or_guard: '23CE002',
    target_name: 'Aditi Verma',
    parent_email: 'parent.aditi@example.com',
    email_sent: 1,
    created_at: '2026-10-09 10:14:22'
  },
  {
    id: 3,
    alert_type: 'GUARD_DEVIATION',
    title: '⚠️ Guard Zone Deviation Alert',
    message: 'Guard guard3 (Officer Anjali Sharma) checked in outside assigned patrol zone.',
    roll_or_guard: 'guard3',
    target_name: 'Officer Anjali Sharma',
    parent_email: '',
    email_sent: 0,
    created_at: '2026-10-09 10:52:40'
  }
];

export const initialSessions = [
  {
    id: 1,
    session_name: 'CS-301: Distributed Operating Systems',
    staff_username: 'staff1',
    start_time: '2026-10-09 09:00:00',
    end_time: '2026-10-09 10:30:00',
    created_at: '2026-10-09 09:00:00'
  },
  {
    id: 2,
    session_name: 'SE-204: Software Architecture & BLE Mesh',
    staff_username: 'staff2',
    start_time: '2026-10-09 10:30:00',
    end_time: '2026-10-09 12:00:00',
    created_at: '2026-10-09 10:30:00'
  }
];

export const initialAttendanceRecords = [
  {
    id: 1,
    session_id: 1,
    roll_number: '23CE001',
    student_name: 'Aarav Sharma',
    status: 'present',
    attended_seconds: 5400,
    percentage: 100.0,
    verified: 1,
    created_at: '2026-10-09 10:30:00'
  },
  {
    id: 2,
    session_id: 1,
    roll_number: '23CE002',
    student_name: 'Aditi Verma',
    status: 'early_quit',
    attended_seconds: 4462,
    percentage: 82.6,
    verified: 1,
    created_at: '2026-10-09 10:30:00'
  },
  {
    id: 3,
    session_id: 1,
    roll_number: '23CE003',
    student_name: 'Rohan Mehta',
    status: 'absent',
    attended_seconds: 0,
    percentage: 0.0,
    verified: 0,
    created_at: '2026-10-09 10:30:00'
  },
  {
    id: 4,
    session_id: 1,
    roll_number: '23CE004',
    student_name: 'Diya Patel',
    status: 'present',
    attended_seconds: 5120,
    percentage: 94.8,
    verified: 1,
    created_at: '2026-10-09 10:30:00'
  }
];
