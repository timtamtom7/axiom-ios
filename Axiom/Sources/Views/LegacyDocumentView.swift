import SwiftUI

/// Full belief evolution document — your complete belief audit over time
struct LegacyDocumentView: View {
    @EnvironmentObject var databaseService: DatabaseService
    @State private var selectedExportFormat: ExportFormat = .pdf
    @State private var isExporting = false
    @State private var showingShareSheet = false

    enum ExportFormat: String, CaseIterable {
        case pdf = "PDF"
        case json = "JSON"
        case markdown = "Markdown"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.spacingXL) {
                        // Header
                        legacyHeader

                        // Summary stats
                        summaryStats

                        // Evolution timeline
                        evolutionTimeline

                        // Core beliefs section
                        coreBeliefsSection

                        // Recent check-ins
                        recentCheckInsSection

                        // Export section
                        exportSection
                    }
                    .padding(Theme.screenMargin)
                }
            }
            .navigationTitle("Legacy Document")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                LegacyExportSheet()
            }
        }
    }

    private var legacyHeader: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Belief Audit")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.textPrimary)
                    Text("Complete Evolution Document")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: "doc.text.fill")
                    .font(.title)
                    .foregroundColor(Theme.accentGold)
            }

            Text("Generated on \(Date().formatted(date: .long, time: .shortened))")
                .font(.caption2)
                .foregroundColor(Theme.textSecondary)

            Divider()
        }
    }

    private var summaryStats: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            Text("Summary")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            HStack(spacing: Theme.spacingM) {
                statCard(title: "Beliefs", value: "\(databaseService.allBeliefs.count)", icon: "brain.head.profile", color: Theme.accentBlue)
                statCard(title: "Core", value: "\(databaseService.allBeliefs.filter { $0.isCore }.count)", icon: "diamond.fill", color: Theme.accentGold)
            }

            HStack(spacing: Theme.spacingM) {
                statCard(title: "Evidence", value: "\(totalEvidence)", icon: "list.bullet.clipboard", color: Theme.accentGreen)
                statCard(title: "Checkpoints", value: "\(totalCheckpoints)", icon: "clock.arrow.circlepath", color: Theme.accentRed)
            }
        }
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.textPrimary)
                Text(title)
                    .font(.caption2)
                    .foregroundColor(Theme.textSecondary)
            }
            Spacer()
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private var evolutionTimeline: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            Text("Belief Evolution")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            if databaseService.allBeliefs.isEmpty {
                Text("No beliefs yet. Start your journey by adding your first belief.")
                    .font(.callout)
                    .foregroundColor(Theme.textSecondary)
                    .italic()
            } else {
                ForEach(sortedByCreation) { belief in
                    timelineRow(for: belief)
                }
            }
        }
    }

    private func timelineRow(for belief: Belief) -> some View {
        HStack(alignment: .top, spacing: Theme.spacingM) {
            // Timeline dot
            VStack(spacing: 0) {
                Circle()
                    .fill(belief.isCore ? Theme.accentGold : Theme.accentBlue)
                    .frame(width: 10, height: 10)
                Rectangle()
                    .fill(Theme.border)
                    .frame(width: 1)
            }

            VStack(alignment: .leading, spacing: Theme.spacingXS) {
                Text(belief.text)
                    .font(.subheadline)
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(2)

                HStack(spacing: Theme.spacingM) {
                    if belief.isCore {
                        Text("CORE")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.accentGold)
                    }
                    Text("Score: \(Int(belief.score))")
                        .font(.caption2)
                        .foregroundColor(Theme.textSecondary)
                    Text("\(belief.evidenceItems.count) evidence")
                        .font(.caption2)
                        .foregroundColor(Theme.textSecondary)
                }

                Text("Added \(belief.createdAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption2)
                    .foregroundColor(Theme.textSecondary)
            }
        }
    }

    private var coreBeliefsSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            Text("Core Beliefs")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            let coreBeliefs = databaseService.allBeliefs.filter { $0.isCore }
            if coreBeliefs.isEmpty {
                Text("No core beliefs marked.")
                    .font(.callout)
                    .foregroundColor(Theme.textSecondary)
                    .italic()
            } else {
                ForEach(coreBeliefs) { belief in
                    coreBeliefRow(for: belief)
                }
            }
        }
    }

    private func coreBeliefRow(for belief: Belief) -> some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            HStack {
                Image(systemName: "diamond.fill")
                    .font(.caption)
                    .foregroundColor(Theme.accentGold)
                Text(belief.text)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Theme.textPrimary)
            }

            if let rootCause = belief.rootCause {
                HStack(spacing: Theme.spacingXS) {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.caption2)
                    Text("Origin: \(rootCause)")
                        .font(.caption)
                }
                .foregroundColor(Theme.textSecondary)
            }

            Text("Score: \(Int(belief.score)) · \(belief.supportingCount) supporting · \(belief.contradictingCount) contradicting")
                .font(.caption2)
                .foregroundColor(Theme.textSecondary)
        }
        .padding(Theme.spacingS)
        .background(Theme.surface)
        .cornerRadius(8)
    }

    private var recentCheckInsSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            Text("Recent Checkpoints")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            let checkpoints = databaseService.allCheckpoints
            if checkpoints.isEmpty {
                Text("No checkpoints yet. Track your belief changes over time.")
                    .font(.callout)
                    .foregroundColor(Theme.textSecondary)
                    .italic()
            } else {
                ForEach(checkpoints.prefix(5)) { checkpoint in
                    checkpointRow(for: checkpoint)
                }
            }
        }
    }

    private func checkpointRow(for checkpoint: BeliefCheckpoint) -> some View {
        let belief = databaseService.allBeliefs.first { $0.id == checkpoint.beliefId }

        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(belief?.text ?? "Unknown belief")
                    .font(.caption)
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)

                Text(checkpoint.recordedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            Text("\(Int(checkpoint.score))")
                .font(.system(.caption, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(scoreColor(for: checkpoint.score))
        }
        .padding(Theme.spacingS)
        .background(Theme.surface)
        .cornerRadius(8)
    }

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            Text("Export")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            Text("Export your full belief evolution as a portable document.")
                .font(.caption)
                .foregroundColor(Theme.textSecondary)

            Button {
                showingShareSheet = true
            } label: {
                Label("Export Legacy Document", systemImage: "square.and.arrow.up")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(Theme.spacingM)
                    .background(Theme.accentBlue.opacity(0.15))
                    .foregroundColor(Theme.accentBlue)
                    .cornerRadius(12)
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private var sortedByCreation: [Belief] {
        databaseService.allBeliefs.sorted { $0.createdAt < $1.createdAt }
    }

    private var totalEvidence: Int {
        databaseService.allBeliefs.reduce(0) { $0 + $1.evidenceItems.count }
    }

    private var totalCheckpoints: Int {
        databaseService.allCheckpoints.count
    }

    private func scoreColor(for score: Double) -> Color {
        if score < 40 { return Theme.accentRed }
        else if score < 70 { return Theme.accentGold }
        else { return Theme.accentGreen }
    }
}

struct LegacyExportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFormat: ExportFormat = .pdf
    @State private var includeCheckpoints = true
    @State private var includeEvidence = true
    @State private var isExporting = false

    enum ExportFormat: String, CaseIterable {
        case pdf = "PDF"
        case json = "JSON"
        case markdown = "Markdown"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: Theme.spacingL) {
                    Text("Export Format")
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)

                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Button {
                            selectedFormat = format
                        } label: {
                            HStack {
                                Text(format.rawValue)
                                    .font(.body)
                                    .foregroundColor(Theme.textPrimary)
                                Spacer()
                                if selectedFormat == format {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Theme.accentGold)
                                }
                            }
                            .padding(Theme.spacingM)
                            .background(selectedFormat == format ? Theme.accentGold.opacity(0.1) : Theme.surface)
                            .cornerRadius(8)
                        }
                    }

                    Toggle(isOn: $includeCheckpoints) {
                        Text("Include checkpoints")
                            .font(.subheadline)
                            .foregroundColor(Theme.textPrimary)
                    }
                    .tint(Theme.accentGold)

                    Toggle(isOn: $includeEvidence) {
                        Text("Include evidence details")
                            .font(.subheadline)
                            .foregroundColor(Theme.textPrimary)
                    }
                    .tint(Theme.accentGold)

                    Spacer()

                    Button {
                        exportDocument()
                    } label: {
                        Label(isExporting ? "Exporting..." : "Export", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(Theme.spacingM)
                            .background(Theme.accentGold)
                            .foregroundColor(Theme.background)
                            .cornerRadius(12)
                    }
                    .disabled(isExporting)
                }
                .padding(Theme.screenMargin)
            }
            .navigationTitle("Export Legacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func exportDocument() {
        isExporting = true
        // Simulate export
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isExporting = false
            dismiss()
        }
    }
}
