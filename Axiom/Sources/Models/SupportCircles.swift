import Foundation
import SwiftUI

/// R7: Support Circles data model and store
struct SupportCircleData: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var description: String
    var memberCount: Int
    var isJoined: Bool
    var topics: [String]
    var meetingTime: String?
    var isPrivate: Bool
    var isActive: Bool
    var lastActivity: Date
    var guidelines: [String]
}

/// Stores support circles community data
@MainActor
final class SupportCirclesStore: ObservableObject {
    static let shared = SupportCirclesStore()

    private let storageKey = "support_circles"

    @Published var circles: [SupportCircleData] = []

    init() {
        loadCircles()
    }

    func loadCircles() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([SupportCircleData].self, from: data) else {
            circles = Self.sampleCircles
            return
        }
        circles = decoded
    }

    func toggleMembership(_ circle: SupportCircleData) {
        if let index = circles.firstIndex(where: { $0.id == circle.id }) {
            circles[index].isJoined.toggle()
            circles[index].memberCount += circles[index].isJoined ? 1 : -1
            save()
        }
    }

    func addCircle(_ circle: SupportCircleData) {
        circles.insert(circle, at: 0)
        save()
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(circles) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private static let sampleCircles: [SupportCircleData] = [
        SupportCircleData(
            id: UUID(),
            name: "Daily Anxiety Support",
            description: "People who also struggle with anxiety. Share experiences, offer support, and check in daily.",
            memberCount: 124,
            isJoined: false,
            topics: ["anxiety", "daily-check-in", "mutual-support", "coping"],
            meetingTime: "Daily 9pm EST",
            isPrivate: false,
            isActive: true,
            lastActivity: Date().addingTimeInterval(-3600),
            guidelines: [
                "Be respectful and supportive",
                "Share from personal experience only",
                "No medical or professional advice",
                "What happens in the circle, stays in the circle"
            ]
        ),
        SupportCircleData(
            id: UUID(),
            name: "CBT Practice Group",
            description: "Working through CBT exercises together. Share progress, insights, and techniques.",
            memberCount: 89,
            isJoined: false,
            topics: ["CBT", "exercises", "belief-work", "cognitive"],
            meetingTime: "Wednesdays 7pm EST",
            isPrivate: false,
            isActive: true,
            lastActivity: Date().addingTimeInterval(-7200),
            guidelines: [
                "Practice regularly and share your experience",
                "Be encouraging to fellow members",
                "Reference CBT principles when helpful",
                "No diagnosing or labeling others"
            ]
        ),
        SupportCircleData(
            id: UUID(),
            name: "Mindfulness & Meditation",
            description: "Gentle practices for grounding and presence. All experience levels welcome.",
            memberCount: 203,
            isJoined: true,
            topics: ["mindfulness", "meditation", "breathing", "grounding"],
            meetingTime: nil,
            isPrivate: false,
            isActive: true,
            lastActivity: Date().addingTimeInterval(-1800),
            guidelines: [
                "All levels welcome — no experience needed",
                "Share techniques that work for you",
                "Be patient with yourself and others",
                "Quiet support over loud advice"
            ]
        ),
        SupportCircleData(
            id: UUID(),
            name: "Progress Celebration",
            description: "Big and small wins. We celebrate every step forward on the belief audit journey.",
            memberCount: 156,
            isJoined: false,
            topics: ["wins", "celebration", "positivity", "milestones"],
            meetingTime: nil,
            isPrivate: false,
            isActive: false,
            lastActivity: Date().addingTimeInterval(-86400 * 2),
            guidelines: [
                "Celebrate wins — big or small",
                "Be genuinely supportive",
                "No comparing your journey to others",
                "Encourage, don't minimize"
            ]
        )
    ]
}
