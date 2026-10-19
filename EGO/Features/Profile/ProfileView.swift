import SwiftUI

/// Quick profile / stats view (redesign). Read-only: reuses `StatsViewModel`
/// (no new logic). Hosts the "Pro" badge that opens the paywall. Used both as
/// the Perfil tab and as a sheet from the Home avatar.
struct ProfileView: View {
    @State private var viewModel: StatsViewModel
    @State private var showingPaywall = false
    /// Set when presented as a sheet (adds a close button).
    var onClose: (() -> Void)?

    init(di: DIContainer, onClose: (() -> Void)? = nil) {
        _viewModel = State(initialValue: di.makeStatsViewModel())
        self.onClose = onClose
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.lg) {
                    headerCard
                    statsGrid
                }
                .padding(.horizontal, DS.Spacing.screenPadding)
                .padding(.vertical, DS.Spacing.lg)
            }
            .background(DS.Colors.bgCanvas)
            .navigationTitle(Text("profile.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if onClose != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { onClose?() } label: {
                            Image(systemName: "xmark").foregroundStyle(DS.Colors.textSecondary)
                        }
                        .accessibilityLabel(Text("timer.close"))
                    }
                }
            }
            .sheet(isPresented: $showingPaywall) { PaywallView() }
            .onAppear { viewModel.refresh() }
        }
    }

    private var headerCard: some View {
        VStack(spacing: DS.Spacing.sm) {
            MascotView(state: .idle)
                .frame(width: 120, height: 120)
            HStack(spacing: DS.Spacing.xs) {
                Text("profile.level \(viewModel.level)")
                    .font(DS.Typography.title)
                    .foregroundStyle(DS.Colors.textPrimary)
            }
            Button { showingPaywall = true } label: {
                HStack(spacing: DS.Spacing.xxs) {
                    Image(systemName: "star.circle.fill")
                    Text("profile.proBadge")
                }
                .font(DS.Typography.callout)
                .foregroundStyle(DS.Colors.textOnBrand)
                .padding(.horizontal, DS.Spacing.md)
                .padding(.vertical, DS.Spacing.xs)
                .background(DS.Colors.accentStreak, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }

    private var statsGrid: some View {
        VStack(spacing: DS.Spacing.sm) {
            HStack(spacing: DS.Spacing.sm) {
                StatTile(value: focusText, labelKey: "profile.focusTotal")
                StatTile(value: "\(viewModel.currentStreak)", labelKey: "profile.streak")
            }
            HStack(spacing: DS.Spacing.sm) {
                StatTile(value: "\(viewModel.xp)", labelKey: "profile.xp")
                StatTile(value: "\(viewModel.coins)", labelKey: "profile.coins")
            }
        }
    }

    private var focusText: String {
        let h = viewModel.totalFocusMinutes / 60
        let m = viewModel.totalFocusMinutes % 60
        return h > 0 ? "\(h)h \(m)min" : "\(m)min"
    }
}

#Preview {
    ProfileView(di: .preview())
}
