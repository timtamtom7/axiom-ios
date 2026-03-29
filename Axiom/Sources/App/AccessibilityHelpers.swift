import SwiftUI
import UIKit

/// R9: Accessibility helpers for iOS
/// Provides VoiceOver, Dynamic Type, and Reduce Motion support

extension EnvironmentValues {
    /// Reduce Motion preference for the environment
    var prefersReducedMotion: Bool {
        // On iOS, UIAccessibility.isReduceMotionEnabled is the source of truth
        UIAccessibility.isReduceMotionEnabled
    }
}

/// Global accessibility Reduce Motion state
var accessibilityReduceMotion: Bool {
    UIAccessibility.isReduceMotionEnabled
}

/// Global VoiceOver state
var isVoiceOverRunning: Bool {
    UIAccessibility.isVoiceOverRunning
}

// MARK: - VoiceOver Accessibility View Modifier

struct AccessibleView<Content: View>: View {
    let label: String
    let hint: String?
    let traits: AccessibilityTraits
    @ViewBuilder let content: () -> Content

    init(
        label: String,
        hint: String? = nil,
        traits: AccessibilityTraits = [],
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.label = label
        self.hint = hint
        self.traits = traits
        self.content = content
    }

    var body: some View {
        content()
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
    }
}

// MARK: - Accessible Button Style

struct AccessibleButtonStyle: ButtonStyle {
    let label: String
    let hint: String?

    init(label: String, hint: String? = nil) {
        self.label = label
        self.hint = hint
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(configuration.isPressed ? .easeOut(duration: 0.1) : .default, value: configuration.isPressed)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
    }
}

// MARK: - Dynamic Type Modifier

struct ScaledFont: ViewModifier {
    @Environment(\.sizeCategory) var sizeCategory
    let size: CGFloat
    let weight: Font.Weight
    let design: Font.Design

    func body(content: Content) -> some View {
        content
            .font(.system(size: scaledSize, weight: weight, design: design))
    }

    private var scaledSize: CGFloat {
        let scale = UIFontMetrics.default.scaledValue(for: size)
        return scale
    }
}

extension View {
    func scaledFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        modifier(ScaledFont(size: size, weight: weight, design: design))
    }
}

// MARK: - Reduce Motion Modifier

struct ReduceMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    let animation: Animation?
    let reducedAnimation: Animation?

    func body(content: Content) -> some View {
        content
            .animation(reduceMotion ? (reducedAnimation ?? .none) : (animation ?? .default), value: reduceMotion)
    }
}

extension View {
    func withReducedMotion(animation: Animation? = .default, reducedAnimation: Animation? = .easeInOut(duration: 0.15)) -> some View {
        modifier(ReduceMotionModifier(animation: animation, reducedAnimation: reducedAnimation))
    }
}

// MARK: - Accessible Belief Card

struct AccessibleBeliefCard<Content: View>: View {
    let belief: Belief
    let onTap: () -> Void
    @ViewBuilder let trailing: () -> Content

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(belief.text)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: Theme.spacingM) {
                        Label("\(belief.supportingCount) supporting", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(Theme.accentGreen)

                        Label("\(belief.contradictingCount) contradicting", systemImage: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(Theme.accentRed)
                    }
                }

                Spacer()

                ScoreBadge(score: belief.score)

                trailing()
            }
            .padding(Theme.spacingM)
            .background(Theme.surface)
            .cornerRadius(Theme.cornerRadiusL)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to view belief details")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            onTap()
        }
    }

    private var accessibilityLabel: String {
        "\(belief.text). Score \(Int(belief.score)) out of 100. \(belief.supportingCount) supporting evidence, \(belief.contradictingCount) contradicting evidence."
    }
}

// MARK: - Accessible Score Badge

struct AccessibleScoreBadge: View {
    let score: Double

    var body: some View {
        ScoreBadge(score: score)
            .accessibilityLabel("Belief strength score: \(Int(score)) out of 100. \(scoreDescription)")
    }

    private var scoreDescription: String {
        if score < 40 {
            return "weak"
        } else if score < 70 {
            return "moderate"
        } else {
            return "strong"
        }
    }
}

// MARK: - Accessible Loading Indicator

struct AccessibleProgressView: View {
    let message: String

    var body: some View {
        HStack(spacing: Theme.spacingM) {
            ProgressView()
            Text(message)
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

// MARK: - Announce for Screen Readers

func announceForVoiceOver(_ message: String, delay: Double = 0.3) {
    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }
}

func announcePageForVoiceOver(_ pageName: String) {
    UIAccessibility.post(notification: .screenChanged, argument: "Navigated to \(pageName)")
}

// MARK: - Dynamic Type Scaling

extension Font {
    /// Returns a scaled version of the font that respects Dynamic Type settings
    static func scaled(_ style: Font.TextStyle, size: CGFloat? = nil, weight: Font.Weight = .regular) -> Font {
        if let size = size {
            return .system(size: size, weight: weight)
        }
        return .system(style)
    }
}

// MARK: - Safe Area Insets for notch

struct SafeAreaInsetsKey: EnvironmentKey {
    static var defaultValue: EdgeInsets {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first { ($0 as? UIWindowScene)?.windows.contains { $0.isKeyWindow } == true } as? UIWindowScene
        let window = windowScene?.windows.first { $0.isKeyWindow }
        return window?.safeAreaInsets.insets ?? EdgeInsets()
    }
}

extension UIEdgeInsets {
    var insets: EdgeInsets {
        EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
    }
}

// MARK: - Reduce Motion Animation

extension Animation {
    /// An animation that respects the reduce motion accessibility setting
    static func accessibleSpring(response: Double = 0.3, dampingFraction: Double = 0.7) -> Animation {
        .spring(response: response, dampingFraction: dampingFraction)
    }

    static var accessibleDefault: Animation {
        .easeInOut(duration: 0.25)
    }
}
