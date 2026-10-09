import React, { useState } from 'react';
import { 
  X, 
  Wifi, 
  CheckCircle, 
  AlertCircle, 
  Server, 
  Terminal, 
  ExternalLink 
} from 'lucide-react';
import { getApiBaseUrl, setApiBaseUrl, apiService } from '../../services/apiService';

export function ApiSettingsModal({ isOpen, onClose, onConnectionChanged }) {
  const [url, setUrl] = useState(getApiBaseUrl());
  const [testing, setTesting] = useState(false);
  const [testResult, setTestResult] = useState(null);

  if (!isOpen) return null;

  const handleTest = async () => {
    setTesting(true);
    setTestResult(null);
    setApiBaseUrl(url);

    const res = await apiService.checkHealth();
    setTesting(false);

    if (res.isLive && res.data) {
      setTestResult({
        success: true,
        message: `Connected successfully to ${res.data.system || 'BlueMesh API'}! Database: ${res.data.connected_db || 'bluemesh_db'}`
      });
      onConnectionChanged(true);
    } else {
      setTestResult({
        success: false,
        message: `Could not reach ${url}. Fallback Local Mesh DB is active for simulation.`
      });
      onConnectionChanged(false);
    }
  };

  const handleSave = () => {
    setApiBaseUrl(url);
    handleTest();
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <Server size={20} color="#3b82f6" />
            <h3 style={{ fontSize: '1.15rem', fontWeight: 700 }}>MySQL & PHP Backend API Settings</h3>
          </div>
          <button onClick={onClose} className="btn-ghost" style={{ padding: '4px' }}>
            <X size={18} />
          </button>
        </div>

        <div className="modal-body">
          <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)', marginBottom: '16px' }}>
            Connect this dashboard directly to your local PHP server or Apache/XAMPP environment running <code className="code-pill">backend/api.php</code>.
          </p>

          <div className="form-group">
            <label className="form-label">PHP API Controller Endpoint URL</label>
            <input 
              type="text" 
              value={url} 
              onChange={(e) => setUrl(e.target.value)}
              placeholder="http://localhost:8000/api.php"
              className="input-field"
              style={{ fontFamily: 'var(--font-mono)' }}
            />
          </div>

          {/* Quick preset buttons */}
          <div style={{ display: 'flex', gap: '8px', marginBottom: '16px', flexWrap: 'wrap' }}>
            <button 
              type="button" 
              onClick={() => setUrl('http://localhost:8000/api.php')} 
              className="btn btn-sm btn-secondary"
              style={{ fontSize: '0.72rem' }}
            >
              Preset: localhost:8000
            </button>
            <button 
              type="button" 
              onClick={() => setUrl('http://localhost/AMRiT-Sudo/backend/api.php')} 
              className="btn btn-sm btn-secondary"
              style={{ fontSize: '0.72rem' }}
            >
              Preset: XAMPP Apache
            </button>
            <button 
              type="button" 
              onClick={() => setUrl('http://127.0.0.1:8000/api.php')} 
              className="btn btn-sm btn-secondary"
              style={{ fontSize: '0.72rem' }}
            >
              Preset: 127.0.0.1:8000
            </button>
          </div>

          {testResult && (
            <div style={{
              padding: '12px 14px',
              borderRadius: 'var(--radius-md)',
              marginBottom: '16px',
              background: testResult.success ? 'rgba(16, 185, 129, 0.15)' : 'rgba(245, 158, 11, 0.15)',
              border: `1px solid ${testResult.success ? 'rgba(16, 185, 129, 0.4)' : 'rgba(245, 158, 11, 0.4)'}`,
              display: 'flex',
              alignItems: 'center',
              gap: '10px',
              fontSize: '0.85rem'
            }}>
              {testResult.success ? <CheckCircle size={18} color="#10b981" /> : <AlertCircle size={18} color="#f59e0b" />}
              <span>{testResult.message}</span>
            </div>
          )}

          {/* Instructions Box */}
          <div style={{
            background: 'rgba(0, 0, 0, 0.3)',
            borderRadius: 'var(--radius-md)',
            padding: '14px',
            border: '1px solid var(--border-color)',
            fontSize: '0.78rem',
            color: 'var(--text-muted)'
          }}>
            <div style={{ fontWeight: 700, color: '#fff', marginBottom: '6px', display: 'flex', alignItems: 'center', gap: '6px' }}>
              <Terminal size={14} color="#60a5fa" />
              To start local PHP server in terminal:
            </div>
            <pre style={{
              fontFamily: 'var(--font-mono)',
              background: 'rgba(0,0,0,0.5)',
              padding: '8px 10px',
              borderRadius: '6px',
              color: '#93c5fd',
              marginTop: '4px',
              overflowX: 'auto'
            }}>
cd e:\hackThon\AMRiT-Sudo\backend
php -S localhost:8000
            </pre>
            <div style={{ marginTop: '8px', fontSize: '0.72rem', color: 'var(--text-dim)' }}>
              Note: If PHP is not currently running, the dashboard continues working seamlessly in high-fidelity local database simulation mode!
            </div>
          </div>
        </div>

        <div className="modal-footer">
          <button onClick={onClose} className="btn btn-secondary">
            Close
          </button>
          <button onClick={handleSave} disabled={testing} className="btn btn-primary">
            {testing ? 'Testing Connection...' : 'Save & Test Connection'}
          </button>
        </div>
      </div>
    </div>
  );
}
