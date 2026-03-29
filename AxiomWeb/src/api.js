// API_BASE = 'http://localhost:8766' // placeholder for Axiom's own API
const mockBeliefs = [
    {
        id: '1',
        text: 'Hard work always leads to success',
        score: 72,
        isCore: true,
        supportingCount: 4,
        contradictingCount: 2,
        createdAt: '2024-01-15T10:00:00Z',
        updatedAt: '2024-03-10T14:30:00Z'
    },
    {
        id: '2',
        text: 'People are fundamentally trustworthy',
        score: 55,
        isCore: false,
        supportingCount: 3,
        contradictingCount: 3,
        createdAt: '2024-02-01T09:00:00Z',
        updatedAt: '2024-03-10T14:30:00Z'
    },
    {
        id: '3',
        text: 'Technology improves mental well-being',
        score: 38,
        isCore: false,
        supportingCount: 2,
        contradictingCount: 5,
        createdAt: '2024-02-20T11:00:00Z',
        updatedAt: '2024-03-10T14:30:00Z'
    }
];
const mockEvidence = [
    { id: 'e1', beliefId: '1', text: 'I got promoted after months of dedication', type: 'support', createdAt: '2024-01-20T10:00:00Z' },
    { id: 'e2', beliefId: '1', text: 'Many hardworking people never reach their goals due to circumstances', type: 'contradict', createdAt: '2024-02-05T10:00:00Z' },
    { id: 'e3', beliefId: '2', text: 'My best friend has always been there for me', type: 'support', createdAt: '2024-02-10T10:00:00Z' },
    { id: 'e4', beliefId: '2', text: 'I was let go from a job without warning', type: 'contradict', createdAt: '2024-02-15T10:00:00Z' },
    { id: 'e5', beliefId: '3', text: 'Apps help me track my mood and habits', type: 'support', createdAt: '2024-02-25T10:00:00Z' },
    { id: 'e6', beliefId: '3', text: 'Social media increases my anxiety', type: 'contradict', createdAt: '2024-03-01T10:00:00Z' }
];
export async function getBeliefs() {
    // TODO: Connect to Axiom's local API when available
    return mockBeliefs;
}
export async function getEvidence(beliefId) {
    return mockEvidence.filter(e => e.beliefId === beliefId);
}
export async function runAIStressTest(_beliefId) {
    return [
        { challenge: "What evidence would need to be true for this belief to be false?", type: 'logic' },
        { challenge: "Is this belief based on a single experience or a pattern?", type: 'evidence' },
        { challenge: "What assumption am I making that might not hold?", type: 'assumption' }
    ];
}
