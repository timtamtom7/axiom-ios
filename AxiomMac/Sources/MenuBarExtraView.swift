import SwiftUI

/// Menu bar extra content for Axiom — quick access to recent beliefs from the menu bar.
struct MenuBarContent: View {
    @ObservedObject var databaseService: DatabaseService

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "scale.3d")
                    .foregroundColor(Theme.accentGold)
                Text("Axiom")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Theme.surfaceElevated)

            Divider()

            // Recent beliefs section
            if recentBeliefs.isEmpty {
                Text("No recent beliefs")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            } else {
                Section("Recent") {
                    ForEach(recentBeliefs.prefix(5)) { belief in
                        Button {
                            openBelief(belief)
                        } label: {
                            HStack {
                                Text(belief.text)
                                    .font(.caption)
                                    .foregroundColor(Theme.textPrimary)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(Int(belief.score))")
                                    .font(.system(.caption2, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundColor(Theme.scoreColor(for: belief.score))
                            }
                        }
                    }
                }

                Divider()
            }

            // Quick stats
            HStack {
                Text("\(databaseService.allBeliefs.count) beliefs")
                    .font(.caption2)
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                let totalEvidence = databaseService.allBeliefs.reduce(0) { $0 + $1.evidenceItems.count }
                Text("\(totalEvidence) evidence")
                    .font(.caption2)
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)

            Divider()

            // Actions
            Button {
                openMainApp()
            } label: {
                HStack {
                    Image(systemName: "arrow.up.forward.square")
                    Text("Open Axiom")
                }
                .font(.caption)
            }

            Button {
                NSApp.terminate(nil)
            } label: {
                HStack {
                    Image(systemName: "power")
                    Text("Quit")
                }
                .font(.caption)
            }
        }
        .frame(width: 240)
    }

    private var recentBeliefs: [Belief] {
        databaseService.allBeliefs
            .filter { !$0.isArchived }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    private func openBelief(_ belief: Belief) {
        NotificationCenter.default.post(
            name: .openBeliefInMainApp,
            object: nil,
            userInfo: ["beliefId": belief.id]
        )
        NSApp.activate()
    }

    private func openMainApp() {
        NSApp.activate()
    }
}

extension Notification.Name {
    static let openBeliefInMainApp = Notification.Name("openBeliefInMainApp")
}

#Preview {
    MenuBarContent(databaseService: DatabaseService.shared)
        .preferredColorScheme(.dark)
}
