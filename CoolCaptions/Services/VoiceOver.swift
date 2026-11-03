import Accessibility
import Foundation

enum VoiceOver {
    /// High priority, so VoiceOver interrupts what it is reading. Braille displays show it too.
    nonisolated static func announce(_ message: String) {
        var announcement = AttributedString(message)
        announcement.accessibilitySpeechAnnouncementPriority = .high
        AccessibilityNotification.Announcement(announcement).post()
    }
}
