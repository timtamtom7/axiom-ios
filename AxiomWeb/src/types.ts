export interface Belief {
  id: string
  text: string
  score: number
  isCore: boolean
  supportingCount: number
  contradictingCount: number
  createdAt: string
  updatedAt: string
}

export interface Evidence {
  id: string
  beliefId: string
  text: string
  type: 'support' | 'contradict'
  createdAt: string
}

export interface AISuggestion {
  challenge: string
  type: 'logic' | 'evidence' | 'assumption'
}
