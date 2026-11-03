import Foundation

@Observable class CaptioningScreen {
    let analytics: Analytics
    let connection: Connection
    let captioner: Captioner
    let preferences: Preferences
    let flags: FeatureFlags
    let platform: Platform

    init(
        analytics: Analytics, connection: Connection, captioner: Captioner,
        preferences: Preferences, flags: FeatureFlags, platform: Platform = Platform()
    ) {
        self.analytics = analytics
        self.connection = connection
        self.captioner = captioner
        self.preferences = preferences
        self.flags = flags
        self.platform = platform
    }

    // MARK: - Properties

    var captions: [Caption] {
        captioner.captions
    }

    var toggleButtonTitle: String {
        captioner.isRunning ? "Stop" : "Start"
    }

    var isPaused: Bool {
        captioner.isRunning && connection.status == .disconnected
    }

    var showsPausedStatus: Bool {
        flags.dropAlerts && isPaused
    }

    private(set) var gaps: [Gap] = []

    /// Goes up by one for each buzz. The view plays a buzz each time it changes.
    private(set) var hapticTrigger = 0

    /// The captions and gaps in time order. A caption comes before a gap that starts at the same time.
    var items: [DisplayItem] {
        var items: [DisplayItem] = []
        var gaps = flags.dropAlerts && flags.gapMarkers ? gaps[...] : []

        for caption in captions {
            while let gap = gaps.first, gap.start < caption.date {
                items.append(.gap(gap))
                gaps.removeFirst()
            }
            items.append(.caption(caption))
        }

        return items + gaps.map(DisplayItem.gap)
    }

    // MARK: - Wording

    func markerText(missed duration: Duration) -> String {
        "Missed \(wording(for: duration, width: .abbreviated)) (no connection)"
    }

    /// Spells the units out, because VoiceOver reads "1 min" less clearly than "1 minute".
    func markerLabel(missed duration: Duration) -> String {
        "Missed \(wording(for: duration, width: .wide)). No connection."
    }

    private func wording(for duration: Duration, width: Duration.UnitsFormatStyle.UnitWidth) -> String {
        duration.formatted(.units(allowed: [.hours, .minutes, .seconds], width: width).locale(platform.locale))
    }

    // MARK: - Analytics

    func viewAppeared() {
        analytics.track(.captioningScreenAppeared)
    }

    func viewDisappeared() {
        analytics.track(.captioningScreenDisappeared)
    }

    func toggleButtonWasPressed() {
        analytics.track(.captioningToggleButtonWasPressed)
        captioner.isRunning ? captioner.stop() : captioner.start()
        recordGap()
    }

    func connectionStatusChanged() {
        recordGap()
    }

    // MARK: - Gap Tracking

    /// True when Stop closed the last gap and its outage is still going,
    /// so pressing Start again continues that gap instead of opening a new one.
    private var canReopenLastGap = false

    /// Opens a gap when captions pause, and closes it when they stop being paused.
    private func recordGap() {
        let isGapOpen = gaps.last.map { $0.end == nil } ?? false
        if connection.status != .disconnected {
            canReopenLastGap = false
        }

        if isPaused, !isGapOpen {
            if canReopenLastGap {
                gaps[gaps.count - 1].end = nil
            } else {
                gaps.append(Gap(id: UUID(), start: platform.now()))
                if flags.dropAlerts, preferences.vibratesWhenPaused {
                    hapticTrigger += 1
                }
            }
            analytics.track(.captionGapStarted)
            if flags.dropAlerts {
                // Marks which drops the user was shown, so the test groups can be told apart.
                analytics.track(.pausedStatusWasShown)
            }
            if flags.dropAlerts, preferences.announcesWithVoiceOver {
                platform.announce("Captions paused. No connection. Reconnecting automatically.")
            }
        } else if !isPaused, isGapOpen {
            let end = platform.now()
            gaps[gaps.count - 1].end = end
            analytics.track(.captionGapEnded)

            if captioner.isRunning, flags.dropAlerts, preferences.announcesWithVoiceOver {
                let missed = Duration.seconds(end.timeIntervalSince(gaps[gaps.count - 1].start))
                platform.announce("Captions resumed. Missed \(wording(for: missed, width: .wide)).")
            }
            canReopenLastGap = connection.status == .disconnected
        }
    }
}
