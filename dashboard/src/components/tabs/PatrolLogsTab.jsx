import React, { useState } from 'react';
import { 
  FileText, 
  MapPin, 
  AlertTriangle, 
  CheckCircle2, 
  Radio, 
  Filter, 
  Clock,
  ShieldAlert
} from 'lucide-react';

export function PatrolLogsTab({ 
  patrolLogs = [], 
  patrolVisits = [] 
}) {
  const [viewMode, setViewMode] = useState('visits'); // 'visits' | 'telemetry'
  const [filterWarningOnly, setFilterWarningOnly] = useState(false);

  const filteredLogs = patrolLogs.filter(log => {
    if (filterWarningOnly) return log.is_warning;
    return true;
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
          <h2 style={{ fontSize: '1.4rem', fontWeight: 800 }}>Patrol Telemetry & Anti-Cheat Audit Trail</h2>
          <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>
            Immutable logs of guard checkpoint scans, BLE signal strengths, and zone deviation events
          </p>
        </div>

        {/* View Switcher Tabs */}
        <div className="tabs-nav">
          <button 
            className={`tab-btn ${viewMode === 'visits' ? 'active' : ''}`}
            onClick={() => setViewMode('visits')}
          >
            <MapPin size={15} /> Physical Checkpoint Visits ({patrolVisits.length})
          </button>
          <button 
            className={`tab-btn ${viewMode === 'telemetry' ? 'active' : ''}`}
            onClick={() => setViewMode('telemetry')}
          >
            <Radio size={15} /> Patrol Telemetry Logs ({patrolLogs.length})
          </button>
        </div>
      </div>

      {/* Filter toolbar */}
      <div className="glass-panel" style={{ padding: '12px 20px', marginBottom: '20px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          <label style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer', fontSize: '0.85rem', fontWeight: 600 }}>
            <input 
              type="checkbox" 
              checked={filterWarningOnly} 
              onChange={(e) => setFilterWarningOnly(e.target.checked)} 
            />
            Show Anti-Cheat Warnings Only
          </label>
        </div>

        <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
          Showing {viewMode === 'visits' ? patrolVisits.length : filteredLogs.length} events
        </div>
      </div>

      {viewMode === 'visits' ? (
        /* Visits Table */
        <div className="glass-panel table-container">
          <table className="data-table">
            <thead>
              <tr>
                <th>Time (Visited At)</th>
                <th>Security Officer</th>
                <th>Checkpoint Name</th>
                <th>Beacon Code</th>
                <th>Zone</th>
                <th>Signal (RSSI)</th>
                <th>Anti-Cheat Verification</th>
              </tr>
            </thead>
            <tbody>
              {patrolVisits.length === 0 ? (
                <tr>
                  <td colSpan="7" style={{ textAlign: 'center', padding: '40px', color: 'var(--text-muted)' }}>
                    No checkpoint scans recorded yet. Simulate a scan from the BLE Beacons tab!
                  </td>
                </tr>
              ) : (
                patrolVisits.map(v => (
                  <tr key={v.id}>
                    <td style={{ fontFamily: 'var(--font-mono)', fontSize: '0.8rem' }}>
                      {v.visited_at}
                    </td>
                    <td>
                      <div style={{ fontWeight: 700, color: '#fff' }}>{v.guard_name || v.guard_username}</div>
                      <div style={{ fontSize: '0.72rem', color: 'var(--text-dim)' }}>Assigned: {v.assigned_zone}</div>
                    </td>
                    <td>
                      <div style={{ fontWeight: 600 }}>{v.checkpoint_name}</div>
                    </td>
                    <td>
                      <span className="code-pill">{v.beacon_code}</span>
                    </td>
                    <td>
                      <span className="badge badge-purple">{v.zone_code}</span>
                    </td>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <span style={{ fontFamily: 'var(--font-mono)', fontSize: '0.8rem', fontWeight: 600, color: v.rssi > -70 ? '#34d399' : '#fbbf24' }}>
                          {v.rssi} dBm
                        </span>
                        <div className="rssi-meter">
                          <span className={`rssi-bar active`} style={{ height: '4px' }} />
                          <span className={`rssi-bar ${v.rssi > -80 ? 'active' : ''}`} style={{ height: '7px' }} />
                          <span className={`rssi-bar ${v.rssi > -70 ? 'active' : ''}`} style={{ height: '10px' }} />
                          <span className={`rssi-bar ${v.rssi > -60 ? 'active' : ''}`} style={{ height: '13px' }} />
                        </div>
                      </div>
                    </td>
                    <td>
                      <span className="badge badge-success">
                        <CheckCircle2 size={13} /> Verified Hardware Beacon
                      </span>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      ) : (
        /* Telemetry Logs Table */
        <div className="glass-panel table-container">
          <table className="data-table">
            <thead>
              <tr>
                <th>Timestamp</th>
                <th>Guard Username</th>
                <th>Reported Zone</th>
                <th>Status</th>
                <th>Anti-Cheat Flag</th>
                <th>Signal (RSSI)</th>
                <th>Telemetry Message / Audit Reason</th>
              </tr>
            </thead>
            <tbody>
              {filteredLogs.length === 0 ? (
                <tr>
                  <td colSpan="7" style={{ textAlign: 'center', padding: '40px', color: 'var(--text-muted)' }}>
                    No telemetry logs found.
                  </td>
                </tr>
              ) : (
                filteredLogs.map(log => (
                  <tr key={log.id} style={{ background: log.is_warning ? 'rgba(239, 68, 68, 0.04)' : undefined }}>
                    <td style={{ fontFamily: 'var(--font-mono)', fontSize: '0.8rem' }}>
                      {log.timestamp}
                    </td>
                    <td>
                      <strong style={{ color: '#fff' }}>{log.guard_username}</strong>
                    </td>
                    <td>
                      <span className="badge badge-purple">{log.zone_code}</span>
                    </td>
                    <td>
                      {log.status === 'patrolling' && <span className="badge badge-success">Patrolling</span>}
                      {log.status === 'idle' && <span className="badge badge-subtle">Idle</span>}
                      {log.status === 'warning_deviation' && <span className="badge badge-danger">Deviation</span>}
                      {log.status === 'warning_inactive' && <span className="badge badge-warning">Inactive</span>}
                    </td>
                    <td>
                      {log.is_warning ? (
                        <span className="badge badge-danger">
                          <AlertTriangle size={12} /> Warning Violation
                        </span>
                      ) : (
                        <span className="badge badge-success">
                          ✓ Normal
                        </span>
                      )}
                    </td>
                    <td style={{ fontFamily: 'var(--font-mono)', fontSize: '0.8rem' }}>
                      {log.rssi} dBm
                    </td>
                    <td style={{ fontSize: '0.8rem', color: log.is_warning ? '#fca5a5' : 'var(--text-muted)' }}>
                      {log.message || 'Heartbeat packet acknowledged'}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
