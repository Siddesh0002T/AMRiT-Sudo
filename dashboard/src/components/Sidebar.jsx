import React from 'react';
import { 
  LayoutDashboard, 
  Users, 
  ShieldAlert, 
  Radio, 
  FileText, 
  Compass, 
  CalendarCheck, 
  HeartHandshake, 
  GraduationCap, 
  BellRing,
  Database,
  ChevronRight
} from 'lucide-react';

export function Sidebar({ 
  activeTab, 
  setActiveTab, 
  counts = {},
  isCollapsed,
  setIsCollapsed
}) {
  const navItems = [
    {
      id: 'overview',
      label: 'Command Center',
      icon: LayoutDashboard,
      badge: null
    },
    {
      id: 'students',
      label: 'Students & Presence',
      icon: Users,
      badge: counts.studentsInside ? `${counts.studentsInside} Inside` : null,
      badgeType: 'success'
    },
    {
      id: 'guards',
      label: 'Guard Patrol Anti-Cheat',
      icon: ShieldAlert,
      badge: counts.guardWarnings > 0 ? `${counts.guardWarnings} Alert` : null,
      badgeType: 'danger'
    },
    {
      id: 'beacons',
      label: 'BLE Patrol Beacons',
      icon: Radio,
      badge: counts.beacons ? `${counts.beacons} Active` : null,
      badgeType: 'primary'
    },
    {
      id: 'patrolLogs',
      label: 'Patrol Audit & Telemetry',
      icon: FileText,
      badge: null
    },
    {
      id: 'zones',
      label: 'Campus Explore Zones',
      icon: Compass,
      badge: null
    },
    {
      id: 'attendance',
      label: 'Attendance Sessions',
      icon: CalendarCheck,
      badge: null
    },
    {
      id: 'parents',
      label: 'Parent Portal Watch',
      icon: HeartHandshake,
      badge: null
    },
    {
      id: 'staff',
      label: 'Staff & Faculty',
      icon: GraduationCap,
      badge: null
    },
    {
      id: 'alerts',
      label: 'Realtime Alerts Hub',
      icon: BellRing,
      badge: counts.totalAlerts ? String(counts.totalAlerts) : null,
      badgeType: 'warning'
    }
  ];

  return (
    <aside style={{
      width: isCollapsed ? '76px' : '260px',
      background: 'rgba(9, 13, 22, 0.95)',
      borderRight: '1px solid var(--border-color)',
      display: 'flex',
      flexDirection: 'column',
      justifyContent: 'space-between',
      transition: 'width 0.25s ease',
      zIndex: 90,
      flexShrink: 0
    }}>
      {/* Top Nav Section */}
      <div style={{ padding: '16px 10px' }}>
        <div style={{
          padding: '0 8px 14px 8px',
          borderBottom: '1px solid var(--border-color)',
          marginBottom: '14px',
          display: 'flex',
          alignItems: 'center',
          justifyContent: isCollapsed ? 'center' : 'space-between'
        }}>
          {!isCollapsed && (
            <span style={{ 
              fontSize: '0.7rem', 
              fontWeight: 700, 
              color: 'var(--text-dim)', 
              textTransform: 'uppercase', 
              letterSpacing: '0.08em' 
            }}>
              System Navigation
            </span>
          )}
          <button 
            onClick={() => setIsCollapsed(!isCollapsed)}
            className="btn-ghost"
            style={{ 
              padding: '4px', 
              borderRadius: '6px', 
              color: 'var(--text-muted)',
              cursor: 'pointer' 
            }}
            title={isCollapsed ? 'Expand sidebar' : 'Collapse sidebar'}
          >
            <ChevronRight 
              size={16} 
              style={{ transform: isCollapsed ? 'none' : 'rotate(180deg)', transition: 'transform 0.2s' }} 
            />
          </button>
        </div>

        {/* Links */}
        <nav style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = activeTab === item.id;

            return (
              <button
                key={item.id}
                onClick={() => setActiveTab(item.id)}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '12px',
                  padding: isCollapsed ? '12px' : '10px 14px',
                  justifyContent: isCollapsed ? 'center' : 'flex-start',
                  borderRadius: 'var(--radius-md)',
                  background: isActive ? 'linear-gradient(135deg, rgba(59, 130, 246, 0.2) 0%, rgba(37, 99, 235, 0.1) 100%)' : 'transparent',
                  border: isActive ? '1px solid rgba(59, 130, 246, 0.4)' : '1px solid transparent',
                  color: isActive ? '#ffffff' : 'var(--text-muted)',
                  cursor: 'pointer',
                  width: '100%',
                  textAlign: 'left',
                  transition: 'all 0.18s ease',
                  position: 'relative'
                }}
                onMouseEnter={(e) => {
                  if (!isActive) {
                    e.currentTarget.style.background = 'rgba(255, 255, 255, 0.04)';
                    e.currentTarget.style.color = '#fff';
                  }
                }}
                onMouseLeave={(e) => {
                  if (!isActive) {
                    e.currentTarget.style.background = 'transparent';
                    e.currentTarget.style.color = 'var(--text-muted)';
                  }
                }}
                title={isCollapsed ? item.label : undefined}
              >
                <Icon size={18} color={isActive ? '#60a5fa' : 'currentColor'} />
                
                {!isCollapsed && (
                  <div style={{ 
                    flex: 1, 
                    display: 'flex', 
                    alignItems: 'center', 
                    justifyContent: 'space-between', 
                    overflow: 'hidden' 
                  }}>
                    <span style={{ 
                      fontSize: '0.85rem', 
                      fontWeight: isActive ? 700 : 500,
                      whiteSpace: 'nowrap',
                      textOverflow: 'ellipsis',
                      overflow: 'hidden'
                    }}>
                      {item.label}
                    </span>

                    {item.badge && (
                      <span className={`badge badge-${item.badgeType || 'primary'}`} style={{ fontSize: '0.65rem', padding: '2px 6px' }}>
                        {item.badge}
                      </span>
                    )}
                  </div>
                )}
              </button>
            );
          })}
        </nav>
      </div>

      {/* Footer Info Box */}
      <div style={{ padding: '14px', borderTop: '1px solid var(--border-color)' }}>
        {!isCollapsed ? (
          <div style={{
            background: 'rgba(255,255,255,0.02)',
            borderRadius: 'var(--radius-md)',
            padding: '12px',
            border: '1px solid var(--border-color)'
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '6px' }}>
              <Database size={14} color="#60a5fa" />
              <span style={{ fontSize: '0.75rem', fontWeight: 700, color: '#fff' }}>MySQL: bluemesh_db</span>
            </div>
            <div style={{ fontSize: '0.7rem', color: 'var(--text-dim)', lineHeight: 1.4 }}>
              Connected with 11 tables & anti-cheat BLE telemetry logs.
            </div>
          </div>
        ) : (
          <div style={{ display: 'flex', justifyContent: 'center' }}>
            <Database size={18} color="#60a5fa" title="bluemesh_db MySQL" />
          </div>
        )}
      </div>
    </aside>
  );
}
