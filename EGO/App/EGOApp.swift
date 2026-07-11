import SwiftUI
import SwiftData

@main
struct EGOApp: App {
    private let di: DIContainer
    @Environment(\.scenePhase) private var scenePhase

    init() {
        #if DEBUG
        // UI-test hook: run onboarding from scratch.
        if ProcessInfo.processInfo.arguments.contains("-ui-test-reset-onboarding") {
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        }
        #endif
        di = DIContainer(modelContainer: PersistenceController.makeAppContainer())
    }

    var body: some Scene {
        WindowGroup {
            AppRouter(di: di)
                .onChange(of: scenePhase) { _, phase in
                    // Re-plan notifications whenever the app leaves the
                    // foreground, so pending nudges reflect today's state.
                    if phase == .background {
                        di.performBackgroundMaintenance()
                        Task { await di.notificationService.refreshSchedules() }
                    }
                }
        }
        .modelContainer(di.modelContainer)
    }
}
