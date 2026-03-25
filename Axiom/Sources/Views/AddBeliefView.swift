import SwiftUI

struct AddBeliefView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var beliefText = ""
    let onSave: (String) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: Theme.spacingL) {
                    VStack(alignment: .leading, spacing: Theme.spacingS) {
                        Text("What do you believe about yourself?")
                            .font(.headline)
                            .foregroundColor(Theme.textPrimary)

                        Text("Write it as a statement: \"I am...\" or \"I can't...\"")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    TextField("I am bad at relationships", text: $beliefText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .foregroundColor(Theme.textPrimary)
                        .padding(Theme.spacingM)
                        .background(Theme.surface)
                        .cornerRadius(12)
                        .lineLimit(3...6)

                    Spacer()
                }
                .padding(Theme.screenMargin)
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
                        onSave(beliefText)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(beliefText.trimmingCharacters(in: .whitespacesAndNewlines).count < 5)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    AddBeliefView { text in
        print("Saved: \(text)")
    }
    .preferredColorScheme(.dark)
}
