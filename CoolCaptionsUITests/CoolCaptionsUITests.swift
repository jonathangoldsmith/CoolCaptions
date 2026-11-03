import XCTest

/// Drives the drop flow through the Debug sheet, the way a tester would by hand.
@MainActor final class CoolCaptionsUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUp() async throws {
        continueAfterFailure = false
        app.launch()
    }

    func testDropShowsPausedStatusThenOneMarker() {
        app.buttons["Start"].tap()

        setConnection(to: "Disconnected")
        XCTAssertTrue(element("pausedStatus").waitForExistence(timeout: 5))

        setConnection(to: "Healthy")
        XCTAssertTrue(element("gapMarker").waitForExistence(timeout: 5))
        XCTAssertFalse(element("pausedStatus").exists)
        XCTAssertTrue(element("gapMarker").label.hasPrefix("Missed"))
    }

    func testRestartingDuringADropKeepsOneMarker() {
        app.buttons["Start"].tap()
        setConnection(to: "Disconnected")

        app.buttons["Stop"].tap()
        app.buttons["Start"].tap()
        XCTAssertTrue(element("pausedStatus").waitForExistence(timeout: 5))

        setConnection(to: "Healthy")
        XCTAssertTrue(element("gapMarker").waitForExistence(timeout: 5))
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "gapMarker").count, 1)
    }

    func testSettingsButtonOpensSettings() {
        app.buttons["Settings"].tap()

        XCTAssertTrue(app.switches["Vibrate"].waitForExistence(timeout: 5))
        // The subtitle is read as part of the label: "Announce with VoiceOver, Only when VoiceOver is on".
        XCTAssertTrue(app.switches.matching(NSPredicate(format: "label BEGINSWITH 'Announce with VoiceOver'")).firstMatch.exists)
    }

    func testDropAlertsFlagOffHidesStatusAndSettings() {
        app.buttons["Start"].tap()
        app.buttons["Debug"].tap()
        turnOff(app.switches["Drop alerts"])
        closeSheet()

        setConnection(to: "Disconnected")

        XCTAssertFalse(app.buttons["Settings"].exists)
        XCTAssertFalse(element("pausedStatus").waitForExistence(timeout: 2))
    }

    // TEMPORARY: holds each state for manual screenshots. Remove before committing.
    func testZZHoldStatesForManualChecks() {
        app.buttons["Start"].tap()
        sleep(6)
        setConnection(to: "Disconnected")
        print("HOLD PAUSED")
        sleep(15)
        setConnection(to: "Healthy")
        sleep(3)
        print("HOLD MARKER")
        sleep(15)
    }

    // MARK: -

    func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    func setConnection(to status: String) {
        app.buttons["Debug"].tap()
        let picker = app.buttons["connectionPicker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        picker.tap()
        app.buttons[status].firstMatch.tap()
        closeSheet()
    }

    func turnOff(_ toggle: XCUIElement) {
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        // Tap the switch itself, at the right-hand end of the row.
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        XCTAssertEqual(toggle.value as? String, "0")
    }

    /// The half-height sheet floats as a card, so tap the dimmed area above it, as a person would.
    func closeSheet() {
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3)).tap()
        XCTAssertTrue(app.navigationBars["Debug"].waitForNonExistence(timeout: 5))
    }
}
