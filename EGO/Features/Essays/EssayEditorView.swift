import SwiftUI

/// F-08 writing space: scaffold hints, editor, word count + timer, finalize.
struct EssayEditorView: View {
    @State private var viewModel: EssayEditorViewModel
    @State private var showingRubric = false
    @Environment(\.dismiss) private var dismiss

    init(di: DIContainer, draft: EssayDraft) {
        _viewModel = State(initialValue: di.makeEssayEditorViewModel(draft: draft))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                TextField("essay.titlePlaceholder", text: $viewModel.title)
                    .font(DS.Typography.headline)
                    .padding(DS.Spacing.sm)
                    .background(DS.Colors.bgSurface)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.button))

                scaffold

                TextEditor(text: $viewModel.body)
                    .font(DS.Typography.body)
                    .scrollContentBackground(.hidden)
                    .padding(DS.Spacing.xs)
                    .frame(minHeight: 260)
                    .background(DS.Colors.bgSurface)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.card)
                            .strokeBorder(DS.Colors.borderSubtle, lineWidth: 1)
                    )

                footer

                if viewModel.isFinished, let score = viewModel.selfScore {
                    Card {
                        HStack(spacing: DS.Spacing.xxs) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(DS.Colors.stateSuccess)
                            Text("rubric.total \(score)")
                                .font(DS.Typography.headline)
                                .foregroundStyle(DS.Colors.textPrimary)
                        }
                    }
                } else {
                    PrimaryButton(titleKey: "essay.finalize") {
                        showingRubric = true
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.screenPadding)
            .padding(.vertical, DS.Spacing.lg)
        }
        .background(DS.Colors.bgCanvas)
        .navigationTitle(Text("essay.editor.title"))
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            viewModel.save()
        }
        .sheet(isPresented: $showingRubric) {
            RubricScoreSheet { scores in
                viewModel.finalize(scores: scores)
            }
            .presentationDetents([.large])
            .presentationCornerRadius(DS.Radius.sheet)
        }
    }

    private var scaffold: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            ForEach(viewModel.sections, id: \.title) { section in
                DisclosureGroup {
                    Text(verbatim: section.hint)
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, DS.Spacing.xxs)
                } label: {
                    Text(verbatim: section.title)
                        .font(DS.Typography.callout)
                        .foregroundStyle(DS.Colors.brandGreenDeep)
                }
                .padding(DS.Spacing.sm)
                .background(DS.Colors.brandGreenSoft)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.button))
            }
        }
    }

    private var footer: some View {
        HStack {
            Text("essay.words \(viewModel.wordCount)")
                .font(DS.Typography.caption)
                .foregroundStyle(DS.Colors.textSecondary)
                .monospacedDigit()
            Spacer()
            HStack(spacing: DS.Spacing.xxs) {
                Image(systemName: "timer")
                    .font(DS.Typography.caption)
                Text(timerInterval: viewModel.startedAt...Date.distantFuture, countsDown: false)
                    .font(DS.Typography.caption)
                    .monospacedDigit()
            }
            .foregroundStyle(DS.Colors.accentFocus)
        }
    }
}
