import Foundation

/// What a screen needs from the device. Tests replace these with fakes.
struct Platform {
    var now: @MainActor () -> Date = { .now }
    var instant: @MainActor () -> ContinuousClock.Instant = { .now }
    var locale: Locale = .autoupdatingCurrent
    var announce: @MainActor (String) -> Void = VoiceOver.announce
}
