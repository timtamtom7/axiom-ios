import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            BeliefListView()
                .tabItem {
                    Label("Beliefs", systemImage: "brain")
                }
                .tag(0)

            BeliefMapView()
                .tabItem {
                    Label("Map", systemImage: "circle.hexagongrid")
                }
                .tag(1)
        }
        .tint(Theme.accentGold)
    }
}

#Preview {
    ContentView()
        .environmentObject(DatabaseService.shared)
        .preferredColorScheme(.dark)
}
