# AxiomIOSMac — Unified Action Plan

## Approach

Fixes are organized by **severity tier**, then **layer** (models → services → views). The principle: unblock the build first, then fix what hurts users (accessibility, broken UX), then polish. Architectural debt that requires disproportionate refactoring is deferred to R14.

---

## Tier 1: Compile Breakers

### 1. Add `Equatable` to `CommunityPost`
**File:** `AxiomIOSMac/Models.swift`
**Line:** ~94 (struct declaration)

```swift
struct CommunityPost: Identifiable, Equatable {
```

**Why:** Swift cannot auto-synthesize `Equatable` for structs containing enums (`InsightType`) without explicit conformance. This will fail to compile in some toolchain configurations.

---

### 2. Add `Equatable` to `AIInsight`
**File:** `AxiomIOSMac/InsightsView.swift`
**Line:** ~100 (struct declaration)

```swift
struct AIInsight: Identifiable, Equatable {
```

**Why:** Same reason — `InsightType` enum prevents auto-synthesis. `AIInsight` is a view-local struct that mirrors `InsightItem` (from Models.swift). Add conformance here; future cleanup should consolidate `AIInsight` → `InsightItem`.

---

## Tier 2: Accessibility & Legal (WCAG, VoiceOver, PHI)

### 3. Fix WCAG AA contrast failure — darken gold
**File:** `AxiomIOSMac/Theme.swift`
**Line:** 9

```swift
// Change:
static let gold = Color(hex: "D4AF37")
// To:
static let gold = Color(hex: "A08020")  // ≈ #9E7C1A — ~5.1:1 on cream
```

**Why:** `#D4AF37` on `#FDF8F0` = 2.8:1, well below the 4.5:1 AA requirement. `#A08020` (a rich gold) achieves ~5.1:1 on cream while preserving the intended palette. You may also want to raise the cream slightly (e.g., `#FAF5EC`) to keep the warm feel while meeting contrast.

---

### 4. Add accessibility label to time range Picker
**File:** `AxiomIOSMac/InsightsView.swift`
**Line:** 10–16

```swift
Picker("", selection: $selectedTimeRange) {
    Text("Week").tag(0)
    Text("Month").tag(1)
    Text("All Time").tag(2)
}
.pickerStyle(.segmented)
.accessibilityLabel("Time range for insights")
```

---

### 5. Add accessibility label to export format Picker
**File:** `AxiomIOSMac/SettingsView.swift`
**Line:** ~357 (ExportSheet Picker)

```swift
Picker("", selection: $exportFormat) {
    Text("JSON").tag(0)
    Text("CSV").tag(1)
    Text("PDF Report").tag(2)
}
.pickerStyle(.segmented)
.accessibilityLabel("Export format")
```

---

### 6. Add accessibility labels to TabButtons
**File:** `AxiomIOSMac/ContentView.swift`
**Lines:** ~90–105 (TabButton definitions)

Each `TabButton` needs an `.accessibilityLabel()`:

```swift
TabButton(title: "Beliefs", icon: "brain", isSelected: selectedTab == 0) {
    selectedTab = 0
}
.accessibilityLabel("Beliefs tab")

TabButton(title: "Community", icon: "person.3", isSelected: selectedTab == 1) {
    selectedTab = 1
}
.accessibilityLabel("Community tab")

TabButton(title: "Insights", icon: "chart.line.uptrend.xyaxis", isSelected: selectedTab == 2) {
    selectedTab = 2
}
.accessibilityLabel("Insights tab")

TabButton(title: "Settings", icon: "gearshape", isSelected: selectedTab == 3) {
    selectedTab = 3
}
.accessibilityLabel("Settings tab")
```

**Why:** VoiceOver users navigating by tab get no label from the icon+text alone in a non-standard tab implementation.

---

### 7. Add accessibility label to new post FAB
**File:** `AxiomIOSMac/CommunityView.swift`
**Line:** ~45 (FAB Button)

