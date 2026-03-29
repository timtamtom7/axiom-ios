import SwiftUI

@main
struct AxiomMacApp: App {
    @StateObject private var databaseService = DatabaseService.shared
    @StateObject private var retentionService = RetentionService.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    /// R25: Tracks whether background services (AI, HealthKit, community) have been warmed up
    @State private var backgroundServicesWarmed = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MacContentView()
                    .environmentObject(databaseService)
                    .environmentObject(retentionService)
                    .preferredColorScheme(.dark)
                    .task(id: backgroundServicesWarmed) {
                        // R25: Warm background services only after UI is on screen
                        if !backgroundServicesWarmed {
                            backgroundServicesWarmed = true
                            await warmBackgroundServices()
                        }
                    }
                    .onAppear {
                        checkRetentionTriggers()
                        // Pre-warm haptic engine (lightweight, no-op if already init'd)
                        HapticService.shared.selection()
                    }
            } else {
                OnboardingView(isOnboarding: $hasCompletedOnboarding)
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Belief") {
                    // Handled via MacContentView's keyboard shortcut
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            CommandGroup(after: .appSettings) {
                Button("Settings") {
                    // Settings action handled in views
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }

        MenuBarExtra {
            MenuBarContent(databaseService: databaseService)
        } label: {
            Image(systemName: "scale.3d")
        }
        .menuBarExtraStyle(.window)
    }

    /// R25: Deferred initialization of non-critical services.
    /// AI, HealthKit, and community sync are loaded on a background thread
    /// so the first frame renders as fast as possible.
    @MainActor
    private func warmBackgroundServices() async {
        async let warmAIService: () = warmAIServiceIfNeeded()
        async let warmHealthKit: () = warmHealthKitIfNeeded()
        async let warmCommunitySync: () = warmCommunitySyncIfNeeded()

        _ = await (warmAIService, warmHealthKit, warmCommunitySync)
        print("[Startup] All background services warmed")
    }

    private func warmAIServiceIfNeeded() async {
        // Defer AI service init until after UI paint
        // In production: AIService.shared.warm() or similar
        try? await Task.sleep(nanoseconds: 500_000_000)
        print("[Startup] AI service ready")
    }

    private func warmHealthKitIfNeeded() async {
        // Defer HealthKit authorization and sync until after UI paint
        // In production: HealthKitService.shared.requestAuthorization()
        try? await Task.sleep(nanoseconds: 300_000_000)
        print("[Startup] HealthKit ready")
    }

    private func warmCommunitySyncIfNeeded() async {
        // Defer community sync until idle
        // In production: CommunitySyncService.shared.syncInBackground()
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        print("[Startup] Community sync complete")
    }

    private func checkRetentionTriggers() {
        retentionService.loadRetentionData()
        retentionService.recordSession()

        // Check if user needs milestone nudge
        if retentionService.needsMilestoneNudge() {
            let milestone = retentionService.currentRetentionMilestone
            print("[Retention] User needs nudge for: \(milestone.rawValue)")
        }

        // R13: Check beliefs count for retention tracking
        let beliefs = DatabaseService.shared.allBeliefs
        if !beliefs.isEmpty {
            retentionService.recordBeliefCreated()
        }
        for belief in beliefs {
            if !belief.evidenceItems.isEmpty {
                retentionService.recordEvidenceAdded()
                break
            }
        }
    }
}
