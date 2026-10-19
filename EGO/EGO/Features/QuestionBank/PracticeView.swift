import SwiftUI

/// F-07 practice screen: statement, options A–E, feedback + explanation,
/// mark-for-review, next.
struct PracticeView: View {
    @Bindable var viewModel: PracticeViewModel
    @Environment(\.dismiss) private var dismiss

    private let letters = ["A", "B", "C", "D", "E"]

    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            header
            if viewModel.isFinished {
                summary
            } else if let question = viewModel.current {
                ScrollView {
                    VStack(alignment: .leading, spacing: DS.Spacing.md) {
                        questionCard(question)
                        optionsList(question)
                        if let feedback = viewModel.feedback {
                            feedbackCard(feedback)
                        }
                    }
                }
                if viewModel.feedback != nil {
                    PrimaryButton(
                        titleKey: viewModel.index + 1 >= viewModel.total
                            ? "practice.finish" : "practice.next"
                    ) {
                        viewModel.next()
                    }
                }
            }
        }
        .padding(.horizontal, DS.Spacing.screenPadding)
        .padding(.vertical, DS.Spacing.lg)
        .background(DS.Colors.bgCanvas)
    }

    private var header: some View {
        ZStack {
            Text("practice.progress \(min(viewModel.index + 1, viewModel.total)) \(viewModel.total)")
                .font(DS.Typography.headline)
                .foregroundStyle(DS.Colors.textPrimary)
                .monospacedDigit()
            HStack {
                if viewModel.timed, !viewModel.isFinished {
                    Text(timerInterval: viewModel.questionStartedAt...Date.distantFuture, countsDown: false)
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.accentFocus)
                        .monospacedDigit()
                }
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(DS.Typography.callout)
                        .foregroundStyle(DS.Colors.textSecondary)
                }
                .accessibilityLabel(Text("timer.close"))
            }
        }
    }

    private func questionCard(_ question: Question) -> some View {
        Card {
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                HStack(spacing: DS.Spacing.xs) {
                    tag(question.subject ?? "")
                    if let topic = question.topic { tag(topic) }
                    if let difficulty = question.difficulty {
                        Text(difficultyKey(difficulty))
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.Colors.textSecondary)
                    }
                }
                Text(verbatim: question.statement ?? "")
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func optionsList(_ question: Question) -> some View {
        VStack(spacing: DS.Spacing.xs) {
            ForEach(Array(question.options.enumerated()), id: \.offset) { offset, option in
                Button {
                    viewModel.answer(offset)
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: DS.Spacing.sm) {
                        Text(verbatim: letters.indices.contains(offset) ? letters[offset] : "\(offset + 1)")
                            .font(DS.Typography.headline)
                            .foregroundStyle(optionLetterColor(offset, question: question))
                        Text(verbatim: option)
                            .font(DS.Typography.callout)
                            .foregroundStyle(DS.Colors.textPrimary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .padding(DS.Spacing.sm)
                    .background(optionBackground(offset, question: question))
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.button))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.button)
                            .strokeBorder(optionBorder(offset, question: question), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.feedback != nil)
                .accessibilityIdentifier("practice.option.\(offset)")
            }
        }
    }

    private func feedbackCard(_ feedback: PracticeViewModel.Feedback) -> some View {
        Card {
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                HStack(spacing: DS.Spacing.xxs) {
                    Image(systemName: feedback.correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(feedback.correct ? DS.Colors.stateSuccess : DS.Colors.stateDanger)
                    Text(feedback.correct ? "practice.correct" : "practice.wrong")
                        .font(DS.Typography.headline)
                        .foregroundStyle(DS.Colors.textPrimary)
                }
                if let explanation = feedback.explanation {
                    Text("practice.explanation")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.textSecondary)
                    Text(verbatim: explanation)
                        .font(DS.Typography.callout)
                        .foregroundStyle(DS.Colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let source = feedback.source {
                    Text(verbatim: source)
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.textSecondary)
                }
                if !viewModel.isReview {
                    Button {
                        viewModel.markForReview()
                    } label: {
                        Label(
                            viewModel.isMarked ? "practice.marked" : "practice.mark",
                            systemImage: viewModel.isMarked ? "bookmark.fill" : "bookmark"
                        )
                        .font(DS.Typography.callout)
                        .foregroundStyle(DS.Colors.accentFocus)
                    }
                    .disabled(viewModel.isMarked)
                }
            }
        }
    }

    private var summary: some View {
        VStack(spacing: DS.Spacing.md) {
            Spacer()
            MascotView(state: .happy)
                .frame(width: 140, height: 140)
            Text("practice.summary.title")
                .font(DS.Typography.title)
                .foregroundStyle(DS.Colors.textPrimary)
            Text("practice.summary \(viewModel.correctCount) \(viewModel.total)")
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colors.textSecondary)
            Spacer()
            PrimaryButton(titleKey: "practice.finish") {
                dismiss()
            }
        }
    }

    // MARK: - Styling helpers

    private func tag(_ text: String) -> some View {
        Text(verbatim: text)
            .font(DS.Typography.caption)
            .foregroundStyle(DS.Colors.brandGreenDeep)
            .padding(.horizontal, DS.Spacing.xs)
            .padding(.vertical, 2)
            .background(DS.Colors.brandGreenSoft)
            .clipShape(Capsule())
    }

    private func difficultyKey(_ difficulty: Int) -> LocalizedStringKey {
        switch difficulty {
        case 1: "bank.difficulty.1"
        case 2: "bank.difficulty.2"
        default: "bank.difficulty.3"
        }
    }

    private func isRevealedCorrect(_ offset: Int, question: Question) -> Bool {
        viewModel.feedback != nil && offset == question.correctIndex
    }

    private func isChosenWrong(_ offset: Int, question: Question) -> Bool {
        viewModel.feedback != nil && offset == viewModel.selectedIndex
            && offset != question.correctIndex
    }

    private func optionBackground(_ offset: Int, question: Question) -> Color {
        if isRevealedCorrect(offset, question: question) { return DS.Colors.brandGreenSoft }
        if isChosenWrong(offset, question: question) { return DS.Colors.bgSurfaceAlt }
        return DS.Colors.bgSurface
    }

    private func optionBorder(_ offset: Int, question: Question) -> Color {
        if isRevealedCorrect(offset, question: question) { return DS.Colors.stateSuccess }
        if isChosenWrong(offset, question: question) { return DS.Colors.stateDanger }
        return DS.Colors.borderSubtle
    }

    private func optionLetterColor(_ offset: Int, question: Question) -> Color {
        if isRevealedCorrect(offset, question: question) { return DS.Colors.stateSuccess }
        if isChosenWrong(offset, question: question) { return DS.Colors.stateDanger }
        return DS.Colors.brandGreen
    }
}
