import React, { useState } from 'react';
import { 
  ShieldAlert, 
  Plus, 
  Battery, 
  MapPin, 
  Zap, 
  Radio, 
  Clock, 
  AlertTriangle, 
  CheckCircle2, 
  Smartphone,
  ShieldCheck
} from 'lucide-react';

export function GuardsTab({ 
  guards = [], 
  zones = [], 
  onAddGuard, 
  onGuardPing 
}) {
  const [selectedGuard, setSelectedGuard] = useState(guards[0]?.username || 'guard1');
  const [currentZone, setCurrentZone] = useState('ZONE-A');
  const [pingStatus, setPingStatus] = useState('patrolling');
  const [battery, setBattery] = useState(90);
  const [rssi, setRssi] = useState(-65);
  const [customMsg, setCustomMsg] = useState('');
  const [pingResult, setPingResult] = useState(null);

  const handleTriggerPing = async (e) => {
    e.preventDefault();
    const result = await onGuardPing({
      username: selectedGuard,
      current_zone: currentZone,
      status: pingStatus,
      battery: Number(battery),
      rssi: Number(rssi),
      message: customMsg
    });
    setPingResult(result);
    setTimeout(() => setPingResult(null), 6000);
  };

  const currentGuardObj = guards.find(g => g.username === selectedGuard);

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
          <h2 style={{ fontSize: '1.4rem', fontWeight: 800 }}>Campus Security Patrol & Anti-Cheat Command</h2>
          <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>
            Real-time geofence tracking, zone violation detection, and stationary guard inactivity alarms
          </p>
        </div>

        <button onClick={onAddGuard} className="btn btn-primary">
          <Plus size={16} />
          Register Security Guard
        </button>
      </div>

      {/* Grid of Guards */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))',
        gap: '20px',
        marginBottom: '28px'
      }}>
        {guards.map(guard => {
          const isWarning = guard.status.includes('warning');
          return (
            <div key={guard.username} className="glass-panel" style={{
              padding: '20px',
              border: isWarning ? '1px solid rgba(239, 68, 68, 0.4)' : '1px solid var(--border-color)',
              background: isWarning ? 'rgba(239, 68, 68, 0.05)' : 'var(--bg-card)'
            }}>
              <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: '14px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                  <div style={{
                    width: '44px',
                    height: '44px',
                    borderRadius: '12px',
                    background: isWarning ? 'rgba(239, 68, 68, 0.2)' : 'rgba(59, 130, 246, 0.15)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    color: isWarning ? '#f87171' : '#60a5fa'
                  }}>
                    <ShieldAlert size={22} />
                  </div>
                  <div>
                    <h3 style={{ fontSize: '1rem', fontWeight: 700 }}>{guard.name}</h3>
                    <div style={{ fontSize: '0.75rem', color: 'var(--text-dim)', fontFamily: 'var(--font-mono)' }}>
                      @{guard.username} • {guard.phone}
                    </div>
                  </div>
                </div>

                {/* Status Badge */}
                <div>
                  {guard.status === 'patrolling' && <span className="badge badge-success">Patrolling</span>}
                  {guard.status === 'idle' && <span className="badge badge-subtle">Idle</span>}
                  {guard.status === 'warning_deviation' && <span className="badge badge-danger">⚠️ Deviation</span>}
                  {guard.status === 'warning_inactive' && <span className="badge badge-warning">⚠️ Inactive</span>}
                </div>
              </div>

              {/* Details */}
              <div style={{
                background: 'rgba(0, 0, 0, 0.25)',
                padding: '12px',
                borderRadius: 'var(--radius-md)',
                display: 'grid',
                gridTemplateColumns: '1fr 1fr',
                gap: '10px',
                fontSize: '0.8rem',
                marginBottom: '14px'
              }}>
                <div>
                  <div style={{ color: 'var(--text-dim)', fontSize: '0.7rem' }}>Assigned Zone</div>
                  <div style={{ fontWeight: 700, color: '#93c5fd' }}>{guard.assigned_zone}</div>
                </div>
                <div>
                  <div style={{ color: 'var(--text-dim)', fontSize: '0.7rem' }}>Device Battery</div>
                  <div style={{ fontWeight: 700, display: 'flex', alignItems: 'center', gap: '4px' }}>
                    <Battery size={14} color={guard.battery_pct > 25 ? '#10b981' : '#ef4444'} />
                    {guard.battery_pct}%
                  </div>
                </div>
                <div style={{ gridColumn: 'span 2' }}>
                  <div style={{ color: 'var(--text-dim)', fontSize: '0.7rem' }}>Last Telemetry Ping</div>
                  <div style={{ fontFamily: 'var(--font-mono)', fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                    {guard.last_ping_at || 'Awaiting initial telemetry ping'}
                  </div>
                </div>
              </div>

              <button 
                onClick={() => {
                  setSelectedGuard(guard.username);
                  setCurrentZone(guard.assigned_zone);
                }}
                className="btn btn-sm btn-secondary"
                style={{ width: '100%' }}
              >
                <Zap size={13} /> Test Patrol Telemetry Ping
              </button>
            </div>
          );
        })}
      </div>

      {/* Interactive Anti-Cheat & Telemetry Ping Simulator */}
      <div className="glass-panel" style={{ padding: '24px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '8px' }}>
          <Radio size={20} color="#8b5cf6" />
          <h3 style={{ fontSize: '1.15rem', fontWeight: 700 }}>Guard Anti-Cheat Telemetry Simulator</h3>
        </div>
        <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)', marginBottom: '20px' }}>
          Simulate real-time guard telemetry pings sent by the guard mobile app. If a guard pings from outside their assigned zone or exceeds inactivity thresholds, the anti-cheat system automatically logs a deviation alert.
        </p>

        {pingResult && (
          <div style={{
            padding: '12px 16px',
            borderRadius: 'var(--radius-md)',
            marginBottom: '20px',
            background: pingResult.is_warning ? 'rgba(239, 68, 68, 0.15)' : 'rgba(16, 185, 129, 0.15)',
            border: `1px solid ${pingResult.is_warning ? 'rgba(239, 68, 68, 0.4)' : 'rgba(16, 185, 129, 0.4)'}`,
            display: 'flex',
            alignItems: 'center',
            gap: '12px'
          }}>
            {pingResult.is_warning ? <AlertTriangle size={20} color="#ef4444" /> : <CheckCircle2 size={20} color="#10b981" />}
            <div>
              <div style={{ fontWeight: 700, fontSize: '0.9rem' }}>
                {pingResult.is_warning ? '⚠️ Anti-Cheat Warning Triggered!' : 'Patrol Ping Processed Successfully'}
              </div>
              <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
                {pingResult.warning_message || 'Guard position conforms to assigned zone schedule.'}
              </div>
            </div>
          </div>
        )}

        <form onSubmit={handleTriggerPing} style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
          gap: '16px'
        }}>
          {/* Select Guard */}
          <div className="form-group">
            <label className="form-label">Select Guard</label>
            <select 
              value={selectedGuard} 
              onChange={(e) => setSelectedGuard(e.target.value)}
              className="select-field"
            >
              {guards.map(g => (
                <option key={g.username} value={g.username}>
                  {g.name} (Assigned: {g.assigned_zone})
                </option>
              ))}
            </select>
          </div>

          {/* Current Ping Zone */}
          <div className="form-group">
            <label className="form-label">
              Ping Zone Location 
              {currentGuardObj && currentGuardObj.assigned_zone !== currentZone && (
                <span style={{ color: '#f87171', marginLeft: '6px' }}>(Zone Mismatch!)</span>
              )}
            </label>
            <select 
              value={currentZone} 
              onChange={(e) => setCurrentZone(e.target.value)}
              className="select-field"
            >
              {zones.map(z => (
                <option key={z.zone_code} value={z.zone_code}>
                  {z.zone_code} - {z.name}
                </option>
              ))}
            </select>
          </div>

          {/* Patrol Status */}
          <div className="form-group">
            <label className="form-label">Reported Status</label>
            <select 
              value={pingStatus} 
              onChange={(e) => setPingStatus(e.target.value)}
              className="select-field"
            >
              <option value="patrolling">Patrolling (Normal)</option>
              <option value="idle">Idle (Stationary)</option>
              <option value="warning_deviation">Force Warning: Deviation</option>
              <option value="warning_inactive">Force Warning: Inactive &gt; Threshold</option>
            </select>
          </div>

          {/* Battery */}
          <div className="form-group">
            <label className="form-label">Battery Level ({battery}%)</label>
            <input 
              type="range" 
              min="5" 
              max="100" 
              value={battery} 
              onChange={(e) => setBattery(e.target.value)}
              style={{ width: '100%', marginTop: '8px' }}
            />
          </div>

          {/* RSSI Signal */}
          <div className="form-group">
            <label className="form-label">Signal RSSI ({rssi} dBm)</label>
            <input 
              type="range" 
              min="-95" 
              max="-45" 
              value={rssi} 
              onChange={(e) => setRssi(e.target.value)}
              style={{ width: '100%', marginTop: '8px' }}
            />
          </div>

          <div className="form-group" style={{ gridColumn: 'span 2' }}>
            <label className="form-label">Telemetry Message / Checkpoint Notes</label>
            <input 
              type="text" 
              placeholder="e.g. Regular perimeter sweep completed near east gate"
              value={customMsg}
              onChange={(e) => setCustomMsg(e.target.value)}
              className="input-field"
            />
          </div>

          <div style={{ gridColumn: 'span 2', display: 'flex', justifyContent: 'flex-end' }}>
            <button type="submit" className="btn btn-primary" style={{ padding: '10px 24px' }}>
              <Zap size={16} /> Transmit Telemetry Ping to MySQL
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
