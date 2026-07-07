import XCTest

final class RouteincomeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAddEntryFlow() throws {
        let app = XCUIApplication()
        app.launch()
        app.buttons["addEntryButton"].tap()
        let titleField = app.textFields["titleField"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap()
        titleField.typeText("UI Test Entry")
        app.textFields["amountField"].tap()
        app.textFields["amountField"].typeText("12.50")
        app.buttons["saveEntryButton"].tap()
        XCTAssertTrue(app.staticTexts["UI Test Entry"].waitForExistence(timeout: 5))
    }

    func testFreeLimitTriggersPaywall() throws {
        let app = XCUIApplication()
        app.launch()
        for i in 0..<12 {
            let addButton = app.buttons["addEntryButton"]
            if !addButton.exists { break }
            addButton.tap()
            let titleField = app.textFields["titleField"]
            if titleField.waitForExistence(timeout: 3) {
                titleField.tap()
                titleField.typeText("Entry \(i)")
                app.textFields["amountField"].tap()
                app.textFields["amountField"].typeText("5")
                app.buttons["saveEntryButton"].tap()
            } else if app.staticTexts["Routeincome Pro"].waitForExistence(timeout: 3) {
                break
            }
        }
        XCTAssertTrue(app.staticTexts["Routeincome Pro"].waitForExistence(timeout: 5))
    }

    func testKeyboardDismissOnTapOutside() throws {
        let app = XCUIApplication()
        app.launch()
        app.buttons["addEntryButton"].tap()
        let titleField = app.textFields["titleField"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap()
        titleField.typeText("Dismiss test")
        XCTAssertTrue(app.keyboards.element.exists)
        app.navigationBars.firstMatch.tap()
        XCTAssertFalse(app.keyboards.element.exists)
    }
}
