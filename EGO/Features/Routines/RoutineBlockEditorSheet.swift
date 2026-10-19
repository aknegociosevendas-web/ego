import SwiftUI

/// F-05 block editor: weekday, subject, minutes, target sessions.
/// Pass `initial` to edit an existing block in place.
struct RoutineBlockEditorSheet: View {
    struct Values: Equatable {
        var weekday: Int
        var subject: String
        var minutes: Int
        var sessions: Int
    }

    private let isEditing: Bool
    var onSave: (_ weekday: Int, _ subject: String, _ minutes: Int, _ sessions: Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.calendar) private var calendar

    @State private var weekday: Int
    @State private var subject: String
    @State private var minutes: Int
    @State private var sessions: Int

    init(
        initial: Values? = nil,
        onSave: @escaping (_ weekday: Int, _ subject: String, _ minutes: Int, _ sessions: Int) -> Void
    ) {
        self.isEditing = initial != nil
        self.onSave = onSave
        _weekday = State(initialValue: initial?.weekday ?? 2)
        _subject = State(initialValue: initial?.subject ?? SubjectCatalog.presets[0])
        _minutes = State(initialValue: initial?.minutes ?? 50)
        _sessions = State(initialValue: initial?.sessions ?? 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Text(isEditing ? "blockEditor.editTitle" : "blockEditor.title")
                .font(DS.Typography.title)
                .foregroundStyle(DS.Colors.textPrimary)

            row(labelKey: "blockEditor.weekday") {
                Menu {
                    ForEach(1...7, id: \.self) { day in
                        Button { weekday = day } label: {
                            Text(verbatim: weekdayName(day))
                        }
                    }
                } label: {
                    Text(verbatim: weekdayName(weekday))
                        .font(DS.Typography.callout)
                        .foregroundStyle(DS.Colors.brandGreen)
                }
            }

            row(labelKey: "blockEditor.subject") {
                Menu {
                    ForEach(SubjectCatalog.presets, id: \.self) { preset in
                        Button { subject = preset } label: { Text(verbatim: preset) }
                    }
                } label: {
                    Text(verbatim: subject)
                        .font(DS.Typography.callout)
                        .foregroundStyle(DS.Colors.brandGreen)
                }
            }

            row(labelKey: "blockEditor.minutes") {
                Stepper(value: $minutes, in: 25...240, step: 25) {
                    Text(verbatim: "\(minutes) min")
                        .font(DS.Typography.callout)
                        .foregroundStyle(DS.Colors.textPrimary)
                        .monospacedDigit()
                }
            }

            row(labelKey: "blockEditor.sessions") {
                Stepper(value: $sessions, in: 1...8) {
                    Text(verbatim: "\(sessions)")
                        .font(DS.Typography.callout)
                        .foregroundStyle(DS.Colors.textPrimary)
                        .monospacedDigit()
                }
            }

            Spacer()

            PrimaryButton(titleKey: "blockEditor.save") {
                onSave(weekday, subject, minutes, sessions)
                dismiss()
            }
        }
        .padding(DS.Spacing.screenPadding)
        .background(DS.Colors.bgCanvas)
    }

    private func weekdayName(_ weekday: Int) -> String {
        let symbols = calendar.standaloneWeekdaySymbols
        let index = weekday - 1
        return symbols.indices.contains(index) ? symbols[index].capitalized : "\(weekday)"
    }

    private func row(labelKey: LocalizedStringKey, @ViewBuilder content: () -> some View) -> some View {
        HStack {
            Text(labelKey)
                .font(DS.Typography.callout)
                .foregroundStyle(DS.Colors.textSecondary)
            Spacer()
            content()
        }
        .padding(.vertical, DS.Spacing.xxs)
    }
}
