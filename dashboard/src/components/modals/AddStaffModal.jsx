import React, { useState } from 'react';
import { X, UserCheck } from 'lucide-react';

export function AddStaffModal({ isOpen, onClose, onSave }) {
  const [formData, setFormData] = useState({
    username: '',
    password: 'staff123',
    name: '',
    email: '',
    phone: '',
    department: 'Computer Science',
    role: 'Faculty'
  });

  if (!isOpen) return null;

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!formData.username || !formData.name) return;
    onSave(formData);
    onClose();
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <UserCheck size={20} color="#8b5cf6" />
            <h3 style={{ fontSize: '1.15rem', fontWeight: 700 }}>Add Faculty / Staff Account</h3>
          </div>
          <button onClick={onClose} className="btn-ghost" style={{ padding: '4px' }}>
            <X size={18} />
          </button>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="modal-body">
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
              <div className="form-group">
                <label className="form-label">Username *</label>
                <input 
                  type="text" 
                  required
                  placeholder="e.g. staff4"
                  value={formData.username}
                  onChange={(e) => setFormData({ ...formData, username: e.target.value })}
                  className="input-field"
                />
              </div>

              <div className="form-group">
                <label className="form-label">Password *</label>
                <input 
                  type="password" 
                  required
                  placeholder="staff123"
                  value={formData.password}
                  onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                  className="input-field"
                />
              </div>

              <div className="form-group" style={{ gridColumn: 'span 2' }}>
                <label className="form-label">Full Name *</label>
                <input 
                  type="text" 
                  required
                  placeholder="e.g. Dr. Ada Lovelace"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  className="input-field"
                />
              </div>

              <div className="form-group">
                <label className="form-label">Department</label>
                <input 
                  type="text" 
                  placeholder="e.g. Computer Science"
                  value={formData.department}
                  onChange={(e) => setFormData({ ...formData, department: e.target.value })}
                  className="input-field"
                />
              </div>

              <div className="form-group">
                <label className="form-label">Institutional Role</label>
                <input 
                  type="text" 
                  placeholder="e.g. Faculty / Assistant Professor"
                  value={formData.role}
                  onChange={(e) => setFormData({ ...formData, role: e.target.value })}
                  className="input-field"
                />
              </div>

              <div className="form-group">
                <label className="form-label">Official Email</label>
                <input 
                  type="email" 
                  placeholder="e.g. ada@institution.edu"
                  value={formData.email}
                  onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                  className="input-field"
                />
              </div>

              <div className="form-group">
                <label className="form-label">Phone</label>
                <input 
                  type="tel" 
                  placeholder="e.g. 9876543204"
                  value={formData.phone}
                  onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                  className="input-field"
                />
              </div>
            </div>
          </div>

          <div className="modal-footer">
            <button type="button" onClick={onClose} className="btn btn-secondary">
              Cancel
            </button>
            <button type="submit" className="btn btn-primary">
              Create Staff Account
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
