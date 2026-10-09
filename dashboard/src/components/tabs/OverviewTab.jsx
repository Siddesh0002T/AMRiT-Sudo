import React from 'react';
import { 
  Users, 
  ShieldAlert, 
  Radio, 
  CalendarCheck, 
  AlertTriangle, 
  ArrowUpRight, 
  CheckCircle2, 
  MapPin, 
  Zap, 
  Clock,
  Battery,
  UserCheck
} from 'lucide-react';

export function OverviewTab({ 
  students = [], 
  guards = [], 
  beacons = [], 
  zones = [], 
  alerts = [], 
  visits = [], 
  sessions = [],
  onQuickSimulate,
  setActiveTab
}) {
  const studentsInside = students.filter(s => s.live_status === 'INSIDE').length;
  const studentsOutside = students.filter(s => s.live_status === 'OUTSIDE').length;
  const studentsEarlyQuit = students.filter(s => s.live_status === 'EARLY_QUIT').length;

  const guardWarnings = guards.filter(g => g.status === 'warning_deviation' || g.status === 'warning_inactive').length;
  const guardsPatrolling = guards.filter(g => g.status === 'patrolling').length;

  return (
    <div>
      {/* Header Banner */}
      <div style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        marginBottom: '24px',
        flexWrap: 'wrap',
        gap: '16px'
      }}>
        <div>
          <h1 className="page-title">Campus Security & Attendance Command Center</h1>
          <p className="page-subtitle">
            Real-time BLE mesh tracking, anti-cheat guard telemetry & automated parent SMS/Email dispatch
          </p>
        </div>

        {/* Quick Simulation Trigger Bar */}
        <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
          <button 
            className="btn btn-sm btn-secondary"
            onClick={() => onQuickSimulate('STUDENT_IN', '23CE001')}
            title="Simulate Aarav Sharma entering classroom"
          >
            <UserCheck size={14} color="#10b981" />
            Simulate Student Check-IN
          </button>
          <button 
            className="btn btn-sm btn-secondary"
            onClick={() => onQuickSimulate('EARLY_QUIT', '23CE002')}
            title="Simulate Aditi Verma early departure trigger"
          >
            <AlertTriangle size={14} color="#ef4444" />
            Simulate Early Quit Alert
          </button>
          <button 
            className="btn btn-sm btn-primary"
            onClick={() => onQuickSimulate('GUARD_PING')}
            title="Simulate Guard anti-cheat telemetry ping"
          >
            <Zap size={14} />
            Simulate Guard Patrol Ping
          </button>
        </div>
      </div>

      {/* KPI Stat Metrics Grid */}
      <div className="metrics-grid">
        {/* Card 1: Students */}
        <div className="glass-panel stat-card" style={{ '--card-accent': 'rgba(59, 130, 246, 0.2)' }}>
          <div className="stat-header">
            <span className="stat-title">Student Population</span>
            <div className="stat-icon" style={{ background: 'rgba(59, 130, 246, 0.15)', color: '#60a5fa' }}>
              <Users size={22} />
            </div>
          </div>
          <div className="stat-value">{students.length}</div>
          <div className="stat-footer">
            <span className="badge badge-success" style={{ fontSize: '0.7rem' }}>
              <span className="pulsing-dot online" /> {studentsInside} Inside
            </span>
            {studentsEarlyQuit > 0 && (
              <span className="badge badge-danger" style={{ fontSize: '0.7rem' }}>
                {studentsEarlyQuit} Early Quit
              </span>
            )}
            <span style={{ marginLeft: 'auto', color: 'var(--text-dim)' }}>
              {studentsOutside} Outside
            </span>
          </div>
        </div>

        {/* Card 2: Guards */}
        <div className="glass-panel stat-card" style={{ '--card-accent': 'rgba(16, 185, 129, 0.2)' }}>
          <div className="stat-header">
            <span className="stat-title">Security Patrol Guards</span>
            <div className="stat-icon" style={{ background: 'rgba(16, 185, 129, 0.15)', color: '#34d399' }}>
              <ShieldAlert size={22} />
            </div>
          </div>
          <div className="stat-value">{guards.length}</div>
          <div className="stat-footer">
            <span className="badge badge-primary" style={{ fontSize: '0.7rem' }}>
              {guardsPatrolling} Patrolling
            </span>
            {guardWarnings > 0 ? (
              <span className="badge badge-danger" style={{ fontSize: '0.7rem' }}>
                <span className="pulsing-dot warning" /> {guardWarnings} Anti-Cheat Alert
              </span>
            ) : (
              <span className="badge badge-success" style={{ fontSize: '0.7rem' }}>
                100% Compliant
              </span>
            )}
          </div>
        </div>

        {/* Card 3: BLE Beacons */}
        <div className="glass-panel stat-card" style={{ '--card-accent': 'rgba(139, 92, 246, 0.2)' }}>
          <div className="stat-header">
            <span className="stat-title">BLE Anti-Cheat Beacons</span>
            <div className="stat-icon" style={{ background: 'rgba(139, 92, 246, 0.15)', color: '#c084fc' }}>
              <Radio size={22} />
            </div>
          </div>
          <div className="stat-value">{beacons.length}</div>
          <div className="stat-footer">
            <span style={{ color: 'var(--text-muted)' }}>
              Deployed across {zones.length} Campus Zones
            </span>
            <button 
              onClick={() => setActiveTab('beacons')} 
              className="btn-ghost" 
              style={{ marginLeft: 'auto', padding: '2px 6px', fontSize: '0.72rem' }}
            >
              View Beacons <ArrowUpRight size={12} />
            </button>
          </div>
        </div>

        {/* Card 4: Attendance Sessions */}
        <div className="glass-panel stat-card" style={{ '--card-accent': 'rgba(245, 158, 11, 0.2)' }}>
          <div className="stat-header">
            <span className="stat-title">Attendance Sessions</span>
            <div className="stat-icon" style={{ background: 'rgba(245, 158, 11, 0.15)', color: '#fbbf24' }}>
              <CalendarCheck size={22} />
            </div>
          </div>
          <div className="stat-value">{sessions.length}</div>
          <div className="stat-footer">
            <span className="badge badge-purple" style={{ fontSize: '0.7rem' }}>
              Synced with MySQL
            </span>
            <button 
              onClick={() => setActiveTab('attendance')} 
              className="btn-ghost" 
              style={{ marginLeft: 'auto', padding: '2px 6px', fontSize: '0.72rem' }}
            >
              View Records <ArrowUpRight size={12} />
            </button>
          </div>
        </div>
      </div>

      {/* Main Dual Grid: Campus Activity Radar & Security Zone Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(450px, 1fr))', gap: '24px', marginBottom: '28px' }}>
        
        {/* Left: Campus Presence Distribution */}
        <div className="glass-panel" style={{ padding: '24px' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '18px' }}>
            <div>
              <h3 style={{ fontSize: '1.1rem', fontWeight: 700 }}>Live Student Mesh Distribution</h3>
              <p style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Real-time BLE signal detection in classrooms</p>
            </div>
            <span className="badge badge-success">
              <span className="pulsing-dot online" /> Live Feed
            </span>
          </div>

          {/* Graphical Progress Visualizer */}
          <div style={{ marginBottom: '20px' }}>
            <div style={{
              height: '14px',
              borderRadius: '999px',
              background: 'rgba(255,255,255,0.06)',
              display: 'flex',
              overflow: 'hidden',
              gap: '2px'
            }}>
              <div 
                style={{ 
                  width: `${(studentsInside / (students.length || 1)) * 100}%`, 
                  background: 'linear-gradient(90deg, #10b981, #059669)',
                  transition: 'width 0.5s ease'
                }} 
                title={`Inside: ${studentsInside}`}
              />
              <div 
                style={{ 
                  width: `${(studentsEarlyQuit / (students.length || 1)) * 100}%`, 
                  background: 'linear-gradient(90deg, #ef4444, #dc2626)',
                  transition: 'width 0.5s ease'
                }} 
                title={`Early Quit: ${studentsEarlyQuit}`}
              />
              <div 
                style={{ 
                  width: `${(studentsOutside / (students.length || 1)) * 100}%`, 
                  background: 'rgba(255,255,255,0.15)',
                  transition: 'width 0.5s ease'
                }} 
                title={`Outside: ${studentsOutside}`}
              />
            </div>

            <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: '14px', fontSize: '0.82rem' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <span style={{ width: '10px', height: '10px', borderRadius: '50%', background: '#10b981' }} />
                <span>Inside Class ({studentsInside})</span>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <span style={{ width: '10px', height: '10px', borderRadius: '50%', background: '#ef4444' }} />
                <span>Early Quit Alert ({studentsEarlyQuit})</span>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <span style={{ width: '10px', height: '10px', borderRadius: '50%', background: 'rgba(255,255,255,0.3)' }} />
                <span>Outside Perimeter ({studentsOutside})</span>
              </div>
            </div>
          </div>

          {/* Quick Student Feed */}
          <div style={{ borderTop: '1px solid var(--border-color)', paddingTop: '16px' }}>
            <div style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-muted)', marginBottom: '10px', textTransform: 'uppercase' }}>
              Active Student Status
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
              {students.slice(0, 4).map(s => (
                <div key={s.roll_number} style={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  padding: '10px 14px',
                  borderRadius: 'var(--radius-md)',
                  background: 'rgba(255,255,255,0.02)',
                  border: '1px solid rgba(255,255,255,0.04)'
                }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                    <span className="code-pill">{s.roll_number}</span>
                    <div>
                      <div style={{ fontWeight: 600, fontSize: '0.875rem' }}>{s.name}</div>
                      <div style={{ fontSize: '0.72rem', color: 'var(--text-dim)' }}>Sec: {s.class_section} • Parent: {s.parent_name}</div>
                    </div>
                  </div>
                  <div>
                    {s.live_status === 'INSIDE' && (
                      <span className="badge badge-success">INSIDE</span>
                    )}
                    {s.live_status === 'EARLY_QUIT' && (
                      <span className="badge badge-danger">EARLY QUIT</span>
                    )}
                    {s.live_status === 'OUTSIDE' && (
                      <span className="badge badge-subtle">OUTSIDE</span>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Right: Security Patrol & Anti-Cheat Telemetry */}
        <div className="glass-panel" style={{ padding: '24px' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '18px' }}>
            <div>
              <h3 style={{ fontSize: '1.1rem', fontWeight: 700 }}>Security Guards & Patrol Radar</h3>
              <p style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Anti-cheat zone conformance & beacon checks</p>
            </div>
            <button onClick={() => setActiveTab('guards')} className="btn-ghost" style={{ fontSize: '0.8rem' }}>
              Manage Guards <ArrowUpRight size={14} />
            </button>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
            {guards.map(g => {
              const isWarning = g.status.includes('warning');
              return (
                <div key={g.id} style={{
                  padding: '14px 16px',
                  borderRadius: 'var(--radius-md)',
                  background: isWarning ? 'rgba(239, 68, 68, 0.08)' : 'rgba(255,255,255,0.02)',
                  border: `1px solid ${isWarning ? 'rgba(239, 68, 68, 0.3)' : 'rgba(255,255,255,0.05)'}`,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between'
                }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
                    <div style={{
                      width: '40px',
                      height: '40px',
                      borderRadius: '10px',
                      background: isWarning ? 'rgba(239, 68, 68, 0.2)' : 'rgba(59, 130, 246, 0.15)',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      color: isWarning ? '#f87171' : '#60a5fa'
                    }}>
                      <ShieldAlert size={20} />
                    </div>
                    <div>
                      <div style={{ fontWeight: 700, fontSize: '0.9rem' }}>{g.name}</div>
                      <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', display: 'flex', alignItems: 'center', gap: '8px', marginTop: '2px' }}>
                        <span>Zone: <strong style={{ color: '#93c5fd' }}>{g.assigned_zone}</strong></span>
                        <span>•</span>
                        <span style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                          <Battery size={13} color={g.battery_pct > 20 ? '#10b981' : '#ef4444'} />
                          {g.battery_pct}%
                        </span>
                      </div>
                    </div>
                  </div>

                  <div style={{ textAlign: 'right' }}>
                    {g.status === 'patrolling' && <span className="badge badge-success">Patrolling</span>}
                    {g.status === 'idle' && <span className="badge badge-subtle">Idle</span>}
                    {g.status === 'warning_deviation' && <span className="badge badge-danger">⚠️ Zone Deviation</span>}
                    {g.status === 'warning_inactive' && <span className="badge badge-warning">⚠️ Inactive</span>}
                    <div style={{ fontSize: '0.7rem', color: 'var(--text-dim)', marginTop: '4px', fontFamily: 'var(--font-mono)' }}>
                      Last ping: {g.last_ping_at ? g.last_ping_at.split(' ')[1] : 'Never'}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>

          {/* Anti-cheat hardware note */}
          <div style={{
            marginTop: '16px',
            padding: '10px 14px',
            borderRadius: 'var(--radius-md)',
            background: 'rgba(59, 130, 246, 0.08)',
            border: '1px solid rgba(59, 130, 246, 0.2)',
            display: 'flex',
            alignItems: 'center',
            gap: '10px',
            fontSize: '0.75rem',
            color: '#93c5fd'
          }}>
            <Radio size={16} />
            <span>Anti-Cheat Verification: Guards must physically scan Bluetooth beacons with RSSI &gt; -75 dBm to prove physical attendance.</span>
          </div>
        </div>
      </div>

      {/* Bottom Section: Recent Critical Alerts Feed & Checkpoint Visits */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(450px, 1fr))', gap: '24px' }}>
        
        {/* Recent Alerts */}
        <div className="glass-panel" style={{ padding: '24px' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '16px' }}>
            <h3 style={{ fontSize: '1.05rem', fontWeight: 700 }}>Real-time Notifications Log</h3>
            <button onClick={() => setActiveTab('alerts')} className="btn-ghost" style={{ fontSize: '0.8rem' }}>
              All Alerts <ArrowUpRight size={14} />
            </button>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
            {alerts.slice(0, 4).map(alert => (
              <div key={alert.id} style={{
                padding: '12px 14px',
                borderRadius: 'var(--radius-md)',
                background: 'rgba(255,255,255,0.02)',
                border: '1px solid var(--border-color)',
                display: 'flex',
                gap: '12px'
              }}>
                <div style={{
                  width: '32px',
                  height: '32px',
                  borderRadius: '8px',
                  background: alert.alert_type.includes('EARLY_QUIT') || alert.alert_type.includes('DEVIATION') 
                    ? 'rgba(239, 68, 68, 0.15)' 
                    : 'rgba(16, 185, 129, 0.15)',
                  color: alert.alert_type.includes('EARLY_QUIT') || alert.alert_type.includes('DEVIATION') 
                    ? '#f87171' 
                    : '#34d399',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  flexShrink: 0
                }}>
                  {alert.alert_type.includes('EARLY_QUIT') ? <AlertTriangle size={16} /> : <CheckCircle2 size={16} />}
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '8px' }}>
                    <div style={{ fontWeight: 700, fontSize: '0.85rem' }}>{alert.title}</div>
                    <span style={{ fontSize: '0.7rem', color: 'var(--text-dim)', fontFamily: 'var(--font-mono)' }}>
                      {alert.created_at ? alert.created_at.split(' ')[1] : ''}
                    </span>
                  </div>
                  <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)', marginTop: '2px', lineHeight: 1.4 }}>
                    {alert.message}
                  </div>
                  {alert.parent_email && (
                    <div style={{ fontSize: '0.7rem', color: '#60a5fa', marginTop: '4px' }}>
                      ✉️ Parent Notification Sent to: {alert.parent_email}
                    </div>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Recent Verified Checkpoint Visits */}
        <div className="glass-panel" style={{ padding: '24px' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '16px' }}>
            <h3 style={{ fontSize: '1.05rem', fontWeight: 700 }}>Physical Checkpoint Scans (Anti-Cheat Audit)</h3>
            <button onClick={() => setActiveTab('patrolLogs')} className="btn-ghost" style={{ fontSize: '0.8rem' }}>
              Full Audit <ArrowUpRight size={14} />
            </button>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
            {visits.slice(0, 4).map(v => (
              <div key={v.id} style={{
                padding: '12px 14px',
                borderRadius: 'var(--radius-md)',
                background: 'rgba(255,255,255,0.02)',
                border: '1px solid var(--border-color)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between'
              }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                  <div style={{
                    width: '32px',
                    height: '32px',
                    borderRadius: '8px',
                    background: 'rgba(59, 130, 246, 0.15)',
                    color: '#60a5fa',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    flexShrink: 0
                  }}>
                    <MapPin size={16} />
                  </div>
                  <div>
                    <div style={{ fontWeight: 600, fontSize: '0.85rem' }}>{v.checkpoint_name}</div>
                    <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)', display: 'flex', gap: '8px' }}>
                      <span>Guard: <strong style={{ color: '#fff' }}>{v.guard_name || v.guard_username}</strong></span>
                      <span>•</span>
                      <span className="code-pill" style={{ fontSize: '0.68rem', padding: '1px 6px' }}>{v.beacon_code}</span>
                    </div>
                  </div>
                </div>

                <div style={{ textAlign: 'right' }}>
                  <span className="badge badge-success" style={{ fontSize: '0.7rem' }}>Verified ✓</span>
                  <div style={{ fontSize: '0.7rem', color: 'var(--text-dim)', marginTop: '4px', fontFamily: 'var(--font-mono)' }}>
                    RSSI: {v.rssi} dBm
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

      </div>
    </div>
  );
}
