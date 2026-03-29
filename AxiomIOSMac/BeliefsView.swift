import SwiftUI

struct BeliefsView: View {
    @StateObject private var dataService = DataService.shared
    @State private var showingAddBelief = false
    @State private var newBeliefText = ""
    @State private var selectedBelief: Belief?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Core beliefs section
                if !dataService.beliefs.filter(\.isCore).isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Core Beliefs")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Theme.navy)
                            Circle().fill(Theme.gold).frame(width: 6, height: 6)
                            Spacer()
                        }
                        .padding(.horizontal, 4)

                        ForEach(dataService.beliefs.filter(\.isCore)) { belief in
                            BeliefCard(belief: belief, onTap: { selectedBelief = belief })
                                .onLongPressGesture { selectedBelief = belief }
                        }
                    }
                }

                // All beliefs section
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("All Beliefs")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.navy)
                        Spacer()
                        Text("\(dataService.beliefs.count)")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 4)

                    ForEach(dataService.beliefs.sorted { $0.updatedAt > $1.updatedAt }) { belief in
                        BeliefCard(belief: belief, onTap: { selectedBelief = belief })
                    }
                }
            }
            .padding(20)
        }
        .background(Theme.surface)
        .overlay(alignment: .bottomTrailing) {
            Button {
                showingAddBelief = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(Theme.navy)
                    .clipShape(Circle())
                    .shadow(color: Theme.navy.opacity(0.3), radius: 4, y: 2)
            }
            .padding(20)
        }
        .sheet(isPresented: $showingAddBelief) {
            AddBeliefSheet(isPresented: $showingAddBelief, dataService: dataService)
        }
        .sheet(item: $selectedBelief) { belief in
            BeliefDetailSheet(belief: belief, dataService: dataService)
        }
    }
}

struct BeliefCard: View {
    let belief: Belief
    let onTap: () -> Void

    var scoreColor: Color {
        switch ScoreLevel(score: belief.score) {
        case .low: return Theme.accentRed
        case .medium: return Theme.accentGold
        case .high: return Theme.accentGreen
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Score indicator
                ZStack {
                    Circle()
                        .stroke(Theme.surface, lineWidth: 3)
                    Circle()
                        .trim(from: 0, to: belief.score / 100)
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    Text("\(Int(belief.score))")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(scoreColor)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(belief.text)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.navy)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 8) {
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark.circle.fill").font(.system(size: 10))
                                .foregroundColor(Theme.accentGreen)
                            Text("\(belief.evidenceItems.filter { $0.type == .support }.count)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        HStack(spacing: 3) {
                            Image(systemName: "xmark.circle.fill").font(.system(size: 10))
                                .foregroundColor(Theme.accentRed)
                            Text("\(belief.evidenceItems.filter { $0.type == .contradict }.count)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if belief.isCore {
                            Text("Core")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(Theme.gold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.gold.opacity(0.15))
                                .cornerRadius(4)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(14)
            .background(Theme.cardBg)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
}

struct AddBeliefSheet: View {
    @Binding var isPresented: Bool
    let dataService: DataService
    @State private var text = ""
    @State private var isCore = false

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("New Belief")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Theme.navy)
                Spacer()
                Button("Cancel") { isPresented = false }
                    .foregroundColor(Theme.gold)
            }

            TextField("I am...", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .padding(12)
                .background(Theme.surface)
                .cornerRadius(8)

            Toggle(isOn: $isCore) {
                HStack {
                    Image(systemName: "star.fill").foregroundColor(Theme.gold)
                    Text("Mark as core belief")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.navy)
                }
            }
            .toggleStyle(.switch)
            .tint(Theme.gold)

            Button {
                if text.count >= 5 {
                    dataService.addBelief(text, isCore: isCore)
                    isPresented = false
                }
            } label: {
                Text("Add Belief")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(text.count >= 5 ? Theme.navy : Theme.navy.opacity(0.4))
                    .cornerRadius(10)
            }
            .disabled(text.count < 5)
        }
        .padding(24)
        .background(Theme.cream)
        .frame(width: 380)
    }
}

struct BeliefDetailSheet: View {
    let belief: Belief
    let dataService: DataService
    @State private var showingAddEvidence = false
    @State private var evidenceType: EvidenceType = .support
    @Environment(\.dismiss) private var dismiss

