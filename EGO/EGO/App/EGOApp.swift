import SwiftUI
import SwiftData

@main
struct EGOApp: App {
    private let di: DIContainer
    @Environment(\.scenePhase) private var scenePhase

    init() {
        DS.Fonts.registerIfNeeded()
        #if DEBUG
        // UI-test hook: run onboarding from scratch.
        if ProcessInfo.processInfo.arguments.contains("-ui-test-reset-onboarding") {
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        }
        #endif
        di = DIContainer(modelContainer: PersistenceController.makeAppContainer())
        di.contentSeedService.seedIfNeeded()
        // Motivational phrase bank (slice 7): version-gated upsert seed, then
        // the delegate so notification taps land on the card presenter.
        di.phraseSeedService.seedIfNeeded()
        di.notificationDelegate.install()
    }

    var body: some Scene {
        WindowGroup {
            AppRouter(di: di)
                // Immersive redesign is dark-first; light variants stay in the
                // colorsets for a future toggle.
                .preferredColorScheme(.dark)
                .onChange(of: scenePhase) { _, phase in
                    switch phase {
                    case .background:
                        // Re-plan notifications whenever the app leaves the
                        // foreground, so pending nudges reflect today's state.
                        di.performBackgroundMaintenance()
                        Task { await di.notificationService.refreshSchedules() }
                    case .active:
                        // Morning nudge is moot once the app opens; also the
                        // anti-spam window check (slice 7).
                        Task { await di.notificationService.appDidBecomeActive() }
                    default:
                        break
                    }
                }
        }
        .modelContainer(di.modelContainer)
    }
}