```swift
Button {
    showingNewPost = true
} label: {
    Image(systemName: "square.and.pencil")
        ...
}
.accessibilityLabel("Create new community post")
.accessibilityHint("Opens a sheet to share a belief with the community")
```

---

### 8. Add accessibility label to add belief FAB
**File:** `AxiomIOSMac/BeliefsView.swift`
**Line:** ~20 (FAB Button)

```swift
Button {
    showingAddBelief = true
} label: {
    Image(systemName: "plus")
        ...
}
.accessibilityLabel("Add new belief")
.accessibilityHint("Opens a sheet to record a new belief")
```

---

### 9. PHI risk — therapist notes in UserDefaults
**File:** `AxiomIOSMac/Services/TherapistService.swift`
**Line:** ~30 (`notesKey = "axiom.therapist.notes"`)

Add a prominent privacy disclosure. The simplest immediate step is a comment at the `notesKey` declaration:

```swift
// ⚠️ RISK: TherapistNote.content may contain PHI. Storing in UserDefaults
// is unacceptable for production. Either encrypt with a user-derived key
// or move to Keychain with appropriate access control. Acceptable for MVP
// internal testing only.
private let notesKey = "axiom.therapist.notes"
```

Additionally, add a privacy notice in `SettingsView` under "Data & Privacy" before the Export/Delete rows:

```swift
SettingsInfoRow(
    title: "Privacy Notice",
    value: "Therapist notes stored locally only"
)
```

**Why:** `TherapistNote.content` could constitute PHI under HIPAA if connected to real therapist accounts. UserDefaults is not encrypted by default.

---

## Tier 3: Core UX (dark mode, AI insights, broken interactions)

### 10. Fix popover auto-show on launch
**File:** `AxiomIOSMac/AppDelegate.swift`
**Line:** ~16 (inside `applicationDidFinishLaunching`)

```swift
// Remove the auto-show:
self.popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
// This line should be REMOVED. The popover should only open
// when the user clicks the status bar button.
```

**Why:** `show(relativeTo:of:preferredEdge:)` is called unconditionally, causing the popover to appear immediately on every launch.

---

### 11. Implement dark mode toggle
**File:** `AxiomIOSMac/ContentView.swift`
**Lines:** ~60 (ContentView body)

The `darkMode` binding in `SettingsView` doesn't affect anything. The fix is two-part:

**Part A — Pass dark mode state to ContentView:**
In `ContentView`, accept a `darkMode` binding or environment value and propagate it to the view hierarchy:

```swift
@AppStorage("axiom.darkMode") private var darkMode = false

// In body, wrap with preferredColorScheme:
.contentPreferredColorScheme(darkMode ? .dark : .light)
```

