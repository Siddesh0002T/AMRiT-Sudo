import React, { useState } from 'react';
import { 
  Users, 
  Plus, 
  Search, 
  Filter, 
  Fingerprint, 
  CheckCircle, 
  AlertCircle, 
  Trash2, 
  Radio, 
  Mail, 
  Phone,
  Clock,
  ShieldCheck
} from 'lucide-react';

export function StudentsTab({ 
  students = [], 
  onAddStudent, 
  onDeleteStudent, 
  onUpdateStudentStatus 
}) {
  const [search, setSearch] = useState('');
  const [sectionFilter, setSectionFilter] = useState('ALL');
  const [statusFilter, setStatusFilter] = useState('ALL');

  const filteredStudents = students.filter(student => {
    const matchesSearch = 
      student.name.toLowerCase().includes(search.toLowerCase()) ||
      student.roll_number.toLowerCase().includes(search.toLowerCase()) ||
      (student.parent_name && student.parent_name.toLowerCase().includes(search.toLowerCase()));
    
    const matchesSection = sectionFilter === 'ALL' || student.class_section === sectionFilter;
    const matchesStatus = statusFilter === 'ALL' || student.live_status === statusFilter;

    return matchesSearch && matchesSection && matchesStatus;
  });

  const sections = ['ALL', ...Array.from(new Set(students.map(s => s.class_section).filter(Boolean)))];

  return (
    <div>
      {/* Header & Actions */}
      <div style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        marginBottom: '20px',
        flexWrap: 'wrap',
        gap: '16px'
      }}>
        <div>
          <h2 style={{ fontSize: '1.4rem', fontWeight: 800 }}>Student Directory & Live Presence Tracking</h2>
          <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>
            BLE mesh classroom tracking, biometric fingerprint enrollment & live parent communications
          </p>
        </div>

        <button onClick={onAddStudent} className="btn btn-primary">
          <Plus size={16} />
          Register Student
        </button>
      </div>

      {/* Filter and Search Bar */}
      <div className="glass-panel" style={{ padding: '16px 20px', marginBottom: '20px', display: 'flex', gap: '16px', alignItems: 'center', flexWrap: 'wrap' }}>
        {/* Search */}
        <div style={{ position: 'relative', flex: '1', minWidth: '220px' }}>
          <Search size={16} color="var(--text-dim)" style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)' }} />
          <input 
            type="text" 
            placeholder="Search student by name, roll number, parent..." 
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="input-field"
            style={{ paddingLeft: '36px' }}
          />
        </div>

        {/* Section Filter */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>Section:</span>
          <select 
            value={sectionFilter} 
            onChange={(e) => setSectionFilter(e.target.value)}
            className="select-field"
            style={{ width: '130px' }}
          >
            {sections.map(sec => (
              <option key={sec} value={sec}>{sec}</option>
            ))}
          </select>
        </div>

        {/* Status Filter */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>Live Mesh:</span>
          <select 
            value={statusFilter} 
            onChange={(e) => setStatusFilter(e.target.value)}
            className="select-field"
            style={{ width: '150px' }}
          >
            <option value="ALL">All Statuses</option>
            <option value="INSIDE">🟢 INSIDE</option>
            <option value="EARLY_QUIT">🔴 EARLY QUIT</option>
            <option value="OUTSIDE">⚪ OUTSIDE</option>
          </select>
        </div>
      </div>

      {/* Students Data Table */}
      <div className="glass-panel table-container">
        <table className="data-table">
          <thead>
            <tr>
              <th>Roll Number</th>
              <th>Student Name</th>
              <th>Class / Sec</th>
              <th>Live Mesh Presence</th>
              <th>Biometrics</th>
              <th>Parent Details</th>
              <th>Last Seen</th>
              <th style={{ textAlign: 'right' }}>Simulate / Actions</th>
            </tr>
          </thead>
          <tbody>
            {filteredStudents.length === 0 ? (
              <tr>
                <td colSpan="8" style={{ textAlign: 'center', padding: '40px', color: 'var(--text-muted)' }}>
                  No students found matching your criteria.
                </td>
              </tr>
            ) : (
              filteredStudents.map(student => (
                <tr key={student.roll_number}>
                  <td>
                    <span className="code-pill" style={{ fontWeight: 600, fontSize: '0.82rem' }}>
                      {student.roll_number}
                    </span>
                  </td>
                  <td>
                    <div style={{ fontWeight: 700, color: '#fff' }}>{student.name}</div>
                    <div style={{ fontSize: '0.75rem', color: 'var(--text-dim)', display: 'flex', gap: '10px' }}>
                      {student.email && <span>{student.email}</span>}
                      {student.phone && <span>• {student.phone}</span>}
                    </div>
                  </td>
                  <td>
                    <span className="badge badge-primary">{student.class_section}</span>
                  </td>
                  <td>
                    {student.live_status === 'INSIDE' && (
                      <span className="badge badge-success">
                        <span className="pulsing-dot online" /> INSIDE CLASS
                      </span>
                    )}
                    {student.live_status === 'EARLY_QUIT' && (
                      <span className="badge badge-danger">
                        <span className="pulsing-dot warning" /> EARLY QUIT
                      </span>
                    )}
                    {student.live_status === 'OUTSIDE' && (
                      <span className="badge badge-subtle">
                        OUTSIDE
                      </span>
                    )}
                  </td>
                  <td>
                    {student.is_fingerprint_registered ? (
                      <span className="badge badge-purple" title="Fingerprint template stored">
                        <Fingerprint size={13} /> Registered
                      </span>
                    ) : (
                      <span className="badge badge-subtle" title="Biometric pending">
                        Pending
                      </span>
                    )}
                  </td>
                  <td>
                    <div style={{ fontSize: '0.82rem', fontWeight: 600 }}>{student.parent_name || 'N/A'}</div>
                    <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>
                      {student.parent_email}
                    </div>
                  </td>
                  <td>
                    <div style={{ fontSize: '0.75rem', fontFamily: 'var(--font-mono)', color: 'var(--text-muted)' }}>
                      {student.last_seen_at || 'No beacon ping'}
                    </div>
                  </td>
                  <td style={{ textAlign: 'right' }}>
                    <div style={{ display: 'inline-flex', gap: '6px' }}>
                      {/* Simulation buttons */}
                      <button 
                        onClick={() => onUpdateStudentStatus(student.roll_number, 'STUDENT_IN')}
                        className="btn btn-sm btn-secondary"
                        style={{ padding: '4px 8px', fontSize: '0.72rem' }}
                        title="Simulate student entering class"
                      >
                        In
                      </button>
                      <button 
                        onClick={() => onUpdateStudentStatus(student.roll_number, 'EARLY_QUIT')}
                        className="btn btn-sm btn-secondary"
                        style={{ padding: '4px 8px', fontSize: '0.72rem', color: '#f87171' }}
                        title="Simulate student quitting class early"
                      >
                        Quit
                      </button>
                      <button 
                        onClick={() => onUpdateStudentStatus(student.roll_number, 'STUDENT_OUT')}
                        className="btn btn-sm btn-secondary"
                        style={{ padding: '4px 8px', fontSize: '0.72rem' }}
                        title="Simulate normal dismissal exit"
                      >
                        Out
                      </button>
                      <button 
                        onClick={() => onDeleteStudent(student.roll_number)}
                        className="btn btn-sm btn-ghost"
                        style={{ padding: '4px 8px', color: '#ef4444' }}
                        title="Delete student record"
                      >
                        <Trash2 size={14} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
