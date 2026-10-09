import React, { useState } from 'react';
import { 
  CalendarCheck, 
  Clock, 
  CheckCircle, 
  AlertCircle, 
  XCircle, 
  Fingerprint, 
  Plus, 
  User, 
  Filter 
} from 'lucide-react';

export function AttendanceTab({ 
  sessions = [], 
  attendanceRecords = [], 
  onSaveSession 
}) {
  const [selectedSessionId, setSelectedSessionId] = useState(sessions[0]?.id || 1);
  const [statusFilter, setStatusFilter] = useState('ALL');

  const currentSession = sessions.find(s => s.id === selectedSessionId) || sessions[0];
  const recordsForSession = attendanceRecords.filter(r => {
    const matchesSession = r.session_id === (currentSession?.id || 1);
    const matchesStatus = statusFilter === 'ALL' || r.status === statusFilter;
    return matchesSession && matchesStatus;
  });

  return (
    <div>
      {/* Header */}
      <div style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        marginBottom: '20px',
        flexWrap: 'wrap',
        gap: '16px'
      }}>
        <div>
          <h2 style={{ fontSize: '1.4rem', fontWeight: 800 }}>Smart Attendance Sessions & BLE Sync</h2>
          <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>
            Automated session duration computation, biometric matching, and real-time early departure detection
          </p>
        </div>

        <div style={{ display: 'flex', gap: '10px' }}>
          <span className="badge badge-primary">
            <CalendarCheck size={14} /> {sessions.length} Recorded Sessions
          </span>
        </div>
      </div>

      {/* Session Selection Selector */}
      <div className="glass-panel" style={{ padding: '16px 20px', marginBottom: '20px', display: 'flex', gap: '16px', alignItems: 'center', flexWrap: 'wrap', justifyContent: 'space-between' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px', flex: 1, minWidth: '280px' }}>
          <label style={{ fontSize: '0.85rem', fontWeight: 700, color: '#fff', whiteSpace: 'nowrap' }}>
            Active Session:
          </label>
          <select 
            value={selectedSessionId} 
            onChange={(e) => setSelectedSessionId(Number(e.target.value))}
            className="select-field"
            style={{ maxWidth: '400px' }}
          >
            {sessions.map(s => (
              <option key={s.id} value={s.id}>
                {s.session_name} (by @{s.staff_username})
              </option>
            ))}
          </select>
        </div>

        {/* Filter by status */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>Filter Status:</span>
          <select 
            value={statusFilter} 
            onChange={(e) => setStatusFilter(e.target.value)}
            className="select-field"
            style={{ width: '150px' }}
          >
            <option value="ALL">All Statuses</option>
            <option value="present">Present</option>
            <option value="early_quit">Early Quit</option>
            <option value="absent">Absent</option>
          </select>
        </div>
      </div>

      {/* Session Info Bar */}
      {currentSession && (
        <div className="glass-panel" style={{
          padding: '16px 22px',
          marginBottom: '20px',
          background: 'rgba(59, 130, 246, 0.08)',
          border: '1px solid rgba(59, 130, 246, 0.25)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          flexWrap: 'wrap',
          gap: '14px'
        }}>
          <div>
            <div style={{ fontSize: '1.05rem', fontWeight: 800, color: '#fff' }}>
              {currentSession.session_name}
            </div>
            <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)', display: 'flex', gap: '12px', marginTop: '2px' }}>
              <span>Faculty: <strong style={{ color: '#93c5fd' }}>@{currentSession.staff_username}</strong></span>
              <span>•</span>
              <span>Start: {currentSession.start_time}</span>
              <span>•</span>
              <span>End: {currentSession.end_time || 'In Progress'}</span>
            </div>
          </div>

          <div style={{ display: 'flex', gap: '10px' }}>
            <span className="badge badge-success">
              Present: {recordsForSession.filter(r => r.status === 'present').length}
            </span>
            <span className="badge badge-danger">
              Early Quit: {recordsForSession.filter(r => r.status === 'early_quit').length}
            </span>
            <span className="badge badge-subtle">
              Absent: {recordsForSession.filter(r => r.status === 'absent').length}
            </span>
          </div>
        </div>
      )}

      {/* Attendance Records Table */}
      <div className="glass-panel table-container">
        <table className="data-table">
          <thead>
            <tr>
              <th>Roll Number</th>
              <th>Student Name</th>
              <th>Attendance Status</th>
              <th>Time Attended</th>
              <th>Completion %</th>
              <th>Biometric Verification</th>
              <th>Recorded At</th>
            </tr>
          </thead>
          <tbody>
            {recordsForSession.length === 0 ? (
              <tr>
                <td colSpan="7" style={{ textAlign: 'center', padding: '40px', color: 'var(--text-muted)' }}>
                  No attendance records recorded for this session.
                </td>
              </tr>
            ) : (
              recordsForSession.map(r => (
                <tr key={r.id || r.roll_number}>
                  <td>
                    <span className="code-pill">{r.roll_number}</span>
                  </td>
                  <td>
                    <div style={{ fontWeight: 700, color: '#fff' }}>{r.student_name}</div>
                  </td>
                  <td>
                    {r.status === 'present' && <span className="badge badge-success"><CheckCircle size={12} /> Present</span>}
                    {r.status === 'early_quit' && <span className="badge badge-danger"><AlertCircle size={12} /> Early Quit</span>}
                    {r.status === 'incomplete' && <span className="badge badge-warning"><AlertCircle size={12} /> Incomplete</span>}
                    {r.status === 'absent' && <span className="badge badge-subtle"><XCircle size={12} /> Absent</span>}
                  </td>
                  <td>
                    <div style={{ fontFamily: 'var(--font-mono)', fontSize: '0.8rem', color: 'var(--text-main)' }}>
                      {Math.floor(r.attended_seconds / 60)}m {r.attended_seconds % 60}s
                    </div>
                  </td>
                  <td style={{ minWidth: '160px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                      <div style={{
                        flex: 1,
                        height: '6px',
                        background: 'rgba(255,255,255,0.08)',
                        borderRadius: '999px',
                        overflow: 'hidden'
                      }}>
                        <div style={{
                          height: '100%',
                          width: `${Math.min(100, r.percentage)}%`,
                          background: r.percentage >= 85 ? '#10b981' : r.percentage >= 50 ? '#f59e0b' : '#ef4444'
                        }} />
                      </div>
                      <span style={{ fontSize: '0.78rem', fontFamily: 'var(--font-mono)', fontWeight: 600 }}>
                        {r.percentage.toFixed(1)}%
                      </span>
                    </div>
                  </td>
                  <td>
                    {r.verified ? (
                      <span className="badge badge-purple">
                        <Fingerprint size={13} /> Biometric Verified
                      </span>
                    ) : (
                      <span className="badge badge-subtle">
                        Unverified
                      </span>
                    )}
                  </td>
                  <td>
                    <span style={{ fontFamily: 'var(--font-mono)', fontSize: '0.75rem', color: 'var(--text-dim)' }}>
                      {r.created_at || 'Automatic sync'}
                    </span>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
