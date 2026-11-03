import Foundation

@MainActor final class TestClock {
    private(set) var now = Date(timeIntervalSinceReferenceDate: 0)

    func advance(by seconds: TimeInterval) {
        now += seconds
    }
}
