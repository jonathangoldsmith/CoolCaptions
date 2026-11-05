import Foundation

@Observable class Connection {
    enum Status: String {
        case healthy
        case degraded
        case disconnected
    }

    // MARK: -

    let analytics: Analytics

    init(analytics: Analytics) {
        self.analytics = analytics
    }

    // MARK: -

    var status: Status = .healthy {
        didSet {
            statusChanged()
            statusDidChange?()
        }
    }

    /// Runs after every change, so the listener sees each one, even two that land before the next render.
    /// shortcut: one listener, the captioning screen. Use a list if a second screen needs it.
    @ObservationIgnored var statusDidChange: (@MainActor () -> Void)?

    // MARK: -

    func statusChanged() {
        switch status {
            case .healthy: analytics.track(.connectionStatusBecameHealthy)
            case .degraded: analytics.track(.connectionStatusBecameDegraded)
            case .disconnected: analytics.track(.connectionStatusBecameDisconnected)
        }
    }
}
