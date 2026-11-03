import Foundation
import Testing
@testable import CoolCaptions

@MainActor struct CaptioningScreenTests {
    let analytics = AnalyticsSpy()
    let announcer = AnnouncementSpy()
    let preferences = Preferences()
    let flags = FeatureFlags()
    let clock: TestClock
    let connection: Connection
    let captioner: Captioner
    let screen: CaptioningScreen

    init() {
        let clock = TestClock()
        let announcer = announcer
        self.clock = clock
        connection = Connection(analytics: analytics)
        // A wait that never ends, so the real conversation can't add captions or events mid-test.
        captioner = Captioner(analytics: analytics, connection: connection, wait: { _ in
            try await Task.sleep(for: .seconds(3600))
        })
        let platform = Platform(
            now: { clock.now }, instant: { clock.instant },
            locale: Locale(identifier: "en_US"), announce: announcer.announce
        )
        screen = CaptioningScreen(
            analytics: analytics, connection: connection, captioner: captioner,
            preferences: preferences, flags: flags, platform: platform
        )
    }

    let pausedAnnouncement = "Captions paused. No connection. Reconnecting automatically."

    func connectionBecomes(_ status: Connection.Status) {
        connection.status = status
    }

    var gapEvents: [Analytics.Event] {
        analytics.events.filter { $0 == .captionGapStarted || $0 == .captionGapEnded }
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
        connectionBecomes(.healthy)

        let gap = try #require(screen.gaps.first)
        #expect(screen.items.map(\.id) == [caption.id, gap.id])
    }

    /// An open gap shows as the paused status, so the transcript only holds finished ones.
    @Test func openGapStaysOutOfTheTranscript() {
        screen.toggleButtonWasPressed()
        defer { captioner.stop() }
        let caption = captionArrives()

        connectionBecomes(.disconnected)

        #expect(screen.items.map(\.id) == [caption.id])
    }

    // MARK: - Edge cases

    @Test func restartsDuringOneOutageKeepOneGap() {
        let start = clock.now
        screen.toggleButtonWasPressed()
        defer { captioner.stop() }
        clock.advance(by: 10)
        connectionBecomes(.disconnected)

        for _ in 1...3 {
            clock.advance(by: 5)
            screen.toggleButtonWasPressed()
            clock.advance(by: 1)
            screen.toggleButtonWasPressed()
        }
        clock.advance(by: 20)
        connectionBecomes(.healthy)

        #expect(screen.gaps.map(\.start) == [start + 10])
        #expect(screen.gaps.map(\.end) == [start + 48])
    }

    @Test func outageThatEndsWhileStoppedIsNotReopened() {
        screen.toggleButtonWasPressed()
        defer { captioner.stop() }
        connectionBecomes(.disconnected)
        screen.toggleButtonWasPressed()
        connectionBecomes(.healthy)

        screen.toggleButtonWasPressed()
        connectionBecomes(.disconnected)

        #expect(screen.gaps.count == 2)
        #expect(screen.isPaused)
    }

    @Test func separateOutagesGetSeparateGaps() {
        screen.toggleButtonWasPressed()
        defer { captioner.stop() }

        connectionBecomes(.disconnected)
        connectionBecomes(.healthy)
        connectionBecomes(.disconnected)
        connectionBecomes(.degraded)

        #expect(screen.gaps.count == 2)
        #expect(screen.gaps.allSatisfy { $0.end != nil })
    }

    @Test func duplicateDisconnectedEventsAreIgnored() {
        let start = clock.now
        screen.toggleButtonWasPressed()
        defer { captioner.stop() }

        connectionBecomes(.disconnected)
        clock.advance(by: 5)
        connectionBecomes(.disconnected)

        #expect(screen.gaps.map(\.start) == [start])
    }

