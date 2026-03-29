import { useState, useEffect } from 'react'
import type { Belief, Evidence, AISuggestion } from './types'
import { getBeliefs, getEvidence, runAIStressTest } from './api'

type Tab = 'support' | 'contradict' | 'stress'

function App() {
  const [beliefs, setBeliefs] = useState<Belief[]>([])
  const [selected, setSelected] = useState<Belief | null>(null)
  const [evidence, setEvidence] = useState<Evidence[]>([])
  const [suggestions, setSuggestions] = useState<AISuggestion[]>([])
  const [tab, setTab] = useState<Tab>('support')
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    getBeliefs().then(b => {
      setBeliefs(b)
      setSelected(b[0] ?? null)
      setLoading(false)
    })
  }, [])

  useEffect(() => {
    if (!selected) return
    getEvidence(selected.id).then(setEvidence)
    runAIStressTest(selected.id).then(setSuggestions)
  }, [selected])

  if (loading) {
    return (
      <div className="loading">
        <span>Loading beliefs...</span>
      </div>
    )
  }

  const supporting = evidence.filter(e => e.type === 'support')
  const contradicting = evidence.filter(e => e.type === 'contradict')

  return (
    <div className="app">
      <header className="header">
        <h1 className="logo">Axiom</h1>
        <span className="count">{beliefs.length} beliefs</span>
      </header>

      <div className="layout">
        <aside className="sidebar">
          {beliefs.map(b => (
            <button
              key={b.id}
              className={`belief-item ${selected?.id === b.id ? 'active' : ''}`}
              onClick={() => setSelected(b)}
            >
              <span className="belief-text">{b.text}</span>
              <div className="belief-meta">
                <span className="score" style={{ color: b.score >= 50 ? '#4ade80' : '#ef4444' }}>
                  {b.score}%
                </span>
                {b.isCore && <span className="core-badge">core</span>}
              </div>
            </button>
          ))}
        </aside>

        <main className="detail">
          {selected ? (
            <>
              <div className="belief-header">
                <h2 className="belief-title">{selected.text}</h2>
                <div className="belief-stats">
                  <span
                    className="stat-score"
                    style={{ color: selected.score >= 50 ? '#4ade80' : '#ef4444' }}
                  >
                    {selected.score}% confidence
                  </span>
                  {selected.isCore && <span className="core-badge">core belief</span>}
                </div>
              </div>

              <div className="tabs">
                <button className={`tab ${tab === 'support' ? 'active' : ''}`} onClick={() => setTab('support')}>
                  Supporting ({supporting.length})
                </button>
                <button className={`tab ${tab === 'contradict' ? 'active' : ''}`} onClick={() => setTab('contradict')}>
                  Contradicting ({contradicting.length})
                </button>
                <button className={`tab ${tab === 'stress' ? 'active' : ''}`} onClick={() => setTab('stress')}>
                  AI Stress Test
                </button>
              </div>

              <div className="tab-content">
                {tab === 'support' && (
                  <ul className="evidence-list">
                    {supporting.length === 0 && <li className="empty">No supporting evidence yet.</li>}
                    {supporting.map(e => (
                      <li key={e.id} className="evidence-item support">
                        <span className="evidence-dot" />
                        <p>{e.text}</p>
                      </li>
                    ))}
                  </ul>
                )}

                {tab === 'contradict' && (
                  <ul className="evidence-list">
                    {contradicting.length === 0 && <li className="empty">No contradicting evidence yet.</li>}
                    {contradicting.map(e => (
                      <li key={e.id} className="evidence-item contradict">
                        <span className="evidence-dot" />
                        <p>{e.text}</p>
                      </li>
                    ))}
                  </ul>
                )}

                {tab === 'stress' && (
                  <ul className="suggestion-list">
                    {suggestions.map((s, i) => (
                      <li key={i} className={`suggestion-item ${s.type}`}>
                        <span className="suggestion-type">{s.type}</span>
                        <p>{s.challenge}</p>
                      </li>
                    ))}
                  </ul>
                )}
              </div>
            </>
          ) : (
            <div className="empty-state">
              <p>Select a belief to view details.</p>
            </div>
          )}
        </main>
      </div>
    </div>
  )
}

export default App
