import XCTest

final class FamilyMeetUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment["FM_STATE_NAME"] = "state"
    }

    func testOnboardingPrefillAndScreenshot() {
        app.launch()

        // Toggle adult confirmation
        let adultToggle = app.switches["onboarding.adultToggle"]
        if adultToggle.waitForExistence(timeout: 5) {
            adultToggle.tap()
        }

        // Continue to info step
        let continueBtn = app.buttons["onboarding.continue"]
        XCTAssertTrue(continueBtn.waitForExistence(timeout: 3))
        continueBtn.tap()

        // Verify prefilled fields
        let names = app.textFields["onboarding.names"]
        let city = app.textFields["onboarding.city"]
        let kids = app.textFields["onboarding.kids"]
        let interests = app.textFields["onboarding.interestsText"]

        XCTAssertTrue(names.waitForExistence(timeout: 5))
        XCTAssertEqual(names.value as? String, "Alex & Jamie")
        XCTAssertEqual(kids.value as? String, "2 and 5")
        // City is intentionally empty in test state
        XCTAssertTrue((city.value as? String)?.isEmpty ?? false)
        XCTAssertEqual(interests.value as? String, "Parks, Playdates")

        // Screenshot
        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = "Onboarding_InfoStep"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

