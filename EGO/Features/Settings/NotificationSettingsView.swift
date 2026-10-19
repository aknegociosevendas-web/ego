import SwiftUI
import UIKit

/// Settings › Notificações (slice 7): quiet hours, per-category toggles and a
/// test fire. Preferences persist via @AppStorage on the same keys
/// `NotificationSettingsStore` reads, so the scheduler always honors what's
/// set here. Schedules are re-planned when the screen closes.
struct NotificationSettingsView: View {
    let notificationService: NotificationService

    @AppStorage(NotificationSettingsStore.Keys.quietStartMinutes)
    private var quietStartMinutes = NotificationSettingsStore.defaultQuietStartMinutes
    @AppStorage(NotificationSettingsStore.Keys.quietEndMinutes)
    private var quietEndMinutes = NotificationSettingsStore.defaultQuietEndMinutes

    @AppStorage("notification.category.morningBoost.enabled") private var morningEnabled = true
    @AppStorage("notification.category.afternoonFocus.enabled") private var afternoonEnabled = true
    @AppStorage("notification.category.eveningWindDown.enabled") private var eveningEnabled = true
    @AppStorage("notification.category.streakAtRisk.enabled") private var streakRiskEnabled = true
    @AppStorage("notification.category.comeback.enabled") private var comebackEnabled = true
    @AppStorage("notification.category.milestone.enabled") private var milestoneEnabled = true
    @AppStorage("notification.category.sessionReminder.enabled") private var reminderEnabled = true
    @AppStorage("notification.category.generic.enabled") private var genericEnabled = true

    @State private var isAuthorized = true
    @State private var testSent = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                if !isAuthorized {
                    permissionBanner
                }

                section(titleKey: "notif.quiet.section") {
                    quietHoursCard
                }

                section(titleKey: "notif.categories.section") {
                    categoriesCard
                }

                testButton
            }
            .padding(.horizontal, DS.Spacing.screenPadding)
            .padding(.vertical, DS.Spacing.lg)
        }
        .background(DS.Colors.bgCanvas)
        .navigationTitle(Text("notif.settings.title"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            isAuthorized = await notificationService.isAuthorized()
        }
        .onDisappear {
            Task { await notificationService.refreshSchedules() }
        }
    }

    // MARK: - Permission banner

    private var permissionBanner: some View {
        Card {
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                HStack(spacing: DS.Spacing.xs) {
                    Image(systemName: "bell.slash.fill")
                        .foregroundStyle(DS.Colors.accentStreak)
                    Text("notif.permission.banner")
                        .font(DS.Typography.callout)
                        .foregroundStyle(DS.Colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("notif.permission.cta")
                        .font(DS.Typography.callout)
                        .foregroundStyle(DS.Colors.brandGreen)
                        .underline()
                }
            }
        }
    }

    // MARK: - Quiet hours

    private var quietHoursCard: some View {
        Card {
            VStack(spacing: DS.Spacing.sm) {
                quietRow(labelKey: "notif.quiet.from", minutes: $quietStartMinutes)
                Divider().overlay(DS.Colors.borderSubtle)
                quietRow(labelKey: "notif.quiet.to", minutes: $quietEndMinutes)
            }
        }
    }

    private func quietRow(labelKey: LocalizedStringKey, minutes: Binding<Int>) -> some View {
        HStack {
            Text(labelKey)
                .font(DS.Typography.callout)
                .foregroundStyle(DS.Colors.textPrimary)
            Spacer()
            DatePicker(
                selection: timeBinding(minutes),
                displayedComponents: .hourAndMinute
            ) {
                Text(labelKey)
            }
            .labelsHidden()
            .datePickerStyle(.compact)
        }
    }

    /// Minutes-since-midnight ↔ Date bridge for the compact time picker.
    private func timeBinding(_ minutes: Binding<Int>) -> Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    bySettingHour: minutes.wrappedValue / 60,
                    minute: minutes.wrappedValue % 60,
                    second: 0,
                    of: .now
                ) ?? .now
            },
            set: { date in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                minutes.wrappedValue = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
            }
        )
    }

    // MARK: - Categories

    private var categoriesCard: some View {
        Card {
            VStack(spacing: DS.Spacing.sm) {
                categoryToggle("notif.category.morningBoost", isOn: $morningEnabled)
                categoryToggle("notif.category.afternoonFocus", isOn: $afternoonEnabled)
                categoryToggle("notif.category.eveningWindDown", isOn: $eveningEnabled)
                categoryToggle("notif.category.streakAtRisk", isOn: $streakRiskEnabled)
                categoryToggle("notif.category.comeback", isOn: $comebackEnabled)
                categoryToggle("notif.category.milestone", isOn: $milestoneEnabled)
                categoryToggle("notif.category.sessionReminder", isOn: $reminderEnabled)
                categoryToggle("notif.category.generic", isOn: $genericEnabled)
            }
        }
    }

    private func categoryToggle(_ titleKey: LocalizedStringKey, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(titleKey)
                .font(DS.Typography.callout)
                .foregroundStyle(DS.Colors.textPrimary)
        }
        .tint(DS.Colors.brandGreen)
    }

    // MARK: - Test fire

    private var testButton: some View {
        VStack(spacing: DS.Spacing.xs) {
            PrimaryButton(titleKey: "notif.test.button") {
                Task {
                    if await notificationService.sendTestNotification() {
                        testSent = true
                    }
                }
            }
            if testSent {
                Text("notif.test.sent")
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.textSecondary)
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
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView(notificationService: DIContainer.preview().notificationService)
    }
}
