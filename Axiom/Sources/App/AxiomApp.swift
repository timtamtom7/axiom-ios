import SwiftUI

@main
struct AxiomApp: App {
    @StateObject private var databaseService = DatabaseService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(databaseService)
                .preferredColorScheme(.dark)
        }
    }
}
