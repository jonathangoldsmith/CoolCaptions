import Foundation

class Analytics {
    enum Event: String {
        case appBecameActive
        case appBecameInactive
        case appEnteredBackground

        case captioningScreenAppeared
        case captioningScreenDisappeared
        case captioningToggleButtonWasPressed

        case captioningStarted
        case captioningStopped
        case captionWasReceived
        case captionWasMissed

        case captionGapStarted
        case captionGapEnded

        case debugScreenAppeared
        case debugScreenDisappeared
        case debugButtonWasPressed

        case settingsButtonWasPressed
        case settingsScreenAppeared
        case settingsScreenDisappeared
        case vibrationWasTurnedOn
        case vibrationWasTurnedOff
        case announcementsWereTurnedOn
        case announcementsWereTurnedOff

        case connectionStatusBecameHealthy
        case connectionStatusBecameDegraded
        case connectionStatusBecameDisconnected
    }

    // MARK: -

    func track(_ event: Event) {
        print(Date.now, event.rawValue)
    }
}