    /// Both changes land in one main-actor turn, so a view's `.onChange` would see healthy to healthy and miss it.
    @Test func dropAndRecoveryBeforeTheNextRenderAreStillRecorded() {
        screen.toggleButtonWasPressed()
        defer { captioner.stop() }

        connection.status = .disconnected
        clock.advance(by: 2)
        connection.status = .healthy

        #expect(screen.gaps.map(\.duration) == [.seconds(2)])
        #expect(gapEvents == [.captionGapStarted, .captionGapEnded])
    }

    @Test func outageWhileStoppedRecordsNothing() {
        connectionBecomes(.disconnected)
        connectionBecomes(.healthy)

        #expect(screen.gaps.isEmpty)
    }

    @Test func aGapIsOpenExactlyWhilePaused() {
        enum Step { case toggle, connection(Connection.Status) }
        let steps: [Step] = [
            .connection(.disconnected), .toggle, .connection(.degraded), .connection(.disconnected),
            .connection(.disconnected), .toggle, .connection(.healthy), .toggle, .connection(.disconnected),
            .toggle, .toggle, .connection(.degraded), .connection(.healthy), .connection(.disconnected),
            .toggle, .connection(.healthy), .toggle,
        ]
        defer { captioner.stop() }

        for step in steps {
            switch step {
                case .toggle: screen.toggleButtonWasPressed()
                case .connection(let status): connectionBecomes(status)
            }
            clock.advance(by: 1)

            #expect((screen.gaps.last?.isOpen ?? false) == screen.isPaused, "after \(step)")
        }
    }

    // MARK: - Analytics

    @Test func logsGapStartAndEnd() {
        screen.toggleButtonWasPressed()
        defer { captioner.stop() }

        connectionBecomes(.disconnected)
        connectionBecomes(.healthy)

        #expect(gapEvents == [.captionGapStarted, .captionGapEnded])
    }

    @Test func logsEachPausedStretchWhenRestartingDuringOutage() {
        screen.toggleButtonWasPressed()
        defer { captioner.stop() }
        connectionBecomes(.disconnected)

        screen.toggleButtonWasPressed()
        screen.toggleButtonWasPressed()
        connectionBecomes(.healthy)

        #expect(gapEvents == [.captionGapStarted, .captionGapEnded, .captionGapStarted, .captionGapEnded])
    }

    @Test func logsNoGapEventsWhileStopped() {
        connectionBecomes(.disconnected)
        connectionBecomes(.healthy)

        #expect(gapEvents.isEmpty)
    }

    @Test func logsNoGapEventsForDegraded() {
        screen.toggleButtonWasPressed()
        defer { captioner.stop() }

        connectionBecomes(.degraded)
        connectionBecomes(.healthy)

        #expect(gapEvents.isEmpty)
    }

    @Test func logsRepeatedDisconnectsOnce() {
        screen.toggleButtonWasPressed()
        defer { captioner.stop() }

        connectionBecomes(.disconnected)
        connectionBecomes(.disconnected)

        #expect(gapEvents == [.captionGapStarted])
    }

    // MARK: - Wording

    @Test(arguments: [
        (3, "Missed 3 sec (no connection)", "Missed 3 seconds. No connection."),
        (45, "Missed 45 sec (no connection)", "Missed 45 seconds. No connection."),
        (72, "Missed 1 min, 12 sec (no connection)", "Missed 1 minute, 12 seconds. No connection."),
        (130, "Missed 2 min, 10 sec (no connection)", "Missed 2 minutes, 10 seconds. No connection."),
        (3600, "Missed 1 hr (no connection)", "Missed 1 hour. No connection."),
    ])
    func markerWording(seconds: Int, text: String, label: String) {
        #expect(screen.markerText(missed: .seconds(seconds)) == text)
        #expect(screen.markerLabel(missed: .seconds(seconds)) == label)
    }

    // MARK: - Announcements

    @Test func announcesPause() {
        screen.toggleButtonWasPressed()
        defer { captioner.stop() }

        connectionBecomes(.disconnected)

        #expect(announcer.messages == [pausedAnnouncement])
    }

