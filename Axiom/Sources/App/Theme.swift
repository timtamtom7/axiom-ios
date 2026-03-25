import SwiftUI

enum Theme {
    // MARK: - Colors
    static let background = Color(hex: "1A1A1A")
    static let surface = Color(hex: "242424")
    static let surfaceElevated = Color(hex: "2E2E2E")
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "9E9E9E")
    static let accentGreen = Color(hex: "4CAF50")
    static let accentRed = Color(hex: "EF5350")
    static let accentBlue = Color(hex: "42A5F5")
    static let accentGold = Color(hex: "FFCA28")
    static let border = Color(hex: "3A3A3A")

    // MARK: - Score Colors
    static func scoreColor(for score: Double) -> Color {
        if score < 40 {
            return accentRed
        } else if score < 70 {
            return accentGold
        } else {
            return accentGreen
        }
    }

    // MARK: - Spacing
    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 16
    static let spacingL: CGFloat = 24
    static let spacingXL: CGFloat = 32
    static let screenMargin: CGFloat = 20
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
