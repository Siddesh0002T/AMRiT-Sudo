import React, { useState } from 'react';
import { 
  X, 
  Radio, 
  UserCheck, 
  AlertTriangle, 
  Zap, 
  CheckCircle2, 
  MapPin,
  ShieldAlert
} from 'lucide-react';

export function SimulatorModal({ 
  isOpen, 
  onClose, 
  students = [], 
  guards = [], 
  zones = [], 
  beacons = [],
  onSimulateStudent, 
  onSimulateGuardPing, 
  onSimulateBeaconVisit 
}) {
  const [activeTab, setActiveTab] = useState('student');
  const [selectedStudentRoll, setSelectedStudentRoll] = useState(students[0]?.roll_number || '23CE001');
  const [studentAction, setStudentAction] = useState('STUDENT_IN');
  const [feedback, setFeedback] = useState(null);

  if (!isOpen) return null;

  const handleStudentRun = async () => {
    const res = await onSimulateStudent(selectedStudentRoll, studentAction);
    setFeedback({
      type: studentAction === 'EARLY_QUIT' ? 'danger' : 'success',
      text: `Simulation complete! Student status updated to "${res.live_status || studentAction}". Email dispatched to parent.`
    });
    setTimeout(() => setFeedback(null), 5000);
  };

  const handleGuardDeviation = async () => {
    // Force a mismatch: guard1 is assigned to ZONE-A, simulate ping in ZONE-C
    const res = await onSimulateGuardPing({
      username: 'guard1',
      current_zone: 'ZONE-C',
      status: 'warning_deviation',
      battery: 88,
      rssi: -72,
      message: 'Simulated deviation violation outside assigned ZONE-A'
    });
    setFeedback({
      type: 'danger',
      text: '⚠️ Anti-Cheat Warning simulated! Guard Vikram Singh flagged outside assigned ZONE-A.'
    });
    setTimeout(() => setFeedback(null), 5000);
  };

  const handleGuardInactivity = async () => {
    const res = await onSimulateGuardPing({
      username: 'guard2',
      current_zone: 'ZONE-B',
      status: 'warning_inactive',
      battery: 75,
      rssi: -65,
      message: 'Simulated prolonged inactivity exceeding 180 seconds'
    });
    setFeedback({
      type: 'warning',
      text: '⚠️ Inactivity alert simulated! Officer Ramesh Kumar flagged stationary in ZONE-B.'
    });
    setTimeout(() => setFeedback(null), 5000);
  };

  const handleBeaconSuccess = async () => {
    const res = await onSimulateBeaconVisit({
      guard_username: 'guard1',
      beacon_code: 'BCN-GATE-01',
      checkpoint_name: 'North Main Gate Checkpoint',
      zone_code: 'ZONE-A',
      rssi: -64
    });
    setFeedback({
      type: 'success',
      text: '✓ Physical checkpoint verified at North Main Gate with RSSI -64 dBm!'
    });
    setTimeout(() => setFeedback(null), 5000);
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" onClick={(e) => e.stopPropagation()} style={{ maxWidth: '620px' }}>
        <div className="modal-header">
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <Radio size={20} color="#8b5cf6" />
            <h3 style={{ fontSize: '1.15rem', fontWeight: 700 }}>BlueMesh Real-time Event Simulator</h3>
          </div>
          <button onClick={onClose} className="btn-ghost" style={{ padding: '4px' }}>
            <X size={18} />
          </button>
        </div>

        <div className="modal-body">
          <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)', marginBottom: '16px' }}>
            Test end-to-end BLE triggers, parental dispatch alerts, and anti-cheat guard deviations instantly without hardware.
          </p>

          {feedback && (
            <div style={{
              padding: '12px 16px',
              borderRadius: 'var(--radius-md)',
              marginBottom: '16px',
              background: feedback.type === 'danger' ? 'rgba(239, 68, 68, 0.15)' : feedback.type === 'warning' ? 'rgba(245, 158, 11, 0.15)' : 'rgba(16, 185, 129, 0.15)',
              border: `1px solid ${feedback.type === 'danger' ? 'rgba(239, 68, 68, 0.4)' : feedback.type === 'warning' ? 'rgba(245, 158, 11, 0.4)' : 'rgba(16, 185, 129, 0.4)'}`,
              fontSize: '0.85rem',
              fontWeight: 600,
              display: 'flex',
              alignItems: 'center',
              gap: '10px'
            }}>
              {feedback.type === 'danger' ? <AlertTriangle size={18} color="#ef4444" /> : <CheckCircle2 size={18} color="#10b981" />}
              <span>{feedback.text}</span>
            </div>
          )}

          {/* Quick preset cards */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
            
            {/* Action 1: Student Presence */}
            <div style={{
              padding: '16px',
              borderRadius: 'var(--radius-md)',
              background: 'rgba(255,255,255,0.02)',
              border: '1px solid var(--border-color)'
            }}>
              <div style={{ fontSize: '0.9rem', fontWeight: 700, marginBottom: '10px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                <UserCheck size={16} color="#60a5fa" />
                <span>Simulate Student BLE Arrival / Departure</span>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px', marginBottom: '12px' }}>
                <div>
                  <label className="form-label">Student</label>
                  <select 
                    value={selectedStudentRoll} 
                    onChange={(e) => setSelectedStudentRoll(e.target.value)}
                    className="select-field"
                  >
                    {students.map(s => (
                      <option key={s.roll_number} value={s.roll_number}>
                        {s.roll_number} - {s.name}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="form-label">Event</label>
                  <select 
                    value={studentAction} 
                    onChange={(e) => setStudentAction(e.target.value)}
                    className="select-field"
                  >
                    <option value="STUDENT_IN">🟢 Check-IN (Inside)</option>
                    <option value="EARLY_QUIT">⚠️ Early Quit Alert (Alerts Parent!)</option>
                    <option value="STUDENT_OUT">⚪ Normal Dismissal Exit</option>
                  </select>
                </div>
              </div>

              <button onClick={handleStudentRun} className="btn btn-sm btn-primary" style={{ width: '100%' }}>
                Trigger Student BLE Event
              </button>
            </div>

            {/* Action 2: Guard Anti-Cheat */}
            <div style={{
              padding: '16px',
              borderRadius: 'var(--radius-md)',
              background: 'rgba(255,255,255,0.02)',
              border: '1px solid var(--border-color)'
            }}>
              <div style={{ fontSize: '0.9rem', fontWeight: 700, marginBottom: '10px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                <ShieldAlert size={16} color="#f87171" />
                <span>Guard Anti-Cheat Deviation Testing</span>
              </div>

              <div style={{ display: 'flex', gap: '10px' }}>
                <button 
                  onClick={handleGuardDeviation}
                  className="btn btn-sm btn-danger"
                  style={{ flex: 1 }}
                >
                  <AlertTriangle size={14} />
                  Simulate Zone Deviation
                </button>
                <button 
                  onClick={handleGuardInactivity}
                  className="btn btn-sm btn-secondary"
                  style={{ flex: 1, color: '#fbbf24' }}
                >
                  <Zap size={14} />
                  Simulate Guard Inactivity
                </button>
              </div>
            </div>

            {/* Action 3: Hardware Checkpoint */}
            <div style={{
              padding: '16px',
              borderRadius: 'var(--radius-md)',
              background: 'rgba(255,255,255,0.02)',
              border: '1px solid var(--border-color)'
            }}>
              <div style={{ fontSize: '0.9rem', fontWeight: 700, marginBottom: '10px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                <MapPin size={16} color="#10b981" />
                <span>Hardware Checkpoint Verification</span>
              </div>

              <button 
                onClick={handleBeaconSuccess}
                className="btn btn-sm btn-secondary"
                style={{ width: '100%', color: '#34d399' }}
              >
                Simulate Successful Scan at BCN-GATE-01 (Zone A)
              </button>
            </div>

          </div>
        </div>

        <div className="modal-footer">
          <button onClick={onClose} className="btn btn-secondary">
            Done
          </button>
        </div>
      </div>
    </div>
  );
}
