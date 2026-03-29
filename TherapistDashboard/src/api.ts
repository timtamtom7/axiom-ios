import type { Patient, Belief, SessionNote } from './types'

// Axiom API: http://localhost:8766 (TODO: connect)

export const mockPatients: Patient[] = [
  {
    id: 'p1',
    name: 'Sarah Chen',
    email: 'sarah.chen@example.com',
    joinedAt: '2025-09-12',
    beliefCount: 14,
    avgScoreChange: 12,
    lastSession: 'Mar 24',
    status: 'active',
  },
  {
    id: 'p2',
    name: 'Marcus Williams',
    email: 'marcus.w@example.com',
    joinedAt: '2025-11-03',
    beliefCount: 8,
    avgScoreChange: -3,
    lastSession: 'Mar 22',
    status: 'active',
  },
  {
    id: 'p3',
    name: 'Elena Rodriguez',
    email: 'elena.r@example.com',
    joinedAt: '2026-01-18',
    beliefCount: 5,
    avgScoreChange: 7,
    lastSession: 'Mar 27',
    status: 'active',
  },
  {
    id: 'p4',
    name: 'James O\'Brien',
    email: 'james.obrien@example.com',
    joinedAt: '2025-07-29',
    beliefCount: 21,
    avgScoreChange: 18,
    lastSession: 'Mar 20',
    status: 'paused',
  },
]

export const mockBeliefs: Belief[] = [
  { id: 'b1', patientId: 'p1', text: 'I am capable of handling difficult emotions', score: 72, isCore: true, supportingCount: 8, contradictingCount: 2, trend: 'improving', lastEvidenceAt: '2026-03-24' },
  { id: 'b2', patientId: 'p1', text: 'My worth depends on my productivity', score: 45, isCore: false, supportingCount: 3, contradictingCount: 6, trend: 'declining', lastEvidenceAt: '2026-03-20' },
  { id: 'b3', patientId: 'p1', text: 'I deserve love and connection', score: 81, isCore: true, supportingCount: 11, contradictingCount: 1, trend: 'stable', lastEvidenceAt: '2026-03-18' },
  { id: 'b4', patientId: 'p2', text: 'I must always be in control', score: 58, isCore: true, supportingCount: 4, contradictingCount: 5, trend: 'stable', lastEvidenceAt: '2026-03-22' },
  { id: 'b5', patientId: 'p2', text: 'Asking for help is a sign of weakness', score: 39, isCore: false, supportingCount: 2, contradictingCount: 7, trend: 'declining', lastEvidenceAt: '2026-03-15' },
  { id: 'b6', patientId: 'p3', text: 'My anxiety defines who I am', score: 62, isCore: false, supportingCount: 5, contradictingCount: 3, trend: 'improving', lastEvidenceAt: '2026-03-27' },
  { id: 'b7', patientId: 'p4', text: 'I am fundamentally broken', score: 28, isCore: true, supportingCount: 2, contradictingCount: 14, trend: 'improving', lastEvidenceAt: '2026-03-19' },
  { id: 'b8', patientId: 'p4', text: 'Recovery is possible for me', score: 74, isCore: true, supportingCount: 9, contradictingCount: 3, trend: 'improving', lastEvidenceAt: '2026-03-20' },
]

export async function getPatients(): Promise<Patient[]> {
  return mockPatients // TODO: connect to Axiom API
}

export async function getPatientBeliefs(patientId: string): Promise<Belief[]> {
  return mockBeliefs.filter(b => b.patientId === patientId)
}

export async function createSessionNote(note: Omit<SessionNote, 'id'>): Promise<SessionNote> {
  return { ...note, id: crypto.randomUUID() }
}
