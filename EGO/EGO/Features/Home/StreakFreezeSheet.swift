import SwiftUI

/// Freeze management sheet (docs/07 §4): shows owned freezes and lets the
/// user buy one with coins. Opened by tapping the streak badge on Home.
struct StreakFreezeSheet: View {
    @Bindable var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            Image(systemName: "snowflake")
                .font(DS.Typography.display)
                .foregroundStyle(DS.Colors.accentFocus)

            Text("freeze.title")
                .font(DS.Typography.title)
                .foregroundStyle(DS.Colors.textPrimary)

            Text("freeze.description")
                .font(DS.Typography.callout)
                .foregroundStyle(DS.Colors.textSecondary)
                .multilineTextAlignment(.center)

            HStack(spacing: DS.Spacing.sm) {
                StatTile(
                    value: "\(viewModel.freezesAvailable)/\(viewModel.maxFreezes)",
                    labelKey: "freeze.owned"
                )
                StatTile(value: "\(viewModel.coins)", labelKey: "stats.coins")
            }

            if let error = viewModel.freezePurchaseError {
                Text(errorKey(for: error))
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.stateDanger)
            }

            PrimaryButton(titleKey: "freeze.buy \(viewModel.freezePrice)") {
                viewModel.buyFreeze()
            }
            .disabled(!viewModel.canBuyFreeze)
            .opacity(viewModel.canBuyFreeze ? 1 : 0.5)
        }
        .padding(.horizontal, DS.Spacing.screenPadding)
        .padding(.vertical, DS.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.Colors.bgCanvas)
    }

    private func errorKey(for error: StreakFreezeService.PurchaseError) -> LocalizedStringKey {
        switch error {
        case .insufficientCoins: "freeze.insufficientCoins"
        case .freezeCapReached: "freeze.capReached"
        }
    }
}

#Preview {
    StreakFreezeSheet(viewModel: DIContainer.preview().makeHomeViewModel())
}
