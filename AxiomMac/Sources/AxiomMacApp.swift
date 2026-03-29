import SwiftUI

@main
struct AxiomMacApp: App {
    @StateObject private var databaseService = DatabaseService.shared
    @StateObject private var retentionService = RetentionService.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MacContentView()
                    .environmentObject(databaseService)
                    .environmentObject(retentionService)
                    .preferredColorScheme(.dark)
                    .onAppear {
                        checkRetentionTriggers()
                    }
            } else {
                OnboardingView(isOnboarding: $hasCompletedOnboarding)
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }

        MenuBarExtra {
            MenuBarContent(databaseService: databaseService)
        } label: {
            Image(systemName: "scale.3d")
        }
        .menuBarExtraStyle(.window)
    }

    private func checkRetentionTriggers() {
        retentionService.loadRetentionData()
        retentionService.recordSession()

        // Check if user needs milestone nudge
        if retentionService.needsMilestoneNudge() {
            let milestone = retentionService.currentRetentionMilestone
            print("[Retention] User needs nudge for: \(milestone.rawValue)")
            // In production, show in-app prompt
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
