import React, { useState, useEffect } from 'react';
import { 
  Shield, 
  Activity, 
  Wifi, 
  WifiOff, 
  Bell, 
  Settings, 
  Radio, 
  Clock, 
  Search,
  UserCheck
} from 'lucide-react';

export function Navbar({ 
  activeTab, 
  setActiveTab, 
  isLiveApi, 
  onOpenSettings, 
  alertsCount, 
  searchQuery, 
  setSearchQuery,
  onOpenSimulator
}) {
  const [time, setTime] = useState(new Date().toLocaleTimeString());

  useEffect(() => {
    const timer = setInterval(() => {
      setTime(new Date().toLocaleTimeString());
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  return (
    <header className="glass-panel" style={{
      borderRadius: 0,
      borderTop: 'none',
      borderLeft: 'none',
      borderRight: 'none',
      borderBottom: '1px solid var(--border-color)',
      padding: '12px 28px',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      position: 'sticky',
      top: 0,
      zIndex: 100,
      background: 'rgba(11, 16, 27, 0.85)'
    }}>
      {/* Brand & Title */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
        <div style={{
          width: '40px',
          height: '40px',
          borderRadius: '12px',
          background: 'linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          boxShadow: '0 0 16px rgba(59, 130, 246, 0.4)'
        }}>
          <Shield size={22} color="#ffffff" />
        </div>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <span style={{ fontSize: '1.25rem', fontWeight: 800, letterSpacing: '-0.02em', color: '#fff' }}>
              BlueMesh
            </span>
            <span style={{ 
              fontSize: '0.65rem', 
              fontWeight: 700, 
              background: 'rgba(59, 130, 246, 0.2)', 
              color: '#60a5fa', 
              padding: '2px 8px', 
              borderRadius: '999px',
              border: '1px solid rgba(59, 130, 246, 0.4)',
              textTransform: 'uppercase'
            }}>
              Institutional Core
            </span>
          </div>
          <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
            BLE Mesh Security, Anti-Cheat Patrol & Smart Attendance
          </p>
        </div>
      </div>

      {/* Global Search Bar */}
      <div style={{ position: 'relative', width: '300px' }}>
        <Search size={16} color="var(--text-dim)" style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)' }} />
        <input 
          type="text"
          placeholder="Quick search roll no, guard, zone..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="input-field"
          style={{ paddingLeft: '36px', height: '36px', fontSize: '0.8rem' }}
        />
      </div>

      {/* Actions & Connection Info */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
        {/* Simulation Shortcut Button */}
        <button 
          onClick={onOpenSimulator}
          className="btn btn-sm btn-primary"
          style={{ background: 'linear-gradient(135deg, #8b5cf6 0%, #6d28d9 100%)' }}
          title="Simulate Bluetooth beacon detection, Guard ping, or Student check-in"
        >
          <Radio size={14} />
          BLE Simulator
        </button>

        {/* Live Clock */}
        <div style={{ 
          display: 'flex', 
          alignItems: 'center', 
          gap: '6px', 
          fontSize: '0.8rem', 
          color: 'var(--text-muted)',
          background: 'rgba(255,255,255,0.03)',
          padding: '6px 12px',
          borderRadius: '8px',
          border: '1px solid var(--border-color)',
          fontFamily: 'var(--font-mono)'
        }}>
          <Clock size={13} color="#60a5fa" />
          <span>{time}</span>
        </div>

        {/* Backend Connection Indicator */}
        <div 
          onClick={onOpenSettings}
          style={{ 
            display: 'flex', 
            alignItems: 'center', 
            gap: '8px', 
            cursor: 'pointer',
            padding: '6px 12px',
            borderRadius: '8px',
            background: isLiveApi ? 'rgba(16, 185, 129, 0.1)' : 'rgba(245, 158, 11, 0.1)',
            border: `1px solid ${isLiveApi ? 'rgba(16, 185, 129, 0.3)' : 'rgba(245, 158, 11, 0.3)'}`,
            transition: 'all 0.2s'
          }}
          title="Click to configure PHP MySQL backend URL"
        >
          {isLiveApi ? (
            <>
              <Wifi size={14} color="#10b981" />
              <span style={{ fontSize: '0.75rem', fontWeight: 600, color: '#34d399' }}>PHP API Live</span>
            </>
          ) : (
            <>
              <Activity size={14} color="#f59e0b" />
              <span style={{ fontSize: '0.75rem', fontWeight: 600, color: '#fbbf24' }}>Local Mesh DB</span>
            </>
          )}
          <Settings size={12} color="var(--text-dim)" />
        </div>

        {/* Alerts Bell */}
        <button 
          onClick={() => setActiveTab('alerts')}
          className="btn-ghost"
          style={{ 
            position: 'relative', 
            padding: '8px', 
            borderRadius: '10px',
            border: '1px solid var(--border-color)',
            cursor: 'pointer'
          }}
          title="View recent alerts"
        >
          <Bell size={18} color="var(--text-muted)" />
          {alertsCount > 0 && (
            <span style={{
              position: 'absolute',
              top: '-4px',
              right: '-4px',
              background: '#ef4444',
              color: '#fff',
              fontSize: '0.65rem',
              fontWeight: 800,
              width: '18px',
              height: '18px',
              borderRadius: '50%',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              boxShadow: '0 0 8px rgba(239, 68, 68, 0.7)'
            }}>
              {alertsCount}
            </span>
          )}
        </button>

        {/* User Profile */}
        <div style={{
          display: 'flex',
          alignItems: 'center',
          gap: '10px',
          padding: '4px 8px 4px 12px',
          borderRadius: '24px',
          background: 'rgba(255,255,255,0.04)',
          border: '1px solid var(--border-color)'
        }}>
          <div style={{ textAlign: 'right' }}>
            <div style={{ fontSize: '0.8rem', fontWeight: 700, color: '#fff' }}>Admin</div>
            <div style={{ fontSize: '0.65rem', color: 'var(--text-dim)' }}>bluemesh_db</div>
          </div>
          <div style={{
            width: '32px',
            height: '32px',
            borderRadius: '50%',
            background: 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            color: '#fff'
          }}>
            <UserCheck size={16} />
          </div>
        </div>
      </div>
    </header>
  );
}
