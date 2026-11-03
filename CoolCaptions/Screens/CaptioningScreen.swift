import Foundation

@Observable class CaptioningScreen {
    let analytics: Analytics
    let connection: Connection
    let captioner: Captioner
    let now: () -> Date

    init(analytics: Analytics, connection: Connection, captioner: Captioner, now: @escaping () -> Date = { .now }) {
        self.analytics = analytics
        self.connection = connection
        self.captioner = captioner
        self.now = now
    }

    // MARK: -

    var captions: [Caption] {
        captioner.captions
    }

    var toggleButtonTitle: String {
        captioner.isRunning ? "Stop" : "Start"
    }

    var isPaused: Bool {
        captioner.isRunning && connection.status == .disconnected
    }

    private(set) var gaps: [Gap] = []

    /// The captions and gaps in time order. A caption comes before a gap that starts at the same time.
    var items: [DisplayItem] {
        var items: [DisplayItem] = []
        var gaps = gaps[...]

        for caption in captions {
            while let gap = gaps.first, gap.start < caption.date {
                items.append(.gap(gap))
                gaps.removeFirst()
            }
            items.append(.caption(caption))
        }

        return items + gaps.map(DisplayItem.gap)
    }

    // MARK: -

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

    // MARK: -

    /// Opens a gap when captions pause, and closes it when they stop being paused.
    private func recordGap() {
        let isGapOpen = gaps.last.map { $0.end == nil } ?? false

        if isPaused, !isGapOpen {
            gaps.append(Gap(id: UUID(), start: now()))
        } else if !isPaused, isGapOpen {
            gaps[gaps.count - 1].end = now()
        }
    }
}
