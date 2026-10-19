import SwiftUI

/// Subscription screen (F — monetization). UI only: no StoreKit/RevenueCat yet,
/// so purchase actions show an "Em breve" toast. Reached from Settings and the
/// profile "Pro" badge.
struct PaywallView: View {
    @State private var selectedPlanID = "annual"
    @State private var showingComingSoon = false

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: DS.Spacing.lg) {
                    hero
                    header
                    plans
                    featureList
                    footer
                }
                .padding(.bottom, DS.Spacing.xxxl)
            }
            .background(DS.Colors.bgCanvas)
            .ignoresSafeArea(edges: .top)

            ctaBar
        }
        .overlay(alignment: .top) { comingSoonToast }
        .animation(.easeInOut(duration: 0.2), value: showingComingSoon)
    }

    // MARK: - Hero

    private var hero: some View {
        ZStack(alignment: .bottom) {
            ForestSceneView()
                .frame(height: 240)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [.clear, DS.Colors.bgCanvas],
                        startPoint: .center, endPoint: .bottom
                    )
                )
            MascotView(state: .idle)
                .frame(width: 120, height: 120)
                .offset(y: 30)
        }
        .frame(height: 260)
    }

    private var header: some View {
        VStack(spacing: DS.Spacing.xs) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(DS.Colors.accentStreak)
            Text("paywall.title")
                .font(DS.Typography.display)
                .foregroundStyle(DS.Colors.textPrimary)
            Text("paywall.subtitle")
                .font(DS.Typography.callout)
                .foregroundStyle(DS.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, DS.Spacing.screenPadding)
    }

    // MARK: - Plans

    private var plans: some View {
        VStack(spacing: DS.Spacing.sm) {
            ForEach(PaywallPlan.all) { plan in
                planRow(plan)
            }
        }
        .padding(.horizontal, DS.Spacing.screenPadding)
    }

    private func planRow(_ plan: PaywallPlan) -> some View {
        let selected = plan.id == selectedPlanID
        return Button {
            selectedPlanID = plan.id
        } label: {
            HStack(spacing: DS.Spacing.sm) {
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(selected ? DS.Colors.brandGreen : DS.Colors.textSecondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.titleKey)
                        .font(DS.Typography.headline)
                        .foregroundStyle(DS.Colors.textPrimary)
                    if let subtitle = plan.subtitleKey {
                        Text(subtitle)
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.Colors.accentFocus)
                    }
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 2) {
                    if plan.recommended {
                        Text("paywall.recommended")
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.Colors.textOnBrand)
                            .padding(.horizontal, DS.Spacing.xs)
                            .padding(.vertical, 2)
                            .background(DS.Colors.brandGreen, in: Capsule())
                    }
                    Text(plan.priceKey)
                        .font(DS.Typography.callout)
                        .foregroundStyle(DS.Colors.textPrimary)
                }
            }
            .padding(DS.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.Colors.bgSurface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .strokeBorder(
                        selected ? DS.Colors.brandGreen : DS.Colors.borderSubtle,
                        lineWidth: selected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Features

    private var featureList: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            ForEach(Array(PaywallPlan.features.enumerated()), id: \.offset) { _, feature in
                HStack(spacing: DS.Spacing.sm) {
                    Image(systemName: feature.icon)
                        .foregroundStyle(DS.Colors.brandGreen)
                        .frame(width: 24)
                    Text(feature.key)
                        .font(DS.Typography.callout)
                        .foregroundStyle(DS.Colors.textPrimary)
                    Spacer(minLength: 0)
                    Image(systemName: "checkmark")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.stateSuccess)
                }
            }
        }
        .padding(.horizontal, DS.Spacing.screenPadding)
    }

    private var footer: some View {
        HStack(spacing: DS.Spacing.md) {
            footerLink("paywall.terms")
            footerLink("paywall.privacy")
            footerLink("paywall.restore")
        }
        .padding(.top, DS.Spacing.xs)
    }

    private func footerLink(_ key: LocalizedStringKey) -> some View {
        Button { showComingSoon() } label: {
            Text(key)
                .font(DS.Typography.caption)
                .foregroundStyle(DS.Colors.textSecondary)
        }
    }

    // MARK: - CTA + toast

    private var ctaBar: some View {
        PrimaryButton(titleKey: "paywall.cta") { showComingSoon() }
            .padding(.horizontal, DS.Spacing.screenPadding)
            .padding(.bottom, DS.Spacing.md)
            .background(
                LinearGradient(
                    colors: [.clear, DS.Colors.bgCanvas],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()
            )
    }

    @ViewBuilder
    private var comingSoonToast: some View {
        if showingComingSoon {
            Text("paywall.comingSoon")
                .font(DS.Typography.callout)
                .foregroundStyle(DS.Colors.textPrimary)
                .padding(.horizontal, DS.Spacing.md)
                .padding(.vertical, DS.Spacing.sm)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(DS.Colors.borderSubtle, lineWidth: 1))
                .padding(.top, DS.Spacing.xxl)
                .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private func showComingSoon() {
        showingComingSoon = true
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            showingComingSoon = false
        }
    }
}

#Preview {
    PaywallView()
}
