import React from 'react';
import { 
  Compass, 
  MapPin, 
  Clock, 
  ShieldCheck, 
  Radio, 
  AlertTriangle 
} from 'lucide-react';

export function ZonesTab({ 
  zones = [], 
  guards = [], 
  beacons = [],
  setActiveTab 
}) {
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
          <h2 style={{ fontSize: '1.4rem', fontWeight: 800 }}>Campus Explore Zones & Geofenced Perimeters</h2>
          <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>
            Institutional security boundaries, maximum allowable inactivity rules & anti-cheat monitoring
          </p>
        </div>

        <span className="badge badge-primary">
          <Compass size={14} /> {zones.length} Configured Zones
        </span>
      </div>

      {/* Zones Grid */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(350px, 1fr))',
        gap: '24px'
      }}>
        {zones.map(zone => {
          const zoneGuards = guards.filter(g => g.assigned_zone === zone.zone_code);
          const zoneBeacons = beacons.filter(b => b.zone_code === zone.zone_code);
          const hasDeviationAlert = zoneGuards.some(g => g.status === 'warning_deviation');

          return (
            <div key={zone.zone_code} className="glass-panel" style={{
              padding: '24px',
              border: hasDeviationAlert ? '1px solid rgba(239, 68, 68, 0.4)' : '1px solid var(--border-color)',
              display: 'flex',
              flexDirection: 'column',
              justifyContent: 'space-between'
            }}>
              <div>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '14px' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                    <div style={{
                      width: '40px',
                      height: '40px',
                      borderRadius: '10px',
                      background: 'rgba(59, 130, 246, 0.15)',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      color: '#60a5fa'
                    }}>
                      <Compass size={22} />
                    </div>
                    <div>
                      <span className="badge badge-purple" style={{ fontSize: '0.75rem' }}>{zone.zone_code}</span>
                      <h3 style={{ fontSize: '1.1rem', fontWeight: 700, marginTop: '2px' }}>{zone.name}</h3>
                    </div>
                  </div>

                  {hasDeviationAlert ? (
                    <span className="badge badge-danger">⚠️ Deviation</span>
                  ) : (
                    <span className="badge badge-success">Active</span>
                  )}
                </div>

                <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)', marginBottom: '18px', lineHeight: 1.5 }}>
                  {zone.description}
                </p>

                {/* Parameters Box */}
                <div style={{
                  background: 'rgba(0, 0, 0, 0.3)',
                  padding: '14px',
                  borderRadius: 'var(--radius-md)',
                  marginBottom: '18px',
                  display: 'flex',
                  flexDirection: 'column',
                  gap: '8px',
                  fontSize: '0.8rem'
                }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <span style={{ color: 'var(--text-dim)', display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <Clock size={13} /> Max Inactivity Threshold:
                    </span>
                    <strong style={{ color: '#fbbf24', fontFamily: 'var(--font-mono)' }}>
                      {zone.max_inactivity_secs} seconds ({Math.round(zone.max_inactivity_secs / 60)} min)
                    </strong>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <span style={{ color: 'var(--text-dim)', display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <Radio size={13} /> Hardware Beacons:
                    </span>
                    <strong style={{ color: '#fff' }}>{zoneBeacons.length} Checkpoints</strong>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <span style={{ color: 'var(--text-dim)', display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <ShieldCheck size={13} /> Assigned Guards:
                    </span>
                    <strong style={{ color: '#38bdf8' }}>{zoneGuards.length} Personnel</strong>
                  </div>
                </div>

                {/* Beacons list */}
                <div style={{ marginBottom: '14px' }}>
                  <div style={{ fontSize: '0.72rem', fontWeight: 700, color: 'var(--text-dim)', textTransform: 'uppercase', marginBottom: '6px' }}>
                    Stationary Checkpoints
                  </div>
                  <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px' }}>
                    {zoneBeacons.map(b => (
                      <span key={b.beacon_code} className="code-pill" style={{ fontSize: '0.72rem' }}>
                        {b.beacon_code}: {b.checkpoint_name}
                      </span>
                    ))}
                  </div>
                </div>

                {/* Guards list */}
                {zoneGuards.length > 0 && (
                  <div>
                    <div style={{ fontSize: '0.72rem', fontWeight: 700, color: 'var(--text-dim)', textTransform: 'uppercase', marginBottom: '6px' }}>
                      Assigned Security Personnel
                    </div>
                    <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px' }}>
                      {zoneGuards.map(g => (
                        <span key={g.username} className={`badge ${g.status.includes('warning') ? 'badge-danger' : 'badge-primary'}`} style={{ fontSize: '0.72rem' }}>
                          {g.name} ({g.status})
                        </span>
                      ))}
                    </div>
                  </div>
                )}
              </div>

              <div style={{ marginTop: '20px', paddingTop: '14px', borderTop: '1px solid var(--border-color)' }}>
                <button 
                  onClick={() => setActiveTab('beacons')} 
                  className="btn btn-sm btn-secondary" 
                  style={{ width: '100%' }}
                >
                  Inspect {zone.zone_code} Beacons
                </button>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
