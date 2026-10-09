import React, { useState, useEffect } from 'react';
import { Navbar } from './components/Navbar';
import { Sidebar } from './components/Sidebar';

// Tabs
import { OverviewTab } from './components/tabs/OverviewTab';
import { StudentsTab } from './components/tabs/StudentsTab';
import { GuardsTab } from './components/tabs/GuardsTab';
import { BeaconsTab } from './components/tabs/BeaconsTab';
import { PatrolLogsTab } from './components/tabs/PatrolLogsTab';
import { ZonesTab } from './components/tabs/ZonesTab';
import { AttendanceTab } from './components/tabs/AttendanceTab';
import { ParentsTab } from './components/tabs/ParentsTab';
import { StaffTab } from './components/tabs/StaffTab';
import { AlertsTab } from './components/tabs/AlertsTab';

// Modals
import { ApiSettingsModal } from './components/modals/ApiSettingsModal';
import { AddStudentModal } from './components/modals/AddStudentModal';
import { AddGuardModal } from './components/modals/AddGuardModal';
import { AddStaffModal } from './components/modals/AddStaffModal';
import { SimulatorModal } from './components/modals/SimulatorModal';

// Mock and Services
import { 
  initialStudents, 
  initialGuards, 
  initialZones, 
  initialBeacons, 
  initialPatrolLogs, 
  initialPatrolVisits, 
  initialParents, 
  initialAlerts, 
  initialSessions, 
  initialAttendanceRecords, 
  initialStaff 
} from './data/mockData';
import { apiService } from './services/apiService';