    var scoreColor: Color {
        switch ScoreLevel(score: belief.score) {
        case .low: return Theme.accentRed
        case .medium: return Theme.accentGold
        case .high: return Theme.accentGreen
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        if belief.isCore {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill").font(.system(size: 10))
                                Text("Core Belief")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(Theme.gold)
                        }
                        Text(belief.text)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Theme.navy)
                    }
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                    }
                }

                // Score
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Belief Strength")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text("\(Int(belief.score))/100")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(scoreColor)
                    }
                    Spacer()
                    ZStack {
                        Circle().stroke(Theme.surface, lineWidth: 6)
                        Circle()
                            .trim(from: 0, to: belief.score / 100)
                            .stroke(scoreColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                    .frame(width: 70, height: 70)
                }
                .padding(16)
                .background(Theme.cardBg)
                .cornerRadius(12)

                // Supporting evidence
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(Theme.accentGreen)
                        Text("Supporting Evidence")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.navy)
                        Spacer()
                        Button {
                            evidenceType = .support
                            showingAddEvidence = true
                        } label: {
                            Image(systemName: "plus").font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Theme.gold)
                        }
                    }
                    let supporting = belief.evidenceItems.filter { $0.type == .support }
                    if supporting.isEmpty {
                        Text("No supporting evidence yet").font(.system(size: 12)).foregroundColor(.secondary)
                    } else {
                        ForEach(supporting) { ev in
                            EvidenceRow(evidence: ev, beliefId: belief.id, dataService: dataService)
                        }
                    }
                }

                // Contradicting evidence
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "xmark.circle.fill").foregroundColor(Theme.accentRed)
                        Text("Contradicting Evidence")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.navy)
                        Spacer()
                        Button {
                            evidenceType = .contradict
                            showingAddEvidence = true
                        } label: {
                            Image(systemName: "plus").font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Theme.gold)
                        }
                    }
                    let contradicting = belief.evidenceItems.filter { $0.type == .contradict }
                    if contradicting.isEmpty {
                        Text("No contradicting evidence yet").font(.system(size: 12)).foregroundColor(.secondary)
                    } else {
                        ForEach(contradicting) { ev in
                            EvidenceRow(evidence: ev, beliefId: belief.id, dataService: dataService)
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Theme.surface)
        .sheet(isPresented: $showingAddEvidence) {
            AddEvidenceSheet(isPresented: $showingAddEvidence, dataService: dataService, beliefId: belief.id, type: evidenceType)
        }
    }
}

struct EvidenceRow: View {
    let evidence: Evidence
    let beliefId: UUID
    let dataService: DataService

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: evidence.type == .support ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(evidence.type == .support ? Theme.accentGreen : Theme.accentRed)
            Text(evidence.text)
                .font(.system(size: 13))
                .foregroundColor(Theme.navy)
            Spacer()
        }
        .padding(10)
        .background(Theme.cardBg)
        .cornerRadius(8)
        .contextMenu {
            Button(role: .destructive) {
                dataService.deleteEvidence(beliefId: beliefId, evidenceId: evidence.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct AddEvidenceSheet: View {
    @Binding var isPresented: Bool
    let dataService: DataService
    let beliefId: UUID
    let type: EvidenceType
    @State private var text = ""

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(type == .support ? "Add Supporting Evidence" : "Add Contradicting Evidence")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.navy)
                Spacer()
                Button("Cancel") { isPresented = false }
                    .foregroundColor(Theme.gold)
            }

            TextField(type == .support ? "Why does this belief make sense?" : "What contradicts this belief?", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .padding(12)
                .background(Theme.surface)
                .cornerRadius(8)

            Button {
                if text.count >= 3 {
                    dataService.addEvidence(to: beliefId, text: text, type: type)
                    isPresented = false
                }
            } label: {
                Text("Add Evidence")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(text.count >= 3 ? Theme.navy : Theme.navy.opacity(0.4))
                    .cornerRadius(8)
            }
            .disabled(text.count < 3)
        }
        .padding(20)
        .background(Theme.cream)
        .frame(width: 360)
    }
}
