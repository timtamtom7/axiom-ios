# Axiom — App Store Launch Checklist

## Pre-Submission Review

### Bundle & Identity
- [ ] Bundle ID: `com.axiom.beliefaudit`
- [ ] App Name: "Axiom" (same across all locales)
- [ ] Primary Category: Health & Fitness → Medical
- [ ] Secondary Category: Education → Self Improvement
- [ ] Content Rights: None required (no third-party content)
- [ ] Age Rating: 4+ (all ages)

### Capabilities
- [ ] Sign in with Apple — not required (no account system yet)
- [ ] HealthKit — enabled for health integration
- [ ] Background Modes — disabled (no background tasks)
- [ ] In-App Purchase — enabled for StoreKit 2

### Info.plist
- [ ] NSCameraUsageDescription — not needed
- [ ] NSHealthShareUsageDescription — "Axiom reads your health data to identify patterns in activity, sleep, and stress that may influence your beliefs."
- [ ] NSHealthUpdateUsageDescription — "Axiom does not write health data."
- [ ] UIBackgroundModes — empty (no background modes)

### Code & Privacy
- [ ] No user tracking or analytics without consent
- [ ] No third-party SDKs that collect data
- [ ] Privacy manifest (PrivacyInfo.xcprivacy) created
- [ ] All data stored locally (SQLite) — no server sync in v1

---

## App Store Connect Metadata

### Localizations (10 languages)
- [ ] English (en)
- [ ] German (de)
- [ ] French (fr)
- [ ] Spanish (es)
- [ ] Italian (it)
- [ ] Portuguese (pt)
- [ ] Japanese (ja)
- [ ] Korean (ko)
- [ ] Simplified Chinese (zh-Hans)
- [ ] Traditional Chinese (zh-Hant)

### Name & Tagline
- Name: Axiom
- Tagline (EN): "Audit your beliefs. Change your thinking."
- Subtitle (optional): "The belief audit app"

### Description Templates
See `APPSTORE_COPY.md` for full localized copy.

### Keywords
```
belief, cognitive, CBT, therapy, mental health, self-improvement,
psychology, evidence, thinking, mindfulness, anxiety, depression,
journal, self-awareness, AI, introspection
```

### URLs
- [ ] Privacy Policy URL: `https://axiom.app/privacy`
- [ ] Support URL: `https://axiom.app/support`
- [ ] Marketing URL: `https://axiom.app`

---

## Screenshots Requirements

### iPhone 16 Pro Max (1290×2796)
- [ ] Shot 1: Belief List — "Your belief universe, at a glance."
- [ ] Shot 2: Belief Detail with Evidence — "Evidence both for and against."
- [ ] Shot 3: AI Challenge — "AI that asks the questions you won't ask yourself."
- [ ] Shot 4: Community — "Join thousands examining their beliefs."
- [ ] Shot 5: Pro Features — "Start free. Go deeper with Pro."

### iPad Pro 13" (2064×2752)
- [ ] Sidecar screenshot showing iPad layout
- [ ] Same 5 shots at iPad resolution

### Mac App Store (1284×2778)
- [ ] Desktop-optimized screenshot

### Video Preview (optional)
- [ ] 30-second App Preview video
- [ ] Shows key flows: add belief → add evidence → AI stress test → community
- [ ] No spoken audio (for silent autoplay) — use music/ambient sound

---

## Build & Submission

### Xcode Cloud / CI
- [ ] Xcode project builds clean (no errors or warnings)
- [ ] Code signing: Automatic (or specific team if manual)
- [ ] Development assets included
- [ ] Build number incremented for each upload

### TestFlight
- [ ] Internal Testing: Add team members
- [ ] External Testing: Submit for Beta App Review (up to 25 external testers)
- [ ] TestFlight build live with Test Notes

### Beta App Review (for external testing)
- [ ] Log in to App Store Connect
- [ ] Go to My Apps → Axiom → TestFlight → External Testing
- [ ] Add build and submit for review
- [ ] Review typically within 24-48 hours

### Production Submission
- [ ] Select build from App Store Connect
- [ ] Fill in Age Rating (4+)
- [ ] Select all applicable categories
- [ ] Add contact email
- [ ] Submit for review

---

## Review Guidelines Compliance

### Common Rejection Reasons — Pre-Check
- [ ] No account/paywall gating before app functionality
- [ ] No excessive permissions requested
- [ ] App doesn't crash on launch
- [ ] In-app purchases work and restore correctly
- [ ] No placeholder content in screenshots
- [ ] App Store screenshots match actual app UI

### Health App Considerations
- [ ] Clear that Axiom is not a medical device
- [ ] No claims of diagnosing or treating conditions
- [ ] Disclaimer: "Axiom is not a substitute for professional medical advice"

---

## Go-Live Checklist

- [ ] App Store Review submitted
- [ ] TestFlight external build ready
- [ ] Support email monitored
- [ ] Privacy policy page live at axiom.app/privacy
- [ ] Marketing page live at axiom.app
- [ ] Social media assets ready (App Store badge, launch post)
- [ ] Analytics/event tracking configured for post-launch metrics
- [ ] Crash reporting (Crashlytics/Xcode Cloud) active

---

## Post-Launch

- [ ] Monitor App Store Connect for Review status
- [ ] Address any review feedback within 24 hours
- [ ] Push update if rejected — fix and resubmit
- [ ] Once approved: "Ready for Sale" — verify in App Store Connect
- [ ] Share App Store link on social channels
- [ ] Submit to Product Hunt if aligned with launch timing
