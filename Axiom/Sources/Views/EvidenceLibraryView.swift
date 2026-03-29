import SwiftUI

/// Browses all evidence across all beliefs — a searchable, filterable library.
struct EvidenceLibraryView: View {
    @EnvironmentObject var databaseService: DatabaseService
    @State private var searchText = ""
    @State private var filterType: EvidenceType? = nil
    @State private var sortOrder: SortOrder = .newest

    enum SortOrder: String, CaseIterable {
        case newest = "Newest First"
        case oldest = "Oldest First"
        case belief = "By Belief"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if allEvidence.isEmpty {
                    EmptyStateView(
                        icon: "books.vertical",
                        title: "No Evidence Yet",
                        subtitle: "Add supporting or contradicting evidence to your beliefs to build your evidence library.",
                        actionTitle: nil,
                        action: nil
                    )
                } else {
                    VStack(spacing: 0) {
                        filterBar
                        evidenceList
                    }
                }
            }
            .navigationTitle("Evidence Library")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var allEvidence: [Evidence] {
        databaseService.allBeliefs.flatMap { $0.evidenceItems }
    }

    private var filteredEvidence: [Evidence] {
        var items = allEvidence

        if let filterType = filterType {
            items = items.filter { $0.type == filterType }
        }

        if !searchText.isEmpty {
            items = items.filter { evidence in
                let matchesText = evidence.text.localizedCaseInsensitiveContains(searchText)
                let matchesBelief = databaseService.allBeliefs.contains { b in
                    b.evidenceItems.contains(where: { $0.id == evidence.id }) &&
                    b.text.localizedCaseInsensitiveContains(searchText)
                }
                return matchesText || matchesBelief
            }
        }

        switch sortOrder {
        case .newest:
            items.sort { $0.createdAt > $1.createdAt }
        case .oldest:
            items.sort { $0.createdAt < $1.createdAt }
        case .belief:
            items.sort { ev1, ev2 in
                let b1 = databaseService.allBeliefs.first { $0.evidenceItems.contains(ev1) }?.text ?? ""
                let b2 = databaseService.allBeliefs.first { $0.evidenceItems.contains(ev2) }?.text ?? ""
                return b1 < b2
            }
        }

        return items
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.spacingS) {
                FilterChip(
                    title: "All",
                    isSelected: filterType == nil,
                    color: Theme.textSecondary
                ) {
                    filterType = nil
                }

                FilterChip(
                    title: "Supporting",
                    isSelected: filterType == .support,
                    color: Theme.accentGreen
                ) {
                    filterType = .support
                }

                FilterChip(
                    title: "Contradicting",
                    isSelected: filterType == .contradict,
                    color: Theme.accentRed
                ) {
                    filterType = .contradict
                }

                Divider()
                    .frame(height: 20)
                    .background(Theme.border)

                Menu {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Button {
                            sortOrder = order
                        } label: {
                            HStack {
                                Text(order.rawValue)
                                if sortOrder == order {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down")
                        Text(sortOrder.rawValue)
                    }
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                    .padding(.horizontal, Theme.spacingS)
                    .padding(.vertical, 4)
                    .background(Theme.surface)
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, Theme.screenMargin)
            .padding(.vertical, Theme.spacingS)
        }
        .background(Theme.surface.opacity(0.5))
    }

    private var evidenceList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.spacingM) {
                ForEach(filteredEvidence) { item in
                    if let belief = databaseService.allBeliefs.first(where: { $0.evidenceItems.contains(item) }) {
                        LibraryEvidenceCard(evidence: item, belief: belief)
                    }
                }
            }
            .padding(.horizontal, Theme.screenMargin)
            .padding(.vertical, Theme.spacingM)
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? Theme.textPrimary : Theme.textSecondary)
                .padding(.horizontal, Theme.spacingS)
                .padding(.vertical, 4)
                .background(isSelected ? color.opacity(0.2) : Theme.surface)
                .cornerRadius(Theme.cornerRadiusFull)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusFull)
                        .stroke(isSelected ? color : Color.clear, lineWidth: 1)
                )
        }
    }
}

