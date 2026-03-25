import SwiftUI
import UIKit

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                iPadContentView
            } else {
                iPhoneContentView
            }
        }
    }

    private var iPhoneContentView: some View {
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

            EvidenceLibraryView()
                .tabItem {
                    Label("Evidence", systemImage: "books.vertical")
                }
                .tag(2)
        }
        .tint(Theme.accentGold)
    }

    private var iPadContentView: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            List {
                Section {
                    NavigationLink(destination: BeliefListView()) {
                        Label("Beliefs", systemImage: "brain")
                    }
                    NavigationLink(destination: BeliefMapView()) {
                        Label("Map", systemImage: "circle.hexagongrid")
                    }
                    NavigationLink(destination: EvidenceLibraryView()) {
                        Label("Evidence Library", systemImage: "books.vertical")
                    }
                }
            }
            .navigationTitle("Axiom")
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 300)
        } detail: {
            // Detail column: shows selected belief detail or placeholder
            NavigationStack {
                ZStack {
                    Theme.background.ignoresSafeArea()
                    VStack(spacing: Theme.spacingL) {
                        Image(systemName: "scale.3d")
                            .font(.system(size: 72))
                            .foregroundColor(Theme.textSecondary.opacity(0.3))
                        Text("Select a belief from the sidebar")
                            .font(.title3)
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                .navigationTitle("Axiom")
                .navigationBarTitleDisplayMode(.large)
            }
        }
        .tint(Theme.accentGold)
    }
}

#Preview {
    ContentView()
        .environmentObject(DatabaseService.shared)
        .preferredColorScheme(.dark)
}
