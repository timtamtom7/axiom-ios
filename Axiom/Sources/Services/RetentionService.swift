import Foundation
import SwiftUI

/// R13: Retention tracking service
/// Day 1: enter first belief
/// Day 7: first evidence entry
/// Day 30: first AI conversation
@MainActor
final class RetentionService: ObservableObject {
    static let shared = RetentionService()

    private let installDateKey = "install_date"
    private let day1BeliefCompletedKey = "day1_belief_completed"
    private let day7EvidenceCompletedKey = "day7_evidence_completed"
    private let day30AICompletedKey = "day30_ai_completed"
    private let lastActiveDateKey = "last_active_date"
    private let sessionsCountKey = "sessions_count"

    @Published var daysSinceInstall: Int = 0
    @Published var day1Completed: Bool = false
    @Published var day7Completed: Bool = false
    @Published var day30Completed: Bool = false
    @Published var sessionsCount: Int = 0

    var currentRetentionMilestone: RetentionMilestone {
        if day30Completed {
            return .completed
        } else if day7Completed {
            return .day30
        } else if day1Completed {
            return .day7
        } else {
            return .day1
        }
    }

    enum RetentionMilestone: String {
        case day1 = "Enter your first belief"
        case day7 = "Add first evidence"
        case day30 = "Have your first AI conversation"
        case completed = "Retention complete!"
    }

    init() {
        loadRetentionData()
    }

    func loadRetentionData() {
        // Calculate days since install
        if let installDate = UserDefaults.standard.object(forKey: installDateKey) as? Date {
            daysSinceInstall = Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0
        } else {
            // First launch - set install date
            UserDefaults.standard.set(Date(), forKey: installDateKey)
            daysSinceInstall = 0
        }

        day1Completed = UserDefaults.standard.bool(forKey: day1BeliefCompletedKey)
        day7Completed = UserDefaults.standard.bool(forKey: day7EvidenceCompletedKey)
        day30Completed = UserDefaults.standard.bool(forKey: day30AICompletedKey)
        sessionsCount = UserDefaults.standard.integer(forKey: sessionsCountKey)

        // Update last active
        UserDefaults.standard.set(Date(), forKey: lastActiveDateKey)
    }

    func recordBeliefCreated() {
        guard !day1Completed else { return }
        day1Completed = true
        UserDefaults.standard.set(true, forKey: day1BeliefCompletedKey)
        trackMilestone(.day1)
    }

    func recordEvidenceAdded() {
        guard !day7Completed else { return }
        day7Completed = true
        UserDefaults.standard.set(true, forKey: day7EvidenceCompletedKey)
        trackMilestone(.day7)
    }

    func recordAIConversation() {
        guard !day30Completed else { return }
        day30Completed = true
        UserDefaults.standard.set(true, forKey: day30AICompletedKey)
        trackMilestone(.day30)
    }

    func recordSession() {
        sessionsCount += 1
        UserDefaults.standard.set(sessionsCount, forKey: sessionsCountKey)
    }

    private func trackMilestone(_ milestone: RetentionMilestone) {
        // In production, send to analytics
        print("[Retention] Milestone completed: \(milestone.rawValue)")
    }

    /// Check if user needs a nudge for the current milestone
    func needsMilestoneNudge() -> Bool {
        switch currentRetentionMilestone {
        case .day1:
            return daysSinceInstall >= 1 && !day1Completed
        case .day7:
            return daysSinceInstall >= 7 && !day7Completed
        case .day30:
            return daysSinceInstall >= 30 && !day30Completed
        case .completed:
            return false
        }
    }

    var nextMilestone: (title: String, description: String, daysUntil: Int) {
        switch currentRetentionMilestone {
        case .day1:
            return ("Add Evidence", "Start building your belief library", max(0, 7 - daysSinceInstall))
        case .day7:
            return ("AI Deep Dive", "Explore your beliefs with AI", max(0, 30 - daysSinceInstall))
        case .day30, .completed:
            return ("Keep Growing", "Continue your belief work", 0)
        }
    }
}
