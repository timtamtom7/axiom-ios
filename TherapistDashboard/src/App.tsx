import { useState } from 'react'
import { mockPatients, mockBeliefs } from './api'
import type { Patient } from './types'
import './styles.css'

function App() {
  const [selectedPatient, setSelectedPatient] = useState<Patient | null>(null)
  const [patients] = useState(mockPatients)

  return (
    <div className="dashboard">
      <aside className="sidebar">
        <div className="logo">Axiom <span>Therapist</span></div>
        <div className="patient-list">
          {patients.map(p => (
            <div
              key={p.id}
              className={`patient-row ${selectedPatient?.id === p.id ? 'active' : ''}`}
              onClick={() => setSelectedPatient(p)}
            >
              <div className="patient-avatar">{p.name[0]}</div>
              <div className="patient-info">
                <div className="patient-name">{p.name}</div>
                <div className="patient-meta">{p.beliefCount} beliefs · {p.avgScoreChange > 0 ? '+' : ''}{p.avgScoreChange}%</div>
              </div>
              <div className={`status-dot ${p.status}`} />
            </div>
          ))}
        </div>
      </aside>

      <main className="content">
        {selectedPatient ? (
          <PatientDetail patient={selectedPatient} />
        ) : (
          <div className="empty-state">
            <div className="empty-icon">👈</div>
            <div className="empty-title">Select a patient</div>
            <div className="empty-subtitle">Choose a patient from the sidebar to view their belief work</div>
          </div>
        )}
      </main>
    </div>
  )
}

function PatientDetail({ patient }: { patient: Patient }) {
  const beliefs = mockBeliefs.filter(b => b.patientId === patient.id)

  return (
    <div className="patient-detail">
      <div className="patient-header">
        <div className="avatar-lg">{patient.name[0]}</div>
        <div>
          <h1>{patient.name}</h1>
          <p>{patient.email}</p>
          <p>Member since {new Date(patient.joinedAt).toLocaleDateString()}</p>
        </div>
      </div>

      <div className="stats-grid">
        <div className="stat-card">
          <div className="stat-value">{patient.beliefCount}</div>
          <div className="stat-label">Beliefs</div>
        </div>
        <div className="stat-card">
          <div className="stat-value" style={{ color: patient.avgScoreChange > 0 ? '#4ade80' : '#ef4444' }}>
            {patient.avgScoreChange > 0 ? '+' : ''}{patient.avgScoreChange}%
          </div>
          <div className="stat-label">Avg. Score Change</div>
        </div>
        <div className="stat-card">
          <div className="stat-value">{patient.lastSession || 'No sessions'}</div>
          <div className="stat-label">Last Session</div>
        </div>
      </div>

      <div className="section">
        <h2>Belief Network</h2>
        <div className="belief-list">
          {beliefs.map(belief => (
            <div key={belief.id} className={`belief-card ${belief.isCore ? 'core' : ''}`}>
              <div className="belief-text">
                {belief.isCore && <span className="core-badge">Core</span>}
                {belief.text}
              </div>
              <div className="belief-meta">
                <span className="score">Score: {belief.score}%</span>
                <span className={`trend ${belief.trend}`}>{belief.trend}</span>
                <span className="evidence">{belief.supportingCount} ↑ {belief.contradictingCount} ↓</span>
              </div>
            </div>
          ))}
        </div>
      </div>

      <div className="section">
        <h2>Session Notes</h2>
        <button className="btn-primary">+ New Session Note</button>
      </div>
    </div>
  )
}

export default App
