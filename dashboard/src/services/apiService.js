// Service to interact with BlueMesh PHP Backend (api.php)
// Features smart fallback to local reactive state when PHP/MySQL is offline.

const DEFAULT_API_BASE = 'http://localhost:8000/api.php';

export const getApiBaseUrl = () => {
  return localStorage.getItem('bluemesh_api_url') || DEFAULT_API_BASE;
};

export const setApiBaseUrl = (url) => {
  localStorage.setItem('bluemesh_api_url', url);
};

// Generic fetch wrapper with timeout
async function apiRequest(action, options = {}) {
  const baseUrl = getApiBaseUrl();
  const url = `${baseUrl}${baseUrl.includes('?') ? '&' : '?'}action=${action}`;

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 4000);

  try {
    const res = await fetch(url, {
      ...options,
      signal: controller.signal,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...(options.headers || {})
      }
    });
    clearTimeout(timeoutId);

    if (!res.ok) {
      throw new Error(`HTTP ${res.status}: ${res.statusText}`);
    }
    const data = await res.json();
    return { data, isLive: true };
  } catch (err) {
    clearTimeout(timeoutId);
    return { error: err.message, isLive: false };
  }
}

export const apiService = {
  async checkHealth() {
    return await apiRequest('');
  },

  // Staff endpoints
  async getStaff() {
    return await apiRequest('get_staff');
  },
  async createStaff(staffData) {
    return await apiRequest('create_staff', {
      method: 'POST',
      body: JSON.stringify(staffData)
    });
  },
  async deleteStaff(id) {
    return await apiRequest('delete_staff', {
      method: 'POST',
      body: JSON.stringify({ id })
    });
  },

  // Student endpoints
  async getStudents() {
    return await apiRequest('get_students');
  },
  async createStudent(studentData) {
    return await apiRequest('create_student', {
      method: 'POST',
      body: JSON.stringify(studentData)
    });
  },
  async deleteStudent(roll_number) {
    return await apiRequest('delete_student', {
      method: 'POST',
      body: JSON.stringify({ roll_number })
    });
  },
  async logStudentAlert(roll_number, alert_type, message = '') {
    return await apiRequest('log_student_alert', {
      method: 'POST',
      body: JSON.stringify({ roll_number, alert_type, message })
    });
  },
  async getParentLiveStatus(roll_number) {
    return await apiRequest(`get_parent_live_status&roll_number=${encodeURIComponent(roll_number)}`);
  },

  // Guard endpoints
  async getGuards() {
    return await apiRequest('get_guards');
  },
  async createGuard(guardData) {
    return await apiRequest('create_guard', {
      method: 'POST',
      body: JSON.stringify(guardData)
    });
  },
  async guardPatrolPing(pingData) {
    return await apiRequest('guard_patrol_ping', {
      method: 'POST',
      body: JSON.stringify(pingData)
    });
  },
  async getGuardPatrolLogs() {
    return await apiRequest('get_guard_patrol_logs');
  },
  async getGuardPatrolSummary(guard_username) {
    return await apiRequest(`get_guard_patrol_summary&guard_username=${encodeURIComponent(guard_username)}`);
  },

  // Zones & Beacons
  async getZones() {
    return await apiRequest('get_zones');
  },
  async getPatrolBeacons(zone_code = '') {
    const query = zone_code ? `&zone_code=${encodeURIComponent(zone_code)}` : '';
    return await apiRequest(`get_patrol_beacons${query}`);
  },
  async verifyBeaconCheckpoint(verificationData) {
    return await apiRequest('verify_beacon_checkpoint', {
      method: 'POST',
      body: JSON.stringify(verificationData)
    });
  },
  async getPatrolVisits(guard_username = '', limit = 50) {
    const q = guard_username ? `&guard_username=${encodeURIComponent(guard_username)}` : '';
    return await apiRequest(`get_patrol_visits${q}&limit=${limit}`);
  },

  // Alerts
  async getAlerts() {
    return await apiRequest('get_alerts');
  },

  // Attendance
  async getAttendanceSessions() {
    return await apiRequest('get_sessions');
  },
  async saveAttendanceSession(sessionData) {
    return await apiRequest('save_session', {
      method: 'POST',
      body: JSON.stringify(sessionData)
    });
  }
};
