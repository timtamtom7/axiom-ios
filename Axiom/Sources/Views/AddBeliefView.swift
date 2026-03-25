import SwiftUI

struct AddBeliefView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var beliefText = ""
    @State private var isCore = false
    @State private var rootCause = ""
    @State private var selectedRootCause: RootCauseOption = .none
    @State private var showAdvanced = false

    let onSave: (String, Bool, String?) -> Void

    enum RootCauseOption: String, CaseIterable {
        case none = "Not sure"
        case childhood = "Childhood experience"
        case trauma = "Trauma or loss"
        case cultural = "Cultural or societal"
        case relationships = "Relationship patterns"
        case failure = "Failure or rejection"
        case comparison = "Comparison to others"

        var emoji: String {
            switch self {
            case .none: return "?"
            case .childhood: return "👶"
            case .trauma: return "⚡"
            case .cultural: return "🌍"
            case .relationships: return "💔"
            case .failure: return "📉"
            case .comparison: return "↔️"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.spacingL) {
                        // Belief text
                        VStack(alignment: .leading, spacing: Theme.spacingS) {
                            Text("What do you believe about yourself?")
                                .font(.headline)
                                .foregroundColor(Theme.textPrimary)

                            Text("Write it as a statement: \"I am...\" or \"I can't...\"")
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                        }

                        TextField("I am bad at relationships", text: $beliefText, axis: .vertical)
                            .textFieldStyle(.plain)
                            .font(.body)
                            .foregroundColor(Theme.textPrimary)
                            .padding(Theme.spacingM)
                            .background(Theme.surface)
                            .cornerRadius(12)
                            .lineLimit(3...6)

                        // Core belief toggle
                        VStack(alignment: .leading, spacing: Theme.spacingS) {
                            Toggle(isOn: $isCore) {
                                HStack {
                                    Image(systemName: "diamond.fill")
                                        .foregroundColor(Theme.accentGold)
                                    Text("This is a core belief")
                                        .font(.subheadline)
                                        .foregroundColor(Theme.textPrimary)
                                }
                            }
                            .toggleStyle(SwitchToggleStyle(tint: Theme.accentGold))
                            .padding(Theme.spacingM)
                            .background(Theme.surface)
                            .cornerRadius(12)

                            if isCore {
                                Text("Core beliefs are foundational — they shape many other beliefs. Identifying them is powerful.")
                                    .font(.caption)
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }

                        // Root cause
                        VStack(alignment: .leading, spacing: Theme.spacingS) {
                            Button {
                                withAnimation { showAdvanced.toggle() }
                            } label: {
                                HStack {
                                    Text("Where does this belief come from?")
                                        .font(.subheadline)
                                        .foregroundColor(Theme.textSecondary)
                                    Spacer()
                                    Image(systemName: showAdvanced ? "chevron.up" : "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(Theme.textSecondary)
                                }
                            }

                            if showAdvanced {
                                ForEach(RootCauseOption.allCases, id: \.self) { option in
                                    Button {
                                        selectedRootCause = option
                                        rootCause = option.rawValue
                                    } label: {
                                        HStack {
                                            Text(option.emoji)
                                            Text(option.rawValue)
                                                .font(.subheadline)
                                                .foregroundColor(Theme.textPrimary)
                                            Spacer()
                                            if selectedRootCause == option {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(Theme.accentBlue)
                                            }
                                        }
                                        .padding(.vertical, Theme.spacingS)
                                    }
                                }
                                .padding(.top, Theme.spacingXS)
                            }
                        }

                        Spacer(minLength: Theme.spacingXL)
                    }
                    .padding(Theme.screenMargin)
                }
            }
            .navigationTitle("New Belief")
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
                        let cause = selectedRootCause == .none ? nil : rootCause
                        onSave(beliefText, isCore, cause)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(beliefText.trimmingCharacters(in: .whitespacesAndNewlines).count < 5)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    AddBeliefView { text, isCore, rootCause in
        print("Saved: \(text), core: \(isCore), root: \(rootCause ?? "none")")
    }
    .preferredColorScheme(.dark)
}
