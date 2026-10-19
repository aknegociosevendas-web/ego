import SwiftUI

/// Home tab: the mascot lives here (F-13), now inside an immersive forest scene
/// (redesign). Same state/VM — only the presentation changed.
struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @State private var showingTimer = false
    @State private var showingFreezeSheet = false
    @State private var showingSettings = false
    @State private var showingProfile = false
    private let di: DIContainer

    init(di: DIContainer) {
        self.di = di
        _viewModel = State(initialValue: di.makeHomeViewModel())
    }

    var body: some View {
        ZStack {
            ForestSceneView()
                .ignoresSafeArea()

            // Frog registered with the scene's rock (both in full-screen
            // coordinates, so it truly sits on it).
            GeometryReader { geo in
                MascotView(state: viewModel.mascotState)
                    .frame(width: geo.size.width * 0.44, height: geo.size.width * 0.44)
                    .position(x: geo.size.width * 0.5, y: geo.size.height * 0.52)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // Top bar (safe area).
            VStack {
                AppTopBar(
                    streak: viewModel.currentStreak,
                    level: viewModel.level,
                    onMenu: { showingSettings = true },
                    onAvatar: { showingProfile = true },
                    onStreak: { showingFreezeSheet = true }
                )
                Spacer()
            }
            .padding(.horizontal, DS.Spacing.screenPadding)
            .padding(.vertical, DS.Spacing.lg)

            // Phrase + stats + CTA, anchored to the bottom (safe area).
            VStack(spacing: DS.Spacing.md) {
                Spacer()

                Text("home.mascotPhrase")
                    .font(DS.Typography.headline)
                    .foregroundStyle(DS.Colors.textPrimary)
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.vertical, DS.Spacing.xs)
                    .background(.ultraThinMaterial, in: Capsule())

                HStack(spacing: DS.Spacing.sm) {
                    GlassCard {
                        statContent(value: "\(viewModel.todayFocusMinutes) min", labelKey: "home.todayFocus")
                    }
                    GlassCard {
                        statContent(value: "\(viewModel.level)", labelKey: "home.level")
                    }
                }

                PrimaryButton(titleKey: "home.startSession") {
                    showingTimer = true
                }
            }
            .padding(.horizontal, DS.Spacing.screenPadding)
            .padding(.vertical, DS.Spacing.lg)
        }
        .fullScreenCover(isPresented: $showingTimer) {
            // Shared VM (slice 7): the card's "Focar agora" flow drives the
            // same timer state.
            FocusFlowView(
                viewModel: di.pomodoroViewModel,
                onMilestones: { di.cardPresenter.enqueueMilestones(from: $0) }
            )
        }
        .sheet(isPresented: $showingFreezeSheet, onDismiss: { viewModel.refresh() }) {
            StreakFreezeSheet(viewModel: viewModel)
                .presentationDetents([.medium])
                .presentationCornerRadius(DS.Radius.sheet)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(di: di)
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView(di: di, onClose: { showingProfile = false })
        }
        .onChange(of: showingTimer) { _, isShowing in
            if !isShowing { viewModel.refresh() }
        }
        .onAppear {
            viewModel.refresh()
        }
    }

    private func statContent(value: String, labelKey: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
            Text(value)
                .font(DS.Typography.title)
                .foregroundStyle(DS.Colors.textPrimary)
            Text(labelKey)
                .font(DS.Typography.caption)
                .foregroundStyle(DS.Colors.textSecondary)
        }
    }
}

#Preview {
    HomeView(di: .preview())
}
