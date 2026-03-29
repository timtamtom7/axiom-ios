# AxiomMac TestFlight Preparation Notes

## How to Build for Distribution

### Prerequisites
- Xcode 16.0+
- Valid Apple Developer account with macOS app capability
- App Store Connect API key configured in Xcode
- `com.axiom.beliefaudit.macos` bundle ID registered in App Store Connect

### Step 1: Set Version & Build Number

In `project.yml` or Xcode:

```yaml
MARKETING_VERSION: "1.0.0"   # bump for each TestFlight/release
CURRENT_PROJECT_VERSION: "1" # increment for each build
```

### Step 2: Configure Signing

In Xcode, select **AxiomMac** target → **Signing & Capabilities**:

- **Team:** Your Apple Developer team
- **Bundle Identifier:** `com.axiom.beliefaudit.macos`
- **Entitlements:** `AxiomMac/AxiomMac.entitlements`
- **App Sandbox:** ✅ Enabled
- **Hardened Runtime:** ✅ Enabled

### Step 3: Build for Distribution

```bash
cd /Users/mauriello/.openclaw/workspace/projects/axiom-ios-code

# Generate project
xcodegen generate

# Clean build
xcodebuild -scheme AxiomMac \
  -configuration Release \
  -destination 'platform=macOS,arch=arm64' \
  clean build \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=YES \
  CODE_SIGNING_ALLOWED=YES \
  DEVELOPMENT_TEAM="YOUR_TEAM_ID"
```

### Step 4: Create ZIP for App Store Connect

```bash
cd build/Release
zip -r Axiom.zip AxiomMac.app
```

### Step 5: Upload via Transporter

```bash
# Install Transporter from Mac App Store if not installed
/Applications/Transporter.app/Contents/MacOS/it Deliver \
  --file Axiom.zip \
  --apiKey YOUR_API_KEY \
  --apiKeyPath ~/.appstoreconnectapi
```

Or drag `Axiom.zip` into Transporter.app.

---

## What to Test in TestFlight

### Core Features

- [ ] **Belief Creation** — Can create a new belief with text, core/non-core flag, and root cause
- [ ] **Evidence Management** — Can add supporting/challenging evidence to any belief
- [ ] **Evidence Library** — Browse, search, and re-use evidence across beliefs
- [ ] **AI Challenges** — AI agent presents counter-evidence; can respond or archive
- [ ] **Check-In Flow** — Due check-ins appear in banner; can score and record checkpoint
- [ ] **Scoring** — Score badge updates based on evidence ratio; displays correctly
- [ ] **Community View** — Can view shared beliefs (enterprise/community layer)
- [ ] **Archive / Obituaries** — Can archive beliefs; archived list shows with reason
- [ ] **Settings** — Subscription status, data export, notification preferences

### UI/UX

- [ ] App launches in < 2 seconds on Apple Silicon
- [ ] Dark mode renders correctly
- [ ] Search filters beliefs with 300ms debounce (no UI stutter)
- [ ] LazyVStack scrolls smoothly with 50+ beliefs
- [ ] Menu bar extra opens and responds
- [ ] Keyboard shortcuts work (⌘N for new belief, ⌘, for settings)

### Edge Cases

- [ ] Empty state shows when no beliefs exist
- [ ] Onboarding flow shows on first launch
- [ ] Archived beliefs don't appear in main list
- [ ] Evidence deletion updates belief score immediately
- [ ] Long belief text truncates with ellipsis in card view

---

## Known Limitations (R25)

1. **No iCloud sync** — Belief data is local to this machine only. Export via Settings for backup.
2. **AI challenges are warmup-tier** — Full AI reasoning requires API key configuration (see `AIService.swift`).
3. **HealthKit integration is stubbed** — Real authorization flow deferred to post-R25.
4. **Community sync is simulated** — Live multi-user sync not yet implemented; UI demonstrates the flow.
5. **No offline mode** — Requires network for AI features; beliefs work offline.
6. **Menu bar extra on macOS 15+** — Uses `.menuBarExtraStyle(.window)`; tested on Sequoia.
7. **SQLite schema migrations** — Safe for fresh installs; migration from v0 to v1 schema not backward-verified.

---

## Post-R25 Roadmap

- iCloud sync via CloudKit
- Full HealthKit correlation dashboard
- Community multiplayer with CRDT sync
- A/B testing framework for AI challenge strategies
- WidgetKit support for belief check-in reminders
