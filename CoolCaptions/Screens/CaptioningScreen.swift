import Foundation

@Observable class CaptioningScreen {
    let analytics: Analytics
    let connection: Connection
    let captioner: Captioner

    init(analytics: Analytics, connection: Connection, captioner: Captioner) {
        self.analytics = analytics
        self.connection = connection
        self.captioner = captioner
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
    }
}
