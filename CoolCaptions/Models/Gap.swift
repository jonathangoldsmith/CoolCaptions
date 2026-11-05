import Foundation

struct Gap: Identifiable, Equatable {
    let id: UUID

    /// Wall-clock time, for ordering against captions and for the on-screen timer.
    let start: Date

    /// Measured on a monotonic clock, because the wall clock can jump while the phone is offline.
    let startInstant: ContinuousClock.Instant
    var duration: Duration?

    /// Fixed when the gap opens, so turning the flag on mid-outage doesn't count as an alert the user saw.
    var showsAlert: Bool

    var isOpen: Bool { duration == nil }
}
