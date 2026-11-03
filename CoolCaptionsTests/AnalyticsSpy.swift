@testable import CoolCaptions

@MainActor final class AnalyticsSpy: Analytics {
    private(set) var events: [Event] = []

    override func track(_ event: Event) {
        events.append(event)
    }
}
