# Axiom — Belief Audit iOS App Specification

## 1. Project Overview

- **Project Name:** Axiom
- **Bundle Identifier:** com.axiom.beliefaudit
- **Core Functionality:** A belief audit app that helps users surface, collect evidence for/against, and stress-test their self-beliefs using AI. Tracks belief strength over time via a scoring system.
- **Target Users:** Intellectually curious individuals interested in self-examination and cognitive clarity
- **iOS Version Support:** iOS 26.0+
- **Architecture:** MVVM with Services layer

---

## 2. UI/UX Specification

### Screen Structure

1. **BeliefListView** — Main screen: list of all beliefs with scores
2. **AddBeliefView** — Sheet: enter a new belief
3. **BeliefDetailView** — Full belief view with evidence + AI stress test
4. **AddEvidenceView** — Sheet: add supporting or contradicting evidence
5. **AIStressTestView** — Sheet: AI challenges the belief
6. **BeliefMapView** — Network graph of beliefs and their connections

### Navigation Structure
- `NavigationStack` with programmatic navigation
- Bottom sheet modals for add/edit flows
- Tab bar with 2 tabs: Beliefs, Map

### Visual Design

#### Color Palette
| Name | Hex | Usage |
|------|-----|-------|
| Background | `#1A1A1A` | Main background |
| Surface | `#242424` | Cards, sheets |
| SurfaceElevated | `#2E2E2E` | Elevated cards |
| TextPrimary | `#FFFFFF` | Headings, primary text |
| TextSecondary | `#9E9E9E` | Secondary text, labels |
| AccentGreen | `#4CAF50` | Supporting evidence |
| AccentRed | `#EF5350` | Contradicting evidence |
| AccentBlue | `#42A5F5` | AI/challenge accent |
| AccentGold | `#FFCA28` | Belief score highlight |
| Border | `#3A3A3A` | Dividers, borders |

#### Typography
| Style | Font | Size | Weight |
|-------|------|------|--------|
| LargeTitle | SF Pro Display | 34pt | Bold |
| Title | SF Pro Display | 22pt | Bold |
| Headline | SF Pro Text | 17pt | Semibold |
| Body | SF Pro Text | 17pt | Regular |
| Callout | SF Pro Text | 16pt | Regular |
| Caption | SF Pro Text | 12pt | Regular |

#### Spacing
- Base unit: 8pt grid
- Card padding: 16pt
- Section spacing: 24pt
- Screen margins: 20pt

### Views & Components

#### BeliefCard
- Shows belief text (truncated to 2 lines)
- Score badge (0-100, color-coded: red <40, yellow 40-70, green >70)
- Evidence count (supporting / contradicting)
- Last updated date
- Tap → BeliefDetailView

#### EvidenceRow
- Evidence text
- Type indicator (green checkmark / red X)
- Timestamp
- Swipe to delete

#### StressTestCard
- AI challenge question
- User response input
- Submit button

#### BeliefNode (Map)
- Circular node, size based on centrality
- Color based on score
- Label with truncated belief text
- Connections to related beliefs

---

## 3. Functionality Specification

### Core Features

#### F1: Belief Entry
- User taps "+" to add belief
- Text field with placeholder: "I am..."
- Validation: minimum 5 characters
- Save creates belief with empty evidence lists, score = 50 (neutral)

#### F2: Evidence Collector
- For each belief, add evidence that SUPPORTS it
- For each belief, add evidence that CONTRADICTS it
- Evidence has: text, type (support/contradict), timestamp
- Evidence can be deleted (swipe)
- Evidence count displayed on belief card

#### F3: AI Stress Test (Apple Intelligence)
- Trigger "Stress Test" button on belief detail
- App uses Apple Intelligence (Image Playground API or Writing Tools) to generate challenging questions
- Fallback: predefined challenge prompts if AI unavailable
- Questions challenge the logic, evidence quality, and assumptions
- User can write their reflection in response

#### F4: Belief Score
- Score = (supporting_count + 1) / (supporting_count + contradicting_count + 2) * 100
- Clamped to 0-100
- Color coded: Red (<40), Yellow (40-70), Green (>70)
- Updated whenever evidence changes
- Shown on card and detail view

#### F5: Belief Map
- Visual network of beliefs
- Node size = evidence count (more evidence = larger node)
- Node color = score color
- Tap node to navigate to belief detail
- Shows connections based on shared themes (keyword matching, future feature)

### Data Model

```
Belief {
    id: UUID
    text: String
    createdAt: Date
    updatedAt: Date
    score: Double // 0-100
    evidenceItems: [Evidence]
}

Evidence {
    id: UUID
    beliefId: UUID
    text: String
    type: EvidenceType // .support, .contradict
    createdAt: Date
}

BeliefConnection {
    id: UUID
    fromBeliefId: UUID
    toBeliefId: UUID
    strength: Double
}
```

### Error Handling
- Empty states: friendly illustrations + CTA
- Database errors: show alert, log error
- AI unavailable: graceful fallback to manual reflection prompts

---

## 4. Technical Specification

### Dependencies (Swift Package Manager)
- **SQLite.swift** (latest) — Local database

### Frameworks Used
- SwiftUI
- Combine
- CloudKit (optional sync, future)
- Apple Intelligence (App Intents framework)

### File Structure
```
Axiom/
├── App/
│   ├── AxiomApp.swift
│   └── ContentView.swift
├── Models/
│   ├── Belief.swift
│   ├── Evidence.swift
│   └── BeliefConnection.swift
├── Services/
│   ├── DatabaseService.swift
│   └── AIStressTestService.swift
├── ViewModels/
│   ├── BeliefListViewModel.swift
│   └── BeliefDetailViewModel.swift
├── Views/
│   ├── BeliefListView.swift
│   ├── BeliefDetailView.swift
│   ├── AddBeliefView.swift
│   ├── AddEvidenceView.swift
│   ├── AIStressTestView.swift
│   ├── BeliefMapView.swift
│   └── Components/
│       ├── BeliefCard.swift
│       ├── EvidenceRow.swift
│       ├── ScoreBadge.swift
│       └── EmptyStateView.swift
└── Resources/
    └── Assets.xcassets
```

### Asset Requirements
- App icon (Axiom logo — stylized scale of justice)
- SF Symbols used throughout
