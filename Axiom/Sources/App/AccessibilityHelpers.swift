import SwiftUI

/// Accessibility helpers for macOS
/// Provides backwards compatibility for accessibilityReduceMotion

extension EnvironmentValues {
    var accessibilityReduceMotion: Bool {
        // On macOS, we don't have UIAccessibility, so default to false
        // The actual value would come from system settings
        return false
    }
}

/// Global accessibility Reduce Motion state
var accessibilityReduceMotion: Bool {
    // On macOS, we don't have UIAccessibility
    // In a real app, this would query the system's accessibility preferences
    return false
}