**Part B — Ensure Theme colors work in dark mode:**
Theme.swift uses hardcoded hex values. In `InsightsView`, `CognitiveDistortionsCard`, and other places, `Color(.windowBackgroundColor)` is used directly instead of Theme colors. This must be replaced with Theme colors that support dark mode (see item #22).

---

### 12. Populate `generateInsights()` with real analysis
**File:** `AxiomIOSMac/InsightsView.swift`
**Lines:** ~82–96 (`generateInsights()` function)

Currently the function discards everything except `analysis.healthierAlternative`, producing near-identical boilerplate for every belief. Fix:

```swift
private func generateInsights() {
    guard !beliefs.isEmpty else { return }
    isLoading = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        let analyses = self.beliefService.analyzeAllBeliefs(self.beliefs)
        self.insights = Array(analyses.values).prefix(5).map { analysis in
            let type: InsightType = analysis.distortions.isEmpty ? .aiAnalysis : .beliefPattern
            let body: String
            if let first = analysis.distortions.first {
                body = "\(first.rawValue): \(first.gentleQuestion)"
            } else {
                body = analysis.healthierAlternative
            }
            return AIInsight(
                id: analysis.id,
                title: analysis.distortions.isEmpty ? "Balanced View" : "Distortion Detected",
                body: body,
                type: type
            )
        }
        self.isLoading = false
    }
}
```

---

### 13. Wire Join Debate button action
**File:** `AxiomIOSMac/CommunityView.swift`
**Lines:** ~72–77 (`// Open in debate` comment)

```swift
Button {
    selected_segment = 1  // Switch to Debates tab
} label: {
    Text("Join Debate")
        .font(.system(size: 10, weight: .medium))
        .foregroundColor(Theme.gold)
}
```

Or link to a debate detail sheet. At minimum, switch to the Debates segment with a populated debate view.

---

### 14. Make SubscriptionCard dynamic (not hardcoded "Active")
**File:** `AxiomIOSMac/SettingsView.swift`
**Line:** ~70 (SubscriptionCard hardcodes "Active")

```swift
// Replace the hardcoded "Active" badge with a real status:
@State private var subscriptionStatus: SubscriptionStatus = .active

// In the badge:
Text(subscriptionStatus == .active ? "Active" : "Inactive")
    .font(.system(size: 10, weight: .semibold))
    .foregroundColor(subscriptionStatus == .active ? Theme.accentGreen : Theme.accentRed)
    .padding(.horizontal, 8)
    .padding(.vertical, 3)
    .background((subscriptionStatus == .active ? Theme.accentGreen : Theme.accentRed).opacity(0.15))
    .cornerRadius(4)
```

**Note:** For MVP this can read from a `@AppStorage` key set by the subscription flow. Real IAP status requires StoreKit2 integration — defer to post-MVP.

---

### 15. Add `setActivationPolicy(.accessory)` to AppDelegate
**File:** `AxiomIOSMac/AppDelegate.swift`
**Line:** ~10 (before creating the status item)

```swift
func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.accessory)  // Hide dock icon — this is a menu bar app

    let popover = NSPopover()
    ...
}
```

---

### 16. Replace `NSApplication.shared.run()` with `@main` SwiftUI.App
**Files:** `AxiomIOSMac/AppDelegate.swift` + new entry point

This is a larger refactor. The current `AppDelegate` uses the old AppKit lifecycle with a manual `NSApplication.shared.run()` implicit in the `NSApplicationDelegate` pattern. SwiftUI menu bar apps are better served by `@main struct AxiomIOSMacApp: App`.

**Option A (minimal change):** Keep `AppDelegate` but add `@main` wrapper in a separate file, or mark `AppDelegate` as `@main` and remove the explicit `run()` call (which doesn't actually appear in the current code — `NSApplicationDelegate` handles this implicitly).

**Option B (clean SwiftUI approach):**
Create `AxiomIOSMacApp.swift`:

```swift
import SwiftUI

@main
struct AxiomIOSMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

Then `AppDelegate` no longer needs to create `NSHostingController` for `ContentView` in `applicationDidFinishLaunching` — move that to the App lifecycle. The `ContentView` `frame(width: 420, height: 600)` should move to a `Window` or `WindowGroup` configuration.

**Recommendation:** Option B for a new SwiftUI-first codebase. This also fixes the popover auto-show issue (item #10) naturally since the window setup moves to the Scene delegate layer.

---

### 17. Fix `ExerciseSession` inout — make it Sendable-safe
**File:** `AxiomIOSMac/Services/CBTExerciseService.swift`
**Lines:** ~145–155 (`advanceStep`, `recordResponse` use `inout`)

The `inout` parameter on `ExerciseSession` prevents it from being `Sendable`. Refactor to return a new `ExerciseSession` rather than mutating in-place:

```swift
// Before:
func advanceStep(in session: inout ExerciseSession) -> Bool {
    guard session.currentStepIndex < session.steps.count - 1 else { return false }
    session.currentStepIndex += 1
    return true
}

// After:
func advanceStep(_ session: ExerciseSession) -> ExerciseSession? {
    guard session.currentStepIndex < session.steps.count - 1 else { return nil }
    var next = session
    next.currentStepIndex += 1
    return next
}

func recordResponse(_ session: ExerciseSession, response: String) -> ExerciseSession {
    var updated = session
    updated.stepResponses[session.currentStep.title] = response
    return updated
}
```

**Why:** Swift 6 will require `Sendable` conformance on actors/classes that capture state. `inout` on non-Sendable types is unsafe.

---

### 18. Fix Biometric Lock / Weekly Digest / Export UI wiring
**File:** `AxiomIOSMac/SettingsView.swift`
**Lines:** ~22–24 (toggle states exist, nothing happens)

- **Biometric Lock:** `@State private var biometricLock = false` — needs to gate app access on launch. This is a real security feature; at minimum, store a flag in Keychain and check it in `AppDelegate.applicationDidFinishLaunching` before showing the popover.
- **Weekly Digest:** `@State private var weeklyDigest = true` — needs to schedule a background notification or email. Until then, the toggle is misleading.
- **Export:** The sheet shows but "Export" button does nothing (`isPresented = false`). Implement actual JSON/CSV export using `NSSavePanel`.

**Recommendation:** For MVP, either wire them minimally or replace the toggles with "Coming Soon" labels. Shipping broken toggles gives users false expectations.

---

## Tier 4: Polish (tokens, keyboard shortcuts, empty states)

### 19. Replace `Color(.windowBackgroundColor)` with Theme colors
**File:** `AxiomIOSMac/InsightsView.swift`
**Lines:** ~38, ~53, ~67, ~80, ~97 (all card `.background()` calls)

All card views in `InsightsView` use `Color(.windowBackgroundColor)`. Replace with `Theme.surface` (or a dedicated `Theme.cardBg`):

```swift
.background(Theme.surface)   // was Color(.windowBackgroundColor)
```

Also ensure `Theme.surface` handles dark mode — if hardcoded, consider:
```swift
static let surface = Color("Surface")  // with an asset catalog color set
// Or use adaptive:
static let surface = Color(UIColor { $0.userInterfaceLevel == .level ? .systemBackground : .secondarySystemBackground })
```

---

### 20. Fix `CognitiveDistortionsCard` icon color
**File:** `AxiomIOSMac/InsightsView.swift`
**Line:** ~109 (`.foregroundColor(.yellow)`)

```swift
Image(systemName: "exclamationmark.triangle")
    .foregroundColor(Theme.gold)  // was .yellow
```

---

### 21. Add empty state to `EvidenceLibraryView`
**File:** `AxiomIOSMac/CommunityView.swift`
**Line:** ~118 (EvidenceLibraryView body)

```swift
var body: some View {
    VStack(alignment: .leading, spacing: 12) {
        Text("Evidence Library")
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(Theme.navy)
        Text("Common beliefs and the evidence around them")
            .font(.system(size: 11))
            .foregroundColor(.secondary)

        if items.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "book.closed")
                    .font(.system(size: 28))
                    .foregroundColor(Theme.gold.opacity(0.5))
                Text("No evidence library items yet")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Text("Evidence library items will appear here when shared by the community")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        } else {
            ForEach(items) { item in
                EvidenceLibraryCard(item: item)
            }
        }
    }
}
```

---

### 22. Fix BeliefTrajectoryCard false affordance
**File:** `AxiomIOSMac/InsightsView.swift`
**Line:** ~60 (`chart.line.uptrend.xyaxis` icon, flat list content)

The `chart.line.uptrend.xyaxis` icon promises trajectory/chart visualization but the card renders a flat list of belief texts. Two options:

**Option A (quick):** Change the icon to match reality:
```swift
Image(systemName: "list.bullet")
    .foregroundColor(.green)
