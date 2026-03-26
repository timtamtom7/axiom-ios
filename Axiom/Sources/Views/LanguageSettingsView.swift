import SwiftUI

/// R13: Language settings view for internationalization
struct LanguageSettingsView: View {
    @StateObject private var localization = LocalizationService.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.spacingL) {
                        // Current language
                        currentLanguageSection

                        // Available languages
                        languagesSection
                    }
                    .padding(Theme.screenMargin)
                }
            }
            .navigationTitle("Language")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var currentLanguageSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            Text("Current Language")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            HStack {
                Text(localization.currentLanguage.flag)
                    .font(.largeTitle)
                VStack(alignment: .leading) {
                    Text(localization.currentLanguage.displayName)
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)
                    Text("Selected language for app content")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Theme.accentGold)
            }
            .padding(Theme.spacingM)
            .background(Theme.surface)
            .cornerRadius(12)
        }
    }

    private var languagesSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            Text("Available Languages")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            ForEach(LocalizationService.AppLanguage.allCases) { language in
                Button {
                    withAnimation {
                        localization.setLanguage(language)
                    }
                } label: {
                    HStack {
                        Text(language.flag)
                            .font(.title2)
                        Text(language.displayName)
                            .font(.body)
                            .foregroundColor(Theme.textPrimary)
                        Spacer()
                        if language == localization.currentLanguage {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Theme.accentGold)
                        }
                    }
                    .padding(Theme.spacingM)
                    .background(language == localization.currentLanguage ? Theme.accentGold.opacity(0.1) : Theme.surface)
                    .cornerRadius(12)
                }
            }
        }
    }
}

#Preview {
    LanguageSettingsView()
}
