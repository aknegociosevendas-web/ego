import SwiftUI

/// F-08 home: template card + drafts. Navigation pushes the editor.
struct EssayHomeView: View {
    @State private var viewModel: EssayHomeViewModel
    @State private var editingDraft: EssayDraft?
    private let di: DIContainer

    init(di: DIContainer) {
        self.di = di
        _viewModel = State(initialValue: di.makeEssayHomeViewModel())
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                templateCard
                repertorioCard
                draftsSection
            }
            .padding(.horizontal, DS.Spacing.screenPadding)
            .padding(.vertical, DS.Spacing.lg)
        }
        .background(DS.Colors.bgCanvas)
        .navigationTitle(Text("essay.title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.refresh()
        }
        .navigationDestination(item: $editingDraft) { draft in
            EssayEditorView(di: di, draft: draft)
        }
    }

    private var repertorioCard: some View {
        NavigationLink {
            RepertorioListView(di: di)
        } label: {
            Card {
                HStack(spacing: DS.Spacing.sm) {
                    Image(systemName: "rectangle.on.rectangle.angled")
                        .foregroundStyle(DS.Colors.brandGreen)
                    VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                        Text("repertorio.title")
                            .font(DS.Typography.headline)
                            .foregroundStyle(DS.Colors.textPrimary)
                        Text("repertorio.entry.subtitle")
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.Colors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var templateCard: some View {
        Card {
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                HStack(spacing: DS.Spacing.xxs) {
                    Image(systemName: "doc.text")
                        .foregroundStyle(DS.Colors.brandGreen)
                    Text(verbatim: viewModel.template?.title ?? "")
                        .font(DS.Typography.headline)
                        .foregroundStyle(DS.Colors.textPrimary)
                }
                PrimaryButton(titleKey: "essay.new") {
                    if let draft = viewModel.newDraft() {
                        editingDraft = draft
                    }
                }
            }
        }
    }

    private var draftsSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text("essay.drafts")
                .font(DS.Typography.headline)
                .foregroundStyle(DS.Colors.textPrimary)
            if viewModel.drafts.isEmpty {
                Card {
                    Text("essay.drafts.empty")
                        .font(DS.Typography.callout)
                        .foregroundStyle(DS.Colors.textSecondary)
                }
            }
            ForEach(viewModel.drafts) { draft in
                Button {
                    editingDraft = draft
                } label: {
                    draftRow(draft)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func draftRow(_ draft: EssayDraft) -> some View {
        Card {
            HStack {
                VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                    Text(verbatim: draft.title?.isEmpty == false
                        ? draft.title! : draft.updatedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(DS.Typography.callout)
                        .foregroundStyle(DS.Colors.textPrimary)
                    Text("essay.words \(draft.wordCount)")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.textSecondary)
                }
                Spacer()
                if let score = draft.selfScore, draft.finishedAt != nil {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(verbatim: "\(score)")
                            .font(DS.Typography.headline)
                            .foregroundStyle(DS.Colors.brandGreenDeep)
                            .monospacedDigit()
                        Text("essay.finished")
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.Colors.stateSuccess)
                    }
                } else {
                    Button {
                        viewModel.delete(draft)
                    } label: {
                        Image(systemName: "trash")
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.Colors.stateDanger)
                    }
                    .accessibilityLabel(Text("study.deleteBlock"))
                }
            }
        }
    }
}
