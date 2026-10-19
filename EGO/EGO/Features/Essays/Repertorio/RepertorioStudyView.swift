import SwiftUI

/// F-08 repertório study screen: flip-card front → reveal back → self-grade
/// into the SM-2 queue, then a session summary.
struct RepertorioStudyView: View {
    @Bindable var viewModel: RepertorioStudyViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            header
            if viewModel.isFinished {
                summary
            } else if let card = viewModel.current {
                ScrollView {
                    cardView(card)
                }
                Spacer(minLength: 0)
                if viewModel.isRevealed {
                    gradeButtons
                } else {
                    PrimaryButton(titleKey: "repertorio.reveal") {
                        viewModel.reveal()
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
            Text("repertorio.progress \(min(viewModel.index + 1, viewModel.total)) \(viewModel.total)")
                .font(DS.Typography.headline)
                .foregroundStyle(DS.Colors.textPrimary)
                .monospacedDigit()
            HStack {
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

    private func cardView(_ card: EssayFlashcard) -> some View {
        Card {
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                if let theme = card.theme {
                    Text(verbatim: theme)
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.brandGreenDeep)
                        .padding(.horizontal, DS.Spacing.xs)
                        .padding(.vertical, 2)
                        .background(DS.Colors.brandGreenSoft)
                        .clipShape(Capsule())
                }
                Text(verbatim: card.front ?? "")
                    .font(DS.Typography.headline)
                    .foregroundStyle(DS.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                if viewModel.isRevealed {
                    Divider()
                    Text(verbatim: card.back ?? "")
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.Colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var gradeButtons: some View {
        VStack(spacing: DS.Spacing.xs) {
            Text("repertorio.grade.prompt")
                .font(DS.Typography.caption)
                .foregroundStyle(DS.Colors.textSecondary)
            HStack(spacing: DS.Spacing.xs) {
                ForEach(RepertorioStudyViewModel.Grade.allCases, id: \.rawValue) { grade in
                    Button {
                        viewModel.grade(grade)
                    } label: {
                        Text(gradeKey(grade))
                            .font(DS.Typography.callout)
                            .foregroundStyle(DS.Colors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DS.Spacing.sm)
                            .background(DS.Colors.bgSurface)
                            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.button))
                            .overlay(
                                RoundedRectangle(cornerRadius: DS.Radius.button)
                                    .strokeBorder(DS.Colors.borderSubtle, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var summary: some View {
        VStack(spacing: DS.Spacing.md) {
            Spacer()
            MascotView(state: .happy)
                .frame(width: 140, height: 140)
            Text("repertorio.summary.title")
                .font(DS.Typography.title)
                .foregroundStyle(DS.Colors.textPrimary)
            Text("repertorio.summary \(viewModel.reviewedCount)")
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colors.textSecondary)
            Spacer()
            PrimaryButton(titleKey: "repertorio.finish") {
                dismiss()
            }
        }
    }

    private func gradeKey(_ grade: RepertorioStudyViewModel.Grade) -> LocalizedStringKey {
        switch grade {
        case .errei: "repertorio.grade.errei"
        case .dificil: "repertorio.grade.dificil"
        case .bom: "repertorio.grade.bom"
        case .facil: "repertorio.grade.facil"
        }
    }
}
