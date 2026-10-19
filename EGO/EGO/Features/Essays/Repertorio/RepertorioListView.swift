import SwiftUI

/// F-08 repertório home: today's review queue, tema filter, and the browsable
/// flashcard bank. Studying (or the review queue) drills cards via SM-2.
struct RepertorioListView: View {
    @State private var viewModel: RepertorioViewModel
    @State private var study: RepertorioStudyViewModel?
    private let di: DIContainer

    init(di: DIContainer) {
        self.di = di
        _viewModel = State(initialValue: di.makeRepertorioViewModel())
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                reviewCard
                if !viewModel.themes.isEmpty {
                    themeFilter
                }
                studyCard
                cardList
            }
            .padding(.horizontal, DS.Spacing.screenPadding)
            .padding(.vertical, DS.Spacing.lg)
        }
        .background(DS.Colors.bgCanvas)
        .navigationTitle(Text("repertorio.title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.refresh() }
        .fullScreenCover(item: $study, onDismiss: { viewModel.refresh() }) { session in
            RepertorioStudyView(viewModel: session)
        }
    }

    // MARK: - Review queue (SM-2)

    private var reviewCard: some View {
        Card {
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                HStack(spacing: DS.Spacing.xxs) {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(DS.Colors.accentFocus)
                    Text("repertorio.review.title")
                        .font(DS.Typography.headline)
                        .foregroundStyle(DS.Colors.textPrimary)
                }
                if viewModel.dueCards.isEmpty {
                    Text("repertorio.review.empty")
                        .font(DS.Typography.callout)
                        .foregroundStyle(DS.Colors.textSecondary)
                } else {
                    Text("repertorio.review.count \(viewModel.dueCards.count)")
                        .font(DS.Typography.callout)
                        .foregroundStyle(DS.Colors.textSecondary)
                    Button {
                        study = di.makeRepertorioStudyViewModel(cards: viewModel.dueCards)
                    } label: {
                        Text("repertorio.review.start")
                            .font(DS.Typography.callout)
                            .foregroundStyle(DS.Colors.accentFocus)
                    }
                }
            }
        }
    }

    // MARK: - Tema filter

    private var themeFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Spacing.xs) {
                themeChip(titleKey: "repertorio.theme.all", theme: nil)
                ForEach(viewModel.themes, id: \.self) { theme in
                    themeChip(title: theme, theme: theme)
                }
            }
        }
    }

    private func themeChip(titleKey: LocalizedStringKey, theme: String?) -> some View {
        chip(label: Text(titleKey), theme: theme)
    }

    private func themeChip(title: String, theme: String?) -> some View {
        chip(label: Text(verbatim: title), theme: theme)
    }

    private func chip(label: Text, theme: String?) -> some View {
        let selected = viewModel.selectedTheme == theme
        return Button {
            viewModel.selectedTheme = theme
        } label: {
            label
                .font(DS.Typography.caption)
                .foregroundStyle(selected ? DS.Colors.textOnBrand : DS.Colors.textPrimary)
                .padding(.horizontal, DS.Spacing.sm)
                .padding(.vertical, DS.Spacing.xs)
                .background(selected ? DS.Colors.brandGreen : DS.Colors.bgSurface)
                .clipShape(Capsule())
                .overlay(
                    Capsule().strokeBorder(DS.Colors.borderSubtle, lineWidth: selected ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Study the current selection

    private var studyCard: some View {
        Card {
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                HStack(spacing: DS.Spacing.xxs) {
                    Image(systemName: "rectangle.on.rectangle.angled")
                        .foregroundStyle(DS.Colors.brandGreen)
                    Text("repertorio.study.title")
                        .font(DS.Typography.headline)
                        .foregroundStyle(DS.Colors.textPrimary)
                }
                Text("repertorio.study.subtitle")
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.textSecondary)
                PrimaryButton(titleKey: "repertorio.study.start") {
                    study = di.makeRepertorioStudyViewModel(cards: viewModel.filtered)
                }
                .disabled(viewModel.filtered.isEmpty)
            }
        }
    }

    // MARK: - Bank

    private var cardList: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text("repertorio.bank.title")
                .font(DS.Typography.headline)
                .foregroundStyle(DS.Colors.textPrimary)
            if viewModel.filtered.isEmpty {
                Card {
                    Text("repertorio.bank.empty")
                        .font(DS.Typography.callout)
                        .foregroundStyle(DS.Colors.textSecondary)
                }
            }
            ForEach(viewModel.filtered) { card in
                RepertorioCardRow(
                    card: card,
                    queued: viewModel.isQueued(card),
                    addToReview: { viewModel.addToReview(card) }
                )
            }
        }
    }
}

/// One browsable flashcard: tap to flip front/back, add to the SM-2 queue.
private struct RepertorioCardRow: View {
    let card: EssayFlashcard
    let queued: Bool
    let addToReview: () -> Void
    @State private var revealed = false

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                Button {
                    revealed.toggle()
                } label: {
                    VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                        Text(verbatim: card.front ?? "")
                            .font(DS.Typography.callout)
                            .foregroundStyle(DS.Colors.textPrimary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        if revealed {
                            Text(verbatim: card.back ?? "")
                                .font(DS.Typography.caption)
                                .foregroundStyle(DS.Colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)

                if queued {
                    Label("repertorio.queued", systemImage: "checkmark.circle.fill")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.stateSuccess)
                } else {
                    Button(action: addToReview) {
                        Label("repertorio.add", systemImage: "plus.circle")
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.Colors.accentFocus)
                    }
                }
            }
        }
    }
}
