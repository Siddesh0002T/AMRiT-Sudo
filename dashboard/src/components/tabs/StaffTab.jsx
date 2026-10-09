import React, { useState } from 'react';
import { 
  GraduationCap, 
  Plus, 
  Search, 
  Trash2, 
  Mail, 
  Phone, 
  Building,
  UserCheck
} from 'lucide-react';

export function StaffTab({ 
  staff = [], 
  onAddStaff, 
  onDeleteStaff 
}) {
  const [search, setSearch] = useState('');

  const filteredStaff = staff.filter(s => 
    s.name.toLowerCase().includes(search.toLowerCase()) ||
    s.username.toLowerCase().includes(search.toLowerCase()) ||
    s.department.toLowerCase().includes(search.toLowerCase())
  );

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
          <h2 style={{ fontSize: '1.4rem', fontWeight: 800 }}>Faculty & Staff Directory</h2>
          <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>
            Institutional educators, attendance session proctors & security zone managers
          </p>
        </div>

        <button onClick={onAddStaff} className="btn btn-primary">
          <Plus size={16} />
          Add Faculty / Staff
        </button>
      </div>

      {/* Search */}
      <div className="glass-panel" style={{ padding: '16px 20px', marginBottom: '20px' }}>
        <div style={{ position: 'relative', maxWidth: '350px' }}>
          <Search size={16} color="var(--text-dim)" style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)' }} />
          <input 
            type="text" 
            placeholder="Search staff by name, department, username..." 
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="input-field"
            style={{ paddingLeft: '36px' }}
          />
        </div>
      </div>

      {/* Staff Table */}
      <div className="glass-panel table-container">
        <table className="data-table">
          <thead>
            <tr>
              <th>Username</th>
              <th>Faculty Name</th>
              <th>Department</th>
              <th>Institutional Role</th>
              <th>Contact Details</th>
              <th>Created Date</th>
              <th style={{ textAlign: 'right' }}>Actions</th>
            </tr>
          </thead>
          <tbody>
            {filteredStaff.length === 0 ? (
              <tr>
                <td colSpan="7" style={{ textAlign: 'center', padding: '40px', color: 'var(--text-muted)' }}>
                  No staff members found matching query.
                </td>
              </tr>
            ) : (
              filteredStaff.map(member => (
                <tr key={member.id}>
                  <td>
                    <span className="code-pill">@{member.username}</span>
                  </td>
                  <td>
                    <div style={{ fontWeight: 700, color: '#fff' }}>{member.name}</div>
                  </td>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '0.82rem' }}>
                      <Building size={14} color="#60a5fa" />
                      <span>{member.department}</span>
                    </div>
                  </td>
                  <td>
                    <span className="badge badge-purple">{member.role}</span>
                  </td>
                  <td>
                    <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>
                      <div>{member.email}</div>
                      <div>{member.phone}</div>
                    </div>
                  </td>
                  <td>
                    <span style={{ fontSize: '0.75rem', fontFamily: 'var(--font-mono)', color: 'var(--text-dim)' }}>
                      {member.created_at || 'Auto-created'}
                    </span>
                  </td>
                  <td style={{ textAlign: 'right' }}>
                    <button 
                      onClick={() => onDeleteStaff(member.id)}
                      className="btn-ghost"
                      style={{ color: '#ef4444', padding: '6px' }}
                      title="Remove staff member"
                    >
                      <Trash2 size={16} />
                    </button>
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
