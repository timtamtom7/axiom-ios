import SwiftUI

struct ContentView: View {
    @StateObject private var dataService = DataService.shared
    @State private var selectedTab = 0
    @AppStorage("axiom.darkMode") private var darkMode = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Axiom")
                        .font(.system(size: 20, weight: .bold, design: .serif))
                        .foregroundColor(Theme.navy)
                    Text("Belief Audit")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.gold)
                }
                Spacer()
                Text("\(dataService.streak) day streak 🔥")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.navy)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Theme.cream)

            // Tab bar
            HStack(spacing: 0) {
                TabButton(title: "Beliefs", icon: "brain", isSelected: selectedTab == 0) { selectedTab = 0 }
                .accessibilityLabel("Beliefs tab")
                .keyboardShortcut("1", modifiers: .command)
                TabButton(title: "Community", icon: "person.3", isSelected: selectedTab == 1) { selectedTab = 1 }
                .accessibilityLabel("Community tab")
                .keyboardShortcut("2", modifiers: .command)
                TabButton(title: "Insights", icon: "chart.line.uptrend.xyaxis", isSelected: selectedTab == 2) { selectedTab = 2 }
                .accessibilityLabel("Insights tab")
                .keyboardShortcut("3", modifiers: .command)
                TabButton(title: "Settings", icon: "gearshape", isSelected: selectedTab == 3) { selectedTab = 3 }
                .accessibilityLabel("Settings tab")
                .keyboardShortcut("4", modifiers: .command)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Theme.surface)

            // Content
            TabView(selection: $selectedTab) {
                BeliefsView().tag(0)
                CommunityView().tag(1)
                InsightsView().tag(2)
                SettingsView().tag(3)
            }
            .tabViewStyle(.automatic)
            .background(Theme.surface)
        }
        .frame(width: 420, height: 600)
        .background(Theme.surface)
        .preferredColorScheme(darkMode ? .dark : .light)
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(isSelected ? Theme.gold : Theme.navy.opacity(0.5))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Theme.navy.opacity(0.08) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}
