# AxiomIOSMac — Launch Checklist

## Pre-Launch (R13)

### Documentation
- [x] `AxiomIOSMac/Marketing/APPSTORE.md` — App Store listing draft
- [x] `AxiomIOSMac/Theme.swift` — Centralized color tokens

### Dark Mode Audit
- [x] All `Color(hex:)` calls centralized in `Theme.swift`
- [x] No hardcoded `Color(red:/green:/blue:)` literals in views
- [x] Semantic colors (`.primary`, `.secondary`, `.accentColor`) used for adaptive text — dark-mode-safe
- [x] Minor badge colors (`.purple`, `.green`, `.orange`) used for decorative capsules only — acceptable
- ⚠️ **Note:** App uses a light-mode-first aesthetic (navy/cream/gold). No dark-mode variants defined. macOS system colors will adapt; custom theme colors will not. A future iteration may add `ThemeDark`.
- ⚠️ **Note:** Uses deprecated `Color(nsColor: .textBackgroundColor)` in GuidedExercisesView and CommunitySupportView — cosmetic only.

### Build
- [x] XcodeGen `xcodegen generate` run
- [x] `xcodebuild` Release build succeeds on Apple Silicon

---

## Submission Checklist

### App Store Connect
- [ ] Create App Store Connect account (if not done)
- [ ] Create new macOS app entry
- [ ] Fill in **Pricing and Availability** (Free)
- [ ] Fill in **Territory Availability** (all or select)
- [ ] Set **Age Rating** to 4+
- [ ] Fill in **Description** (see APPSTORE.md)
- [ ] Set **Keywords** (see APPSTORE.md)
- [ ] Set **Marketing URL** (optional)
- [ ] Set **Support URL** (GitHub issues page)
- [ ] Set **Privacy Policy URL** (required — can use a hosted `privacy.md` on GitHub Pages)
- [ ] Upload **screenshots** (1280×720, 900×600, 658×400 @2x)
- [ ] Set **Category** → Health & Fitness / Health & Wellness
- [ ] Fill in **Release Notes** (version 1.0: "Initial release of Axiom — CBT journaling for macOS")

### Identity & Certificates
- [ ] Bundle Identifier: `com.axiom.cbt.macos` (or verify existing)
- [ ] Confirm App Store Distribution certificate exists in Xcode
- [ ] Confirm App Store Provisioning Profile exists
- [ ] Ensure `INFOPLIST_FILE` and `PRODUCT_BUNDLE_IDENTIFIER` in Xcode match App Store Connect

### Build & Archive
- [ ] Increment build number in `AxiomIOSMac/Info.plist` (CFBundleVersion)
- [ ] Increment version in `Info.plist` (CFBundleShortVersionString)
- [ ] Set `CODE_SIGN_IDENTITY` to `Apple Distribution` (not `-`)
- [ ] Archive in Xcode: **Product → Archive**
- [ ] Distribute via Xcode Organizer → **App Store Connect** → Upload

### App Store Connect (Post-Upload)
- [ ] Wait for **Bundle Validation** in App Store Connect
- [ ] Confirm **Build** appears under the app's "Build" section
- [ ] Complete all remaining "App Store Information" fields
- [ ] Click **Add for Review**

### Post-Submission
- [ ] Apple review (typically 1–3 days for macOS)
- [ ] Address any rejection feedback
- [ ] Upon approval: **Release** button in App Store Connect

---

## Post-Launch (Future Iterations)
- [ ] Monitor App Store Connect analytics (installs, crash rate)
- [ ] Collect and respond to user reviews
- [ ] Consider TestFlight for beta updates
- [ ] Add dark mode theme tokens if demand warrants
- [ ] Privacy policy URL must remain live
