import SwiftUI

/// Home tab: the mascot lives here (F-13), with streak, today's progress and
/// the entry point to a focus session.
struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @State private var pomodoroViewModel: PomodoroViewModel
    @State private var showingTimer = false
    @State private var showingFreezeSheet = false

    init(di: DIContainer) {
        _viewModel = State(initialValue: di.makeHomeViewModel())
        _pomodoroViewModel = State(initialValue: di.makePomodoroViewModel())
    }

    var body: some View {
        VStack(spacing: DS.Spacing.lg) {
            HStack {
                Button {
                    showingFreezeSheet = true
                } label: {
                    StreakBadge(count: viewModel.currentStreak)
                }
                .buttonStyle(.plain)
                .accessibilityHint(Text("freeze.badgeHint"))
                Spacer()
            }

            Spacer()

            MascotView(state: viewModel.mascotState)
                .frame(width: 220, height: 220)

            Text("home.greeting")
                .font(DS.Typography.headline)
                .foregroundStyle(DS.Colors.textPrimary)

            Spacer()

            HStack(spacing: DS.Spacing.sm) {
                StatTile(value: "\(viewModel.todayFocusMinutes) min", labelKey: "home.todayFocus")
                StatTile(value: "\(viewModel.level)", labelKey: "home.level")
            }

            PrimaryButton(titleKey: "home.startSession") {
                showingTimer = true
            }
        }
        .padding(.horizontal, DS.Spacing.screenPadding)
        .padding(.vertical, DS.Spacing.lg)
        .background(DS.Colors.bgCanvas)
        .fullScreenCover(isPresented: $showingTimer) {
            FocusTimerView(viewModel: pomodoroViewModel)
        }
        .sheet(isPresented: $showingFreezeSheet, onDismiss: { viewModel.refresh() }) {
            StreakFreezeSheet(viewModel: viewModel)
                .presentationDetents([.medium])
                .presentationCornerRadius(DS.Radius.sheet)
        }
        .onChange(of: showingTimer) { _, isShowing in
            if !isShowing { viewModel.refresh() }
        }
        .onAppear {
            viewModel.refresh()
        }
    }
}

#Preview {
    HomeView(di: .preview())
}
