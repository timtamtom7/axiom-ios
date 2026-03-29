import SwiftUI
import UIKit

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var hasCompletedOnboarding: Bool = UserDefaults.standard.bool(forKey: "has_completed_onboarding")

    var body: some View {
        ZStack {
            Group {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    iPadContentView
                } else {
                    iPhoneContentView
                }
            }

            if !hasCompletedOnboarding {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: hasCompletedOnboarding)
    }

    private var iPhoneContentView: some View {
        TabView(selection: $selectedTab) {
            BeliefListView()
                .tabItem {
                    Label("Beliefs", systemImage: "brain")
                }
                .tag(0)

            InsightsDashboardView()
                .tabItem {
                    Label("Insights", systemImage: "chart.bar")
                }
                .tag(1)

            BeliefMapView()
                .tabItem {
                    Label("Map", systemImage: "circle.hexagongrid")
                }
                .tag(2)

            EvidenceLibraryView()
                .tabItem {
                    Label("Evidence", systemImage: "books.vertical")
                }
                .tag(3)

            CommunityView()
                .tabItem {
                    Label("Community", systemImage: "person.3")
                }
                .tag(4)
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
                    NavigationLink(destination: InsightsDashboardView()) {
                        Label("Insights", systemImage: "chart.bar")
                    }
                    NavigationLink(destination: BeliefMapView()) {
                        Label("Map", systemImage: "circle.hexagongrid")
                    }
                    NavigationLink(destination: EvidenceLibraryView()) {
                        Label("Evidence Library", systemImage: "books.vertical")
                    }
                    NavigationLink(destination: CommunityView()) {
                        Label("Community", systemImage: "person.3")
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
