import Foundation
#if os(macOS)
import AppKit
#endif

/// Cross-platform haptic feedback service for key interactions
/// On macOS, uses NSHapticFeedbackManager
@MainActor
final class HapticService {
    static let shared = HapticService()

    private init() {}

    // MARK: - macOS Haptics

    #if os(macOS)
    /// Play haptic feedback on macOS
    nonisolated private func playHaptic(style: NSHapticFeedbackManager.FeedbackPattern) {
        if #available(macOS 10.15, *) {
            NSHapticFeedbackManager.defaultPerformer.perform(style, performanceTime: .now)
        }
    }
    #endif

    // MARK: - Public API

    /// Belief was created successfully
    func beliefCreated() {
        #if os(macOS)
        if #available(macOS 10.15, *) {
            playHaptic(style: .generic)
        }
        #endif
    }

    /// Evidence was added to a belief
    func evidenceAdded() {
        #if os(macOS)
        if #available(macOS 10.15, *) {
            playHaptic(style: .alignment)
        }
        #endif
    }

    /// AI challenge or stress test response received
    func aiChallengeReceived() {
        #if os(macOS)
        if #available(macOS 10.15, *) {
            playHaptic(style: .levelChange)
        }
        #endif
    }

    /// Debate submitted successfully
    func debateSubmitted() {
        #if os(macOS)
        if #available(macOS 10.15, *) {
            playHaptic(style: .generic)
        }
        #endif
    }

    /// Light selection/choice feedback
    func selection() {
        #if os(macOS)
        if #available(macOS 10.15, *) {
            playHaptic(style: .alignment)
        }
        #endif
    }

    /// Error feedback
    func error() {
        #if os(macOS)
        if #available(macOS 10.15, *) {
            playHaptic(style: .levelChange)
        }
        #endif
    }
}
