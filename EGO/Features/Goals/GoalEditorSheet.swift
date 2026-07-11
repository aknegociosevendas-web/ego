import SwiftUI

/// F-10 goal editor: subject, free topic, hours target, optional deadline.
struct GoalEditorSheet: View {
    var onSave: (_ subject: String, _ topic: String, _ targetHours: Double, _ deadline: Date?) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var subject = SubjectCatalog.presets[0]
    @State private var topic = ""
    @State private var targetHours = 10
    @State private var hasDeadline = false
    @State private var deadline = Date.now.addingTimeInterval(30 * 86_400)

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Text("goalEditor.title")
                .font(DS.Typography.title)
                .foregroundStyle(DS.Colors.textPrimary)

            HStack {
                Text("blockEditor.subject")
                    .font(DS.Typography.callout)
                    .foregroundStyle(DS.Colors.textSecondary)
                Spacer()
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

            TextField("goalEditor.topic.placeholder", text: $topic)
                .font(DS.Typography.body)
                .padding(DS.Spacing.sm)
                .background(DS.Colors.bgSurface)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.button))

            HStack {
                Text("goalEditor.targetHours")
                    .font(DS.Typography.callout)
                    .foregroundStyle(DS.Colors.textSecondary)
                Spacer()
                Stepper(value: $targetHours, in: 1...200, step: 1) {
                    Text(verbatim: "\(targetHours)h")
                        .font(DS.Typography.callout)
                        .foregroundStyle(DS.Colors.textPrimary)
                        .monospacedDigit()
                }
            }

            Toggle(isOn: $hasDeadline) {
                Text("goalEditor.deadline")
                    .font(DS.Typography.callout)
                    .foregroundStyle(DS.Colors.textSecondary)
            }
            .tint(DS.Colors.brandGreen)

            if hasDeadline {
                DatePicker(
                    selection: $deadline,
                    in: Date.now...,
                    displayedComponents: .date
                ) {
                    Text("goalEditor.deadline")
                        .font(DS.Typography.callout)
                        .foregroundStyle(DS.Colors.textSecondary)
                }
                .tint(DS.Colors.brandGreen)
            }

            Spacer()

            PrimaryButton(titleKey: "goalEditor.save") {
                onSave(subject, topic, Double(targetHours), hasDeadline ? deadline : nil)
                dismiss()
            }
        }
        .padding(DS.Spacing.screenPadding)
        .background(DS.Colors.bgCanvas)
    }
}
