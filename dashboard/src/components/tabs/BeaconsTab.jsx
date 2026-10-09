import React, { useState } from 'react';
import { 
  Radio, 
  MapPin, 
  ShieldCheck, 
  AlertTriangle, 
  CheckCircle2, 
  Sliders, 
  Zap, 
  Search,
  Hash
} from 'lucide-react';

export function BeaconsTab({ 
  beacons = [], 
  guards = [], 
  onVerifyBeacon 
}) {
  const [selectedBeacon, setSelectedBeacon] = useState(beacons[0]?.beacon_code || 'BCN-GATE-01');
  const [selectedGuard, setSelectedGuard] = useState(guards[0]?.username || 'guard1');
  const [rssi, setRssi] = useState(-68);
  const [verifyResult, setVerifyResult] = useState(null);
  const [search, setSearch] = useState('');
  const [zoneFilter, setZoneFilter] = useState('ALL');

  const handleSimulateScan = async (e) => {
    e.preventDefault();
    const beaconObj = beacons.find(b => b.beacon_code === selectedBeacon);
    if (!beaconObj) return;

    const res = await onVerifyBeacon({
      guard_username: selectedGuard,
      beacon_code: beaconObj.beacon_code,
      checkpoint_name: beaconObj.checkpoint_name,
      zone_code: beaconObj.zone_code,
      rssi: Number(rssi)
    });

    setVerifyResult(res);
    setTimeout(() => setVerifyResult(null), 7000);
  };

  const filteredBeacons = beacons.filter(b => {
    const matchesSearch = 
      b.checkpoint_name.toLowerCase().includes(search.toLowerCase()) ||
      b.beacon_code.toLowerCase().includes(search.toLowerCase()) ||
      b.location_desc.toLowerCase().includes(search.toLowerCase());
    const matchesZone = zoneFilter === 'ALL' || b.zone_code === zoneFilter;
    return matchesSearch && matchesZone;
  });

  const zonesList = ['ALL', ...Array.from(new Set(beacons.map(b => b.zone_code)))];
  const targetBeacon = beacons.find(b => b.beacon_code === selectedBeacon);
  const targetGuard = guards.find(g => g.username === selectedGuard);
  const isPotentialZoneMismatch = targetGuard && targetBeacon && targetGuard.assigned_zone !== targetBeacon.zone_code;

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
          <h2 style={{ fontSize: '1.4rem', fontWeight: 800 }}>Campus BLE Patrol Beacons (Physical Checkpoints)</h2>
          <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>
            Physical hardware Bluetooth beacons deployed across perimeter and buildings for anti-cheat verification
          </p>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <span className="badge badge-primary">
            <Radio size={14} /> {beacons.length} Hardware Checkpoints
          </span>
        </div>
      </div>

      {/* Simulator Card */}
      <div className="glass-panel" style={{ padding: '24px', marginBottom: '28px', border: '1px solid rgba(139, 92, 246, 0.3)' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '8px' }}>
          <ShieldCheck size={20} color="#a78bfa" />
          <h3 style={{ fontSize: '1.15rem', fontWeight: 700 }}>Simulate BLE Hardware Checkpoint Scan (Anti-Cheat Verification)</h3>
        </div>
        <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)', marginBottom: '18px' }}>
          When a guard arrives at a physical checkpoint, their device reads the BLE beacon's UUID and signal RSSI. If the beacon is located in a different zone than the guard's assigned patrol zone, the system detects a zone deviation breach!
        </p>

        {verifyResult && (
          <div style={{
            padding: '14px 18px',
            borderRadius: 'var(--radius-md)',
            marginBottom: '18px',
            background: verifyResult.is_zone_mismatch ? 'rgba(239, 68, 68, 0.15)' : 'rgba(16, 185, 129, 0.15)',
            border: `1px solid ${verifyResult.is_zone_mismatch ? 'rgba(239, 68, 68, 0.4)' : 'rgba(16, 185, 129, 0.4)'}`,
            display: 'flex',
            alignItems: 'center',
            gap: '12px'
          }}>
            {verifyResult.is_zone_mismatch ? (
              <AlertTriangle size={24} color="#ef4444" />
            ) : (
              <CheckCircle2 size={24} color="#10b981" />
            )}
            <div>
              <div style={{ fontWeight: 700, fontSize: '0.95rem', color: verifyResult.is_zone_mismatch ? '#f87171' : '#34d399' }}>
                {verifyResult.is_zone_mismatch ? '⚠️ ANTI-CHEAT ALERT: ZONE MISMATCH DETECTED!' : 'Physical Checkpoint Verified ✓'}
              </div>
              <div style={{ fontSize: '0.82rem', color: 'var(--text-muted)', marginTop: '2px' }}>
                {verifyResult.message || `Logged visit for ${verifyResult.checkpoint_name} with RSSI ${verifyResult.rssi} dBm`}
              </div>
            </div>
          </div>
        )}

        <form onSubmit={handleSimulateScan} style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '16px' }}>
          <div className="form-group">
            <label className="form-label">Patrolling Guard</label>
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

          <div className="form-group">
            <label className="form-label">Target BLE Checkpoint</label>
            <select 
              value={selectedBeacon} 
              onChange={(e) => setSelectedBeacon(e.target.value)}
              className="select-field"
            >
              {beacons.map(b => (
                <option key={b.beacon_code} value={b.beacon_code}>
                  {b.beacon_code} - {b.checkpoint_name} ({b.zone_code})
                </option>
              ))}
            </select>
          </div>

          <div className="form-group">
            <label className="form-label">Signal RSSI dBm ({rssi} dBm)</label>
            <input 
              type="range" 
              min="-90" 
              max="-50" 
              value={rssi} 
              onChange={(e) => setRssi(e.target.value)}
              style={{ width: '100%', marginTop: '8px' }}
            />
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.7rem', color: 'var(--text-dim)', marginTop: '4px' }}>
              <span>Weak (-90)</span>
              <span>Strong (-50)</span>
            </div>
          </div>

          <div style={{ display: 'flex', alignItems: 'flex-end', marginBottom: '16px' }}>
            <button 
              type="submit" 
              className={`btn ${isPotentialZoneMismatch ? 'btn-danger' : 'btn-primary'}`}
              style={{ width: '100%', height: '42px' }}
            >
              <Zap size={16} />
              {isPotentialZoneMismatch ? 'Simulate Deviation Scan' : 'Verify Physical Scan'}
            </button>
          </div>
        </form>

        {isPotentialZoneMismatch && (
          <div style={{ fontSize: '0.78rem', color: '#f87171', marginTop: '6px' }}>
            ⚠️ Notice: Guard {targetGuard?.name} is assigned to <strong>{targetGuard?.assigned_zone}</strong>, but selected checkpoint is located in <strong>{targetBeacon?.zone_code}</strong>. Scanning will trigger an anti-cheat deviation violation in MySQL!
          </div>
        )}
      </div>

      {/* Filter and Search Bar */}
      <div className="glass-panel" style={{ padding: '16px 20px', marginBottom: '20px', display: 'flex', gap: '16px', alignItems: 'center', flexWrap: 'wrap' }}>
        <div style={{ position: 'relative', flex: '1', minWidth: '220px' }}>
          <Search size={16} color="var(--text-dim)" style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)' }} />
          <input 
            type="text" 
            placeholder="Search beacons by code, name, or description..." 
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="input-field"
            style={{ paddingLeft: '36px' }}
          />
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>Zone:</span>
          <select 
            value={zoneFilter} 
            onChange={(e) => setZoneFilter(e.target.value)}
            className="select-field"
            style={{ width: '140px' }}
          >
            {zonesList.map(z => (
              <option key={z} value={z}>{z}</option>
            ))}
          </select>
        </div>
      </div>

      {/* Checkpoints Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(340px, 1fr))', gap: '20px' }}>
        {filteredBeacons.map(beacon => (
          <div key={beacon.beacon_code} className="glass-panel" style={{ padding: '20px' }}>
            <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: '12px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                <div style={{
                  width: '38px',
                  height: '38px',
                  borderRadius: '10px',
                  background: 'rgba(59, 130, 246, 0.15)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  color: '#60a5fa'
                }}>
                  <Radio size={20} />
                </div>
                <div>
                  <h4 style={{ fontSize: '0.95rem', fontWeight: 700 }}>{beacon.checkpoint_name}</h4>
                  <span className="code-pill">{beacon.beacon_code}</span>
                </div>
              </div>
              <span className="badge badge-purple">{beacon.zone_code}</span>
            </div>

            <p style={{ fontSize: '0.8rem', color: 'var(--text-muted)', marginBottom: '14px', lineHeight: 1.4 }}>
              {beacon.location_desc || 'Campus perimeter anti-cheat checkpoint pillar.'}
            </p>

            <div style={{
              background: 'rgba(0,0,0,0.25)',
              padding: '10px 12px',
              borderRadius: 'var(--radius-md)',
              fontSize: '0.75rem',
              display: 'flex',
              flexDirection: 'column',
              gap: '6px'
            }}>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span style={{ color: 'var(--text-dim)' }}>Target Signal RSSI:</span>
                <span style={{ fontWeight: 600, color: '#10b981' }}>{beacon.target_rssi} dBm</span>
              </div>
              <div>
                <span style={{ color: 'var(--text-dim)', display: 'block', marginBottom: '2px' }}>UUID:</span>
                <span style={{ fontFamily: 'var(--font-mono)', fontSize: '0.68rem', color: 'var(--text-muted)', wordBreak: 'break-all' }}>
                  {beacon.beacon_uuid}
                </span>
              </div>
            </div>

            <button 
              onClick={() => {
                setSelectedBeacon(beacon.beacon_code);
                window.scrollTo({ top: 0, behavior: 'smooth' });
              }}
              className="btn btn-sm btn-secondary" 
              style={{ width: '100%', marginTop: '14px' }}
            >
              Simulate Guard Verification Scan
            </button>
          </div>
        ))}
      </div>
    </div>
  );
}
