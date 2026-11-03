import Testing
@testable import CoolCaptions

@MainActor struct CoolCaptionsTests {
    let analytics = AnalyticsSpy()
    let model: CoolCaptions

    init() {
        model = CoolCaptions(analytics: analytics)
    }

    @Test func settingsButtonOpensSettings() {
        model.settingsButtonWasPressed()

        #expect(model.isSettingsScreenVisible)
        #expect(analytics.events == [.settingsButtonWasPressed])
    }

    @Test func settingsChangeWhatTheCaptioningScreenDoes() {
        #expect(model.settingsScreen.preferences === model.captioningScreen.preferences)
    }

    @Test func settingsButtonFollowsAlertsFlag() {
        #expect(model.isSettingsButtonVisible)

        model.flags.dropAlerts = false

        #expect(!model.isSettingsButtonVisible)
    }

    @Test func flagsChangeWhatTheCaptioningScreenDoes() {
        #expect(model.flags === model.captioningScreen.flags)
    }
}
