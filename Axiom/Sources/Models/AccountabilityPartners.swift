import Foundation
import SwiftUI

/// R7: Accountability Partner data model and store
struct AccountabilityPartnerData: Identifiable, Codable, Equatable {
    let id: UUID
    var partnerId: UUID
    var partnerName: String
    var pairedAt: Date
    var checkInStreak: Int
    var lastCheckIn: Date?
    var goals: [String]
    var isActive: Bool
    var sharedProgress: [SharedProgress]
}

struct SharedProgress: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    let beliefProgress: String
    let completedGoals: Int
    let totalGoals: Int
}

@MainActor
final class AccountabilityPartnersStore: ObservableObject {
    static let shared = AccountabilityPartnersStore()

    private let storageKey = "accountability_partners"

    @Published var partners: [AccountabilityPartnerData] = []

    init() {
        loadPartners()
    }

    func loadPartners() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([AccountabilityPartnerData].self, from: data) else {
            partners = Self.samplePartners
            return
        }
        partners = decoded
    }

    func recordCheckIn(for partner: AccountabilityPartnerData) {
        if let index = partners.firstIndex(where: { $0.id == partner.id }) {
            let now = Date()
            let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: now)!

            // Update streak
            if let lastCheckIn = partners[index].lastCheckIn, lastCheckIn > oneDayAgo {
                // Streak continues
                partners[index].checkInStreak += 1
            } else {
                // Streak broken or first check-in
                partners[index].checkInStreak = 1
            }
            partners[index].lastCheckIn = now
            save()
        }
    }

    func addPartner(name: String, email: String) {
        let newPartner = AccountabilityPartnerData(
            id: UUID(),
            partnerId: UUID(),
            partnerName: name,
            pairedAt: Date(),
            checkInStreak: 0,
            lastCheckIn: nil,
            goals: [],
            isActive: false,
            sharedProgress: []
        )
        partners.insert(newPartner, at: 0)
        save()
    }

    func removePartner(_ partner: AccountabilityPartnerData) {
        partners.removeAll { $0.id == partner.id }
        save()
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(partners) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private static let samplePartners: [AccountabilityPartnerData] = [
        AccountabilityPartnerData(
            id: UUID(),
            partnerId: UUID(),
            partnerName: "Marcus Rivera",
            pairedAt: Date().addingTimeInterval(-86400 * 14),
            checkInStreak: 5,
            lastCheckIn: Date().addingTimeInterval(-3600 * 6),
            goals: [
                "Complete evidence for at least one belief per week",
                "Run AI stress test on core beliefs monthly",
                "Share progress with therapist each month"
            ],
            isActive: true,
            sharedProgress: []
        )
    ]
}
