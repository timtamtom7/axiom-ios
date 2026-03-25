import SwiftUI

struct BeliefEvolutionView: View {
    let belief: Belief
    let checkpoints: [BeliefCheckpoint]
    @Environment(\.dismiss) private var dismiss
    @State private var narrative: String?
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if isLoading {
                    VStack(spacing: Theme.spacingM) {
                        ProgressView()
                            .tint(Theme.accentGold)
                        Text("Writing your belief's story...")
                            .font(.callout)
                            .foregroundColor(Theme.textSecondary)
                    }
                } else if let error = error {
                    VStack(spacing: Theme.spacingM) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Theme.accentRed)
                        Text("Couldn't generate narrative")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.textPrimary)
                        Text(error)
                            .font(.callout)
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                        Button {
                            generateNarrative()
                        } label: {
                            Text("Try Again")
                                .font(.headline)
                                .padding(.horizontal, Theme.spacingXL)
                                .padding(.vertical, Theme.spacingM)
                                .background(Theme.surface)
                                .cornerRadius(12)
                        }
                    }
                    .padding(Theme.screenMargin)
                } else if let narrative = narrative {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Theme.spacingL) {
                            evolutionChartSection
                            if !checkpoints.isEmpty {
                                timelineSection
                            }
                            narrativeSection(narrative)
                        }
                        .padding(Theme.screenMargin)
                    }
                }
            }
            .navigationTitle("Belief Evolution")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                if narrative == nil && !isLoading {
                    generateNarrative()
                }
            }
        }
        .presentationDetents([.large])
    }

    private var evolutionChartSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            Text("Score Journey")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            let sorted = checkpoints.sorted { $0.recordedAt < $1.recordedAt }
            if sorted.count >= 2, let firstCP = sorted.first, let lastCP = sorted.last {
                let first = firstCP.score
                let last = lastCP.score
                let delta = last - first

                HStack(alignment: .bottom, spacing: Theme.spacingS) {
                    VStack(alignment: .leading) {
                        Text("\(Int(first))")
                            .font(.system(.title2, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(Theme.textSecondary)
                        Text("Start")
                            .font(.caption2)
                            .foregroundColor(Theme.textSecondary)
                    }
                    .frame(width: 50)

                    GeometryReader { geo in
                        let minScore: Double = max(0, (sorted.map { $0.score }.min() ?? 0) - 10)
                        let maxScore: Double = min(100, (sorted.map { $0.score }.max() ?? 100) + 10)
                        let scoreRange = maxScore - minScore

                        Path { path in
                            for (i, cp) in sorted.enumerated() {
                                let x = geo.size.width * CGFloat(i) / CGFloat(sorted.count - 1)
                                let normalized = (cp.score - minScore) / scoreRange
                                let y = geo.size.height * (1 - normalized)
                                if i == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(Theme.accentGold, lineWidth: 2)

                        ForEach(Array(sorted.enumerated()), id: \.element.id) { i, cp in
                            let x = geo.size.width * CGFloat(i) / CGFloat(sorted.count - 1)
                            let normalized = (cp.score - minScore) / scoreRange
                            let y = geo.size.height * (1 - normalized)
                            Circle()
                                .fill(Theme.accentGold)
                                .frame(width: 8, height: 8)
                                .position(x: x, y: y)
                        }
                    }
                    .frame(height: 80)

                    VStack(alignment: .trailing) {
                        Text("\(Int(last))")
                            .font(.system(.title2, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(Theme.scoreColor(for: last))
                        Text("Now")
                            .font(.caption2)
                            .foregroundColor(Theme.textSecondary)
                    }
                    .frame(width: 50)

                    VStack(alignment: .trailing) {
                        HStack(spacing: 2) {
                            Image(systemName: delta >= 0 ? "arrow.up" : "arrow.down")
                            Text("\(Int(abs(delta)))")
                        }
                        .font(.system(.callout, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(delta >= 0 ? Theme.accentGreen : Theme.accentRed)
                        Text("pts")
                            .font(.caption2)
                            .foregroundColor(Theme.textSecondary)
                    }
                    .frame(width: 50)
                }
            } else {
                Text("Record at least 2 checkpoints to see your belief's journey.")
                    .font(.callout)
                    .foregroundColor(Theme.textSecondary)
                    .italic()
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            Text("Timeline")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            let sorted = checkpoints.sorted { $0.recordedAt < $1.recordedAt }
            ForEach(Array(sorted.enumerated()), id: \.element.id) { index, cp in
                HStack(alignment: .top, spacing: Theme.spacingM) {
                    VStack {
                        Circle()
                            .fill(index == 0 || index == sorted.count - 1 ? Theme.accentGold : Theme.surfaceElevated)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(Theme.accentGold, lineWidth: 1)
                            )
                        if index < sorted.count - 1 {
                            Rectangle()
                                .fill(Theme.border)
                                .frame(width: 1, height: 30)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(cp.recordedAt.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                            Spacer()
                            Text("\(Int(cp.score))")
                                .font(.system(.callout, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(Theme.scoreColor(for: cp.score))
                        }
                        if let note = cp.note, !note.isEmpty {
                            Text("\"\(note)\"")
                                .font(.caption2)
                                .foregroundColor(Theme.textSecondary)
                                .italic()
                        }
                    }
                }
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private func narrativeSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack {
                Image(systemName: "wand.and.stars")
                    .foregroundColor(Theme.accentGold)
                Text("AI Evolution Narrative")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
            }

            Text(text)
                .font(.body)
                .foregroundColor(Theme.textPrimary)
                .textSelection(.enabled)
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private func generateNarrative() {
        isLoading = true
        error = nil
        Task {
            do {
                let result = try await AIStressTestService().getEvolutionNarrative(for: belief, checkpoints: checkpoints)
                await MainActor.run {
                    narrative = result
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    BeliefEvolutionView(belief: .preview, checkpoints: [
        BeliefCheckpoint(beliefId: UUID(), recordedAt: Date().addingTimeInterval(-86400 * 60), score: 72, note: "Starting point"),
        BeliefCheckpoint(beliefId: UUID(), recordedAt: Date().addingTimeInterval(-86400 * 30), score: 65),
        BeliefCheckpoint(beliefId: UUID(), recordedAt: Date(), score: 55, note: "New evidence found")
    ])
    .preferredColorScheme(.dark)
}
