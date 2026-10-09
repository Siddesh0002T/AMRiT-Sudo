import React, { useState } from 'react';
import { 
  HeartHandshake, 
  UserCheck, 
  Mail, 
  Phone, 
  Clock, 
  ShieldAlert, 
  CheckCircle2, 
  AlertTriangle,
  Radio
} from 'lucide-react';

export function ParentsTab({ 
  parents = [], 
  students = [], 
  alerts = [] 
}) {
  const [selectedRoll, setSelectedRoll] = useState(students[0]?.roll_number || '23CE001');

  const selectedStudent = students.find(s => s.roll_number === selectedRoll) || students[0];
  const studentAlerts = alerts.filter(a => a.roll_or_guard === selectedRoll);
  const parentObj = parents.find(p => p.student_roll_number === selectedRoll);

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
          <h2 style={{ fontSize: '1.4rem', fontWeight: 800 }}>Parent Portal & Live Student Safety Watch</h2>
          <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>
            Real-time automated parent communications, arrival/departure email alerts & student tracking
          </p>
        </div>

        <span className="badge badge-primary">
          <HeartHandshake size={14} /> {parents.length} Enrolled Families
        </span>
      </div>

      {/* Parent Perspective Simulator Screen */}
      <div className="glass-panel" style={{
        padding: '24px',
        marginBottom: '28px',
        border: '1px solid rgba(16, 185, 129, 0.3)',
        background: 'linear-gradient(180deg, rgba(16, 185, 129, 0.04) 0%, rgba(18, 24, 38, 0.8) 100%)'
      }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '20px', flexWrap: 'wrap', gap: '14px' }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <span className="badge badge-success" style={{ fontSize: '0.72rem' }}>Parent Perspective</span>
              <h3 style={{ fontSize: '1.2rem', fontWeight: 800 }}>Live Student Safety Monitor</h3>
            </div>
            <p style={{ fontSize: '0.8rem', color: 'var(--text-muted)', marginTop: '2px' }}>
              Select a student to preview what the guardian sees on the mobile web portal
            </p>
          </div>

          {/* Student Selector */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <span style={{ fontSize: '0.85rem', fontWeight: 600, color: '#fff' }}>Student:</span>
            <select 
              value={selectedRoll} 
              onChange={(e) => setSelectedRoll(e.target.value)}
              className="select-field"
              style={{ width: '220px' }}
            >
              {students.map(s => (
                <option key={s.roll_number} value={s.roll_number}>
                  {s.roll_number} - {s.name}
                </option>
              ))}
            </select>
          </div>
        </div>

        {selectedStudent && (
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '20px', marginBottom: '22px' }}>
            {/* Status Card */}
            <div style={{
              background: 'rgba(0, 0, 0, 0.35)',
              padding: '20px',
              borderRadius: 'var(--radius-lg)',
              border: '1px solid var(--border-color)',
              display: 'flex',
              flexDirection: 'column',
              justifyContent: 'space-between'
            }}>
              <div>
                <div style={{ fontSize: '0.75rem', color: 'var(--text-dim)', textTransform: 'uppercase', fontWeight: 700 }}>
                  Current Campus Presence
                </div>
                <div style={{ marginTop: '10px', display: 'flex', alignItems: 'center', gap: '10px' }}>
                  {selectedStudent.live_status === 'INSIDE' && (
                    <>
                      <span className="pulsing-dot online" style={{ width: '14px', height: '14px' }} />
                      <span style={{ fontSize: '1.3rem', fontWeight: 800, color: '#34d399' }}>Inside Classroom</span>
                    </>
                  )}
                  {selectedStudent.live_status === 'EARLY_QUIT' && (
                    <>
                      <span className="pulsing-dot warning" style={{ width: '14px', height: '14px' }} />
                      <span style={{ fontSize: '1.3rem', fontWeight: 800, color: '#f87171' }}>⚠️ Early Quit Flagged</span>
                    </>
                  )}
                  {selectedStudent.live_status === 'OUTSIDE' && (
                    <>
                      <span style={{ width: '14px', height: '14px', borderRadius: '50%', background: '#94a3b8', display: 'inline-block' }} />
                      <span style={{ fontSize: '1.3rem', fontWeight: 800, color: '#94a3b8' }}>Outside Campus</span>
                    </>
                  )}
                </div>
              </div>

              <div style={{ marginTop: '16px', fontSize: '0.8rem', color: 'var(--text-muted)' }}>
                Last BLE Beacon Heartbeat: <strong style={{ color: '#fff', fontFamily: 'var(--font-mono)' }}>{selectedStudent.last_seen_at || 'No active ping'}</strong>
              </div>
            </div>

            {/* Student & Guardian Info */}
            <div style={{
              background: 'rgba(0, 0, 0, 0.35)',
              padding: '20px',
              borderRadius: 'var(--radius-lg)',
              border: '1px solid var(--border-color)'
            }}>
              <div style={{ fontSize: '0.75rem', color: 'var(--text-dim)', textTransform: 'uppercase', fontWeight: 700, marginBottom: '10px' }}>
                Guardian Details
              </div>
              <div style={{ fontSize: '1.05rem', fontWeight: 700, color: '#fff' }}>
                {selectedStudent.parent_name || 'Registered Parent'}
              </div>
              <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)', marginTop: '8px', display: 'flex', flexDirection: 'column', gap: '4px' }}>
                <span style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                  <Mail size={13} color="#60a5fa" /> {selectedStudent.parent_email || 'No email registered'}
                </span>
                <span style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                  <Phone size={13} color="#34d399" /> {selectedStudent.parent_phone || 'No phone registered'}
                </span>
                <span style={{ marginTop: '4px' }}>
                  Linked Student: <strong style={{ color: '#fff' }}>{selectedStudent.name} ({selectedStudent.roll_number})</strong>
                </span>
              </div>
            </div>
          </div>
        )}

        {/* Real-time Alerts Sent to this Parent */}
        <div>
          <div style={{ fontSize: '0.85rem', fontWeight: 700, color: '#fff', marginBottom: '10px', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <Mail size={15} color="#60a5fa" />
            <span>Automated Notification Log for this Student</span>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
            {studentAlerts.length === 0 ? (
              <div style={{ padding: '16px', background: 'rgba(0,0,0,0.2)', borderRadius: 'var(--radius-md)', color: 'var(--text-muted)', fontSize: '0.85rem', textAlign: 'center' }}>
                No notifications logged yet for {selectedStudent?.name}.
              </div>
            ) : (
              studentAlerts.map(alert => (
                <div key={alert.id} style={{
                  padding: '12px 16px',
                  borderRadius: 'var(--radius-md)',
                  background: 'rgba(0,0,0,0.3)',
                  border: '1px solid var(--border-color)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  gap: '12px'
                }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                    {alert.alert_type === 'EARLY_QUIT' ? (
                      <AlertTriangle size={18} color="#ef4444" />
                    ) : (
                      <CheckCircle2 size={18} color="#10b981" />
                    )}
                    <div>
                      <div style={{ fontWeight: 700, fontSize: '0.85rem' }}>{alert.title}</div>
                      <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>{alert.message}</div>
                    </div>
                  </div>

                  <div style={{ textAlign: 'right' }}>
                    <span className="badge badge-success" style={{ fontSize: '0.68rem' }}>Email Dispatched ✓</span>
                    <div style={{ fontSize: '0.7rem', color: 'var(--text-dim)', fontFamily: 'var(--font-mono)', marginTop: '4px' }}>
                      {alert.created_at}
                    </div>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      </div>

      {/* Parents Accounts Table */}
      <h3 style={{ fontSize: '1.1rem', fontWeight: 700, marginBottom: '14px' }}>Registered Guardian Accounts</h3>
      <div className="glass-panel table-container">
        <table className="data-table">
          <thead>
            <tr>
              <th>Username</th>
              <th>Parent Name</th>
              <th>Linked Student Roll</th>
              <th>Contact Email</th>
              <th>Contact Phone</th>
              <th>Registered At</th>
            </tr>
          </thead>
          <tbody>
            {parents.map(p => (
              <tr key={p.id}>
                <td>
                  <span className="code-pill">@{p.username}</span>
                </td>
                <td>
                  <strong style={{ color: '#fff' }}>{p.parent_name}</strong>
                </td>
                <td>
                  <span className="badge badge-primary">{p.student_roll_number}</span>
                </td>
                <td>
                  <div style={{ fontSize: '0.82rem', color: 'var(--text-muted)' }}>{p.email}</div>
                </td>
                <td>
                  <div style={{ fontSize: '0.82rem', color: 'var(--text-muted)' }}>{p.phone}</div>
                </td>
                <td>
                  <span style={{ fontSize: '0.75rem', fontFamily: 'var(--font-mono)', color: 'var(--text-dim)' }}>
                    {p.created_at || 'Auto-created'}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
