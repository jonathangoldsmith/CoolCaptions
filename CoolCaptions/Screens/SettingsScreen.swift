import Foundation

@Observable class SettingsScreen {
    let analytics: Analytics
    let preferences: Preferences

    init(analytics: Analytics, preferences: Preferences) {
        self.analytics = analytics
        self.preferences = preferences
    }

    // MARK: - Options

    var vibratesWhenPaused: Bool {
        get { preferences.vibratesWhenPaused }
        set {
            preferences.vibratesWhenPaused = newValue
            analytics.track(newValue ? .vibrationWasTurnedOn : .vibrationWasTurnedOff)
        }
    }

    var announcesWithVoiceOver: Bool {
        get { preferences.announcesWithVoiceOver }
        set {
            preferences.announcesWithVoiceOver = newValue
            analytics.track(newValue ? .announcementsWereTurnedOn : .announcementsWereTurnedOff)
        }
    }

    // MARK: - View Analytics

    func viewAppeared() {
        analytics.track(.settingsScreenAppeared)
    }

    func viewDisappeared() {
        analytics.track(.settingsScreenDisappeared)
    }
}
