import Testing
@testable import CoolCaptions

@MainActor struct CaptioningScreenTests {
    let analytics = AnalyticsSpy()
    let connection: Connection
    let captioner: Captioner
    let screen: CaptioningScreen

    init() {
        connection = Connection(analytics: analytics)
        captioner = Captioner(analytics: analytics, connection: connection)
        screen = CaptioningScreen(analytics: analytics, connection: connection, captioner: captioner)
    }

    func connectionBecomes(_ status: Connection.Status) {
        connection.status = status
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
}
