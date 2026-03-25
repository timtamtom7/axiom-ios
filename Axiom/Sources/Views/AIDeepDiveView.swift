import SwiftUI

/// Interactive back-and-forth dialogue with AI about a belief.
/// User can respond to AI questions and ask their own questions.
struct AIDeepDiveView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var aiService = AIStressTestService()
    let belief: Belief
    @State private var userInput = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    if !aiService.isInDeepDive && aiService.conversationMessages.isEmpty {
                        // Opening state
                        openingView
                    } else {
                        // Conversation
                        conversationView
                    }
                }
            }
            .navigationTitle("AI Deep Dive")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        aiService.endDeepDive()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            aiService.startDeepDive(for: belief)
        }
    }

    private var openingView: some View {
        VStack(spacing: Theme.spacingL) {
            Spacer()
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 48))
                .foregroundColor(Theme.accentBlue)

            Text("AI Deep Dive")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Theme.textPrimary)

            Text("A real conversation about this belief. Ask questions, explore feelings, challenge assumptions. I'll push back and dig deeper.")
                .font(.callout)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                aiService.startDeepDive(for: belief)
            } label: {
                Text("Begin Conversation")
                    .font(.headline)
                    .foregroundColor(Theme.background)
                    .padding(.horizontal, Theme.spacingXL)
                    .padding(.vertical, Theme.spacingM)
                    .background(Theme.accentBlue)
                    .cornerRadius(12)
            }

            Spacer()
        }
        .padding(Theme.screenMargin)
    }

    private var conversationView: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: Theme.spacingM) {
                        ForEach(aiService.conversationMessages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }

                        if aiService.isLoading {
                            HStack {
                                ProgressView()
                                    .tint(Theme.accentBlue)
                                Text("Thinking...")
                                    .font(.caption)
                                    .foregroundColor(Theme.textSecondary)
                            }
                            .padding(Theme.spacingM)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(Theme.screenMargin)
                }
                .onChange(of: aiService.conversationMessages.count) { _, _ in
                    withAnimation {
                        proxy.scrollTo(aiService.conversationMessages.last?.id, anchor: .bottom)
                    }
                }
            }

            Divider()
                .background(Theme.border)

            // Input area
            HStack(spacing: Theme.spacingM) {
                TextField("Ask or respond...", text: $userInput, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.callout)
                    .foregroundColor(Theme.textPrimary)
                    .padding(Theme.spacingS)
                    .background(Theme.surface)
                    .cornerRadius(20)
                    .lineLimit(1...4)
                    .focused($isInputFocused)

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(
                            userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? Theme.textSecondary
                                : Theme.accentBlue
                        )
                }
                .disabled(userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(Theme.spacingM)
            .background(Theme.surface)
        }
    }

    private func sendMessage() {
        let text = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        userInput = ""
        aiService.sendUserMessage(text, belief: belief)
    }
}

struct MessageBubble: View {
    let message: AIStressTestService.ConversationMessage

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: Theme.spacingXS) {
                HStack(spacing: Theme.spacingXS) {
                    if !isUser {
                        Image(systemName: "brain")
                            .font(.caption2)
                            .foregroundColor(Theme.accentBlue)
                    }
                    Text(isUser ? "You" : "Axiom")
                        .font(.caption2)
                        .foregroundColor(Theme.textSecondary)
                }

                Text(message.text)
                    .font(.callout)
                    .foregroundColor(isUser ? Theme.textPrimary : Theme.textPrimary)
                    .padding(.horizontal, Theme.spacingM)
                    .padding(.vertical, Theme.spacingS)
                    .background(isUser ? Theme.surfaceElevated : Theme.surface)
                    .cornerRadius(16)
            }

            if !isUser { Spacer(minLength: 60) }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }
}

#Preview {
    AIDeepDiveView(belief: .preview)
        .preferredColorScheme(.dark)
}
