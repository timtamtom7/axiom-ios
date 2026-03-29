export interface Patient {
  id: string
  name: string
  email: string
  joinedAt: string
  beliefCount: number
  avgScoreChange: number
  lastSession: string
  status: 'active' | 'paused'
}

export interface Belief {
  id: string
  patientId: string
  text: string
  score: number
  isCore: boolean
  supportingCount: number
  contradictingCount: number
  trend: 'improving' | 'stable' | 'declining'
  lastEvidenceAt: string
}

export interface SessionNote {
  id: string
  patientId: string
  therapistId: string
  date: string
  summary: string
  beliefWorkNotes: string
  recommendations: string
  nextSessionDate: string
}
