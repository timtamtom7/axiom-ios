import SwiftUI

struct AddEvidenceView: View {
    @Environment(\.dismiss) private var dismiss
    let beliefId: UUID
    let onSave: (String, EvidenceType) -> Void

    @State private var evidenceText = ""
    @State private var selectedType: EvidenceType = .support

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: Theme.spacingL) {
                    // Type Picker
                    HStack(spacing: Theme.spacingM) {
                        ForEach(EvidenceType.allCases, id: \.self) { type in
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
                                .background(
                                    selectedType == type
                                        ? (type == .support ? Theme.accentGreen : Theme.accentRed).opacity(0.2)
                                        : Theme.surface
                                )
                                .foregroundColor(
                                    selectedType == type
                                        ? (type == .support ? Theme.accentGreen : Theme.accentRed)
                                        : Theme.textSecondary
                                )
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            selectedType == type
                                                ? (type == .support ? Theme.accentGreen : Theme.accentRed)
                                                : Color.clear,
                                            lineWidth: 1
                                        )
                                )
                            }
                        }
                    }

                    Text("Describe a specific example or piece of evidence")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    TextField("What specific event or fact supports this?", text: $evidenceText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .foregroundColor(Theme.textPrimary)
                        .padding(Theme.spacingM)
                        .background(Theme.surface)
                        .cornerRadius(12)
                        .lineLimit(4...8)

                    Spacer()
                }
                .padding(Theme.screenMargin)
            }
            .navigationTitle("Add Evidence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(evidenceText, selectedType)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(evidenceText.trimmingCharacters(in: .whitespacesAndNewlines).count < 5)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    AddEvidenceView(beliefId: UUID()) { text, type in
        print("Saved: \(text), type: \(type)")
    }
    .preferredColorScheme(.dark)
}
