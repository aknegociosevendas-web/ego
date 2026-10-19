import SwiftUI

/// Static paywall plan data (view-only; no StoreKit/RevenueCat yet).
/// Prices are placeholders until billing is wired.
struct PaywallPlan: Identifiable, Equatable {
    let id: String
    let titleKey: LocalizedStringKey
    let priceKey: LocalizedStringKey
    let subtitleKey: LocalizedStringKey?
    let recommended: Bool

    static let all: [PaywallPlan] = [
        PaywallPlan(
            id: "monthly",
            titleKey: "paywall.plan.monthly",
            priceKey: "paywall.price.monthly",
            subtitleKey: nil,
            recommended: false
        ),
        PaywallPlan(
            id: "annual",
            titleKey: "paywall.plan.annual",
            priceKey: "paywall.price.annual",
            subtitleKey: "paywall.trial",
            recommended: true
        ),
        PaywallPlan(
            id: "lifetime",
            titleKey: "paywall.plan.lifetime",
            priceKey: "paywall.price.lifetime",
            subtitleKey: nil,
            recommended: false
        ),
    ]

    /// Pro benefits list.
    static let features: [(icon: String, key: LocalizedStringKey)] = [
        ("person.3.fill", "paywall.feature.characters"),
        ("timer", "paywall.feature.timer"),
        ("chart.bar.fill", "paywall.feature.stats"),
        ("hand.raised.slash.fill", "paywall.feature.noads"),
    ]
}
