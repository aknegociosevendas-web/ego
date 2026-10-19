import SwiftUI

/// ENEM self-score sheet: 5 competências, 0–200 each in steps of 40
/// (docs/08 §2). Total maps to /1000.
struct RubricScoreSheet: View {
    var onConfirm: ([Int]) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var scores = Array(
        repeating: 120, count: EssayRubricCatalog.competencies.count
    )

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Text("rubric.title")
                .font(DS.Typography.title)
                .foregroundStyle(DS.Colors.textPrimary)

            ForEach(EssayRubricCatalog.competencies) { competency in
                let index = competency.number - 1
                VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                    Text(verbatim: "\(competency.number). \(competency.title)")
                        .font(DS.Typography.callout)
                        .foregroundStyle(DS.Colors.textPrimary)
                    Stepper(
                        value: $scores[index],
                        in: 0...EssayRubricCatalog.maxPerCompetency,
                        step: EssayRubricCatalog.scoreStep
                    ) {
                        Text(verbatim: "\(scores[index])")
                            .font(DS.Typography.headline)
                            .foregroundStyle(DS.Colors.brandGreenDeep)
                            .monospacedDigit()
                    }
                }
            }

            Spacer()

            Text("rubric.total \(scores.reduce(0, +))")
                .font(DS.Typography.headline)
                .foregroundStyle(DS.Colors.textPrimary)
                .monospacedDigit()

            PrimaryButton(titleKey: "rubric.confirm") {
                onConfirm(scores)
                dismiss()
            }
        }
        .padding(DS.Spacing.screenPadding)
        .background(DS.Colors.bgCanvas)
    }
}
