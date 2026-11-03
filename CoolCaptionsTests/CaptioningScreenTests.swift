import Foundation
import Testing
@testable import CoolCaptions

@MainActor struct CaptioningScreenTests {
    let analytics = AnalyticsSpy()
    let clock: TestClock
    let connection: Connection
    let captioner: Captioner
    let screen: CaptioningScreen

    init() {
        let clock = TestClock()
        self.clock = clock
        connection = Connection(analytics: analytics)
        captioner = Captioner(analytics: analytics, connection: connection)
        screen = CaptioningScreen(analytics: analytics, connection: connection, captioner: captioner, now: { clock.now })
    }

    /// Does what the view does when the connection changes.
    func connectionBecomes(_ status: Connection.Status) {
        connection.status = status
        screen.connectionStatusChanged()
    }

    func captionArrives() -> Caption {
        let caption = Caption(id: UUID(), date: clock.now, body: "Line")
        captioner.captions.append(caption)
        return caption
    }

    // MARK: -

    @Test func toggleStartsAndStopsCaptioning() {
        screen.toggleButtonWasPressed()
        #expect(captioner.isRunning)
        #expect(screen.toggleButtonTitle == "Stop")

        screen.toggleButtonWasPressed()
        #expect(!captioner.isRunning)
        #expect(screen.toggleButtonTitle == "Start")

        #expect(analytics.events == [
            .captioningToggleButtonWasPressed, .captioningStarted,
            .captioningToggleButtonWasPressed, .captioningStopped,
        ])
    }

    // MARK: - Paused state

    @Test func pausesWhenDisconnectedWhileCaptioning() {
        screen.toggleButtonWasPressed()
        defer { captioner.stop() }

        connectionBecomes(.disconnected)

        #expect(screen.isPaused)
    }

    @Test func doesNotPauseWhenNotCaptioning() {
        connectionBecomes(.disconnected)

        #expect(!screen.isPaused)
    }

    @Test func doesNotPauseWhenDegraded() {
        screen.toggleButtonWasPressed()
        defer { captioner.stop() }

        connectionBecomes(.degraded)

        #expect(!screen.isPaused)
    }

    @Test func pausesWhenStartedWhileAlreadyDisconnected() {
        connectionBecomes(.disconnected)

        screen.toggleButtonWasPressed()
        defer { captioner.stop() }

        #expect(screen.isPaused)
    }

    @Test(arguments: [Connection.Status.healthy, .degraded])
    func resumesOnReconnect(to status: Connection.Status) {
        screen.toggleButtonWasPressed()
        defer { captioner.stop() }
        connectionBecomes(.disconnected)

        connectionBecomes(status)

        #expect(!screen.isPaused)
    }

    @Test func stopClearsPause() {
        screen.toggleButtonWasPressed()
        connectionBecomes(.disconnected)

        screen.toggleButtonWasPressed()

        #expect(!screen.isPaused)
    }

    // MARK: - Recording the gap

    @Test func recordsGapStartAndEnd() {
        let start = clock.now
        screen.toggleButtonWasPressed()
        defer { captioner.stop() }

        clock.advance(by: 10)
        connectionBecomes(.disconnected)
        clock.advance(by: 72)
        connectionBecomes(.healthy)

        #expect(screen.gaps.map(\.start) == [start + 10])
        #expect(screen.gaps.map(\.end) == [start + 82])
    }

    @Test func stopDuringOutageEndsGapAtStopTime() {
        let start = clock.now
        screen.toggleButtonWasPressed()
        clock.advance(by: 10)
        connectionBecomes(.disconnected)

        clock.advance(by: 20)
        screen.toggleButtonWasPressed()

        #expect(screen.gaps.map(\.end) == [start + 30])
    }

    @Test func gapSitsBetweenTheCaptionsItInterrupts() throws {
        screen.toggleButtonWasPressed()
        defer { captioner.stop() }

        let before = captionArrives()
        clock.advance(by: 5)
        connectionBecomes(.disconnected)
        clock.advance(by: 30)
        connectionBecomes(.healthy)
        clock.advance(by: 3)
        let after = captionArrives()

        let gap = try #require(screen.gaps.first)
        #expect(screen.items.map(\.id) == [before.id, gap.id, after.id])
    }

    @Test func captionWinsTieWithGapStart() throws {
        screen.toggleButtonWasPressed()
        defer { captioner.stop() }

        let caption = captionArrives()
        connectionBecomes(.disconnected)

        let gap = try #require(screen.gaps.first)
        #expect(screen.items.map(\.id) == [caption.id, gap.id])
    }
}
