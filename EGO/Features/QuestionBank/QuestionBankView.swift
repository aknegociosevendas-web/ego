import SwiftUI

/// F-07 browse screen: review queue, filters, practice launcher, preview list.
struct QuestionBankView: View {
    @State private var viewModel: QuestionBankViewModel
    @State private var practice: PracticeViewModel?
    private let di: DIContainer

    init(di: DIContainer) {
        self.di = di
        _viewModel = State(initialValue: di.makeQuestionBankViewModel())
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                reviewCard
                filtersRow
                practiceCard
                questionList
            }
            .padding(.horizontal, DS.Spacing.screenPadding)
            .padding(.vertical, DS.Spacing.lg)
        }
        .background(DS.Colors.bgCanvas)
        .navigationTitle(Text("bank.title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.refresh()
        }
        .fullScreenCover(item: $practice, onDismiss: { viewModel.refresh() }) { session in
            PracticeView(viewModel: session)
        }
    }

    // MARK: - Review queue (SM-2)

    private var reviewCard: some View {
        Card {
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                HStack(spacing: DS.Spacing.xxs) {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(DS.Colors.accentFocus)
                    Text("bank.review.title")
                        .font(DS.Typography.headline)
                        .foregroundStyle(DS.Colors.textPrimary)
                }
                if viewModel.dueQuestions.isEmpty {
                    Text("bank.review.empty")
                        .font(DS.Typography.callout)
                        .foregroundStyle(DS.Colors.textSecondary)
                } else {
                    Text("bank.review.count \(viewModel.dueQuestions.count)")
                        .font(DS.Typography.callout)
                        .foregroundStyle(DS.Colors.textSecondary)
                    Button {
                        practice = di.makePracticeViewModel(
                            questions: viewModel.dueQuestions, isReview: true, timed: false
                        )
                    } label: {
                        Text("bank.review.start")
                            .font(DS.Typography.callout)
                            .foregroundStyle(DS.Colors.accentFocus)
                    }
                }
            }
        }
    }

    // MARK: - Filters

    private var filtersRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Spacing.xs) {
                stringFilter("bank.filter.subject", values: viewModel.subjects, selection: $viewModel.filters.subject)
                stringFilter("bank.filter.topic", values: viewModel.topics, selection: $viewModel.filters.topic)
                difficultyFilter
                stringFilter("bank.filter.exam", values: viewModel.exams, selection: $viewModel.filters.exam)
                intFilter("bank.filter.year", values: viewModel.years, selection: $viewModel.filters.year)
            }
            .padding(.horizontal, DS.Spacing.xxs)
        }
    }

    private func stringFilter(
        _ labelKey: LocalizedStringKey,
        values: [String],
        selection: Binding<String?>
    ) -> some View {
        Menu {
            Button { selection.wrappedValue = nil } label: { Text("bank.filter.all") }
            ForEach(values, id: \.self) { value in
                Button { selection.wrappedValue = value } label: { Text(verbatim: value) }
            }
        } label: {
            filterChip(
                label: selection.wrappedValue.map(Text.init(verbatim:)) ?? Text(labelKey),
                active: selection.wrappedValue != nil
            )
        }
    }

    private func intFilter(
        _ labelKey: LocalizedStringKey,
        values: [Int],
        selection: Binding<Int?>
    ) -> some View {
        Menu {
            Button { selection.wrappedValue = nil } label: { Text("bank.filter.all") }
            ForEach(values, id: \.self) { value in
                Button { selection.wrappedValue = value } label: { Text(verbatim: "\(value)") }
            }
        } label: {
            filterChip(
                label: selection.wrappedValue.map { Text(verbatim: "\($0)") } ?? Text(labelKey),
                active: selection.wrappedValue != nil
            )
        }
    }

    private var difficultyFilter: some View {
        Menu {
            Button { viewModel.filters.difficulty = nil } label: { Text("bank.filter.all") }
            ForEach(viewModel.difficulties, id: \.self) { value in
                Button { viewModel.filters.difficulty = value } label: {
                    Text(difficultyKey(value))
                }
            }
        } label: {
            filterChip(
                label: viewModel.filters.difficulty.map { Text(difficultyKey($0)) }
                    ?? Text("bank.filter.difficulty"),
                active: viewModel.filters.difficulty != nil
            )
        }
    }

    private func filterChip(label: Text, active: Bool) -> some View {
        HStack(spacing: DS.Spacing.xxs) {
            label
                .font(DS.Typography.callout)
            Image(systemName: "chevron.down")
                .font(DS.Typography.caption)
        }
        .foregroundStyle(active ? DS.Colors.brandGreenDeep : DS.Colors.textPrimary)
        .padding(.horizontal, DS.Spacing.sm)
        .padding(.vertical, DS.Spacing.xs)
        .background(active ? DS.Colors.brandGreenSoft : DS.Colors.bgSurfaceAlt)
        .clipShape(Capsule())
    }

    // MARK: - Practice launcher + list

    private var practiceCard: some View {
        Card {
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                HStack {
                    Text("bank.count \(viewModel.filtered.count)")
                        .font(DS.Typography.headline)
                        .foregroundStyle(DS.Colors.textPrimary)
                    Spacer()
                    Toggle(isOn: $viewModel.timedPractice) {
                        Text("bank.timed")
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.Colors.textSecondary)
                    }
                    .tint(DS.Colors.accentFocus)
                    .fixedSize()
                }
                PrimaryButton(titleKey: "bank.practice") {
                    practice = di.makePracticeViewModel(
                        questions: viewModel.filtered,
                        isReview: false,
                        timed: viewModel.timedPractice
                    )
                }
                .disabled(viewModel.filtered.isEmpty)
                .opacity(viewModel.filtered.isEmpty ? 0.5 : 1)
            }
        }
    }

    private var questionList: some View {
        VStack(spacing: DS.Spacing.xs) {
            if viewModel.filtered.isEmpty {
                Card {
                    Text("bank.empty")
                        .font(DS.Typography.callout)
                        .foregroundStyle(DS.Colors.textSecondary)
                }
            }
            ForEach(viewModel.filtered.prefix(20)) { question in
                Card {
                    VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                        Text(verbatim: question.statement ?? "")
                            .font(DS.Typography.callout)
                            .foregroundStyle(DS.Colors.textPrimary)
                            .lineLimit(2)
                        Text(verbatim: [question.subject, question.topic]
                            .compactMap(\.self).joined(separator: " · "))
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.Colors.textSecondary)
                    }
                }
            }
        }
    }

    private func difficultyKey(_ difficulty: Int) -> LocalizedStringKey {
        switch difficulty {
        case 1: "bank.difficulty.1"
        case 2: "bank.difficulty.2"
        default: "bank.difficulty.3"
        }
    }
}
