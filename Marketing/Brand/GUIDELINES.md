# Axiom Brand Guidelines

---

## Core Identity

### Tagline
**"Change your beliefs, change your life."**

### Elevator Pitch
Axiom is a belief audit app that helps you examine, challenge, and strengthen your core beliefs using evidence-based Cognitive Behavioral Therapy (CBT) techniques.

### Brand Personality
- **Calm** — The app creates a sense of quiet reflection, not anxiety or urgency
- **Cerebral** — Intelligent, thoughtful, science-backed. Not self-helpy or new-age
- **Therapeutic** — Like a trusted philosophy journal, not a therapist's office
- **Sharp but warm** — Intelligent without being cold. Precise without being clinical
- **Private** — Your beliefs are yours. The app respects that absolutely

### Tone of Voice
- Direct and clear. No filler words.
- Confident but not prescriptive. We present evidence, you decide.
- Occasionally wry or philosophical — we acknowledge the complexity of being human.
- Never preachy, never alarming, never "fix your life" energy.

---

## Color Palette

### Background Colors
| Name | Hex | Usage |
|---|---|---|
| Deep Void | `#0a0a0f` | Primary background. App background, screen fills |
| Surface | `#161616` | Cards, sheets, modal backgrounds |
| Elevated | `#1e1e1e` | Hover states, selected rows, input fields |
| Border | `#2a2a2a` | Dividers, subtle separators |

### Text Colors
| Name | Hex | Usage |
|---|---|---|
| Primary | `#ffffff` | Headings, primary content, buttons |
| Secondary | `#8B8B9B` | Labels, subtitles, metadata |
| Tertiary | `#4a4a58` | Placeholder text, disabled states |

### Semantic Colors
| Name | Hex | Usage |
|---|---|---|
| Accent — Belief | `#e879f9` | Belief nodes, primary brand accent, active states |
| Accent Glow | `#f0abfc` | Halos, glows around belief nodes |
| Support | `#4ade80` | Supporting evidence, positive indicators, checkmarks |
| Support Dim | `#166534` | Support badge backgrounds, subtle tints |
| Contradict | `#ef4444` | Contradicting evidence, warnings, negative indicators |
| Contradict Dim | `#7f1d1d` | Contradict badge backgrounds |
| AI / Processing | `#a78bfa` | AI-related elements, brain icon active state |
| Warning | `#f59e0b` | Weak link highlights, caution states |
| Score High | `#4ade80` | Scores 70–100% |
| Score Mid | `#f59e0b` | Scores 40–69% |
| Score Low | `#ef4444` | Scores 0–39% |

---

## Typography

### Font Stack

| Style | Font | Weight | Usage |
|---|---|---|---|
| App Name / Wordmark | SF Pro Display | Bold | Axiom wordmark only |
| Screen Titles | New York (serif) | Bold | Navigation titles, belief text |
| Headings | New York (serif) | Semibold | Section headers, card titles |
| Body | SF Pro | Regular | Descriptions, evidence text, long-form |
| Body Bold | SF Pro | Semibold | Important body copy, button labels |
| Data / Scores | SF Mono | Medium | Confidence percentages, scores, metrics |
| Captions | SF Pro | Regular | Timestamps, metadata, secondary labels |
| System Fallback | -system-ui | - | SF Pro unavailable (iOS fallback is automatic) |

### Type Scale

| Level | Size | Weight | Line Height | Usage |
|---|---|---|---|---|
| Display | 34 pt | Bold | 1.15 | Tagline on marketing materials |
| Title 1 | 28 pt | Bold | 1.2 | Screen titles |
| Title 2 | 22 pt | Semibold | 1.25 | Section headings |
| Title 3 | 20 pt | Semibold | 1.3 | Card headings |
| Body | 17 pt | Regular | 1.4 | Primary body copy |
| Callout | 16 pt | Regular | 1.35 | Evidence text |
| Footnote | 13 pt | Regular | 1.4 | Metadata, timestamps |
| Caption | 12 pt | Regular | 1.3 | Labels, badges |

