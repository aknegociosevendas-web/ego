import SwiftUI

/// F-17 skeleton: welcome + notification opt-in. The full flow (mascot pick,
/// exam target, daily goal, Screen Time permission) lands in later phases.
struct OnboardingView: View {
    @State private var viewModel: OnboardingViewModel
    var onFinish: () -> Void

    init(di: DIContainer, onFinish: @escaping () -> Void) {
        _viewModel = State(initialValue: di.makeOnboardingViewModel())
        self.onFinish = onFinish
    }

    var body: some View {
        Group {
            switch viewModel.step {
            case .welcome:
                welcomeStep
            case .notifications:
                notificationsStep
            }
        }
        .padding(.horizontal, DS.Spacing.screenPadding)
        .padding(.bottom, DS.Spacing.xl)
        .background(DS.Colors.bgCanvas)
    }

    private var welcomeStep: some View {
        VStack(spacing: DS.Spacing.md) {
            Spacer()
            MascotView(state: .idle)
                .frame(width: 180, height: 180)
            Text("onboarding.title")
                .font(DS.Typography.display)
                .foregroundStyle(DS.Colors.textPrimary)
                .multilineTextAlignment(.center)
            Text("onboarding.subtitle")
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colors.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
            PrimaryButton(titleKey: "onboarding.start") {
                viewModel.advanceToNotifications()
            }
        }
    }

    private var notificationsStep: some View {
        VStack(spacing: DS.Spacing.md) {
            Spacer()
            MascotView(state: .happy)
                .frame(width: 180, height: 180)
            Text("onboarding.notifications.title")
                .font(DS.Typography.title)
                .foregroundStyle(DS.Colors.textPrimary)
                .multilineTextAlignment(.center)
            Text("onboarding.notifications.subtitle")
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colors.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
            PrimaryButton(titleKey: "onboarding.notifications.enable") {
                Task {
                    await viewModel.enableNotifications()
                    onFinish()
                }
            }
            Button {
                onFinish()
            } label: {
                Text("onboarding.notifications.skip")
                    .font(DS.Typography.callout)
                    .foregroundStyle(DS.Colors.textSecondary)
            }
            .padding(.top, DS.Spacing.xxs)
        }
    }
}

#Preview {
    OnboardingView(di: .preview()) {}
}