export default function App() {
  const [activeTab, setActiveTab] = useState('overview');
  const [isSidebarCollapsed, setIsSidebarCollapsed] = useState(false);
  const [isLiveApi, setIsLiveApi] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');

  // Data State
  const [students, setStudents] = useState(() => {
    const saved = localStorage.getItem('bluemesh_students');
    return saved ? JSON.parse(saved) : initialStudents;
  });

  const [guards, setGuards] = useState(() => {
    const saved = localStorage.getItem('bluemesh_guards');
    return saved ? JSON.parse(saved) : initialGuards;
  });

  const [zones, setZones] = useState(initialZones);
  const [beacons, setBeacons] = useState(initialBeacons);

  const [patrolLogs, setPatrolLogs] = useState(() => {
    const saved = localStorage.getItem('bluemesh_logs');
    return saved ? JSON.parse(saved) : initialPatrolLogs;
  });

  const [patrolVisits, setPatrolVisits] = useState(() => {
    const saved = localStorage.getItem('bluemesh_visits');
    return saved ? JSON.parse(saved) : initialPatrolVisits;
  });

  const [parents, setParents] = useState(() => {
    const saved = localStorage.getItem('bluemesh_parents');
    return saved ? JSON.parse(saved) : initialParents;
  });

  const [alerts, setAlerts] = useState(() => {
    const saved = localStorage.getItem('bluemesh_alerts');
    return saved ? JSON.parse(saved) : initialAlerts;
  });

  const [sessions, setSessions] = useState(initialSessions);
  const [attendanceRecords, setAttendanceRecords] = useState(initialAttendanceRecords);

  const [staff, setStaff] = useState(() => {
    const saved = localStorage.getItem('bluemesh_staff');
    return saved ? JSON.parse(saved) : initialStaff;
  });

  // Modal Visibility States
  const [isApiSettingsOpen, setIsApiSettingsOpen] = useState(false);
  const [isStudentModalOpen, setIsStudentModalOpen] = useState(false);
  const [isGuardModalOpen, setIsGuardModalOpen] = useState(false);
  const [isStaffModalOpen, setIsStaffModalOpen] = useState(false);
  const [isSimulatorOpen, setIsSimulatorOpen] = useState(false);

  // Sync to local storage
  useEffect(() => {
    localStorage.setItem('bluemesh_students', JSON.stringify(students));
  }, [students]);

  useEffect(() => {
    localStorage.setItem('bluemesh_guards', JSON.stringify(guards));
  }, [guards]);

  useEffect(() => {
    localStorage.setItem('bluemesh_logs', JSON.stringify(patrolLogs));
  }, [patrolLogs]);

  useEffect(() => {
    localStorage.setItem('bluemesh_visits', JSON.stringify(patrolVisits));
  }, [patrolVisits]);

  useEffect(() => {
    localStorage.setItem('bluemesh_alerts', JSON.stringify(alerts));
  }, [alerts]);

  useEffect(() => {
    localStorage.setItem('bluemesh_staff', JSON.stringify(staff));
  }, [staff]);

  // Initial Check Health & Fetch from PHP Backend if running
  useEffect(() => {
    const initData = async () => {
      const health = await apiService.checkHealth();
      if (health.isLive) {
        setIsLiveApi(true);

        // Fetch live entities
        const [stuRes, gRes, zRes, bRes, aRes, sRes] = await Promise.all([
          apiService.getStudents(),
          apiService.getGuards(),
          apiService.getZones(),
          apiService.getPatrolBeacons(),
          apiService.getAlerts(),
          apiService.getStaff()
        ]);

        if (stuRes?.data?.students) setStudents(stuRes.data.students);
        if (gRes?.data?.guards) setGuards(gRes.data.guards);
        if (zRes?.data?.zones) setZones(zRes.data.zones);
        if (bRes?.data?.beacons) setBeacons(bRes.data.beacons);
        if (aRes?.data?.alerts) setAlerts(aRes.data.alerts);
        if (sRes?.data?.staff) setStaff(sRes.data.staff);
      } else {
        setIsLiveApi(false);
      }
    };

    initData();
  }, []);

  // Handlers for Student
  const handleAddStudent = async (studentData) => {
    if (isLiveApi) {
      await apiService.createStudent(studentData);
    }
    const newStudent = {
      id: Date.now(),
      ...studentData,
      live_status: 'OUTSIDE',
      last_seen_at: null,
      created_at: new Date().toISOString().replace('T', ' ').substring(0, 19)
    };
    setStudents(prev => [newStudent, ...prev]);

    if (studentData.parent_name || studentData.parent_email) {
      const newParent = {
        id: Date.now(),
        username: `parent_${studentData.roll_number.toLowerCase()}`,
        parent_name: studentData.parent_name || `Parent of ${studentData.name}`,
        email: studentData.parent_email,
        phone: studentData.parent_phone,
        student_roll_number: studentData.roll_number,
        created_at: new Date().toISOString().replace('T', ' ').substring(0, 19)
      };
      setParents(prev => [newParent, ...prev]);
    }
  };

  const handleDeleteStudent = async (roll_number) => {
    if (isLiveApi) {
      await apiService.deleteStudent(roll_number);
    }
    setStudents(prev => prev.filter(s => s.roll_number !== roll_number));
  };

  const handleUpdateStudentStatus = async (roll_number, alert_type, customMsg = '') => {
    const student = students.find(s => s.roll_number === roll_number);
    if (!student) return;

    const newLiveStatus = alert_type === 'STUDENT_IN' ? 'INSIDE' : alert_type === 'EARLY_QUIT' ? 'EARLY_QUIT' : 'OUTSIDE';
    const now = new Date().toISOString().replace('T', ' ').substring(0, 19);

    if (isLiveApi) {
      await apiService.logStudentAlert(roll_number, alert_type, customMsg);
    }

    setStudents(prev => prev.map(s => s.roll_number === roll_number ? {
      ...s,
      live_status: newLiveStatus,
      last_seen_at: now
    } : s));

    // Create alert record
    const title = alert_type === 'STUDENT_IN' 
      ? 'Student Checked IN' 
      : alert_type === 'EARLY_QUIT' 
      ? '⚠️ Early Quit Alert!' 
      : 'Student Departure Logged';

    const msg = customMsg || (
      alert_type === 'STUDENT_IN'
        ? `${student.name} (${student.roll_number}) entered the BLE Mesh classroom perimeter.`
        : alert_type === 'EARLY_QUIT'
        ? `${student.name} (${student.roll_number}) disconnected from BLE session prior to dismissal. Early quit recorded!`
        : `${student.name} (${student.roll_number}) exited the campus perimeter.`
    );

    const newAlert = {
      id: Date.now(),
      alert_type,
      title,
      message: msg,
      roll_or_guard: roll_number,
      target_name: student.name,
      parent_email: student.parent_email,
      email_sent: 1,
      created_at: now
    };

    setAlerts(prev => [newAlert, ...prev]);
    return { live_status: newLiveStatus };
  };

  // Handlers for Guard
  const handleAddGuard = async (guardData) => {
    if (isLiveApi) {
      await apiService.createGuard(guardData);
    }
    const newGuard = {
      id: Date.now(),
      ...guardData,
      status: 'idle',
      battery_pct: 100,
      last_ping_at: null,
      created_at: new Date().toISOString().replace('T', ' ').substring(0, 19)
    };
    setGuards(prev => [newGuard, ...prev]);
  };

  const handleGuardPing = async (pingData) => {
    let result = null;
    if (isLiveApi) {
      const res = await apiService.guardPatrolPing(pingData);
      if (res?.data) result = res.data;
    }

    const guard = guards.find(g => g.username === pingData.username);
    const assignedZone = guard ? guard.assigned_zone : 'ZONE-A';
    const isWarning = pingData.status.includes('warning') || pingData.current_zone !== assignedZone;
    const finalStatus = isWarning ? (pingData.status === 'warning_inactive' ? 'warning_inactive' : 'warning_deviation') : pingData.status;
    const now = new Date().toISOString().replace('T', ' ').substring(0, 19);

    setGuards(prev => prev.map(g => g.username === pingData.username ? {
      ...g,
      status: finalStatus,
      battery_pct: pingData.battery,
      last_ping_at: now
    } : g));

    const warnReason = isWarning 
      ? (pingData.status === 'warning_inactive'
          ? `⚠️ INACTIVITY ALERT: Guard ${guard?.name} has been stationary too long in ${pingData.current_zone}!`
          : `⚠️ ZONE VIOLATION: Guard ${guard?.name} is outside assigned zone (${assignedZone}) in ${pingData.current_zone}!`)
      : (pingData.message || 'Patrol checkpoint verified');

    const newLog = {
      id: Date.now(),
      guard_username: pingData.username,
      zone_code: pingData.current_zone,
      status: finalStatus,
      is_warning: isWarning ? 1 : 0,
      message: warnReason,
      rssi: pingData.rssi,
      timestamp: now
    };
    setPatrolLogs(prev => [newLog, ...prev]);

    if (isWarning) {
      const newAlert = {
        id: Date.now(),
        alert_type: 'GUARD_DEVIATION',
        title: '⚠️ Guard Security Warning',
        message: warnReason,
        roll_or_guard: pingData.username,
        target_name: guard?.name || pingData.username,
        parent_email: '',
        email_sent: 0,
        created_at: now
      };
      setAlerts(prev => [newAlert, ...prev]);
    }

    return result || {
      success: true,
      is_warning: isWarning,
      warning_message: isWarning ? warnReason : '',
      status: finalStatus
    };
  };

  // Handlers for Beacon Verification
  const handleVerifyBeacon = async (data) => {
    let result = null;
    if (isLiveApi) {
      const res = await apiService.verifyBeaconCheckpoint(data);
      if (res?.data) result = res.data;
    }

    const guard = guards.find(g => g.username === data.guard_username);
    const isMismatch = guard && guard.assigned_zone && guard.assigned_zone !== data.zone_code;
    const now = new Date().toISOString().replace('T', ' ').substring(0, 19);

    const newVisit = {
      id: Date.now(),
      guard_username: data.guard_username,
      guard_name: guard?.name,
      assigned_zone: guard?.assigned_zone,
      beacon_code: data.beacon_code,
      checkpoint_name: data.checkpoint_name,
      zone_code: data.zone_code,
      rssi: data.rssi,
      is_verified: 1,
      visited_at: now
    };
    setPatrolVisits(prev => [newVisit, ...prev]);

    // Update guard status
    setGuards(prev => prev.map(g => g.username === data.guard_username ? {
      ...g,
      status: isMismatch ? 'warning_deviation' : 'patrolling',
      last_ping_at: now
    } : g));

    // Log telemetry
    const msg = `Physical checkpoint verified via Bluetooth beacon ${data.beacon_code} (${data.checkpoint_name}) with RSSI: ${data.rssi} dBm` +
      (isMismatch ? ` [ANTI-CHEAT WARNING: Checkpoint is in ${data.zone_code}, but guard is assigned to ${guard?.assigned_zone}!]` : '');

    const newLog = {
      id: Date.now(),
      guard_username: data.guard_username,
      zone_code: data.zone_code,
      status: isMismatch ? 'warning_deviation' : 'patrolling',
      is_warning: isMismatch ? 1 : 0,
      message: msg,
      rssi: data.rssi,
      timestamp: now
    };
    setPatrolLogs(prev => [newLog, ...prev]);

    if (isMismatch) {
      const newAlert = {
        id: Date.now(),
        alert_type: 'GUARD_DEVIATION',
        title: '⚠️ Guard Zone Deviation Alert',
        message: `Guard ${data.guard_username} checked in at ${data.checkpoint_name} (${data.zone_code}) but is assigned to ${guard?.assigned_zone}.`,
        roll_or_guard: data.guard_username,
        target_name: guard?.name || data.guard_username,
        parent_email: '',
        email_sent: 0,
        created_at: now
      };
      setAlerts(prev => [newAlert, ...prev]);
    }

    return result || {
      success: true,
      is_zone_mismatch: Boolean(isMismatch),
      checkpoint_name: data.checkpoint_name,
      beacon_code: data.beacon_code,
      rssi: data.rssi,
      message: msg
    };
  };

  // Handlers for Staff
  const handleAddStaff = async (staffData) => {
    if (isLiveApi) {
      await apiService.createStaff(staffData);
    }
    const newMember = {
      id: Date.now(),
      ...staffData,
      created_at: new Date().toISOString().replace('T', ' ').substring(0, 19)
    };
    setStaff(prev => [newMember, ...prev]);
  };

  const handleDeleteStaff = async (id) => {
    if (isLiveApi) {
      await apiService.deleteStaff(id);
    }
    setStaff(prev => prev.filter(s => s.id !== id));
  };

  // Quick Simulation handler from Overview
  const handleQuickSimulate = (type, param) => {
    if (type === 'STUDENT_IN') {
      handleUpdateStudentStatus(param || '23CE001', 'STUDENT_IN');
    } else if (type === 'EARLY_QUIT') {
      handleUpdateStudentStatus(param || '23CE002', 'EARLY_QUIT');
    } else if (type === 'GUARD_PING') {
      handleGuardPing({
        username: 'guard1',
        current_zone: 'ZONE-A',
        status: 'patrolling',
        battery: 92,
        rssi: -66,
        message: 'Quick simulated perimeter sweep'
      });
    }
  };

  const studentsInside = students.filter(s => s.live_status === 'INSIDE').length;
  const guardWarnings = guards.filter(g => g.status.includes('warning')).length;

  return (
    <div className="app-container">
      {/* Sidebar Navigation */}
      <Sidebar 
        activeTab={activeTab}
        setActiveTab={setActiveTab}
        counts={{
          studentsInside,
          guardWarnings,
          beacons: beacons.length,
          totalAlerts: alerts.length
        }}
        isCollapsed={isSidebarCollapsed}
        setIsCollapsed={setIsSidebarCollapsed}
      />

      {/* Main Page Area */}
      <div className="main-content">
        <Navbar 
          activeTab={activeTab}
          setActiveTab={setActiveTab}
          isLiveApi={isLiveApi}
          onOpenSettings={() => setIsApiSettingsOpen(true)}
          alertsCount={alerts.length}
          searchQuery={searchQuery}
          setSearchQuery={setSearchQuery}
          onOpenSimulator={() => setIsSimulatorOpen(true)}
        />

        <main className="page-body">
          {activeTab === 'overview' && (
            <OverviewTab 
              students={students}
              guards={guards}
              beacons={beacons}
              zones={zones}
              alerts={alerts}
              visits={patrolVisits}
              sessions={sessions}
              onQuickSimulate={handleQuickSimulate}
              setActiveTab={setActiveTab}
            />
          )}

          {activeTab === 'students' && (
            <StudentsTab 
              students={students}
              onAddStudent={() => setIsStudentModalOpen(true)}
              onDeleteStudent={handleDeleteStudent}
              onUpdateStudentStatus={handleUpdateStudentStatus}
            />
          )}

          {activeTab === 'guards' && (
            <GuardsTab 
              guards={guards}
              zones={zones}
              onAddGuard={() => setIsGuardModalOpen(true)}
              onGuardPing={handleGuardPing}
            />
          )}

          {activeTab === 'beacons' && (
            <BeaconsTab 
              beacons={beacons}
              guards={guards}
              onVerifyBeacon={handleVerifyBeacon}
            />
          )}

          {activeTab === 'patrolLogs' && (
            <PatrolLogsTab 
              patrolLogs={patrolLogs}
              patrolVisits={patrolVisits}
            />
          )}

          {activeTab === 'zones' && (
            <ZonesTab 
              zones={zones}
              guards={guards}
              beacons={beacons}
              setActiveTab={setActiveTab}
            />
          )}

          {activeTab === 'attendance' && (
            <AttendanceTab 
              sessions={sessions}
              attendanceRecords={attendanceRecords}
              onSaveSession={() => {}}
            />
          )}

          {activeTab === 'parents' && (
            <ParentsTab 
              parents={parents}
              students={students}
              alerts={alerts}
            />
          )}

          {activeTab === 'staff' && (
            <StaffTab 
              staff={staff}
              onAddStaff={() => setIsStaffModalOpen(true)}
              onDeleteStaff={handleDeleteStaff}
            />
          )}

          {activeTab === 'alerts' && (
            <AlertsTab 
              alerts={alerts}
              onClearAlerts={() => setAlerts([])}
            />
          )}
        </main>
      </div>

      {/* Modals */}
      <ApiSettingsModal 
        isOpen={isApiSettingsOpen}
        onClose={() => setIsApiSettingsOpen(false)}
        onConnectionChanged={(live) => setIsLiveApi(live)}
      />

      <AddStudentModal 
        isOpen={isStudentModalOpen}
        onClose={() => setIsStudentModalOpen(false)}
        onSave={handleAddStudent}
      />

      <AddGuardModal 
        isOpen={isGuardModalOpen}
        onClose={() => setIsGuardModalOpen(false)}
        onSave={handleAddGuard}
        zones={zones}
      />

      <AddStaffModal 
        isOpen={isStaffModalOpen}
        onClose={() => setIsStaffModalOpen(false)}
        onSave={handleAddStaff}
      />

      <SimulatorModal 
        isOpen={isSimulatorOpen}
        onClose={() => setIsSimulatorOpen(false)}
        students={students}
        guards={guards}
        zones={zones}
        beacons={beacons}
        onSimulateStudent={handleUpdateStudentStatus}
        onSimulateGuardPing={handleGuardPing}
        onSimulateBeaconVisit={handleVerifyBeacon}
      />
    </div>
  );
}
