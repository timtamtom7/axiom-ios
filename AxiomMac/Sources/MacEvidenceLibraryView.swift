import SwiftUI

/// macOS evidence library with search, filter, and submit functionality.
struct MacEvidenceLibraryView: View {
    @EnvironmentObject var databaseService: DatabaseService
    @State private var searchText = ""
    @State private var filterType: EvidenceType? = nil
    @State private var sortOrder: MacEvidenceSortOrder = .newest
    @State private var showingSubmitSheet = false
    @State private var selectedEvidence: Evidence?

    enum MacEvidenceSortOrder: String, CaseIterable {
        case newest = "Newest First"
        case oldest = "Oldest First"
        case belief = "By Belief"
        case rating = "By Rating"
    }

    var body: some View {
        NavigationSplitView {
            sidebarView
                .frame(minWidth: 280, idealWidth: 320)
                .background(Theme.surface)
        } detail: {
            detailView
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingSubmitSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .help("Submit evidence")
            }
        }
        .sheet(isPresented: $showingSubmitSheet) {
            MacSubmitEvidenceSheet()
        }
        .sheet(item: $selectedEvidence) { evidence in
            MacEvidenceDetailSheet(evidence: evidence)
        }
    }

    private var sidebarView: some View {
        VStack(spacing: 0) {
            searchBar
            Divider()
            filterSection
            Divider()
            evidenceList
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Theme.textSecondary)
            TextField("Search evidence...", text: $searchText)
                .font(.subheadline)
                .foregroundColor(Theme.textPrimary)
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
        .padding(Theme.spacingS)
        .background(Theme.surfaceElevated)
        .cornerRadius(8)
        .padding(Theme.screenMargin)
    }

    private var filterSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            HStack(spacing: Theme.spacingXS) {
                FilterToggle(title: "All", isSelected: filterType == nil) { filterType = nil }
                FilterToggle(title: "Supporting", isSelected: filterType == .support, color: Theme.accentGreen) { filterType = .support }
                FilterToggle(title: "Contradicting", isSelected: filterType == .contradict, color: Theme.accentRed) { filterType = .contradict }
            }
            HStack {
                Text("Sort:")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                Picker("Sort", selection: $sortOrder) {
                    ForEach(MacEvidenceSortOrder.allCases, id: \.self) { order in Text(order.rawValue).tag(order) }
                }
                .pickerStyle(.menu)
                .font(.caption)
            }
        }
        .padding(Theme.screenMargin)
    }

    private var evidenceList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.spacingS) {
                ForEach(filteredEvidence) { item in
                    MacLibraryEvidenceRow(evidence: item)
                        .onTapGesture { selectedEvidence = item }
                }
                if filteredEvidence.isEmpty {
                    VStack(spacing: Theme.spacingM) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(Theme.textSecondary.opacity(0.5))
                        Text("No evidence found")
                            .font(.headline)
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(.vertical, Theme.spacingXL)
                }
            }
            .padding(Theme.screenMargin)
        }
        .accessibilityLabel("Evidence library. \(filteredEvidence.count) items. \(filterType == nil ? "Showing all evidence" : (filterType == .support ? "Showing supporting evidence" : "Showing contradicting evidence")).")
    }

    @ViewBuilder
    private var detailView: some View {
        if let evidence = selectedEvidence,
           let belief = databaseService.allBeliefs.first(where: { $0.evidenceItems.contains(evidence) }) {
            MacEvidenceDetailView(evidence: evidence, belief: belief)
        } else {
            placeholderView
        }
    }

    private var placeholderView: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: Theme.spacingL) {
                Image(systemName: "books.vertical")
                    .font(.system(size: 64))
                    .foregroundColor(Theme.textSecondary.opacity(0.3))
                Text("Select evidence to view details")
                    .font(.title3)
                    .foregroundColor(Theme.textSecondary)
            }
        }
    }

    private var filteredEvidence: [Evidence] {
        var items = databaseService.allBeliefs.flatMap { $0.evidenceItems }
        if let filterType = filterType {
            items = items.filter { $0.type == filterType }
        }
        if !searchText.isEmpty {
            items = items.filter { item in
                let matchesText = item.text.localizedCaseInsensitiveContains(searchText)
                let matchesBelief = databaseService.allBeliefs.contains { b in
                    b.evidenceItems.contains(where: { $0.id == item.id }) &&
                    b.text.localizedCaseInsensitiveContains(searchText)
                }
                return matchesText || matchesBelief
            }
        }
        switch sortOrder {
        case .newest: items.sort { $0.createdAt > $1.createdAt }
        case .oldest: items.sort { $0.createdAt < $1.createdAt }
        case .belief:
            items.sort { ev1, ev2 in
                let b1 = databaseService.allBeliefs.first { $0.evidenceItems.contains(ev1) }?.text ?? ""
                let b2 = databaseService.allBeliefs.first { $0.evidenceItems.contains(ev2) }?.text ?? ""
                return b1 < b2
            }
        case .rating: items.sort { $0.confidence > $1.confidence }
        }
        return items
    }
}

