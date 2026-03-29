# Axiom Clinical Validation

---

## Overview

Axiom is built on a foundation of established clinical psychology research, specifically Cognitive Behavioral Therapy (CBT). This document outlines the theoretical grounding, research partnerships, and privacy architecture that underpin the app.

---

## CBT Foundation

### What is CBT?

Cognitive Behavioral Therapy is an evidence-based psychotherapy that focuses on identifying and challenging unhelpful cognitive patterns (beliefs, attitudes, and automatic thoughts) and replacing them with more realistic, adaptive alternatives.

CBT is one of the most extensively researched and empirically validated forms of psychotherapy. It is recommended as a first-line treatment by:

- **National Institute for Health and Care Excellence (NICE)** — UK
- **American Psychological Association (APA)**
- **World Health Organization (WHO)**
- **National Alliance on Mental Illness (NAMI)**

### Key CBT Concepts in Axiom

#### Beck's Cognitive Triad
Aaron Beck's cognitive triad describes how individuals with depression hold negative self-beliefs across three domains:
1. **Self** — "I am inadequate, defective, or worthless"
2. **World** — "The world is demanding, hostile, or depriving"
3. **Future** — "The future is hopeless"

Axiom directly engages with Domain 1 by helping users examine and challenge negative self-beliefs.

#### Automatic Thoughts
Spontaneous, involuntary thoughts that arise in response to situations. These are often distorted and unexamined. Axiom surfaces these as "evidence" for deeper beliefs.

#### Cognitive Distortions
Beck identified specific thinking errors that maintain negative beliefs. Axiom's AI Stress Test targets these distortions:

| Distortion | Description | Axiom's Response |
|---|---|---|
| All-or-Nothing | Seeing things in black and white | AI questions polarized evidence |
| Overgeneralization | Drawing broad conclusions from single events | AI flags single-instance evidence |
| Mental Filter | Focusing exclusively on negatives | AI surfaces contradictory evidence |
| Disqualifying the Positive | Dismissing positive experiences | AI highlights positive evidence as "discounted" |
| Mind Reading | Assuming others are negatively disposed | AI questions subjective interpretations |
| Fortune Telling | Predicting negative outcomes | AI challenges predictive beliefs |
| Emotional Reasoning | "I feel it, so it must be true" | AI separates emotion from evidence |
| Should Statements | Rigid rules with "should/must" | AI reframes as preferences |
| Labeling | Attaching negative labels to self | AI deconstructs labels into facts |
| Personalization | Taking undue responsibility | AI examines attribution |

### Evidence-Based Treatment Protocols

Axiom incorporates techniques from established CBT protocols:

- **Belief Recording** — Structured logging of beliefs (adapted from Beck's Belief Scale)
- **Evidence Examination** — Pro/con analysis (central to Beck's cognitive restructuring)
- **Downward Arrow Technique** — Tracing automatic thoughts to core beliefs (integrated into AI Stress Test)
- **Socratic Questioning** — AI-generated challenges based on Socratic method

---

## Research Partnerships

> **Note:** The following are target/placeholder partnerships. Formal research relationships will be established prior to clinical marketing claims.

### Stanford Neuroscience Lab
**Contact:** TBD
**Status:** Outreach in progress
**Focus:** Investigating the correlation between belief clarity scores and self-reported wellbeing metrics

### UCL Clinical Psychology
**Contact:** TBD
**Status:** Exploratory discussion
**Focus:** Validation of AI Stress Test effectiveness vs. manual Socratic questioning in CBT sessions

### Published CBT Research We Draw From

- Beck, A.T. (1979). *Cognitive Therapy and the Emotional Disorders*. Penguin Books.
- Beck, J.S. (2011). *Cognitive Behavioral Therapy: Basics and Beyond* (2nd ed.). Guilford Press.
- Ellis, A. & Dryden, W. (2007). *The Practice of Rational Emotive Behavior Therapy* (2nd ed.). Springer.
- Hofmann, S.G. et al. (2012). "The Efficacy of Cognitive Behavioral Therapy." *Annual Review of Clinical Psychology*, 8, 357–379.

---

## HIPAA Compliance

### Data Architecture

Axiom is designed with privacy as a core architectural principle, not an afterthought.

#### Local-First Storage
- **All belief data is stored locally on the user's device** using iOS Keychain and encrypted SQLite (via SQLCipher)
- No belief data is transmitted to Axiom's servers in plaintext
- A local-only mode is available (no iCloud sync) for maximum privacy

#### End-to-End Encrypted Sync
- When iCloud sync is enabled, all belief data is encrypted on-device before leaving the device
- Encryption: AES-256-GCM with keys derived from the user's device-specific keychain entry
- Axiom Inc. cannot decrypt synced data — key access is device-bound

#### No Data Sold or Shared
- Axiom does not sell, rent, or share user data with third parties
- No advertising networks, no analytics brokers, no data brokers
- No data is used to train machine learning models

#### Privacy Dashboard
- Users can view, export, or delete all their data at any time
- Deletion is permanent and irreversible (local + iCloud)

### HIPAA Alignment

Axiom is designed to align with HIPAA's Protected Health Information (PHI) standards for mental health data:

| HIPAA Requirement | Axiom Implementation |
|---|---|
| Access Control | Device passcode/biometric required to access app |
| Audit Controls | Local logging of data access (user-visible) |
| Integrity | Data integrity verified via HMAC on each belief entry |
| Transmission Security | TLS 1.3 minimum, certificate pinning |
| PHI Definition | Belief data qualifies as sensitive mental health information — treated accordingly |

> **Disclaimer:** Axiom is a self-help wellness application, not a medical device, and is not intended to diagnose, treat, prevent, or cure any mental health condition. It is not a substitute for professional mental health care. Users experiencing mental health crises should contact a qualified mental health professional.

---

## Efficacy & User Outcomes

> **Note:** User outcome data will be collected post-launch and published when statistically significant sample size is reached (n ≥ 500).

### Placeholder Metrics (Target Post-Launch)

| Metric | Target |
|---|---|
| User-reported belief clarity improvement | ≥ 20% after 30 days |
| Average beliefs challenged per active user | ≥ 3 per month |
| AI Stress Test completion rate | ≥ 60% of active users |
| User retention at 30 days | ≥ 40% |

---

## Safety & Guardrails

### Crisis Detection
- If a user enters belief text containing crisis-related keywords (self-harm, suicide, harm to others), Axiom displays a prominent crisis resource overlay with:
  - **988 Suicide & Crisis Lifeline** (US): call or text 988
  - **Crisis Text Line**: text HOME to 741741
  - **International Crisis Lines**: links to resources by country

### Content Filtering
- Crisis keyword detection runs locally on-device
- No belief data is sent to external servers for content filtering
- The crisis resource overlay cannot be dismissed for 10 seconds

### No Medical Claims
- Axiom makes no claims of curing, treating, or preventing mental health conditions
- All marketing and in-app copy uses "may help," "designed to support," and "evidence-based techniques" language
- No before/after mental health comparisons

---

## Changelog

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-03-28 | Initial Clinical Validation document |
