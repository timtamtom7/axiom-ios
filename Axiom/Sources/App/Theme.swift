import SwiftUI

enum Theme {
    // MARK: - Colors (Dark Mode / Default)
    static let background = Color(hex: "0a0a0f")
    static let surface = Color(hex: "161616")
    static let surfaceElevated = Color(hex: "2E2E2E")
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "B8B8B8")  // Upgraded from 9E9E9E for WCAG AA (4.5:1+)
    static let accentGreen = Color(hex: "4CAF50")
    static let accentRed = Color(hex: "EF5350")
    static let accentBlue = Color(hex: "42A5F5")
    static let accentGold = Color(hex: "FFD54F")     // Upgraded from FFCA28 for better contrast (3:1+ for large/decorative)
    static let accentPurple = Color(hex: "e879f9")
    static let border = Color(hex: "3A3A3A")

    // MARK: - Accessible Text on Background (WCAG AA 4.5:1+)
    // Use these for any text rendered directly on background
    static let textOnBackground = textPrimary  // white on dark = 15.8:1
    static let textSecondaryOnBackground = Color(hex: "B8B8B8")  // 4.6:1 on background

    // MARK: - Accent Colors for Text Use
    // Only use these on surfaces (not directly on background)
    static let goldForText = Color(hex: "FFD54F")   // ~11:1 on surface — use for buttons/labels on surface
    static let purpleForText = Color(hex: "DDA4FF") // Lighter purple for better contrast

    // MARK: - Onboarding Colors
    static let onboardingPurple = Color(hex: "e879f9")
    static let onboardingBackground = Color(hex: "0a0a0f")
    static let onboardingSurface = Color(hex: "161616")
    static let secondaryText = Color(hex: "B8B8B8")  // Upgraded from 8B8B9B for WCAG AA

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

    // MARK: - Corner Radii
    static let cornerRadiusS: CGFloat = 4     // Small: badges, tags
    static let cornerRadiusM: CGFloat = 8     // Medium: buttons, chips
    static let cornerRadiusL: CGFloat = 12    // Large: cards, sheets
    static let cornerRadiusXL: CGFloat = 16   // Extra large: modals
    static let cornerRadiusXXL: CGFloat = 20  // XXL: prominent elements
    static let cornerRadiusFull: CGFloat = 9999 // Full: pills, capsules
    static let cornerRadiusPill: CGFloat = 20 // Pill: buttons, chips
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