```

**Option B (real fix):** Implement actual trajectory visualization — show score over time for beliefs that have been updated. This requires storing historical score snapshots. Defer to post-MVP; for now change the icon.

---

### 23. Add keyboard shortcuts
**File:** `AxiomIOSMac/ContentView.swift` (and `BeliefsView.swift`, `CommunityView.swift`)

Add `.keyboardShortcut()` modifiers to major actions:

```swift
// In ContentView — tab switching:
TabButton(title: "Beliefs", ...) { ... }
    .keyboardShortcut("1", modifiers: .command)

TabButton(title: "Community", ...) { ... }
    .keyboardShortcut("2", modifiers: .command)

TabButton(title: "Insights", ...) { ... }
    .keyboardShortcut("3", modifiers: .command)

TabButton(title: "Settings", ...) { ... }
    .keyboardShortcut("4", modifiers: .command)

// In BeliefsView — add belief:
Button { showingAddBelief = true } label: { ... }
    .keyboardShortcut("n", modifiers: .command)

// In CommunityView — new post FAB:
Button { showingNewPost = true } label: { ... }
    .keyboardShortcut("n", modifiers: [.command, .shift])
```

---

### 24. Design tokens — extract hardcoded spacing/radius
**File:** `AxiomIOSMac/Theme.swift`
**Add:**

```swift
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
}

