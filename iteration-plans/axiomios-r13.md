# AxiomIOSMac — R13: Polish, App Store Listing & Launch

## Theme
Final polish, App Store preparation, and launch readiness.

## Features

### R13.1 — Visual Polish Pass
- **Animation Refinement:** Smooth transitions between all views (300ms ease-in-out)
- **Loading States:** Skeleton screens for async operations
- **Empty States:** Thoughtful empty state illustrations with clear CTAs
- **Error States:** Friendly error messages with recovery suggestions
- **Haptic Feedback:** Subtle haptics on key interactions (menu bar app)
- **Accessibility Audit:**
  - Full VoiceOver support with meaningful labels
  - Dynamic Type support (all text scales)
  - Minimum 4.5:1 contrast ratios
  - Reduced Motion support

### R13.2 — App Store Assets
- **App Icon:** Professional icon design (brain + scale motif)
- **Screenshots:** 6-8 screenshots showing key flows
- **Preview Video:** 30-second app preview
- **Description:** Clear, compelling 170-character and full descriptions
- **Keywords:** Researched keyword set for discovery
- **Promotional Graphics:** Feature graphic for App Store

### R13.3 — Launch Checklist
- [ ] TestFlight beta with 10+ external testers
- [ ] Privacy Policy URL (required for App Store)
- [ ] Support URL and Marketing URL
- [ ] Age Rating: 4+ (no age restrictions)
- [ ] Category: Health & Fitness or Medical
- [ ] Tax/Payment setup in App Store Connect
- [ ] Beta testing crash reporting verified
- [ ] All localization strings externalized
- [ ] Build number incremented for release
- [ ] Code signing certificates ready
- [ ] App Store Connect record created
- [ ] Review team contact info in App Store Connect notes

### R13.4 — Pre-launch Marketing
- **Launch Date:** Target 2 weeks after R13 completion
- **Social Proof:** Testimonial collection from beta testers
- **Landing Page:** Simple landing page at axiom.app
- **Launch Announcement:** Draft Telegram/Social post
- [ ] Hacker News if relevant (Show HN)
- [ ] Product Hunt listing

### R13.5 — Post-Launch Monitoring
- **Crash Reporting:** Verify crashlytics/reporting active
- **Analytics:** Anonymous usage analytics (Opt-in)
- **Review Prompt:** Prompt after 7 days of consistent use
- **Support Channel:** Setup support@axiom.app email

## Technical

### Build Configuration
- **Deployment Target:** macOS 15.0
- **Swift Version:** 6.0
- **Code Signing:** Developer ID for notarization
- **Hardened Runtime:** Enabled for notarization
- **App Sandbox:** Enabled for App Store submission

### Entitlements
```xml
com.apple.security.app-sandbox: true
com.apple.security.network.client: true (for AI API calls)
```

## Design Notes
- This is the most polished version — every pixel matters
- App Store listing should convey trust, warmth, and scientific credibility
- First impressions during onboarding are critical
- Menu bar app UX: quick access, minimal friction, fast interactions
