import React, { useState } from 'react';
import { X, ShieldPlus } from 'lucide-react';

export function AddGuardModal({ isOpen, onClose, onSave, zones = [] }) {
  const [formData, setFormData] = useState({
    username: '',
    password: 'guard123',
    name: '',
    phone: '',
    assigned_zone: 'ZONE-A'
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
            <ShieldPlus size={20} color="#10b981" />
            <h3 style={{ fontSize: '1.15rem', fontWeight: 700 }}>Enroll Security Guard</h3>
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
                  placeholder="e.g. guard4"
                  value={formData.username}
                  onChange={(e) => setFormData({ ...formData, username: e.target.value })}
                  className="input-field"
                />
              </div>

              <div className="form-group">
                <label className="form-label">Default Password</label>
                <input 
                  type="password" 
                  required
                  placeholder="guard123"
                  value={formData.password}
                  onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                  className="input-field"
                />
              </div>

              <div className="form-group" style={{ gridColumn: 'span 2' }}>
                <label className="form-label">Officer Full Name *</label>
                <input 
                  type="text" 
                  required
                  placeholder="e.g. Officer Suresh Patil"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  className="input-field"
                />
              </div>

              <div className="form-group">
                <label className="form-label">Officer Phone</label>
                <input 
                  type="tel" 
                  placeholder="e.g. 9876543296"
                  value={formData.phone}
                  onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                  className="input-field"
                />
              </div>

              <div className="form-group">
                <label className="form-label">Assigned Security Zone</label>
                <select 
                  value={formData.assigned_zone}
                  onChange={(e) => setFormData({ ...formData, assigned_zone: e.target.value })}
                  className="select-field"
                >
                  {zones.map(z => (
                    <option key={z.zone_code} value={z.zone_code}>
                      {z.zone_code} ({z.name.split(':')[0]})
                    </option>
                  ))}
                </select>
              </div>
            </div>
          </div>

          <div className="modal-footer">
            <button type="button" onClick={onClose} className="btn btn-secondary">
              Cancel
            </button>
            <button type="submit" className="btn btn-primary">
              Save Guard Account
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
