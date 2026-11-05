import Testing
@testable import CoolCaptions

@MainActor struct SettingsScreenTests {
    let analytics = AnalyticsSpy()
    let preferences = Preferences()
    let screen: SettingsScreen

    init() {
        screen = SettingsScreen(analytics: analytics, preferences: preferences)
    }

    @Test(arguments: [false, true])
    func vibrateSwitchWritesThroughAndLogs(isOn: Bool) {
        screen.vibratesWhenPaused = isOn

        #expect(preferences.vibratesWhenPaused == isOn)
        #expect(analytics.events == [isOn ? .vibrationWasTurnedOn : .vibrationWasTurnedOff])
    }

    @Test(arguments: [false, true])
    func announceSwitchWritesThroughAndLogs(isOn: Bool) {
        screen.announcesWithVoiceOver = isOn

        #expect(preferences.announcesWithVoiceOver == isOn)
        #expect(analytics.events == [isOn ? .announcementsWereTurnedOn : .announcementsWereTurnedOff])
    }
}
