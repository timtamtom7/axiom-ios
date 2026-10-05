# Axiom

Belief audit. Track claims you hold, gather evidence for and against them, and let AI stress-test whether you actually believe what you say.

## Concept

- Belief tracking
- Evidence — both supporting and opposing
- AI stress-testing of a belief
- Deep-dive analysis on demand

## Targets

- iOS
- AxiomMac
- AxiomWatch

## Stack

- SwiftUI
- SwiftData
- WatchKit
- XcodeGen (`project.yml`)

## Structure

Three targets from one codebase — the iPhone app is primary, with Catalyst and a watchOS companion. Source lives under `Axiom/`, with `AxiomMac/` and `AxiomWatch/` alongside.

Key types: `AIBeliefAgentService`, `AIStressTestService`/`AIStressTestView`, `AIDeepDiveView`, `AddBeliefView`, `AddEvidenceView`.

Version 1.0.0.

## Recovered work

Round 4 audit fixes are on `rescue/local-ahead-2026-10-05` — a CGFloat type mismatch on `BeliefMapView.nodeSize`, a batch of medium/low fixes, and a critical/high fix pass. The GitHub `main` branch is 34 commits ahead of local and contains R12/R13 work: Community Circles (shared belief challenges), therapist integration, guided exercises, and an App Store listing.

## Status

Apple-platform experiment built to explore what an AI coding agent could produce for a native app. Not actively maintained.

Xcode projects here were generated with XcodeGen (`project.yml`); open the `.xcodeproj` directly.