    @Test func announcesResumeWithTheMissedTime() {
        screen.toggleButtonWasPressed()
        defer { captioner.stop() }
        clock.advance(by: 10)
        connectionBecomes(.disconnected)
        clock.advance(by: 72)

        connectionBecomes(.healthy)

        #expect(announcer.messages == [pausedAnnouncement, "Captions resumed. Missed 1 minute, 12 seconds."])
    }

    @Test func noAnnouncementsForDegradedOrRepeats() {
        screen.toggleButtonWasPressed()
        defer { captioner.stop() }

        connectionBecomes(.degraded)
        connectionBecomes(.healthy)
        connectionBecomes(.disconnected)
        connectionBecomes(.disconnected)

        #expect(announcer.messages == [pausedAnnouncement])
    }

    @Test func stopDuringOutageAnnouncesNoResume() {
        screen.toggleButtonWasPressed()
        connectionBecomes(.disconnected)

        screen.toggleButtonWasPressed()

        #expect(announcer.messages == [pausedAnnouncement])
    }

    // MARK: - Buzz

    @Test func buzzesOncePerOutage() {
        screen.toggleButtonWasPressed()
        defer { captioner.stop() }

        connectionBecomes(.disconnected)
        #expect(screen.hapticTrigger == 1)

        connectionBecomes(.disconnected)
        connectionBecomes(.healthy)
        connectionBecomes(.degraded)
        #expect(screen.hapticTrigger == 1)

        connectionBecomes(.disconnected)
        #expect(screen.hapticTrigger == 2)
    }

    @Test func restartDuringOutageAnnouncesAgainWithoutBuzzing() {
        screen.toggleButtonWasPressed()
        defer { captioner.stop() }
        connectionBecomes(.disconnected)

        screen.toggleButtonWasPressed()
        screen.toggleButtonWasPressed()

        #expect(announcer.messages == [pausedAnnouncement, pausedAnnouncement])
        #expect(screen.hapticTrigger == 1)
    }

    // MARK: - User settings

    @Test func cuesAreOnByDefault() {
        #expect(Preferences().vibratesWhenPaused)
        #expect(Preferences().announcesWithVoiceOver)
    }

    @Test func noBuzzWhenVibrateIsOff() {
        preferences.vibratesWhenPaused = false
        screen.toggleButtonWasPressed()
        defer { captioner.stop() }

        connectionBecomes(.disconnected)

        #expect(screen.hapticTrigger == 0)
        #expect(announcer.messages == [pausedAnnouncement])
    }

    @Test func noAnnouncementsWhenAnnounceIsOff() {
        preferences.announcesWithVoiceOver = false
        screen.toggleButtonWasPressed()
        defer { captioner.stop() }

        connectionBecomes(.disconnected)
        connectionBecomes(.healthy)

        #expect(announcer.messages.isEmpty)
        #expect(screen.hapticTrigger == 1)
    }

    @Test func statusAndMarkerIgnoreTheSettings() throws {
        preferences.vibratesWhenPaused = false
        preferences.announcesWithVoiceOver = false
        screen.toggleButtonWasPressed()
        defer { captioner.stop() }

        connectionBecomes(.disconnected)
        #expect(screen.isPaused)

        connectionBecomes(.healthy)
        let gap = try #require(screen.gaps.first)
        #expect(screen.items.map(\.id) == [gap.id])
        #expect(gapEvents == [.captionGapStarted, .captionGapEnded])
    }

    // MARK: - Feature flags

    @Test func pausedStatusShowsWhilePaused() {
        screen.toggleButtonWasPressed()
        defer { captioner.stop() }

        connectionBecomes(.disconnected)
        #expect(screen.showsPausedStatus)

        connectionBecomes(.healthy)
        #expect(!screen.showsPausedStatus)
    }

    @Test func alertsFlagOffShowsNothing() {
        flags.dropAlerts = false
        screen.toggleButtonWasPressed()
        defer { captioner.stop() }

        connectionBecomes(.disconnected)
        #expect(!screen.showsPausedStatus)
        #expect(screen.hapticTrigger == 0)

        connectionBecomes(.healthy)
        #expect(screen.items.isEmpty)
        #expect(announcer.messages.isEmpty)
    }