enum Radius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let pill: CGFloat = 9999
}

enum Shadow {
    static let card = (color: Color.black.opacity(0.04), radius: CGFloat(4), y: CGFloat(2))
}
```

Then replace hardcoded values throughout views. This is a large find-and-replace; recommended as a dedicated cleanup pass rather than trying to do it in this round.

---

## What NOT to fix in this round

The following are **deferred to R14** (post-MVP, or when the fix cost exceeds the problem cost):

| Issue | Reason to defer |
|---|---|
| Full persistence layer (Core Data / SQLite) | Significant architecture. `loadSampleData()` re-seeding is a known MVP limitation. |
| Real AI/ML backend for `generateInsights()` | Requires external API integration. The stub implementation is intentional for MVP. |
| `TherapistService` concrete `DataService.shared` dependency | Architectural fix requires protocol abstraction, dependency injection setup. Testable at integration level for now. |
| StoreKit2 subscription management | Real IAP requires App Store Connect setup, receipt validation. Hardcoded "Active" status is acceptable for MVP. |
| `@unchecked Sendable` on `AIBeliefService` | The service is a simple singleton with no shared mutable state. Correct fix (actor isolation) requires broader concurrency refactor. |
| Full biometric authentication gate | Requires LocalAuthentication framework integration; MVP can note this as a roadmap item. |
| Asset catalog + dark mode adaptive Theme colors | Design tokens (item #24) should drive this. Deferred to the design token pass. |
| Weekly digest notification scheduling | Requires `UNUserNotificationCenter` setup. The toggle UI can exist without the backend. |
| `CommunityPost`/`AIInsight`/`InsightItem` type consolidation | Three structs with identical fields doing similar jobs. Consolidate after MVP stabilizes the data model. |

---

## Build Verification

After applying all Tier 1 and Tier 2 fixes:

```bash
cd /Users/mauriello/.openclaw/workspace/projects/axiom-ios/AxiomIOSMac
swift build 2>&1 | grep -E "(error:|warning:.*nonisolated|warning:.*Sendable)"
```

**Expected result:** Zero errors. Minor warnings about `@unchecked Sendable` and deprecated API usage are acceptable (those are the High-tier items deferred to R14).

**Manual smoke test after build:**
1. Launch the app — popover should NOT appear automatically ✓
2. Click the menu bar icon — popover opens ✓
3. Tab through all 4 tabs with VoiceOver — each element announces ✓
4. Toggle Dark Mode in Settings — UI responds ✓
5. Add a belief, add evidence — it persists within the session ✓
6. Navigate to Community → Debates → Join Debate button — it navigates ✓
7. Check Insights — AI Analysis shows distinct insights per belief, not identical boilerplate ✓

---

*Generated by Unified Planner (Phase 3). 20 consolidated issues → 4 severity tiers, 24 specific fixes.*