// MARK: - FilterToggle

struct FilterToggle: View {
    let title: String
    let isSelected: Bool
    var color: Color = Theme.textSecondary
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? Theme.textPrimary : Theme.textSecondary)
                .padding(.horizontal, Theme.spacingS)
                .padding(.vertical, Theme.spacingXS)
                .background(isSelected ? color.opacity(0.2) : Theme.surfaceElevated)
                .cornerRadius(Theme.cornerRadiusPill)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusPill)
                        .stroke(isSelected ? color : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}

// MARK: - MacLibraryEvidenceRow

struct MacLibraryEvidenceRow: View {
    let evidence: Evidence
    @EnvironmentObject var databaseService: DatabaseService

    private var belief: Belief? {
        databaseService.allBeliefs.first { $0.evidenceItems.contains(evidence) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingXS) {
            HStack {
                Image(systemName: evidence.type == .support ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(evidence.type == .support ? Theme.accentGreen : Theme.accentRed)
                Text(evidence.type == .support ? "Supporting" : "Contradicting")
                    .font(.caption2)
                    .foregroundColor(evidence.type == .support ? Theme.accentGreen : Theme.accentRed)
                if let belief = belief {
                    Text("·")
                        .foregroundColor(Theme.textSecondary)
                    Text(belief.text)
                        .font(.caption2)
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(1)
                }
                Spacer()
                StarRatingView(rating: confidenceToStars(evidence.confidence))
            }
            Text(evidence.text)
                .font(.callout)
                .foregroundColor(Theme.textPrimary)
                .lineLimit(2)
            HStack {
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
                Spacer()
                Text(evidence.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(Theme.spacingS)
        .background(Theme.surface)
        .cornerRadius(8)
    }

    private func confidenceToStars(_ confidence: Double) -> Int {
        if confidence >= 0.8 { return 5 }
        else if confidence >= 0.6 { return 4 }
        else if confidence >= 0.4 { return 3 }
        else if confidence >= 0.2 { return 2 }
        else { return 1 }
    }
}

// MARK: - StarRatingView

struct StarRatingView: View {
    let rating: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1..<6, id: \.self) { i in
                Image(systemName: i <= rating ? "star.fill" : "star")
                    .font(.system(size: 8))
                    .foregroundColor(i <= rating ? Theme.accentGold : Theme.border)
            }
        }
    }
}

// MARK: - MacEvidenceDetailView

struct MacEvidenceDetailView: View {
    let evidence: Evidence
    let belief: Belief
    @EnvironmentObject var databaseService: DatabaseService

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spacingL) {
                VStack(alignment: .leading, spacing: Theme.spacingS) {
                    Text("BELIEF")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.textSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.surface)
                        .cornerRadius(4)
                    HStack {
                        ScoreBadge(score: belief.score)
                        Text(belief.text)
                            .font(.headline)
                            .foregroundColor(Theme.textPrimary)
                    }
                }
                .padding(Theme.spacingM)
                .background(Theme.surface)
                .cornerRadius(12)

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
                        .textSelection(.enabled)
                }
                .padding(Theme.spacingM)
                .background(Theme.surface)
                .cornerRadius(12)

                VStack(alignment: .leading, spacing: Theme.spacingS) {
                    Text("Confidence")
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)
                    HStack(spacing: Theme.spacingM) {
                        StarRatingView(rating: confidenceToStars(evidence.confidence))
                        Text("\(Int(evidence.confidence * 100))%")
                            .font(.system(.callout, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(Theme.scoreColor(for: evidence.confidence * 100))
                    }
                    HStack(spacing: Theme.spacingXS) {
                        ForEach(0..<10, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Double(i) / 10.0 <= evidence.confidence ? Theme.scoreColor(for: evidence.confidence * 100) : Theme.border)
                                .frame(width: 24, height: 8)
                        }
                    }
                    Text(evidence.confidenceLabel)
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(Theme.spacingM)
                .background(Theme.surface)
                .cornerRadius(12)

                if let label = evidence.sourceLabel {
                    VStack(alignment: .leading, spacing: Theme.spacingS) {
                        Text("Source")
                            .font(.headline)
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
            }
            .padding(Theme.screenMargin)
        }
        .background(Theme.background)
        .navigationTitle("Evidence")
    }

    private func confidenceToStars(_ confidence: Double) -> Int {
        if confidence >= 0.8 { return 5 }
        else if confidence >= 0.6 { return 4 }
        else if confidence >= 0.4 { return 3 }
        else if confidence >= 0.2 { return 2 }
        else { return 1 }
    }
}

