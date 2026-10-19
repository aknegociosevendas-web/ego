import SwiftUI

/// Settings sheet reached from the hamburger (redesign navigation). Sections
/// are scaffolding for now — only "Assinatura" (→ paywall) and "Sobre" carry
/// real content; the rest land with their features.
struct SettingsView: View {
    let di: DIContainer
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.lg) {
                    section(titleKey: "settings.section.preferences") {
                        row(icon: "timer", titleKey: "settings.timer")
                        row(icon: "speaker.wave.2.fill", titleKey: "settings.sounds")
                        NavigationLink {
                            NotificationSettingsView(
                                notificationService: di.notificationService
                            )
                        } label: {
                            rowLabel(icon: "bell.badge.fill", titleKey: "settings.notifications")
                        }
                        .buttonStyle(.plain)
                        row(icon: "gearshape.fill", titleKey: "settings.system")
                    }
                    section(titleKey: "settings.section.more") {
                        NavigationLink {
                            PaywallView()
                        } label: {
                            rowLabel(icon: "star.circle.fill", titleKey: "settings.subscription", accent: true)
                        }
                        .buttonStyle(.plain)
                        NavigationLink {
                            AboutView()
                        } label: {
                            rowLabel(icon: "info.circle.fill", titleKey: "settings.about")
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, DS.Spacing.screenPadding)
                .padding(.vertical, DS.Spacing.lg)
            }
            .background(DS.Colors.bgCanvas)
            .navigationTitle(Text("settings.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(DS.Colors.textSecondary)
                    }
                    .accessibilityLabel(Text("timer.close"))
                }
            }
        }
    }

    private func section<Content: View>(
        titleKey: LocalizedStringKey, @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text(titleKey)
                .font(DS.Typography.caption)
                .foregroundStyle(DS.Colors.textSecondary)
            VStack(spacing: DS.Spacing.xs) { content() }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Preference row: navigates to a "coming soon" detail until the real
    /// feature lands (still tappable so the row isn't a dead end).
    private func row(icon: String, titleKey: LocalizedStringKey) -> some View {
        NavigationLink {
            SettingsPlaceholderView(icon: icon, titleKey: titleKey)
        } label: {
            rowLabel(icon: icon, titleKey: titleKey)
        }
        .buttonStyle(.plain)
    }

    private func rowLabel(
        icon: String, titleKey: LocalizedStringKey, accent: Bool = false
    ) -> some View {
        Card {
            HStack(spacing: DS.Spacing.sm) {
                Image(systemName: icon)
                    .foregroundStyle(accent ? DS.Colors.accentStreak : DS.Colors.brandGreen)
                    .frame(width: 24)
                Text(titleKey)
                    .font(DS.Typography.callout)
                    .foregroundStyle(DS.Colors.textPrimary)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.textSecondary)
            }
        }
    }
}

/// Detail shown for preference rows whose feature hasn't shipped yet.
private struct SettingsPlaceholderView: View {
    let icon: String
    let titleKey: LocalizedStringKey

    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(DS.Colors.brandGreen)
            Text(titleKey)
                .font(DS.Typography.title)
                .foregroundStyle(DS.Colors.textPrimary)
            Text("settings.comingSoon")
                .font(DS.Typography.callout)
                .foregroundStyle(DS.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, DS.Spacing.screenPadding)
        .background(DS.Colors.bgCanvas)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Minimal "Sobre" page (version + credits).
private struct AboutView: View {
    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.lg) {
                MascotView(state: .idle)
                    .frame(width: 120, height: 120)
                Text(verbatim: "EGO")
                    .font(DS.Typography.title)
                    .foregroundStyle(DS.Colors.textPrimary)
                Text("about.version \(version)")
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.textSecondary)
                Text("about.tagline")
                    .font(DS.Typography.callout)
                    .foregroundStyle(DS.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, DS.Spacing.screenPadding)
            .padding(.vertical, DS.Spacing.xxl)
        }
        .background(DS.Colors.bgCanvas)
        .navigationTitle(Text("settings.about"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView(di: .preview())
}
