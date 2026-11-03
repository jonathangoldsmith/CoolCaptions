import SwiftUI

@Observable class CoolCaptions {
    let analytics: Analytics
    let connection: Connection
    let captioner: Captioner

    let debugScreen: DebugScreen
    let captioningScreen: CaptioningScreen

    init() {
        analytics = Analytics()
        connection = Connection(analytics: analytics)
        captioner = Captioner(analytics: analytics, connection: connection)
        debugScreen = DebugScreen(analytics: analytics, connection: connection)
        captioningScreen = CaptioningScreen(analytics: analytics, connection: connection, captioner: captioner)
    }

    // MARK: -

    var isDebugScreenVisible = false

    // MARK: -

    func scenePhaseChanged(to phase: ScenePhase) {
        switch phase {
            case .active: analytics.track(.appBecameActive)
            case .inactive: analytics.track(.appBecameInactive)
            case .background: analytics.track(.appEnteredBackground)
            @unknown default: break
        }
    }

    func debugButtonWasPressed() {
        analytics.track(.debugButtonWasPressed)
        isDebugScreenVisible.toggle()
    }
}
