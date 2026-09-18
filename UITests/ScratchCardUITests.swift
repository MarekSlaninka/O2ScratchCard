import XCTest

@MainActor
final class ScratchCardUITests: XCTestCase {
    private let scratchDuration: TimeInterval = 2
    private let timeout: TimeInterval = 5

    override func setUp() {
        continueAfterFailure = false
    }

    func testActivationIsUnavailableBeforeScratching() {
        // Arrange
        let app = launch()

        // Assert
        XCTAssertEqual(app.buttons[.openActivation].value as? String, "Najprv zotrite kartu, aby ste odhalili kód.")

        // Act
        app.buttons[.openActivation].tap()

        // Assert
        XCTAssertTrue(app.buttons[.activateButton].waitForExistence(timeout: timeout))
        XCTAssertFalse(app.buttons[.activateButton].isEnabled)
        XCTAssertEqual(app.buttons[.activateButton].value as? String, "Najprv sa vráťte a zotrite kartu, aby ste odhalili kód.")
        XCTAssertTrue(app.element(.cardUnscratched).exists)
    }

    func testLeavingScratchScreenCancelsScratching() {
        // Arrange
        let app = launch()

        // Act
        app.buttons[.openScratch].tap()
        XCTAssertTrue(app.buttons[.scratchButton].waitForExistence(timeout: timeout))
        app.buttons[.scratchButton].tap()
        app.goBack()

        // Assert
        XCTAssertTrue(app.buttons[.openScratch].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.element(.cardUnscratched).waitForExistence(timeout: scratchDuration + timeout))

        // Act
        app.buttons[.openScratch].tap()

        // Assert
        XCTAssertTrue(app.buttons[.scratchButton].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons[.scratchButton].isEnabled)
    }

    func testScratchRevealsCodeAndEnablesActivation() {
        // Arrange
        let app = launch()

        // Act
        app.scratchCard(timeout: scratchDuration + timeout)

        // Assert
        XCTAssertFalse(app.buttons[.scratchButton].isEnabled)
        XCTAssertTrue(app.element(.cardScratched).exists)
        attachScreenshot(of: app, named: "Revealed card")

        // Act
        app.goBack()

        // Assert
        XCTAssertTrue(app.element(.cardScratched).waitForExistence(timeout: timeout))

        // Act
        app.buttons[.openActivation].tap()

        // Assert
        XCTAssertTrue(app.buttons[.activateButton].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons[.activateButton].isEnabled)
    }

    func testActivationContinuesAfterLeavingScreen() {
        // Arrange
        let app = launch(arguments: ["-uiTestActivationSucceeds"])
        app.scratchCard(timeout: scratchDuration + timeout)
        app.goBack()
        XCTAssertTrue(app.buttons[.openActivation].waitForExistence(timeout: timeout))
        app.buttons[.openActivation].tap()
        XCTAssertTrue(app.buttons[.activateButton].waitForExistence(timeout: timeout))

        // Act
        app.buttons[.activateButton].tap()
        app.goBack()

        // Assert
        XCTAssertTrue(app.buttons[.openActivation].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.element(.cardActivated).waitForExistence(timeout: timeout))

        // Act
        app.buttons[.openActivation].tap()

        // Assert
        XCTAssertTrue(app.element(.activationSuccess).waitForExistence(timeout: timeout))
        XCTAssertFalse(app.buttons[.activateButton].isEnabled)
        attachScreenshot(of: app, named: "Activated card")
    }

    func testActivationFailureIsPresentedAtRootAndCanBeRetried() {
        // Arrange
        let app = launch(arguments: ["-uiTestActivationFails"])
        app.scratchCard(timeout: scratchDuration + timeout)
        app.goBack()
        XCTAssertTrue(app.buttons[.openActivation].waitForExistence(timeout: timeout))
        app.buttons[.openActivation].tap()
        XCTAssertTrue(app.buttons[.activateButton].waitForExistence(timeout: timeout))

        // Act
        app.buttons[.activateButton].tap()
        app.goBack()

        // Assert
        let dismissButton = app.buttons.matching(identifier: .dismissActivationError).firstMatch
        XCTAssertTrue(dismissButton.waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons[.openActivation].exists)

        // Act
        dismissButton.tap()

        // Assert
        XCTAssertTrue(app.element(.cardScratched).waitForExistence(timeout: timeout))

        // Act
        app.buttons[.openActivation].tap()

        // Assert
        XCTAssertTrue(app.buttons[.activateButton].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons[.activateButton].isEnabled)
    }

