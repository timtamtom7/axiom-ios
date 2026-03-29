import SwiftUI

struct OnboardingView: View {
    @Binding var isOnboarding: Bool
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    WelcomePage()
                        .tag(0)
                    
                    WhatIsBeliefPage()
                        .tag(1)
                    
                    HowAxiomWorksPage()
                        .tag(2)
                    
                    CoreBeliefsPage()
                        .tag(3)
                    
                    GetStartedPage(isOnboarding: $isOnboarding)
                        .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                // Page indicator + navigation
                HStack(spacing: 12) {
                    ForEach(0..<5) { index in
                        Circle()
                            .fill(index == currentPage ? Theme.accentPurple : Color.secondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                    
                    Spacer()
                    
                    if currentPage < 4 {
                        Button("Skip") {
                            currentPage = 4
                        }
                        .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
    }
}

// MARK: - Page 1: Welcome
struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundColor(Theme.accentPurple)
            
            Text("Welcome to Axiom")
                .font(.system(size: 36, weight: .bold, design: .serif))
                .foregroundColor(Theme.textPrimary)
            
            Text("Change your beliefs, change your life.")
                .font(.title3)
                .foregroundColor(Theme.textSecondary)
            
            Text("Axiom helps you examine, challenge, and strengthen the beliefs that shape your reality — using evidence-based cognitive behavioral techniques.")
                .font(.body)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
            
            Spacer()
        }
    }
}

// MARK: - Page 2: What is a belief?
struct WhatIsBeliefPage: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text("What is a belief?")
                .font(.system(size: 32, weight: .bold, design: .serif))
                .foregroundColor(Theme.textPrimary)
            
            VStack(alignment: .leading, spacing: 16) {
                BeliefExampleRow(belief: "\"I am not good enough\"", type: .negative)
                BeliefExampleRow(belief: "\"I deserve happiness\"", type: .positive)
                BeliefExampleRow(belief: "\"Other people can't be trusted\"", type: .negative)
            }
            .padding(.horizontal, 48)
            
            Text("A belief is a thought you hold about yourself, others, or the world. Some help you. Some hold you back.")
                .font(.body)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
            
            Spacer()
        }
    }
}

struct BeliefExampleRow: View {
    let belief: String
    let type: BeliefType
    
    enum BeliefType { case positive, negative }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type == .positive ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(type == .positive ? .green : .red)
            Text(belief)
                .italic()
                .foregroundColor(Theme.textPrimary)
            Spacer()
        }
        .font(.body)
    }
}

// MARK: - Page 3: How Axiom Works
struct HowAxiomWorksPage: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("How Axiom Works")
                .font(.system(size: 32, weight: .bold, design: .serif))
                .foregroundColor(Theme.textPrimary)
            
            VStack(spacing: 20) {
                StepRow(number: 1, title: "Add a belief", description: "Write down a belief you're curious about")
                StepRow(number: 2, title: "Add evidence", description: "List times this belief was true or false")
                StepRow(number: 3, title: "Get challenged", description: "AI finds your belief's weakest points")
                StepRow(number: 4, title: "Watch it shift", description: "Your score changes as you build clarity")
            }
            .padding(.horizontal, 64)
            
            Spacer()
        }
    }
}

struct StepRow: View {
    let number: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Theme.accentPurple.opacity(0.2))
                    .frame(width: 40, height: 40)
                Text("\(number)")
                    .font(.headline)
                    .foregroundColor(Theme.accentPurple)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Text(description)
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Page 4: Core Beliefs
struct CoreBeliefsPage: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "heart.fill")
                .font(.system(size: 60))
                .foregroundColor(.pink)
            
            Text("Start with what's core")
                .font(.system(size: 32, weight: .bold, design: .serif))
                .foregroundColor(Theme.textPrimary)
            
            Text("Core beliefs are the foundation of how you see yourself. They affect everything — relationships, work, self-worth.")
                .font(.body)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
            
            VStack(alignment: .leading, spacing: 12) {
                CoreBeliefSuggestion("I am not good enough")
                CoreBeliefSuggestion("I can't trust people")
                CoreBeliefSuggestion("I don't deserve love")
                CoreBeliefSuggestion("I must be perfect to be valued")
            }
            .padding(.horizontal, 64)
            
            Spacer()
        }
    }
}

struct CoreBeliefSuggestion: View {
    let text: String
    var body: some View {
        HStack {
            Image(systemName: "quote.opening")
                .foregroundColor(Theme.textSecondary)
            Text(text)
                .italic()
                .foregroundColor(Theme.textPrimary)
            Spacer()
        }
    }
}

// MARK: - Page 5: Get Started
struct GetStartedPage: View {
    @Binding var isOnboarding: Bool
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("You're ready")
                .font(.system(size: 36, weight: .bold, design: .serif))
                .foregroundColor(Theme.textPrimary)
            
            Text("Add your first belief and start examining what's really true.")
                .font(.body)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
            
            Spacer()
            
            Button {
                isOnboarding = false
            } label: {
                Text("Start Axiom")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.accentPurple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 48)
            .padding(.bottom, 48)
        }
    }
}
