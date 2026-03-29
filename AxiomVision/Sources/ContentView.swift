import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Belief Network
            BeliefNetworkView(
                beliefs: Belief.sampleBeliefs,
                connections: BeliefConnection.sampleConnections
            )
            .tabItem {
                Label("Network", systemImage: "circle.hexagongrid.fill")
            }
            .tag(0)

            // Tab 2: Therapy Session
            SessionView()
            .tabItem {
                Label("Session", systemImage: "brain.head.profile")
            }
            .tag(1)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
