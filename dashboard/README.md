# 🛡️ BlueMesh Institutional Security & Smart Attendance Dashboard

A modern, high-performance React command center for the **BlueMesh Institutional System** (`bluemesh_db`). Engineered with a sleek dark cyber-physical mesh aesthetic, glassmorphic UI, real-time BLE tracking, guard anti-cheat verification, and automated parent communication dispatches.

---

## 🚀 Key Features & Modules

### 1. 📊 Executive Command Center (`Overview`)
- **Key Performance Indicators (KPIs):** Real-time counters for registered students, active guards on duty, anti-cheat deviation warnings, and deployed hardware beacons.
- **Live Student Mesh Distribution:** Dynamic progress visualization showing students currently `INSIDE` class, flagged for `EARLY_QUIT`, or `OUTSIDE`.
- **Security Guard Telemetry Radar:** Guard status tracking with battery level indicators and real-time zone conformance checks.
- **Live Notification Ticker:** Streaming feed of student movements and security alerts with parent email delivery status.
- **Physical Checkpoint Scan Feed:** Audit logs of hardware Bluetooth beacon scans with signal RSSI meters.

### 2. 🎓 Students Directory & Live Presence Tracking
- **Table view** with filters for section (`CS-A`, `CS-B`, etc.) and live mesh status (`INSIDE`, `EARLY_QUIT`, `OUTSIDE`).
- **Biometric Fingerprint Badges:** Identifies registered biometric templates.
- **Parental Linking:** Shows linked guardian contact information (name, email, phone).
- **Interactive Triggers:** Simulate student check-in, early departure warnings, or dismissal exits on the fly.
- **Registration Modal:** Add new student records directly to MySQL with auto-generated parent accounts.

### 3. 🛡️ Guard Patrol Anti-Cheat & Telemetry Center
- **Officer Profile Cards:** Displays username, phone, assigned zone, device battery, and last telemetry ping.
- **Interactive Anti-Cheat Simulator:** Test zone violation logic (e.g. guard assigned to `ZONE-A` pinging from `ZONE-C` triggers immediate alarm), battery drainage, and stationary inactivity timers.
- **Enroll Guard Modal:** Register new security officers and assign patrol zones.

### 4. 📡 BLE Patrol Beacons (Physical Checkpoints)
- **Hardware Checkpoint Inventory:** Detailed cards for physical beacons (`BCN-GATE-01`, `BCN-LAB-03`, `BCN-LIB-04`, etc.), UUIDs, locations, and target RSSI thresholds.
- **Anti-Cheat Physical Scan Simulator:** Allows testing Bluetooth signal strength (`RSSI dBm`) and verifies whether the officer was physically present in their assigned perimeter.

### 5. 📋 Patrol Audit & Telemetry Logs
- Dual-mode viewer toggling between **Physical Checkpoint Visits** (`patrol_visits`) and **Patrol Telemetry Logs** (`guard_patrol_logs`).
- Signal strength visualizer with 4-bar RSSI meters.
- Flag filtering for anti-cheat violations.

### 6. 📍 Campus Explore Zones
- Geofenced perimeters: `ZONE-A` (Main Gate & Perimeter), `ZONE-B` (Academic Block & Labs), `ZONE-C` (Sports & Cafeteria), `ZONE-D` (Student Hostels).
- Maximum inactivity rules (e.g., 120s, 180s, 240s) and active guard mapping.

### 7. 🕒 Attendance Sessions & Smart Sync
- Multi-session browser (`attendance_sessions`): Course title, proctoring faculty username, start/end timestamps.
- Student session records (`attendance_records`): Percentage progress bars, attendance seconds, and biometric verification stamps.

### 8. 👨‍👩‍👧 Parent Portal Watch
- Directory of registered guardian accounts (`parents` table).
- **Live Family Safety Monitor:** Switch perspectives to preview what a parent sees in real time on their mobile web app, complete with automated arrival/early-departure email delivery timestamps.

### 9. 🏛️ Faculty & Staff Directory
- Comprehensive roster of academic staff, department affiliations, official contact info, and role permissions (`staff` table).
- Modal to enroll new faculty members.

### 10. 🔔 Realtime Alert Dispatches
- Real-time logging of `STUDENT_IN`, `STUDENT_OUT`, `EARLY_QUIT`, and `GUARD_DEVIATION` events.
- Dispatch confirmation flags for parent email delivery.

---

## 🛠️ Tech Stack & Architecture

- **Frontend:** React 19, Vite, Vanilla CSS Design System with custom dark glassmorphic tokens, CSS variables, and Lucide React icons.
- **Typography:** Plus Jakarta Sans & JetBrains Mono.
- **Backend Connector:** `src/services/apiService.js` connecting to PHP backend (`backend/api.php`).
- **Resilience Mode:** Automatic local state persistence in `localStorage` mirroring `bluemesh_db` initial seeds when PHP/MySQL is offline.

---

## 💻 Running the Application

### 1. Start the React Frontend Dashboard
```powershell
cd e:\hackThon\AMRiT-Sudo\dashboard
npm install
npm run dev
```
Open **[http://localhost:5173](http://localhost:5173)** in your browser.

### 2. Connect to the PHP & MySQL Backend (Optional)
To connect the dashboard directly to your live MySQL database (`bluemesh_db`), start the PHP built-in server in the backend directory:
```powershell
cd e:\hackThon\AMRiT-Sudo\backend
php -S localhost:8000
```
- In the dashboard top bar, click the **Connection Badge** (or the Settings icon).
- Verify the endpoint is set to `http://localhost:8000/api.php` and click **Save & Test Connection**.
- The badge will switch to **PHP API Live (Green)** and synchronize with your MySQL database!
