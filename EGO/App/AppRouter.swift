import SwiftUI

/// Navigation root: onboarding gate, then the main tab bar.
struct AppRouter: View {
    let di: DIContainer
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        if hasCompletedOnboarding {
            MainTabView(di: di)
        } else {
            OnboardingView(di: di) { hasCompletedOnboarding = true }
        }
    }
}

private struct MainTabView: View {
    let di: DIContainer

    var body: some View {
        TabView {
            HomeView(di: di)
                .tabItem { Label("tab.home", systemImage: "house.fill") }
            StudyView(di: di)
                .tabItem { Label("tab.study", systemImage: "book.fill") }
            StatsView(di: di)
                .tabItem { Label("tab.stats", systemImage: "chart.bar.fill") }
            PlaceholderScreen(titleKey: "tab.profile")
                .tabItem { Label("tab.profile", systemImage: "person.fill") }
        }
        .tint(DS.Colors.brandGreen)
    }
}

/// Temporary Phase 0 screen; each tab is replaced by its feature module later.
private struct PlaceholderScreen: View {
    let titleKey: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.lg) {
            Text(titleKey)
                .font(DS.Typography.display)
                .foregroundStyle(DS.Colors.textPrimary)
            Card {
                Text("placeholder.comingSoon")
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colors.textSecondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DS.Spacing.screenPadding)
        .padding(.top, DS.Spacing.xxl)
        .background(DS.Colors.bgCanvas)
    }
}

#Preview {
    AppRouter(di: .preview())
}