// MARK: - MacEvidenceDetailSheet

struct MacEvidenceDetailSheet: View {
    let evidence: Evidence
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var databaseService: DatabaseService

    private var belief: Belief? {
        databaseService.allBeliefs.first { $0.evidenceItems.contains(evidence) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                if let belief = belief {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Theme.spacingL) {
                            VStack(alignment: .leading, spacing: Theme.spacingS) {
                                Text("BELIEF")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(Theme.textSecondary)
                                HStack {
                                    ScoreBadge(score: belief.score)
                                    Text(belief.text)
                                        .font(.headline)
                                        .foregroundColor(Theme.textPrimary)
                                }
                            }
                            .padding(Theme.spacingM)
                            .background(Theme.surface)
                            .cornerRadius(12)

                            VStack(alignment: .leading, spacing: Theme.spacingS) {
                                HStack {
                                    Image(systemName: evidence.type.icon)
                                        .foregroundColor(evidence.type == .support ? Theme.accentGreen : Theme.accentRed)
                                    Text(evidence.type.displayName)
                                        .foregroundColor(evidence.type == .support ? Theme.accentGreen : Theme.accentRed)
                                    Spacer()
                                    Text(evidence.createdAt.formatted(date: .long, time: .omitted))
                                        .font(.caption)
                                        .foregroundColor(Theme.textSecondary)
                                }
                                Text(evidence.text)
                                    .font(.body)
                                    .foregroundColor(Theme.textPrimary)
                                    .textSelection(.enabled)
                            }
                            .padding(Theme.spacingM)
                            .background(Theme.surface)
                            .cornerRadius(12)

                            if let label = evidence.sourceLabel {
                                VStack(alignment: .leading, spacing: Theme.spacingS) {
                                    Text("Source")
                                        .font(.subheadline)
                                        .foregroundColor(Theme.textSecondary)
                                    if let url = evidence.sourceURL, let parsedURL = URL(string: url) {
                                        Link(destination: parsedURL) {
                                            HStack {
                                                Image(systemName: "link")
                                                Text(label)
                                            }
                                            .foregroundColor(Theme.accentBlue)
                                        }
                                    } else {
                                        HStack {
                                            Image(systemName: "link")
                                            Text(label)
                                        }
                                        .foregroundColor(Theme.textSecondary)
                                    }
                                }
                                .padding(Theme.spacingM)
                                .background(Theme.surface)
                                .cornerRadius(12)
                            }
                        }
                        .padding(Theme.screenMargin)
                    }
                }
            }
            .navigationTitle("Evidence Detail")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - MacSubmitEvidenceSheet

