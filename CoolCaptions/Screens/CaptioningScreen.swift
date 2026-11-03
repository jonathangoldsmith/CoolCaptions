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

        connection.statusDidChange = { [weak self] in self?.recordGap() }
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
        flags.dropAlerts && openGap?.showsAlert == true
    }

    /// When the open gap started, for the status timer. Start during an outage keeps the first start.
    var pausedSince: Date? {
        showsPausedStatus ? openGap?.start : nil
    }

    private var openGap: Gap? {
        gaps.last.flatMap { $0.isOpen ? $0 : nil }
    }

    private(set) var gaps: [Gap] = []

    /// Goes up by one for each buzz. The view plays a buzz each time it changes.
    private(set) var hapticTrigger = 0

    /// The captions and finished gaps in time order. A caption comes before a gap that starts at the same time.
    /// An open gap shows as the paused status instead.
    var items: [DisplayItem] {
        var items: [DisplayItem] = []
        let showsMarkers = flags.dropAlerts && flags.gapMarkers
        var gaps = showsMarkers ? gaps.filter { $0.showsAlert && !$0.isOpen }[...] : []

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

    /// Announced when captions pause, and used as the paused status's VoiceOver label.
    static let pausedMessage = String(
        localized: "Captions paused. No connection. Reconnecting automatically.",
        comment: "VoiceOver announcement when captions stop because the connection dropped."
    )

    func markerText(missed duration: Duration) -> String {
        String(
            localized: "Missed \(wording(for: duration, width: .abbreviated)) (no connection)",
            comment: "Transcript marker. The placeholder is how long captions were paused, such as 1 min, 12 sec."
        )
    }

    /// Spells the units out, because VoiceOver reads "1 min" less clearly than "1 minute".
    func markerLabel(missed duration: Duration) -> String {
        String(
            localized: "Missed \(wording(for: duration, width: .wide)). No connection.",
            comment: "VoiceOver label for the transcript marker. The placeholder is how long captions were paused, such as 1 minute, 12 seconds."
        )
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

    // MARK: - Gap Tracking

    /// True when Stop closed the last gap and its outage is still going,
    /// so pressing Start again continues that gap instead of opening a new one.
    private var canReopenLastGap = false

    /// Opens a gap when captions pause, and closes it when they stop being paused.
    private func recordGap() {
        if connection.status != .disconnected {
            canReopenLastGap = false
        }

        if isPaused, openGap == nil {
            if canReopenLastGap {
                gaps[gaps.count - 1].end = nil
                gaps[gaps.count - 1].duration = nil
                gaps[gaps.count - 1].showsAlert = flags.dropAlerts
            } else {
                gaps.append(Gap(
                    id: UUID(), start: platform.now(), startInstant: platform.instant(), showsAlert: flags.dropAlerts
                ))
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
                platform.announce(Self.pausedMessage)
            }
        } else if !isPaused, openGap != nil {
            gaps[gaps.count - 1].end = platform.now()
            gaps[gaps.count - 1].duration = platform.instant() - gaps[gaps.count - 1].startInstant
            analytics.track(.captionGapEnded)

            if captioner.isRunning, flags.dropAlerts, preferences.announcesWithVoiceOver,
               let missed = gaps[gaps.count - 1].duration {
                platform.announce(String(
                    localized: "Captions resumed. Missed \(wording(for: missed, width: .wide)).",
                    comment: "VoiceOver announcement when captions come back. The placeholder is how long they were paused, such as 1 minute, 12 seconds."
                ))
            }
            canReopenLastGap = connection.status == .disconnected
        }
    }
}