---

## Spacing & Layout

### Grid
- **Base unit:** 8pt grid
- **Screen margins:** 16pt (iPhone), 24pt (iPad)
- **Card padding:** 16pt
- **Section spacing:** 24pt between major sections
- **List row height:** 60pt minimum (belief rows)

### iOS-Specific
- Respect safe area insets on all screens
- Use native iOS navigation patterns ( UINavigationController, UITabBarController)
- Bottom sheet modals: use UISheetPresentationController with `.medium()` and `.large()` detents
- No custom navigation — always follow iOS HIG

---

## Visual Assets

### Icons
- **SF Symbols only** — no custom iconography
- Standard weight: `.regular` for inactive, `.medium` for active
- Key symbols used:
  - `plus.circle.fill` — Add belief / Add evidence
  - `brain` — AI Challenge
  - `checkmark.circle` — Supporting evidence
  - `xmark.circle` — Contradicting evidence
  - `square.and.arrow.up` — Share
  - `person.circle` — Profile
  - `gearshape` — Settings
  - `chart.bar.xaxis` — Stats / Graph view
  - `eye.slash` — Privacy mode
  - `shield.checker` — HIPAA / Security
  - `heart.text.square` — Community
  - `arrow.triangle.2.circlepath` — Sync

### Illustrations
- **No custom illustrations**
- No emoji in UI
- No decorative graphics in the app itself

### Images
- No stock photography in the app
- Network graphs and belief nodes are rendered with Core Graphics / SwiftUI Canvas
- No user-uploaded photos displayed in the app shell

### Animations
- Subtle, purposeful, not decorative
- Node pulse: `0.8s` ease-in-out, scale `1.0 → 1.05 → 1.0`, opacity `0.7 → 1.0 → 0.7`
- Score ring fill: `600ms` ease-out
- Edge draw: `400ms` linear
- Sheet present: native iOS spring animation

---

## Dark Aesthetic

Axiom is **always dark**. There is no light mode.

- Backgrounds are never pure white or light gray
- All surfaces are within the `#0a0a0f` to `#1e1e1e` range
- Contrast ratios must meet WCAG AA for all text:
  - Primary text on `#0a0a0f`: ≥ 15.8:1 ✓
  - Secondary text (`#8B8B9B`) on `#0a0a0f`: ≥ 5.7:1 ✓
  - Tertiary text (`#4a4a58`) on `#161616`: ≥ 4.6:1 ✓

---

## App Icon

- **Shape:** Rounded rectangle (iOS standard mask, 100% radius on corners)
- **Background:** `#0a0a0f` (deep void)
- **Symbol:** Abstract belief node — a circle with a smaller circle inside, connected by a line (network motif). Color: `#e879f9`.
- **Style:** Minimal, flat, no gradients, no shadows
- **Variants:**
  - iPhone: 180×180 @3x, 120×120 @2x
  - iPad: 167×167 @2x (Pro), 152×152 @2x (standard)
  - App Store: 1024×1024

---

## Accessibility

- All interactive elements have accessibility labels (SF Symbols included)
- Scores are announced as "78 percent confidence" not just "78"
- Evidence types announced as "Supporting evidence" / "Contradicting evidence"
- AI Challenge results: full text available via VoiceOver
- Reduce Motion: disable node pulse animations, use crossfade instead
- High Contrast: boost text to `#ffffff` on all surfaces

---

## What Not To Do

- ❌ Do not use bright, saturated colors outside the defined palette
- ❌ Do not use illustrations, emojis, or photographic imagery
- ❌ Do not create a light mode
- ❌ Do not use serif fonts other than New York for headings
- ❌ Do not use decorative animations — motion must be meaningful
- ❌ Do not use third-party icon sets — SF Symbols only
- ❌ Do not add branded graphics to user content (no Axiom watermark on screenshots)
- ❌ Do not use language that implies Axiom is a substitute for therapy
