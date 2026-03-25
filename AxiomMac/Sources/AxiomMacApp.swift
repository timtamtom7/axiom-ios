import SwiftUI

@main
struct AxiomMacApp: App {
    @StateObject private var databaseService = DatabaseService.shared

    var body: some Scene {
        WindowGroup {
            MacContentView()
                .environmentObject(databaseService)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
