import Foundation

/// What a screen needs from the device. Tests replace these with fakes.
nonisolated struct Platform {
    var now: () -> Date = { .now }
    var locale: Locale = .autoupdatingCurrent
    var announce: (String) -> Void = VoiceOver.announce
}
