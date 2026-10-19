import SwiftUI
import UIKit

/// Navigation root: onboarding gate, then the main tab bar. Also hosts the
/// motivational card (notification deep link / milestones, slice 7) and the
/// focus flow the card's "Focar agora" opens — both above whatever tab is
/// active.
struct AppRouter: View {
    let di: DIContainer
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView(di: di)
            } else {
                OnboardingView(di: di) { hasCompletedOnboarding = true }
            }
        }
        // Single root cover: motivational card or the focus flow it opens —
        // never both at once (see MotivationalCardPresenter.Route).
        .fullScreenCover(item: Binding(
            get: { di.cardPresenter.route },
            set: { if $0 == nil { di.cardPresenter.coverWasDismissed() } }
        )) { route in
            switch route {
            case .card(let card):
                MotivationalCardView(viewModel: MotivationalCardViewModel(
                    card: card,
                    onFocusNow: { di.cardPresenter.requestFocusFlow() },
                    onDismiss: { di.cardPresenter.dismissCard() }
                ))
            case .focusFlow:
                FocusFlowView(
                    viewModel: di.pomodoroViewModel,
                    onMilestones: { di.cardPresenter.enqueueMilestones(from: $0) }
                )
            }
        }
    }
}

private struct MainTabView: View {
    let di: DIContainer

    init(di: DIContainer) {
        self.di = di
        Self.configureTranslucentTabBar()
    }

    var body: some View {
        TabView {
            HomeView(di: di)
                .tabItem { Label("tab.home", systemImage: "house.fill") }
            StudyView(di: di)
                .tabItem { Label("tab.study", systemImage: "book.fill") }
            StatsView(di: di)
                .tabItem { Label("tab.stats", systemImage: "chart.bar.fill") }
            ProfileView(di: di)
                .tabItem { Label("tab.profile", systemImage: "person.fill") }
        }
        .tint(DS.Colors.brandGreen)
    }

    /// Blur/translucent tab bar so the Home scene reads through it (redesign).
    private static func configureTranslucentTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        appearance.backgroundColor = UIColor(DS.Colors.bgCanvas).withAlphaComponent(0.55)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    AppRouter(di: .preview())
}
