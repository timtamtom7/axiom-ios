import SwiftUI

struct EvidenceRow: View {
    let evidence: Evidence
    let onDelete: () -> Void

    private var borderColor: Color {
        evidence.type == .support ? Theme.accentGreen : Theme.accentRed
    }

    private var confidenceColor: Color {
        if evidence.confidence >= 0.8 { return Theme.accentGreen }
        else if evidence.confidence >= 0.5 { return Theme.accentGold }
        else { return Theme.accentRed }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            HStack(alignment: .top, spacing: Theme.spacingM) {
                Image(systemName: evidence.type.icon)
                    .foregroundColor(borderColor)
                    .font(.headline)

                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                    Text(evidence.text)
                        .font(.callout)
                        .foregroundColor(Theme.textPrimary)

                    HStack(spacing: Theme.spacingM) {
                        // Confidence indicator
                        HStack(spacing: Theme.spacingXS) {
                            ForEach(0..<3) { i in
                                Circle()
                                    .fill(i < confidenceDots ? confidenceColor : Theme.border)
                                    .frame(width: 6, height: 6)
                            }
                            Text(evidence.confidenceLabel)
                                .font(.caption2)
                                .foregroundColor(Theme.textSecondary)
                        }

                        // Source label if present
                        if let label = evidence.sourceLabel {
                            Text(label)
                                .font(.caption2)
                                .foregroundColor(Theme.accentBlue)
                                .lineLimit(1)
                        }

                        // Attachment indicator
                        if evidence.attachmentPath != nil {
                            Image(systemName: evidence.attachmentType?.icon ?? "paperclip")
                                .font(.caption2)
                                .foregroundColor(Theme.accentBlue)
                        }

                        Spacer()

                        Text(evidence.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2)
                            .foregroundColor(Theme.textSecondary)
                    }
                }

                Spacer()
            }
        }
        .padding(Theme.spacingS)
        .background(Theme.surfaceElevated)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor.opacity(0.5), lineWidth: 1)
        )
        .cornerRadius(8)
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var confidenceDots: Int {
        if evidence.confidence >= 0.8 { return 3 }
        else if evidence.confidence >= 0.5 { return 2 }
        else { return 1 }
    }
}

#Preview {
    let support = Evidence(
        beliefId: UUID(),
        text: "My last relationship ended badly",
        type: .support,
        confidence: 0.9,
        sourceLabel: "Personal memory"
    )
    let contradict = Evidence(
        beliefId: UUID(),
        text: "I have many close friends who value me",
        type: .contradict,
        confidence: 0.4
    )
    return VStack {
        EvidenceRow(evidence: support) {}
        EvidenceRow(evidence: contradict) {}
    }
    .padding()
    .background(Theme.background)
    .preferredColorScheme(.dark)
}
