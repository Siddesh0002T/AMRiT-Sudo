import React, { useState } from 'react';
import { 
  BellRing, 
  AlertTriangle, 
  CheckCircle2, 
  ShieldAlert, 
  Mail, 
  Clock, 
  Filter, 
  Radio 
} from 'lucide-react';

export function AlertsTab({ 
  alerts = [], 
  onClearAlerts 
}) {
  const [filterType, setFilterType] = useState('ALL');

  const filteredAlerts = alerts.filter(a => {
    if (filterType === 'ALL') return true;
    return a.alert_type === filterType;
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
          <h2 style={{ fontSize: '1.4rem', fontWeight: 800 }}>Institutional Alert Logs & Parent Dispatches</h2>
          <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>
            Real-time security deviations, early departure violations & automated email delivery records
          </p>
        </div>

        <div style={{ display: 'flex', gap: '10px' }}>
          <span className="badge badge-warning">
            <BellRing size={14} /> {alerts.length} Total Alerts Logged
          </span>
        </div>
      </div>

      {/* Filter Bar */}
      <div className="glass-panel" style={{ padding: '14px 20px', marginBottom: '20px', display: 'flex', gap: '16px', alignItems: 'center', flexWrap: 'wrap', justifyContent: 'space-between' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <span style={{ fontSize: '0.85rem', fontWeight: 600, color: 'var(--text-muted)' }}>Filter by Type:</span>
          <select 
            value={filterType} 
            onChange={(e) => setFilterType(e.target.value)}
            className="select-field"
            style={{ width: '220px' }}
          >
            <option value="ALL">All Event Types</option>
            <option value="EARLY_QUIT">⚠️ Early Quit Violations</option>
            <option value="GUARD_DEVIATION">🛡️ Guard Zone Deviations</option>
            <option value="STUDENT_IN">🟢 Student Check-IN</option>
            <option value="STUDENT_OUT">⚪ Student Dismissal</option>
          </select>
        </div>

        <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
          Showing {filteredAlerts.length} events
        </div>
      </div>

      {/* Alerts Stream */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
        {filteredAlerts.length === 0 ? (
          <div className="glass-panel" style={{ padding: '40px', textAlign: 'center', color: 'var(--text-muted)' }}>
            No alerts found matching selected filter.
          </div>
        ) : (
          filteredAlerts.map(alert => {
            const isDanger = alert.alert_type === 'EARLY_QUIT' || alert.alert_type.includes('DEVIATION');
            const isSuccess = alert.alert_type === 'STUDENT_IN';

            return (
              <div key={alert.id} className="glass-panel" style={{
                padding: '18px 22px',
                border: isDanger ? '1px solid rgba(239, 68, 68, 0.35)' : '1px solid var(--border-color)',
                background: isDanger ? 'rgba(239, 68, 68, 0.04)' : 'var(--bg-card)',
                display: 'flex',
                alignItems: 'flex-start',
                justifyContent: 'space-between',
                gap: '16px',
                flexWrap: 'wrap'
              }}>
                <div style={{ display: 'flex', gap: '16px', flex: 1, minWidth: '280px' }}>
                  <div style={{
                    width: '42px',
                    height: '42px',
                    borderRadius: '12px',
                    background: isDanger ? 'rgba(239, 68, 68, 0.2)' : isSuccess ? 'rgba(16, 185, 129, 0.2)' : 'rgba(59, 130, 246, 0.2)',
                    color: isDanger ? '#f87171' : isSuccess ? '#34d399' : '#60a5fa',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    flexShrink: 0
                  }}>
                    {isDanger ? <AlertTriangle size={22} /> : isSuccess ? <CheckCircle2 size={22} /> : <BellRing size={22} />}
                  </div>

                  <div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '10px', flexWrap: 'wrap' }}>
                      <h4 style={{ fontSize: '1rem', fontWeight: 700, color: '#fff' }}>{alert.title}</h4>
                      {isDanger ? (
                        <span className="badge badge-danger">{alert.alert_type}</span>
                      ) : (
                        <span className="badge badge-success">{alert.alert_type}</span>
                      )}
                    </div>

                    <p style={{ fontSize: '0.85rem', color: isDanger ? '#fca5a5' : 'var(--text-muted)', marginTop: '4px', lineHeight: 1.4 }}>
                      {alert.message}
                    </p>

                    <div style={{ display: 'flex', alignItems: 'center', gap: '14px', marginTop: '8px', fontSize: '0.75rem', color: 'var(--text-dim)', flexWrap: 'wrap' }}>
                      <span>Target: <strong style={{ color: '#fff' }}>{alert.target_name} ({alert.roll_or_guard})</strong></span>
                      {alert.parent_email && (
                        <span style={{ display: 'flex', alignItems: 'center', gap: '4px', color: '#60a5fa' }}>
                          <Mail size={12} /> Email Dispatched to: {alert.parent_email}
                        </span>
                      )}
                    </div>
                  </div>
                </div>

                <div style={{ textAlign: 'right' }}>
                  {alert.email_sent ? (
                    <span className="badge badge-success" style={{ fontSize: '0.7rem' }}>
                      <CheckCircle2 size={12} /> Email Sent
                    </span>
                  ) : (
                    <span className="badge badge-subtle" style={{ fontSize: '0.7rem' }}>
                      Internal Log
                    </span>
                  )}
                  <div style={{ fontSize: '0.75rem', fontFamily: 'var(--font-mono)', color: 'var(--text-dim)', marginTop: '6px' }}>
                    {alert.created_at}
                  </div>
                </div>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
}