    func testAccessibilityAuditAcrossCardStates() throws {
        // Arrange
        let app = launch(arguments: ["-uiTestActivationSucceeds"])

        // Act
        try audit(app)
        app.buttons[.openScratch].tap()

        // Assert
        XCTAssertTrue(app.buttons[.scratchButton].waitForExistence(timeout: timeout))
        try audit(app)

        // Act
        app.buttons[.scratchButton].tap()

        // Assert
        XCTAssertTrue(app.element(.scratchSuccess).waitForExistence(timeout: scratchDuration + timeout))
        try audit(app)
        attachScreenshot(of: app, named: "Accessibility - revealed card")

        // Act
        app.goBack()
        app.buttons[.openActivation].tap()
        try audit(app)
        app.buttons[.activateButton].tap()

        // Assert
        XCTAssertTrue(app.element(.activationSuccess).waitForExistence(timeout: timeout))
        try audit(app)
    }

    func testAccessibilityAtLargestTextSizeInDarkMode() throws {
        // Arrange
        let app = launch(arguments: ["-uiTestDarkMode", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])

        // Act
        try audit(app)
        app.scrollTo(app.buttons[.openScratch])

        // Assert
        XCTAssertTrue(app.buttons[.openScratch].isHittable)
        XCTAssertGreaterThanOrEqual(app.buttons[.openScratch].frame.height, 44)
        try audit(app)
        attachScreenshot(of: app, named: "Accessibility - largest text home")

        // Act
        app.buttons[.openScratch].tap()
        app.scrollTo(app.buttons[.scratchButton])

        // Assert
        XCTAssertTrue(app.buttons[.scratchButton].isHittable)
        try audit(app)
        attachScreenshot(of: app, named: "Accessibility - largest text scratch")
    }

    private func audit(_ app: XCUIApplication) throws {
        attachScreenshot(of: app, named: "Accessibility audit screen")
        try app.performAccessibilityAudit { issue in
            print("Accessibility audit: \(issue.detailedDescription)")
            if issue.auditType == .contrast, let element = issue.element,
               !app.scrollViews.firstMatch.frame.contains(element.frame) {
                print("Contrast measurement unavailable for partially or fully offscreen element: \(element.label)")
                return true
            }
            return false
        }
    }

    private func launch(arguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = arguments
        app.launch()
        XCTAssertTrue(app.buttons[.openScratch].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons[.openActivation].exists)
        return app
    }

    private func attachScreenshot(of app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

private extension XCUIElement {
    func tapWhenHittable(timeout: TimeInterval) {
        let predicate = NSPredicate(format: "isHittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: timeout), .completed)
        tap()
    }
}

private extension XCUIElementQuery {
    subscript(identifier: AccessibilityIdentifier) -> XCUIElement {
        self[identifier.rawValue]
    }

    func matching(identifier: AccessibilityIdentifier) -> XCUIElementQuery {
        matching(identifier: identifier.rawValue)
    }
}

private extension XCUIApplication {
    func element(_ identifier: AccessibilityIdentifier) -> XCUIElement {
        descendants(matching: .any)[identifier.rawValue]
    }

    func scrollTo(_ element: XCUIElement) {
        for _ in 0..<8 {
            if element.isHittable && scrollViews.firstMatch.frame.insetBy(dx: 0, dy: 60).contains(element.frame) { return }
            scrollViews.firstMatch.swipeUp()
        }
    }

    func goBack() {
        navigationBars.buttons.element(boundBy: 0).tap()
    }

    /// Opens the scratch screen and waits for the code to be revealed.
    func scratchCard(timeout: TimeInterval) {
        buttons[.openScratch].tapWhenHittable(timeout: timeout)
        XCTAssertTrue(buttons[.scratchButton].waitForExistence(timeout: timeout))
        buttons[.scratchButton].tap()
        XCTAssertTrue(element(.scratchSuccess).waitForExistence(timeout: timeout))
    }
}
