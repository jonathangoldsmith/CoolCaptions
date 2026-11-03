import Foundation

/// The user's settings. Held in memory, so they reset at every launch.
@Observable class Preferences {
    /// On by default: the people who miss drops would never turn an alert on.
    var vibratesWhenPaused = true
    var announcesWithVoiceOver = true
}
