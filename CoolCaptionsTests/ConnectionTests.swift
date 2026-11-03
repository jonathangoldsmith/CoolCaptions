import Testing
@testable import CoolCaptions

@MainActor struct ConnectionTests {
    @Test func disconnectingLogsTheChange() {
        let analytics = AnalyticsSpy()
        let connection = Connection(analytics: analytics)

        connection.status = .disconnected

        #expect(analytics.events == [.connectionStatusBecameDisconnected])
    }
}
