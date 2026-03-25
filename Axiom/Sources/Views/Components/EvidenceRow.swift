import SwiftUI

struct EvidenceRow: View {
    let evidence: Evidence
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Theme.spacingM) {
            Image(systemName: evidence.type.icon)
                .foregroundColor(evidence.type == .support ? Theme.accentGreen : Theme.accentRed)
                .font(.headline)

            VStack(alignment: .leading, spacing: Theme.spacingXS) {
                Text(evidence.text)
                    .font(.callout)
                    .foregroundColor(Theme.textPrimary)

                Text(evidence.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()
        }
        .padding(.vertical, Theme.spacingXS)
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview {
    let evidence = Evidence(
        beliefId: UUID(),
        text: "My last relationship ended badly",
        type: .support
    )
    return EvidenceRow(evidence: evidence) {
        print("Delete")
    }
    .padding()
    .background(Theme.surface)
    .preferredColorScheme(.dark)
}
