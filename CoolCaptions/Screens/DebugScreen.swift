import Foundation

@Observable class DebugScreen {
    let analytics: Analytics
    let connection: Connection
    let flags: FeatureFlags

    init(analytics: Analytics, connection: Connection, flags: FeatureFlags) {
        self.analytics = analytics
        self.connection = connection
        self.flags = flags
    }

    // MARK: -

    var connectionStatus: Connection.Status {
        get { connection.status }
        set { connection.status = newValue }
    }

    var dropAlerts: Bool {
        get { flags.dropAlerts }
        set { flags.dropAlerts = newValue }
    }

    var gapMarkers: Bool {
        get { flags.gapMarkers }
        set { flags.gapMarkers = newValue }
    }

    // MARK: -

    func viewAppeared() {
        analytics.track(.debugScreenAppeared)
    }

    func viewDisappeared() {
        analytics.track(.debugScreenDisappeared)
    }
}
