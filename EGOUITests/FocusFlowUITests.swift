import XCTest

/// Smoke test for the core habit loop: Home → timer → start focus.
final class FocusFlowUITests: XCTestCase {
    @MainActor
    func testStartFocusSessionFromHome() throws {
        let app = XCUIApplication()
        app.launch()

        // First run may still show onboarding.
        let onboardingStart = app.buttons["Começar"]
        if onboardingStart.waitForExistence(timeout: 2) {
            onboardingStart.tap()
        }

        app.buttons["Começar a focar"].tap()
        XCTAssertTrue(app.staticTexts["25:00"].waitForExistence(timeout: 3))

        app.buttons["Iniciar"].tap()
        XCTAssertTrue(app.buttons["Pausar"].waitForExistence(timeout: 3))

        sleep(2)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "focus-running"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testSessionSummaryAppearsAfterCompletion() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-test-short-focus"]
        app.launch()

        let onboardingStart = app.buttons["Começar"]
        if onboardingStart.waitForExistence(timeout: 2) {
            onboardingStart.tap()
        }

        app.buttons["Começar a focar"].tap()
        app.buttons["Iniciar"].tap()

        // Zero-length focus completes on the first tick → summary sheet.
        XCTAssertTrue(app.staticTexts["Sessão concluída!"].waitForExistence(timeout: 5))
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "session-summary"
        attachment.lifetime = .keepAlways
        add(attachment)

        app.buttons["Continuar"].tap()
        XCTAssertFalse(app.staticTexts["Sessão concluída!"].waitForExistence(timeout: 1))
    }

    @MainActor
    func testOnboardingNotificationOptIn() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-test-reset-onboarding"]
        app.launch()

        app.buttons["Começar"].tap()
        XCTAssertTrue(app.staticTexts["Posso te lembrar de estudar?"].waitForExistence(timeout: 3))

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "onboarding-notifications"
        attachment.lifetime = .keepAlways
        add(attachment)

        app.buttons["Ativar lembretes"].tap()

        // System permission alert lives in Springboard.
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allow = springboard.buttons["Allow"].exists
            ? springboard.buttons["Allow"]
            : springboard.buttons["Permitir"]
        if allow.waitForExistence(timeout: 3) {
            allow.tap()
        }

        XCTAssertTrue(app.buttons["Começar a focar"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testFreezeSheetOpensFromStreakBadge() throws {
        let app = XCUIApplication()
        app.launch()

        let onboardingStart = app.buttons["Começar"]
        if onboardingStart.waitForExistence(timeout: 2) {
            onboardingStart.tap()
            let skip = app.buttons["Agora não"]
            if skip.waitForExistence(timeout: 2) { skip.tap() }
        }

        let badge = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Sequência de'")
        ).firstMatch
        XCTAssertTrue(badge.waitForExistence(timeout: 3))
        badge.tap()

        XCTAssertTrue(app.staticTexts["Freeze de sequência"].waitForExistence(timeout: 3))
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "freeze-sheet"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testLiveActivityAppearsAfterStartingFocus() throws {
        let app = XCUIApplication()
        app.launch()

        let onboardingStart = app.buttons["Começar"]
        if onboardingStart.waitForExistence(timeout: 2) {
            onboardingStart.tap()
            let skip = app.buttons["Agora não"]
            if skip.waitForExistence(timeout: 2) { skip.tap() }
        }

        app.buttons["Começar a focar"].tap()
        XCTAssertTrue(app.buttons["Iniciar"].waitForExistence(timeout: 3))
        app.buttons["Iniciar"].tap()

        // Leave the app so the Live Activity takes over the Dynamic Island.
        XCUIDevice.shared.press(.home)
        sleep(3)

        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "live-activity-home"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testStudyTabCreatesRoutineFromTemplate() throws {
        let app = XCUIApplication()
        app.launch()

        let onboardingStart = app.buttons["Começar"]
        if onboardingStart.waitForExistence(timeout: 2) {
            onboardingStart.tap()
            let skip = app.buttons["Agora não"]
            if skip.waitForExistence(timeout: 2) { skip.tap() }
        }

        app.tabBars.buttons["Estudar"].tap()

        // Fresh install shows the template picker; pick ENEM 6 meses.
        let template = app.buttons["ENEM 6 meses"]
        if template.waitForExistence(timeout: 3) {
            template.tap()
        }

        XCTAssertTrue(app.staticTexts["Hoje"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Semana"].exists)
        XCTAssertTrue(app.staticTexts["Metas"].exists)

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "study-tab"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testStatsTabShowsDashboard() throws {
        let app = XCUIApplication()
        app.launch()

        let onboardingStart = app.buttons["Começar"]
        if onboardingStart.waitForExistence(timeout: 2) {
            onboardingStart.tap()
        }

        app.tabBars.buttons["Estatísticas"].tap()
        XCTAssertTrue(app.staticTexts["Foco total"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Últimos 7 dias"].exists)

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "stats-dashboard"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
