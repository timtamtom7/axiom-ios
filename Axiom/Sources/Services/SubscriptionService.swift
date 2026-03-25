import Foundation
import SwiftUI

enum SubscriptionTier: String, Codable {
    case free = "free"
    case pro = "pro"

    var maxBeliefs: Int? { nil } // unlimited
    static var freeMaxBeliefs: Int { 3 }

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .pro: return "Pro"
        }
    }

    var canAddMoreBeliefs: Bool {
        true // Always can add in current tier
    }

    var features: [String] {
        switch self {
        case .free:
            return [
                "Up to 3 beliefs",
                "Evidence tracking",
                "AI stress test",
                "Basic statistics"
            ]
        case .pro:
            return [
                "Unlimited beliefs",
                "Unlimited evidence",
                "AI Deep Dive",
                "Community sharing",
                "Legacy document export",
                "Apple Watch app",
                "iPad side-by-side"
            ]
        }
    }
}

@MainActor
final class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()

    private let tierKey = "subscription_tier"
    private let proUnlockedKey = "pro_unlocked"

    @Published var currentTier: SubscriptionTier = .free

    var isPro: Bool { currentTier == .pro }

    var canAddBelief: Bool {
        if isPro { return true }
        return DatabaseService.shared.allBeliefs.count < SubscriptionTier.freeMaxBeliefs
    }

    var beliefsRemaining: Int {
        max(0, SubscriptionTier.freeMaxBeliefs - DatabaseService.shared.allBeliefs.count)
    }

    init() {
        loadTier()
    }

    func loadTier() {
        if let tierString = UserDefaults.standard.string(forKey: tierKey),
           let tier = SubscriptionTier(rawValue: tierString) {
            currentTier = tier
        } else {
            // Check if pro was previously unlocked
            if UserDefaults.standard.bool(forKey: proUnlockedKey) {
                currentTier = .pro
            } else {
                currentTier = .free
            }
        }
    }

    func upgradeToPro() {
        currentTier = .pro
        UserDefaults.standard.set(SubscriptionTier.pro.rawValue, forKey: tierKey)
        UserDefaults.standard.set(true, forKey: proUnlockedKey)
    }

    func downgradeToFree() {
        currentTier = .free
        UserDefaults.standard.set(SubscriptionTier.free.rawValue, forKey: tierKey)
    }

    /// Simulates a purchase (in real app, this would use StoreKit)
    func simulatePurchase() {
        upgradeToPro()
    }
}
