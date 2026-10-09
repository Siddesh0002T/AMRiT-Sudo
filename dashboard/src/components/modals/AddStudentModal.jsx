import React, { useState } from 'react';
import { X, UserPlus, Fingerprint } from 'lucide-react';

export function AddStudentModal({ isOpen, onClose, onSave }) {
  const [formData, setFormData] = useState({
    roll_number: '',
    name: '',
    class_section: 'CS-A',
    email: '',
    phone: '',
    is_fingerprint_registered: 1,
    parent_name: '',
    parent_email: '',
    parent_phone: ''
  });

  if (!isOpen) return null;

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!formData.roll_number || !formData.name) return;
    onSave(formData);
    onClose();
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <UserPlus size={20} color="#3b82f6" />
            <h3 style={{ fontSize: '1.15rem', fontWeight: 700 }}>Register New Student</h3>
          </div>
          <button onClick={onClose} className="btn-ghost" style={{ padding: '4px' }}>
            <X size={18} />
          </button>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="modal-body">
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
              <div className="form-group">
                <label className="form-label">Roll Number *</label>
                <input 
                  type="text" 
                  required
                  placeholder="e.g. 23CE006"
                  value={formData.roll_number}
                  onChange={(e) => setFormData({ ...formData, roll_number: e.target.value.toUpperCase() })}
                  className="input-field"
                />
              </div>

              <div className="form-group">
                <label className="form-label">Full Name *</label>
                <input 
                  type="text" 
                  required
                  placeholder="e.g. Rahul Verma"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  className="input-field"
                />
              </div>

              <div className="form-group">
                <label className="form-label">Class Section</label>
                <select 
                  value={formData.class_section}
                  onChange={(e) => setFormData({ ...formData, class_section: e.target.value })}
                  className="select-field"
                >
                  <option value="CS-A">CS-A</option>
                  <option value="CS-B">CS-B</option>
                  <option value="SE-A">SE-A</option>
                  <option value="IT-A">IT-A</option>
                </select>
              </div>

              <div className="form-group">
                <label className="form-label">Student Phone</label>
                <input 
                  type="tel" 
                  placeholder="e.g. 9876543215"
                  value={formData.phone}
                  onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                  className="input-field"
                />
              </div>

              <div className="form-group" style={{ gridColumn: 'span 2' }}>
                <label className="form-label">Student Email</label>
                <input 
                  type="email" 
                  placeholder="e.g. rahul@student.edu"
                  value={formData.email}
                  onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                  className="input-field"
                />
              </div>

              <div className="form-group" style={{ gridColumn: 'span 2', margin: '4px 0' }}>
                <label style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer', fontSize: '0.85rem' }}>
                  <input 
                    type="checkbox" 
                    checked={formData.is_fingerprint_registered === 1}
                    onChange={(e) => setFormData({ ...formData, is_fingerprint_registered: e.target.checked ? 1 : 0 })}
                  />
                  <span>Enroll Biometric Fingerprint Template in MySQL</span>
                </label>
              </div>

              <div style={{ gridColumn: 'span 2', borderTop: '1px solid var(--border-color)', paddingTop: '14px', marginTop: '6px' }}>
                <div style={{ fontSize: '0.85rem', fontWeight: 700, color: '#93c5fd', marginBottom: '10px' }}>
                  Parent / Guardian Details (For Automated SMS/Email Alerts)
                </div>
              </div>

              <div className="form-group">
                <label className="form-label">Parent Name</label>
                <input 
                  type="text" 
                  placeholder="e.g. Mohan Verma"
                  value={formData.parent_name}
                  onChange={(e) => setFormData({ ...formData, parent_name: e.target.value })}
                  className="input-field"
                />
              </div>

              <div className="form-group">
                <label className="form-label">Parent Phone</label>
                <input 
                  type="tel" 
                  placeholder="e.g. 9876500006"
                  value={formData.parent_phone}
                  onChange={(e) => setFormData({ ...formData, parent_phone: e.target.value })}
                  className="input-field"
                />
              </div>

              <div className="form-group" style={{ gridColumn: 'span 2' }}>
                <label className="form-label">Parent Email (Receives Alerts)</label>
                <input 
                  type="email" 
                  placeholder="e.g. parent.rahul@example.com"
                  value={formData.parent_email}
                  onChange={(e) => setFormData({ ...formData, parent_email: e.target.value })}
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
              Register Student to MySQL
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