    @Test func alertsFlagOffStillRecordsAndLogsGaps() {
        flags.dropAlerts = false
        screen.toggleButtonWasPressed()
        defer { captioner.stop() }

        connectionBecomes(.disconnected)
        #expect(screen.isPaused)
        connectionBecomes(.healthy)

        #expect(screen.gaps.count == 1)
        #expect(gapEvents == [.captionGapStarted, .captionGapEnded])
    }

    @Test func markerSwitchOffHidesOnlyMarkers() {
        screen.toggleButtonWasPressed()
        defer { captioner.stop() }
        let caption = captionArrives()
        connectionBecomes(.disconnected)
        connectionBecomes(.healthy)

        flags.gapMarkers = false
        #expect(screen.items.map(\.id) == [caption.id])

        connectionBecomes(.disconnected)
        #expect(screen.showsPausedStatus)
        #expect(screen.hapticTrigger == 2)
        #expect(announcer.messages.count == 3)
    }

    @Test(arguments: [true, false])
    func logsStatusShownOnlyWhenAlertsAreOn(alertsAreOn: Bool) {
        flags.dropAlerts = alertsAreOn
        screen.toggleButtonWasPressed()
        defer { captioner.stop() }

        connectionBecomes(.disconnected)
        screen.toggleButtonWasPressed()
        screen.toggleButtonWasPressed()

        #expect(analytics.events.count(where: { $0 == .captionGapStarted }) == 2)
        #expect(analytics.events.count(where: { $0 == .pausedStatusWasShown }) == (alertsAreOn ? 2 : 0))
    }

    // MARK: - View hooks

    @Test func gapDurationIsKnownOnceItEnds() {
        screen.toggleButtonWasPressed()
        defer { captioner.stop() }
        connectionBecomes(.disconnected)
        #expect(screen.gaps.first?.duration == nil)

        clock.advance(by: 72)
        connectionBecomes(.healthy)

        #expect(screen.gaps.first?.duration == .seconds(72))
    }

    @Test func pausedStatusCountsFromTheDrop() {
        let start = clock.now
        screen.toggleButtonWasPressed()
        defer { captioner.stop() }
        clock.advance(by: 10)
        connectionBecomes(.disconnected)

        clock.advance(by: 5)
        screen.toggleButtonWasPressed()
        screen.toggleButtonWasPressed()
        #expect(screen.pausedSince == start + 10)

        flags.dropAlerts = false
        #expect(screen.pausedSince == nil)
    }

    /// Starting the captioner directly skips the screen, so no gap opens. The timer must not reuse a finished one.
    @Test func pausedSinceIgnoresAFinishedGap() {
        screen.toggleButtonWasPressed()
        defer { captioner.stop() }
        connectionBecomes(.disconnected)
        connectionBecomes(.healthy)
        screen.toggleButtonWasPressed()

        connectionBecomes(.disconnected)
        captioner.start()

        #expect(screen.pausedSince == nil)
    }

    @Test func flagTurnedOnMidOutageWaitsForTheNextDrop() {
        flags.dropAlerts = false
        screen.toggleButtonWasPressed()
        defer { captioner.stop() }
        connectionBecomes(.disconnected)

        flags.dropAlerts = true
        #expect(!screen.showsPausedStatus)
        connectionBecomes(.healthy)
        #expect(screen.items.isEmpty)

        connectionBecomes(.disconnected)
        #expect(screen.showsPausedStatus)
        #expect(analytics.events.count(where: { $0 == .pausedStatusWasShown }) == 1)
    }

    @Test func wallClockJumpsDoNotChangeTheMissedTime() {
        screen.toggleButtonWasPressed()
        defer { captioner.stop() }
        connectionBecomes(.disconnected)

        clock.advance(by: 40)
        clock.jumpWallClock(by: -3600)
        connectionBecomes(.healthy)

        #expect(screen.gaps.first?.duration == .seconds(40))
    }
}
