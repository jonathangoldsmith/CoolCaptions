import SwiftUI

@Observable class CoolCaptions {
    let analytics: Analytics
    let connection: Connection
    let captioner: Captioner
    let preferences: Preferences

    let debugScreen: DebugScreen
    let settingsScreen: SettingsScreen
    let captioningScreen: CaptioningScreen

    init(analytics: Analytics = Analytics()) {
        self.analytics = analytics
        connection = Connection(analytics: analytics)
        captioner = Captioner(analytics: analytics, connection: connection)
        preferences = Preferences()
        debugScreen = DebugScreen(analytics: analytics, connection: connection)
        settingsScreen = SettingsScreen(analytics: analytics, preferences: preferences)
        captioningScreen = CaptioningScreen(
            analytics: analytics, connection: connection, captioner: captioner, preferences: preferences
        )
    }

    // MARK: -

    var isDebugScreenVisible = false
    var isSettingsScreenVisible = false

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

    func settingsButtonWasPressed() {
        analytics.track(.settingsButtonWasPressed)
        isSettingsScreenVisible = true
    }
}
