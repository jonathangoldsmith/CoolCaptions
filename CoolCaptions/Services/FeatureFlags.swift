import Foundation

/// Mock flags, flipped from the Debug screen. Both start on so the sample shows the change.
/// shortcut: in memory only. A real flag service would assign users to groups and default `dropAlerts` to off.
@Observable class FeatureFlags {
    /// Decides who gets the change: the paused status, the buzz, the announcements and the settings button.
    var dropAlerts = true

    /// An off switch for the transcript marker alone. It has no effect while `dropAlerts` is off.
    var gapMarkers = true
}