struct MacSubmitEvidenceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var databaseService: DatabaseService
    @State private var selectedBelief: Belief?
    @State private var evidenceText = ""
    @State private var selectedType: EvidenceType = .support
    @State private var confidence: Double = 0.7
    @State private var sourceURL = ""
    @State private var sourceLabel = ""
    @State private var showingSuccess = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.spacingL) {
                        // Belief picker
                        VStack(alignment: .leading, spacing: Theme.spacingXS) {
                            Text("Belief")
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                            Menu {
                                beliefMenuContent
                            } label: {
                                HStack {
                                    if let belief = selectedBelief {
                                        Text(belief.text)
                                            .foregroundColor(Theme.textPrimary)
                                    } else {
                                        Text("Select a belief...")
                                            .foregroundColor(Theme.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(Theme.textSecondary)
                                }
                                .padding(Theme.spacingS)
                                .background(Theme.surface)
                                .cornerRadius(8)
                            }
                        }

                        // Evidence text
                        VStack(alignment: .leading, spacing: Theme.spacingXS) {
                            Text("Evidence")
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                            TextField("Describe the evidence...", text: $evidenceText, axis: .vertical)
                                .textFieldStyle(.plain)
                                .font(.body)
                                .foregroundColor(Theme.textPrimary)
                                .padding(Theme.spacingS)
                                .background(Theme.surface)
                                .cornerRadius(8)
                                .lineLimit(3...6)
                        }

                        // Type
                        VStack(alignment: .leading, spacing: Theme.spacingXS) {
                            Text("Type")
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                            HStack(spacing: Theme.spacingS) {
                                EvidenceTypeButton(type: .support, isSelected: selectedType == .support) { selectedType = .support }
                                EvidenceTypeButton(type: .contradict, isSelected: selectedType == .contradict) { selectedType = .contradict }
                            }
                        }

                        // Confidence
                        VStack(alignment: .leading, spacing: Theme.spacingXS) {
                            HStack {
                                Text("Confidence")
                                    .font(.caption)
                                    .foregroundColor(Theme.textSecondary)
                                Spacer()
                                Text("\(Int(confidence * 100))%")
                                    .font(.system(.caption, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundColor(Theme.scoreColor(for: confidence * 100))
                            }
                            Slider(value: $confidence, in: 0...1, step: 0.1)
                                .tint(Theme.scoreColor(for: confidence * 100))
                                .accessibilityLabel("Belief strength, \(Int(confidence * 100)) percent. Drag left or right to adjust.")
                        }

                        // Source
                        VStack(alignment: .leading, spacing: Theme.spacingXS) {
                            Text("Source (optional)")
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                            TextField("Source label", text: $sourceLabel)
                                .textFieldStyle(.plain)
                                .font(.body)
                                .foregroundColor(Theme.textPrimary)
                                .padding(Theme.spacingS)
                                .background(Theme.surface)
                                .cornerRadius(8)
                            TextField("URL", text: $sourceURL)
                                .textFieldStyle(.plain)
                                .font(.body)
                                .foregroundColor(Theme.textPrimary)
                                .padding(Theme.spacingS)
                                .background(Theme.surface)
                                .cornerRadius(8)
                        }

                        if showingSuccess {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Theme.accentGreen)
                                Text("Evidence submitted!")
                                    .font(.subheadline)
                                    .foregroundColor(Theme.accentGreen)
                            }
                            .padding(Theme.spacingM)
                            .frame(maxWidth: .infinity)
                            .background(Theme.accentGreen.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding(Theme.screenMargin)
                }
            }
            .navigationTitle("Submit Evidence")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") { submitEvidence() }
                        .fontWeight(.semibold)
                        .disabled(selectedBelief == nil || evidenceText.trimmingCharacters(in: .whitespacesAndNewlines).count < 5)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func submitEvidence() {
        guard let belief = selectedBelief else { return }
        let evidence = Evidence(
            beliefId: belief.id,
            text: evidenceText,
            type: selectedType,
            confidence: confidence,
            sourceURL: sourceURL.isEmpty ? nil : sourceURL,
            sourceLabel: sourceLabel.isEmpty ? nil : sourceLabel
        )
        databaseService.addEvidence(evidence)
        withAnimation(accessibilityReduceMotion ? .none : .default) { showingSuccess = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
    }

    @ViewBuilder
    private var beliefMenuContent: some View {
        let beliefs = databaseService.allBeliefs.filter { !$0.isArchived }
        ForEach(beliefs) { belief in
            Button {
                selectedBelief = belief
            } label: {
                HStack {
                    Text(belief.text)
                    if selectedBelief?.id == belief.id {
                        Image(systemName: "checkmark")
                    }
                }
            }
        }
    }
}

struct EvidenceTypeButton: View {
    let type: EvidenceType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: type.icon)
                Text(type.displayName)
            }
            .font(.subheadline)
            .foregroundColor(isSelected ? Theme.textPrimary : Theme.textSecondary)
            .padding(.horizontal, Theme.spacingM)
            .padding(.vertical, Theme.spacingS)
            .background(isSelected ? (type == .support ? Theme.accentGreen : Theme.accentRed).opacity(0.2) : Theme.surface)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? (type == .support ? Theme.accentGreen : Theme.accentRed) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(type == .support ? "Add supporting evidence" : "Add contradicting evidence")
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}

#Preview {
    MacEvidenceLibraryView()
        .environmentObject(DatabaseService.shared)
        .preferredColorScheme(.dark)
}
