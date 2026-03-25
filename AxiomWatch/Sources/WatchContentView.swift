import SwiftUI

struct WatchContentView: View {
    @StateObject private var storage = WatchStorageService.shared
    @State private var selectedBelief: WatchBelief?
    @State private var showingCheckIn = false

    var body: some View {
        NavigationStack {
            if selectedBelief == nil {
                beliefListView
            } else if let belief = selectedBelief {
                beliefDetailView(belief: belief)
            }
        }
    }

    private var beliefListView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(topBeliefs) { belief in
                    WatchBeliefRow(belief: belief)
                        .onTapGesture {
                            selectedBelief = belief
                        }
                }
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("Beliefs")
        .onAppear {
            storage.loadBeliefs()
        }
    }

    private func beliefDetailView(belief: WatchBelief) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(belief.text)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(3)

                HStack {
                    Text("Score:")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text("\(Int(belief.score))")
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(watchScoreColor(for: belief.score))
                }

                HStack(spacing: 8) {
                    Button {
                        showingCheckIn = true
                    } label: {
                        Label("Check In", systemImage: "checkmark.circle")
                            .font(.caption)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accentGold)

                    Button {
                        selectedBelief = nil
                    } label: {
                        Label("Back", systemImage: "chevron.left")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(8)
        }
        .navigationTitle("Belief")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    selectedBelief = nil
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
        }
        .sheet(isPresented: $showingCheckIn) {
            if let belief = selectedBelief {
                WatchCheckInView(belief: belief) {
                    showingCheckIn = false
                    selectedBelief = nil
                }
            }
        }
    }

    private var topBeliefs: [WatchBelief] {
        Array(storage.beliefs.prefix(5))
    }

    private func watchScoreColor(for score: Double) -> Color {
        if score < 40 { return Theme.accentRed }
        else if score < 70 { return Theme.accentGold }
        else { return Theme.accentGreen }
    }
}

struct WatchBeliefRow: View {
    let belief: WatchBelief

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(watchScoreColor(for: belief.score))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 1) {
                Text(belief.text)
                    .font(.caption2)
                    .foregroundColor(.white)
                    .lineLimit(2)

                Text("\(belief.supportingCount) for · \(belief.contradictingCount) against")
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(Theme.surface)
        .cornerRadius(8)
    }

    private func watchScoreColor(for score: Double) -> Color {
        if score < 40 { return Theme.accentRed }
        else if score < 70 { return Theme.accentGold }
        else { return Theme.accentGreen }
    }
}

struct WatchCheckInView: View {
    let belief: WatchBelief
    let onDismiss: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedScore: Double = 50
    @State private var note = ""
    @State private var isSaving = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("How strong is this belief now?")
                    .font(.caption)
                    .foregroundColor(.gray)

                // Score selector
                HStack(spacing: 4) {
                    ForEach(0..<11, id: \.self) { score in
                        Button {
                            selectedScore = Double(score * 10)
                        } label: {
                            Text("\(score * 10)")
                                .font(.system(size: 9, design: .rounded))
                                .fontWeight(selectedScore == Double(score * 10) ? .bold : .regular)
                                .foregroundColor(selectedScore == Double(score * 10) ? .white : .gray)
                                .frame(width: 24, height: 24)
                                .background(selectedScore == Double(score * 10) ? watchScoreColor(Double(score * 10)) : Color.clear)
                                .cornerRadius(4)
                        }
                    }
                }

                TextField("Note (optional)", text: $note, axis: .vertical)
                    .font(.caption2)
                    .padding(4)
                    .background(Theme.surfaceElevated)
                    .cornerRadius(6)
                    .lineLimit(2...3)

                Button {
                    saveCheckpoint()
                } label: {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("Save Checkpoint")
                    }
                }
                .font(.caption)
                .buttonStyle(.borderedProminent)
                .tint(Theme.accentGold)
                .disabled(isSaving)
            }
            .padding(8)
        }
        .navigationTitle("Check-In")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func saveCheckpoint() {
        isSaving = true
        let checkpoint = WatchCheckpoint(
            id: UUID(),
            beliefId: belief.id,
            recordedAt: Date(),
            score: selectedScore,
            note: note.isEmpty ? nil : note
        )
        WatchStorageService.shared.addCheckpoint(checkpoint)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSaving = false
            dismiss()
            onDismiss()
        }
    }

    private func watchScoreColor(for score: Double) -> Color {
        if score < 40 { return Theme.accentRed }
        else if score < 70 { return Theme.accentGold }
        else { return Theme.accentGreen }
    }
}