struct LibraryEvidenceCard: View {
    let evidence: Evidence
    let belief: Belief
    @State private var showingDetail = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            // Belief context
            HStack(spacing: Theme.spacingXS) {
                Image(systemName: evidence.type == .support ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(evidence.type == .support ? Theme.accentGreen : Theme.accentRed)

                Text(evidence.type == .support ? "Supporting" : "Contradicting")
                    .font(.caption2)
                    .foregroundColor(evidence.type == .support ? Theme.accentGreen : Theme.accentRed)

                Text("·")
                    .foregroundColor(Theme.textSecondary)

                Text(belief.text)
                    .font(.caption2)
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(1)

                Spacer()
            }

            // Evidence text
            Text(evidence.text)
                .font(.callout)
                .foregroundColor(Theme.textPrimary)
                .lineLimit(3)

            // Footer
            HStack {
                // Confidence
                HStack(spacing: 4) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(confidenceBarColor(for: i))
                            .frame(width: 6, height: 6)
                    }
                    Text(evidence.confidenceLabel)
                        .font(.caption2)
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()

                if let label = evidence.sourceLabel {
                    HStack(spacing: 2) {
                        Image(systemName: "link")
                            .font(.caption2)
                        Text(label)
                            .lineLimit(1)
                    }
                    .font(.caption2)
                    .foregroundColor(Theme.accentBlue)
                }

                Text(evidence.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
        .onTapGesture {
            showingDetail = true
        }
        .sheet(isPresented: $showingDetail) {
            NavigationStack {
                ZStack {
                    Theme.background.ignoresSafeArea()

                    ScrollView {
                        VStack(alignment: .leading, spacing: Theme.spacingL) {
                            // Belief header
                            HStack {
                                ScoreBadge(score: belief.score)
                                Text(belief.text)
                                    .font(.headline)
                                    .foregroundColor(Theme.textPrimary)
                            }
                            .padding(Theme.spacingM)
                            .background(Theme.surface)
                            .cornerRadius(12)

                            // Evidence
                            VStack(alignment: .leading, spacing: Theme.spacingS) {
                                HStack {
                                    Image(systemName: evidence.type.icon)
                                        .foregroundColor(evidence.type == .support ? Theme.accentGreen : Theme.accentRed)
                                    Text(evidence.type.displayName)
                                        .font(.subheadline)
                                        .foregroundColor(evidence.type == .support ? Theme.accentGreen : Theme.accentRed)
                                    Spacer()
                                    Text(evidence.createdAt.formatted(date: .long, time: .omitted))
                                        .font(.caption)
                                        .foregroundColor(Theme.textSecondary)
                                }

                                Text(evidence.text)
                                    .font(.body)
                                    .foregroundColor(Theme.textPrimary)
                            }
                            .padding(Theme.spacingM)
                            .background(Theme.surface)
                            .cornerRadius(12)

                            // Confidence
                            VStack(alignment: .leading, spacing: Theme.spacingS) {
                                Text("Confidence")
                                    .font(.subheadline)
                                    .foregroundColor(Theme.textPrimary)
                                HStack(spacing: Theme.spacingM) {
                                    ForEach(0..<10, id: \.self) { i in
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Double(i) / 10.0 <= evidence.confidence ? Theme.scoreColor(for: evidence.confidence * 100) : Theme.border)
                                            .frame(width: 20, height: 8)
                                    }
                                    Text("\(Int(evidence.confidence * 100))%")
                                        .font(.caption)
                                        .foregroundColor(Theme.textSecondary)
                                }
                                Text(evidence.confidenceLabel)
                                    .font(.caption)
                                    .foregroundColor(Theme.textSecondary)
                            }
                            .padding(Theme.spacingM)
                            .background(Theme.surface)
                            .cornerRadius(12)

                            // Source
                            if let label = evidence.sourceLabel {
                                VStack(alignment: .leading, spacing: Theme.spacingS) {
                                    Text("Source")
                                        .font(.subheadline)
                                        .foregroundColor(Theme.textPrimary)
                                    if let url = evidence.sourceURL, let parsedURL = URL(string: url) {
                                        Link(destination: parsedURL) {
                                            HStack {
                                                Image(systemName: "link")
                                                Text(label)
                                            }
                                            .font(.callout)
                                            .foregroundColor(Theme.accentBlue)
                                        }
                                    } else {
                                        HStack {
                                            Image(systemName: "link")
                                            Text(label)
                                        }
                                        .font(.callout)
                                        .foregroundColor(Theme.textSecondary)
                                    }
                                }
                                .padding(Theme.spacingM)
                                .background(Theme.surface)
                                .cornerRadius(12)
                            }

                            Spacer(minLength: Theme.spacingXL)
                        }
                        .padding(Theme.screenMargin)
                    }
                }
                .navigationTitle("Evidence Detail")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { showingDetail = false }
                    }
                }
            }
            .presentationDetents([.large])
        }
    }

    private func confidenceBarColor(for index: Int) -> Color {
        let thresholds = [0.3, 0.6, 0.9]
        let filled = evidence.confidence >= thresholds[index]
        if evidence.confidence >= 0.7 {
            return filled ? Theme.accentGreen : Theme.border
        } else if evidence.confidence >= 0.4 {
            return filled ? Theme.accentGold : Theme.border
        } else {
            return filled ? Theme.accentRed : Theme.border
        }
    }
}

#Preview {
    EvidenceLibraryView()
        .environmentObject(DatabaseService.shared)
        .preferredColorScheme(.dark)
}
