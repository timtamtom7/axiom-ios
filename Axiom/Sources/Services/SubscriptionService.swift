import Foundation
import SwiftUI

// R13: Subscription Business - 4 tiers as per plan:
// - Axiom Free: 3 beliefs, basic evidence, simple analysis
// - Axiom Pro: Unlimited beliefs, AI deep dive, network graph, evolution tracking ($9.99/month or $79.99/year)
// - Axiom Therapy: Pro + therapist connection, treatment plans, progress reports ($24.99/month)
// - Axiom Teams: Group workshops, shared belief projects ($14.99/user/month, min 5 users)

enum SubscriptionTier: String, Codable, CaseIterable {
    case free = "free"
    case pro = "pro"
    case therapy = "therapy"
    case teams = "teams"

    // Pricing
    var monthlyPrice: Double {
        switch self {
        case .free: return 0
        case .pro: return 9.99
        case .therapy: return 24.99
        case .teams: return 14.99
        }
    }

    var yearlyPrice: Double {
        switch self {
        case .free: return 0
        case .pro: return 79.99
        case .therapy: return 249.99
        case .teams: return 149.99
        }
    }

    var maxBeliefs: Int? {
        switch self {
        case .free: return 3
        case .pro, .therapy, .teams: return nil // unlimited
        }
    }

    static var freeMaxBeliefs: Int { 3 }

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .pro: return "Pro"
        case .therapy: return "Therapy"
        case .teams: return "Teams"
        }
    }

    var subtitle: String {
        switch self {
        case .free: return "3 beliefs, basic evidence"
        case .pro: return "Unlimited + AI Deep Dive"
        case .therapy: return "Pro + therapist support"
        case .teams: return "Shared belief projects"
        }
    }

    var features: [String] {
        switch self {
        case .free:
            return [
                "Up to 3 beliefs",
                "Basic evidence tracking",
                "Simple analysis",
                "Community browsing"
            ]
        case .pro:
            return [
                "Unlimited beliefs",
                "Unlimited evidence",
                "AI Deep Dive analysis",
                "Belief network graph",
                "Evolution tracking",
                "Legacy document export",
                "Apple Watch app",
                "iPad side-by-side"
            ]
        case .therapy:
            return [
                "Everything in Pro",
                "Therapist connection",
                "Treatment plans",
                "Progress reports",
                "Priority support",
                "Monthly wellness check"
            ]
        case .teams:
            return [
                "Everything in Pro",
                "Group workshops",
                "Shared belief projects",
                "Team analytics",
                "Collaborative evidence",
                "Minimum 5 users"
            ]
        }
    }

    var isRecommended: Bool {
        self == .pro
    }
}

@MainActor
final class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()

    private let tierKey = "subscription_tier"
    private let proUnlockedKey = "pro_unlocked"
    private let therapyUnlockedKey = "therapy_unlocked"
    private let teamsUnlockedKey = "teams_unlocked"
    private let teamsMemberCountKey = "teams_member_count"

    @Published var currentTier: SubscriptionTier = .free
    @Published var teamsMemberCount: Int = 1

    var isPro: Bool { currentTier == .pro || currentTier == .therapy || currentTier == .teams }
    var isTherapy: Bool { currentTier == .therapy }
    var isTeams: Bool { currentTier == .teams }

    var canAddBelief: Bool {
        if isPro { return true }
        return DatabaseService.shared.allBeliefs.count < SubscriptionTier.freeMaxBeliefs
    }

    var beliefsRemaining: Int {
        if isPro { return Int.max }
        return max(0, SubscriptionTier.freeMaxBeliefs - DatabaseService.shared.allBeliefs.count)
    }

    var canAccessAIDeepDive: Bool { isPro }
    var canAccessTherapistConnection: Bool { isTherapy }
    var canCreateTeamProjects: Bool { isTeams }

    init() {
        loadTier()
    }

    func loadTier() {
        if let tierString = UserDefaults.standard.string(forKey: tierKey),
           let tier = SubscriptionTier(rawValue: tierString) {
            currentTier = tier
        } else {
            currentTier = .free
        }
        teamsMemberCount = UserDefaults.standard.integer(forKey: teamsMemberCountKey)
        if teamsMemberCount == 0 { teamsMemberCount = 1 }
    }

    func upgradeToPro() {
        currentTier = .pro
        saveTier()
    }

    func upgradeToTherapy() {
        currentTier = .therapy
        saveTier()
    }

    func upgradeToTeams(memberCount: Int = 5) {
        currentTier = .teams
        teamsMemberCount = memberCount
        UserDefaults.standard.set(memberCount, forKey: teamsMemberCountKey)
        saveTier()
    }

    func downgradeToFree() {
        currentTier = .free
        saveTier()
    }

    private func saveTier() {
        UserDefaults.standard.set(currentTier.rawValue, forKey: tierKey)
    }

    /// Simulates a purchase (in real app, this would use StoreKit 2)
    func simulatePurchase(tier: SubscriptionTier) {
        switch tier {
        case .free:
            downgradeToFree()
        case .pro:
            upgradeToPro()
        case .therapy:
            upgradeToTherapy()
        case .teams:
            upgradeToTeams()
        }
    }

    /// R13: Calculate monthly cost for teams
    var monthlyTeamsCost: Double {
        guard isTeams else { return 0 }
        return SubscriptionTier.teams.monthlyPrice * Double(teamsMemberCount)
    }
}
