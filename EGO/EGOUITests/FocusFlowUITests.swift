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

        // Slice 4: a setup step now precedes the timer.
        app.buttons["Começar a focar"].tap()
        XCTAssertTrue(app.staticTexts["No que você vai focar agora?"].waitForExistence(timeout: 3))

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

        // Zero-length focus completes on the first tick → journal summary.
        let focusedLine = app.staticTexts.matching(
            NSPredicate(format: "label BEGINSWITH 'Focou'")
        ).firstMatch
        XCTAssertTrue(focusedLine.waitForExistence(timeout: 5))

        // The motivational line must resolve — a raw key leaking means the
        // dynamic lookup regressed (slice 6).
        XCTAssertEqual(
            app.staticTexts.matching(
                NSPredicate(format: "label BEGINSWITH 'summary.phrase'")
            ).count,
            0
        )
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "session-summary"
        attachment.lifetime = .keepAlways
        add(attachment)

        app.buttons["Continuar"].tap()
        XCTAssertFalse(focusedLine.waitForExistence(timeout: 1))
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
    func testQuestionPracticeShowsFeedback() throws {
        let app = XCUIApplication()
        app.launch()

        let onboardingStart = app.buttons["Começar"]
        if onboardingStart.waitForExistence(timeout: 2) {
            onboardingStart.tap()
            let skip = app.buttons["Agora não"]
            if skip.waitForExistence(timeout: 2) { skip.tap() }
        }

        app.tabBars.buttons["Estudar"].tap()
        app.buttons["Questões"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Praticar"].waitForExistence(timeout: 3))
        app.buttons["Praticar"].tap()

        let option = app.buttons["practice.option.0"]
        XCTAssertTrue(option.waitForExistence(timeout: 3))
        option.tap()

        // Feedback + explanation appear; the session can advance.
        XCTAssertTrue(app.staticTexts["Explicação"].waitForExistence(timeout: 3))
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "practice-feedback"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testEssayEditorCountsWords() throws {
        let app = XCUIApplication()
        app.launch()

        let onboardingStart = app.buttons["Começar"]
        if onboardingStart.waitForExistence(timeout: 2) {
            onboardingStart.tap()
            let skip = app.buttons["Agora não"]
            if skip.waitForExistence(timeout: 2) { skip.tap() }
        }

        app.tabBars.buttons["Estudar"].tap()
        app.buttons["Redação"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Nova redação"].waitForExistence(timeout: 3))
        app.buttons["Nova redação"].tap()

        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 3))
        editor.tap()
        editor.typeText("Escrever bem exige treino diário")

        XCTAssertTrue(
            app.staticTexts.matching(
                NSPredicate(format: "label CONTAINS 'palavras'")
            ).firstMatch.waitForExistence(timeout: 3)
        )
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "essay-editor"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testRedesignHomeSettingsPaywallProfile() throws {
        let app = XCUIApplication()
        app.launch()

        let onboardingStart = app.buttons["Começar"]
        if onboardingStart.waitForExistence(timeout: 2) {
            onboardingStart.tap()
            let skip = app.buttons["Agora não"]
            if skip.waitForExistence(timeout: 2) { skip.tap() }
        }

        // Immersive Home scene.
        XCTAssertTrue(app.buttons["home.menu"].waitForExistence(timeout: 3))
        shot(app, "redesign-home")

        // Hamburger → Settings.
        app.buttons["home.menu"].tap()
        XCTAssertTrue(app.staticTexts["Ajustes"].waitForExistence(timeout: 3))
        shot(app, "redesign-settings")

        // Settings → Paywall.
        app.buttons["Assinatura"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Recomendado"].waitForExistence(timeout: 3))
        shot(app, "redesign-paywall")

        // Dismiss the settings sheet, then open Profile from the avatar.
        app.swipeDown(velocity: .fast)
        if app.buttons["home.avatar"].waitForExistence(timeout: 3) {
            app.buttons["home.avatar"].tap()
            if app.staticTexts["EGO Pro"].waitForExistence(timeout: 3) {
                shot(app, "redesign-profile")
            }
        }
    }

    @MainActor
    func testSettingsPreferenceRowsNavigate() throws {
        let app = XCUIApplication()
        app.launch()

        let onboardingStart = app.buttons["Começar"]
        if onboardingStart.waitForExistence(timeout: 2) {
            onboardingStart.tap()
            let skip = app.buttons["Agora não"]
            if skip.waitForExistence(timeout: 2) { skip.tap() }
        }

        XCTAssertTrue(app.buttons["home.menu"].waitForExistence(timeout: 3))
        app.buttons["home.menu"].tap()
        XCTAssertTrue(app.staticTexts["Ajustes"].waitForExistence(timeout: 3))

        // Each preference row must be tappable and push a detail screen.
        for row in ["Timer", "Música e sons", "Sistema"] {
            let button = app.buttons[row]
            XCTAssertTrue(button.waitForExistence(timeout: 3), "Row \(row) missing")
            button.tap()
            // The placeholder detail shows the "coming soon" copy.
            XCTAssertTrue(
                app.staticTexts["Este recurso chega em breve."].waitForExistence(timeout: 3),
                "Row \(row) did not navigate"
            )
            app.navigationBars.buttons.element(boundBy: 0).tap() // back
            XCTAssertTrue(app.staticTexts["Ajustes"].waitForExistence(timeout: 3))
        }
    }

    /// Slice 7: Settings › Notificações is a real screen (quiet hours,
    /// category toggles, test fire).
    @MainActor
    func testNotificationSettingsScreen() throws {
        let app = XCUIApplication()
        app.launch()

        let onboardingStart = app.buttons["Começar"]
        if onboardingStart.waitForExistence(timeout: 2) {
            onboardingStart.tap()
            let skip = app.buttons["Agora não"]
            if skip.waitForExistence(timeout: 2) { skip.tap() }
        }

        XCTAssertTrue(app.buttons["home.menu"].waitForExistence(timeout: 3))
        app.buttons["home.menu"].tap()
        XCTAssertTrue(app.staticTexts["Ajustes"].waitForExistence(timeout: 3))

        app.buttons["Notificações"].tap()
        XCTAssertTrue(app.staticTexts["Horário silencioso"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Sequência em risco"].exists)
        XCTAssertTrue(app.buttons["Testar notificação"].exists)
        shot(app, "notification-settings")
    }

    @MainActor
    func testFishingSceneRendersIdleAndRunning() throws {
        let app = XCUIApplication()
        app.launch()

        let onboardingStart = app.buttons["Começar"]
        if onboardingStart.waitForExistence(timeout: 2) {
            onboardingStart.tap()
            let skip = app.buttons["Agora não"]
            if skip.waitForExistence(timeout: 2) { skip.tap() }
        }

        // Slice 4: setup step (scenery + config), then the running scene.
        app.buttons["Começar a focar"].tap()
        XCTAssertTrue(app.staticTexts["No que você vai focar agora?"].waitForExistence(timeout: 3))
        shot(app, "focus-setup")

        app.buttons["Iniciar"].tap()
        XCTAssertTrue(app.buttons["Pausar"].waitForExistence(timeout: 3))
        sleep(1)
        shot(app, "fishing-running")
    }

    /// Tapping "Concluir" and confirming in the native dialog ends the focus
    /// early and lands on the journal summary (slice 6 regression net).
    @MainActor
    func testFinishEarlyShowsSummary() throws {
        let app = launchToTimer()
        app.buttons["Concluir"].tap()

        // The identifier lands on more than one node of the dialog's
        // hierarchy — firstMatch resolves it; label lookup is the fallback.
        var confirm = app.buttons["finish.confirm"].firstMatch
        if !confirm.waitForExistence(timeout: 2) {
            confirm = app.buttons["Encerrar"].firstMatch
        }
        XCTAssertTrue(confirm.waitForExistence(timeout: 3))
        shot(app, "finish-dialog")
        confirm.tap()

        let endedLine = app.staticTexts.matching(
            NSPredicate(format: "label BEGINSWITH 'Foco encerrado após'")
        ).firstMatch
        XCTAssertTrue(endedLine.waitForExistence(timeout: 3))
        shot(app, "summary-ended-early")

        app.buttons["Continuar"].tap()
        XCTAssertTrue(app.buttons["Começar a focar"].waitForExistence(timeout: 3))
    }

    /// Shared path: Home → setup → running timer.
    @MainActor
    private func launchToTimer() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        let onboardingStart = app.buttons["Começar"]
        if onboardingStart.waitForExistence(timeout: 2) {
            onboardingStart.tap()
            let skip = app.buttons["Agora não"]
            if skip.waitForExistence(timeout: 2) { skip.tap() }
        }
        app.buttons["Começar a focar"].tap()
        XCTAssertTrue(app.staticTexts["No que você vai focar agora?"].waitForExistence(timeout: 3))
        app.buttons["Iniciar"].tap()
        XCTAssertTrue(app.buttons["Pausar"].waitForExistence(timeout: 3))
        return app
    }

    @MainActor
    private func shot(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testRepertorioScreenRenders() throws {
        let app = XCUIApplication()
        app.launch()

        let onboardingStart = app.buttons["Começar"]
        if onboardingStart.waitForExistence(timeout: 2) {
            onboardingStart.tap()
            let skip = app.buttons["Agora não"]
            if skip.waitForExistence(timeout: 2) { skip.tap() }
        }

        app.tabBars.buttons["Estudar"].tap()
        app.buttons["Redação"].firstMatch.tap()

        // Repertório is a card link on the essay home.
        let entry = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Repertório'")
        ).firstMatch
        XCTAssertTrue(entry.waitForExistence(timeout: 3))
        entry.tap()

        XCTAssertTrue(app.staticTexts["Revisar hoje"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Cards"].exists)

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "repertorio-list"
        attachment.lifetime = .keepAlways
        add(attachment)

        // Flip a card open to confirm the browse interaction renders the verso.
        let card = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'dignidade'")
        ).firstMatch
        if card.waitForExistence(timeout: 2) {
            card.tap()
            let flipped = XCTAttachment(screenshot: app.screenshot())
            flipped.name = "repertorio-card-flipped"
            flipped.lifetime = .keepAlways
            add(flipped)
        }
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
