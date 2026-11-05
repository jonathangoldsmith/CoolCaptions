import Foundation

@MainActor final class TestClock {
    private(set) var now = Date(timeIntervalSinceReferenceDate: 0)
    private(set) var instant = ContinuousClock.now

    func advance(by seconds: TimeInterval) {
        now += seconds
        instant = instant.advanced(by: .seconds(seconds))
    }

    /// Moves only the wall clock, as a time sync or a time-zone change can.
    func jumpWallClock(by seconds: TimeInterval) {
        now += seconds
    }
}
