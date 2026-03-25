import SwiftUI

struct AddEvidenceView: View {
    @Environment(\.dismiss) private var dismiss
    let beliefId: UUID
    let onSave: (String, EvidenceType, Double, String?, String?) -> Void

    @State private var evidenceText = ""
    @State private var selectedType: EvidenceType = .support
    @State private var confidence: Double = 0.7
    @State private var sourceURL = ""
    @State private var sourceLabel = ""
    @State private var showAdvanced = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.spacingL) {
                        typePickerSection
                        textSection
                        confidenceSection
                        sourceToggle
                        if showAdvanced {
                            sourceFieldsSection
                        }
                        Spacer(minLength: Theme.spacingXL)
                    }
                    .padding(Theme.screenMargin)
                }
            }
            .navigationTitle("Add Evidence")
#if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveEvidence() }
                        .fontWeight(.semibold)
                        .disabled(evidenceText.trimmingCharacters(in: .whitespacesAndNewlines).count < 5)
                }
            }
        }
#if os(iOS)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
#endif
    }

    private var typePickerSection: some View {
        HStack(spacing: Theme.spacingM) {
            ForEach(EvidenceType.allCases, id: \.self) { type in
                typeButton(for: type)
            }
        }
    }

    private func typeButton(for type: EvidenceType) -> some View {
        Button {
            selectedType = type
        } label: {
            HStack {
                Image(systemName: type.icon)
                Text(type.displayName)
                    .font(.subheadline)
            }
            .padding(.horizontal, Theme.spacingM)
            .padding(.vertical, Theme.spacingS)
            .background(typeBackground(for: type))
            .foregroundColor(typeForeground(for: type))
            .cornerRadius(8)
            .overlay(typeOverlay(for: type))
        }
    }

    private func typeBackground(for type: EvidenceType) -> Color {
        selectedType == type
            ? (type == .support ? Theme.accentGreen : Theme.accentRed).opacity(0.2)
            : Theme.surface
    }

    private func typeForeground(for type: EvidenceType) -> Color {
        selectedType == type
            ? (type == .support ? Theme.accentGreen : Theme.accentRed)
            : Theme.textSecondary
    }

    private func typeOverlay(for type: EvidenceType) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(
                selectedType == type
                    ? (type == .support ? Theme.accentGreen : Theme.accentRed)
                    : Color.clear,
                lineWidth: 1
            )
    }

    private var textSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            Text("Describe a specific example or piece of evidence")
                .font(.caption)
                .foregroundColor(Theme.textSecondary)

            TextField("What specific event or fact supports this?", text: $evidenceText, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.body)
                .foregroundColor(Theme.textPrimary)
                .padding(Theme.spacingM)
                .background(Theme.surface)
                .cornerRadius(12)
                .lineLimit(4...8)
        }
    }

    private var confidenceSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            HStack {
                Text("Confidence")
                    .font(.subheadline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text(confidenceLabel)
                    .font(.caption)
                    .foregroundColor(confidenceColor)
            }

            HStack(spacing: Theme.spacingM) {
                Text("Low")
                    .font(.caption2)
                    .foregroundColor(Theme.textSecondary)
                Slider(value: $confidence, in: 0.1...1.0, step: 0.1)
                    .tint(confidenceColor)
                Text("High")
                    .font(.caption2)
                    .foregroundColor(Theme.textSecondary)
            }

            HStack(spacing: Theme.spacingXS) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(barColor(for: i))
                        .frame(height: 4)
                        .cornerRadius(2)
                }
                Text("How certain are you about this evidence?")
                    .font(.caption2)
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private var sourceToggle: some View {
        Button {
            withAnimation { showAdvanced.toggle() }
        } label: {
            HStack {
                Image(systemName: "link")
                    .foregroundColor(Theme.accentBlue)
                Text("Add source or reference")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                Image(systemName: showAdvanced ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
        }
    }

    private var sourceFieldsSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            VStack(alignment: .leading, spacing: Theme.spacingXS) {
                Text("Source label (optional)")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                TextField("e.g. Book: Thinking Fast and Slow", text: $sourceLabel)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .foregroundColor(Theme.textPrimary)
                    .padding(Theme.spacingS)
                    .background(Theme.surface)
                    .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: Theme.spacingXS) {
                Text("URL (optional)")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                TextField("https://...", text: $sourceURL)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .foregroundColor(Theme.textPrimary)
#if os(iOS)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
#endif
                    .padding(Theme.spacingS)
                    .background(Theme.surface)
                    .cornerRadius(8)
            }
        }
        .padding(.top, Theme.spacingS)
    }

    private var confidenceLabel: String {
        if confidence >= 0.8 { return "High — I'm very certain" }
        else if confidence >= 0.5 { return "Medium — Some uncertainty" }
        else { return "Low — I'm not very certain" }
    }

    private var confidenceColor: Color {
        if confidence >= 0.8 { return Theme.accentGreen }
        else if confidence >= 0.5 { return Theme.accentGold }
        else { return Theme.accentRed }
    }

    private func barColor(for index: Int) -> Color {
        let filled = confidence >= [0.3, 0.6, 0.9][index]
        return filled ? confidenceColor : Theme.border
    }

    private func saveEvidence() {
        let url = sourceURL.isEmpty ? nil : (URL(string: sourceURL) != nil ? sourceURL : nil)
        let label = sourceLabel.isEmpty ? nil : sourceLabel
        onSave(evidenceText, selectedType, confidence, url, label)
        dismiss()
    }
}

#Preview {
    AddEvidenceView(beliefId: UUID()) { text, type, confidence, url, label in
        print("Saved: \(text), type: \(type), confidence: \(confidence)")
    }
    .preferredColorScheme(.dark)
}
