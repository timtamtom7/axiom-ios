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

        MenuBarExtra {
            MenuBarContent(databaseService: databaseService)
        } label: {
            Image(systemName: "scale.3d")
        }
        .menuBarExtraStyle(.window)
    }
}
