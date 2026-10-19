import SwiftUI

/// "Estudar" tab hub: today's agenda, consistency trend, weekly editor and
/// topic goals (F-05/F-06/F-10). The question bank joins here in Phase 3.
struct StudyView: View {
    @State private var routinesViewModel: RoutinesViewModel
    @State private var goalsViewModel: GoalsViewModel
    @State private var showingBlockEditor = false
    @State private var editingBlock: RoutineBlock?
    @State private var showingGoalEditor = false
    @State private var goalPrefillSubject: String?
    @Environment(\.calendar) private var calendar
    private let di: DIContainer

    init(di: DIContainer) {
        self.di = di
        _routinesViewModel = State(initialValue: di.makeRoutinesViewModel())
        _goalsViewModel = State(initialValue: di.makeGoalsViewModel())
    }

    var body: some View {
        NavigationStack {
            studyContent
        }
    }

    private var studyContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                treelineBanner

                Text("study.title")
                    .font(DS.Typography.display)
                    .foregroundStyle(DS.Colors.textPrimary)

                contentLinks

                if let suggestion = routinesViewModel.suggestion {
                    suggestionCard(suggestion)
                }

                if routinesViewModel.routine == nil {
                    templatePicker
                } else {
                    if let consistency = routinesViewModel.consistency {
                        consistencyCard(consistency)
                    }
                    todaySection
                    weekSection
                }

                goalsSection
            }
            .padding(.horizontal, DS.Spacing.screenPadding)
            .padding(.vertical, DS.Spacing.lg)
        }
        .background(DS.Colors.bgCanvas)
        .onAppear {
            routinesViewModel.refresh()
            goalsViewModel.refresh()
        }
        .sheet(isPresented: $showingBlockEditor) {
            RoutineBlockEditorSheet { weekday, subject, minutes, sessions in
                routinesViewModel.addBlock(
                    weekday: weekday, subject: subject, minutes: minutes, sessions: sessions
                )
            }
            .presentationDetents([.medium])
            .presentationCornerRadius(DS.Radius.sheet)
        }
        .sheet(item: $editingBlock) { block in
            RoutineBlockEditorSheet(
                initial: RoutineBlockEditorSheet.Values(
                    weekday: block.weekday ?? 2,
                    subject: block.subject ?? SubjectCatalog.presets[0],
                    minutes: block.targetMinutes,
                    sessions: block.targetSessions
                )
            ) { weekday, subject, minutes, sessions in
                routinesViewModel.updateBlock(
                    block, weekday: weekday, subject: subject, minutes: minutes, sessions: sessions
                )
            }
            .presentationDetents([.medium])
            .presentationCornerRadius(DS.Radius.sheet)
        }
        .sheet(isPresented: $showingGoalEditor, onDismiss: { goalPrefillSubject = nil }) {
            GoalEditorSheet(initialSubject: goalPrefillSubject) { subject, topic, hours, deadline in
                goalsViewModel.createGoal(
                    subject: subject, topic: topic, targetHours: hours, deadline: deadline
                )
            }
            .presentationDetents([.medium])
            .presentationCornerRadius(DS.Radius.sheet)
        }
    }

    // MARK: - Content links (F-07 / F-08)

    /// Pixel treeline to break the flat top (redesign). Two muted-green layers
    /// so it reads as scenery without competing with the content.
    private var treelineBanner: some View {
        ZStack(alignment: .bottom) {
            Treeline(count: 9, jitter: 0.42)
                .fill(DS.Colors.brandGreenSoft)
                .frame(height: 56)
            Treeline(count: 14, jitter: 0.6)
                .fill(DS.Colors.brandGreenDeep)
                .frame(height: 44)
        }
        .frame(maxWidth: .infinity, alignment: .bottom)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(DS.Colors.borderSubtle)
                .frame(height: 1)
        }
        .accessibilityHidden(true)
    }

    private var contentLinks: some View {
        HStack(spacing: DS.Spacing.sm) {
            NavigationLink {
                QuestionBankView(di: di)
            } label: {
                contentLinkCard(
                    icon: "text.book.closed.fill",
                    titleKey: "study.questions",
                    badge: routinesViewModel.dueReviewCount
                )
            }
            .buttonStyle(.plain)
            NavigationLink {
                EssayHomeView(di: di)
            } label: {
                contentLinkCard(icon: "square.and.pencil", titleKey: "study.essays", badge: 0)
            }
            .buttonStyle(.plain)
        }
    }

    private func contentLinkCard(icon: String, titleKey: LocalizedStringKey, badge: Int) -> some View {
        Card {
            HStack(spacing: DS.Spacing.xs) {
                Image(systemName: icon)
                    .foregroundStyle(DS.Colors.brandGreen)
                Text(titleKey)
                    .font(DS.Typography.callout)
                    .foregroundStyle(DS.Colors.textPrimary)
                Spacer(minLength: 0)
                if badge > 0 {
                    Text(verbatim: "\(badge)")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.textOnBrand)
                        .padding(.horizontal, DS.Spacing.xs)
                        .padding(.vertical, 2)
                        .background(DS.Colors.accentFocus)
                        .clipShape(Capsule())
                        .monospacedDigit()
                }
                Image(systemName: "chevron.right")
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.textSecondary)
            }
        }
    }

    // MARK: - Suggestion (performance → goal)

    private func suggestionCard(_ suggestion: SuggestionLogic.Suggestion) -> some View {
        Card {
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                HStack(spacing: DS.Spacing.xxs) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(DS.Colors.accentStreak)
                    Text("study.suggestion.title")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.textSecondary)
                }
                Text("study.suggestion.body \(suggestion.subject) \(Int((suggestion.accuracy * 100).rounded()))")
                    .font(DS.Typography.callout)
                    .foregroundStyle(DS.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    goalPrefillSubject = suggestion.subject
                    showingGoalEditor = true
                } label: {
                    Text("study.suggestion.action")
                        .font(DS.Typography.callout)
                        .foregroundStyle(DS.Colors.brandGreen)
                }
            }
        }
    }

    // MARK: - Empty state / templates

    private var templatePicker: some View {
        Card {
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                Text("study.empty.title")
                    .font(DS.Typography.headline)
                    .foregroundStyle(DS.Colors.textPrimary)
                Text("study.empty.subtitle")
                    .font(DS.Typography.callout)
                    .foregroundStyle(DS.Colors.textSecondary)
                ForEach(RoutineTemplateCatalog.templates) { template in
                    Button {
                        routinesViewModel.createRoutine(fromTemplateKey: template.key)
                    } label: {
                        HStack {
                            Text(verbatim: template.name)
                                .font(DS.Typography.callout)
                                .foregroundStyle(DS.Colors.brandGreenDeep)
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(DS.Colors.brandGreen)
                        }
                        .padding(DS.Spacing.sm)
                        .background(DS.Colors.brandGreenSoft)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.button))
                    }
                }
            }
        }
    }

    // MARK: - Consistency (F-06)

    private func consistencyCard(_ consistency: RoutineTrends.Consistency) -> some View {
        Card {
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                HStack {
                    Text("study.consistency")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.textSecondary)
                    Spacer()
                    Text(verbatim: "\(Int((consistency.percentage * 100).rounded()))%")
                        .font(DS.Typography.headline)
                        .foregroundStyle(DS.Colors.brandGreenDeep)
                        .monospacedDigit()
                }
                ProgressBar(progress: consistency.percentage)
                Text("study.consistency.detail \(consistency.completedCount) \(consistency.plannedCount)")
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.textSecondary)
            }
        }
    }

    // MARK: - Today (F-05 agenda)

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text("study.today")
                .font(DS.Typography.headline)
                .foregroundStyle(DS.Colors.textPrimary)
            if routinesViewModel.todayEntries.isEmpty {
                Card {
                    Text("study.today.empty")
                        .font(DS.Typography.callout)
                        .foregroundStyle(DS.Colors.textSecondary)
                }
            } else {
                ForEach(routinesViewModel.todayEntries) { entry in
                    todayRow(entry)
                }
            }
        }
    }

    private func todayRow(_ entry: RoutinesViewModel.TodayEntry) -> some View {
        Card {
            HStack(spacing: DS.Spacing.sm) {
                VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                    Text(verbatim: entry.subject)
                        .font(DS.Typography.callout)
                        .foregroundStyle(DS.Colors.textPrimary)
                    Text(verbatim: "\(entry.completedMinutes)/\(entry.targetMinutes) min")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.textSecondary)
                        .monospacedDigit()
                    ProgressBar(
                        progress: entry.targetMinutes > 0
                            ? Double(entry.completedMinutes) / Double(entry.targetMinutes)
                            : 0,
                        height: 6
                    )
                }
                Spacer()
                Button {
                    routinesViewModel.checkOff(entry)
                } label: {
                    Image(systemName: entry.completed ? "checkmark.circle.fill" : "circle")
                        .font(DS.Typography.title)
                        .foregroundStyle(entry.completed ? DS.Colors.stateSuccess : DS.Colors.borderSubtle)
                }
                .disabled(entry.completed)
                .accessibilityLabel(Text("study.checkOff"))
            }
        }
    }

    // MARK: - Week editor (F-05)

    private var weekSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            HStack {
                Text("study.week")
                    .font(DS.Typography.headline)
                    .foregroundStyle(DS.Colors.textPrimary)
                Spacer()
                Button {
                    showingBlockEditor = true
                } label: {
                    Label("study.addBlock", systemImage: "plus")
                        .font(DS.Typography.callout)
                        .foregroundStyle(DS.Colors.brandGreen)
                }
            }
            Card {
                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    ForEach(routinesViewModel.weekdaysWithBlocks, id: \.weekday) { group in
                        VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                            Text(verbatim: weekdayName(group.weekday))
                                .font(DS.Typography.caption)
                                .foregroundStyle(DS.Colors.textSecondary)
                            ForEach(group.blocks) { block in
                                HStack {
                                    Button {
                                        editingBlock = block
                                    } label: {
                                        HStack {
                                            Text(verbatim: block.subject ?? "")
                                                .font(DS.Typography.callout)
                                                .foregroundStyle(DS.Colors.textPrimary)
                                            Spacer()
                                            Text(verbatim: "\(block.targetMinutes) min")
                                                .font(DS.Typography.caption)
                                                .foregroundStyle(DS.Colors.textSecondary)
                                                .monospacedDigit()
                                        }
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityHint(Text("study.editBlock"))
                                    Button {
                                        routinesViewModel.deleteBlock(block)
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
            }
        }
    }

    // MARK: - Goals (F-10)

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            HStack {
                Text("study.goals")
                    .font(DS.Typography.headline)
                    .foregroundStyle(DS.Colors.textPrimary)
                Spacer()
                Button {
                    showingGoalEditor = true
                } label: {
                    Label("study.addGoal", systemImage: "plus")
                        .font(DS.Typography.callout)
                        .foregroundStyle(DS.Colors.brandGreen)
                }
            }
            if goalsViewModel.rows.isEmpty {
                Card {
                    Text("study.goals.empty")
                        .font(DS.Typography.callout)
                        .foregroundStyle(DS.Colors.textSecondary)
                }
            } else {
                ForEach(goalsViewModel.rows) { row in
                    goalRow(row)
                }
            }
        }
    }

    private func goalRow(_ row: GoalsViewModel.GoalRow) -> some View {
        Card {
            VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(verbatim: row.topic ?? row.subject)
                            .font(DS.Typography.callout)
                            .foregroundStyle(DS.Colors.textPrimary)
                        if row.topic != nil {
                            Text(verbatim: row.subject)
                                .font(DS.Typography.caption)
                                .foregroundStyle(DS.Colors.textSecondary)
                        }
                    }
                    Spacer()
                    if row.completed {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(DS.Colors.stateSuccess)
                    } else {
                        Button {
                            goalsViewModel.deleteGoal(row)
                        } label: {
                            Image(systemName: "trash")
                                .font(DS.Typography.caption)
                                .foregroundStyle(DS.Colors.stateDanger)
                        }
                        .accessibilityLabel(Text("study.deleteGoal"))
                    }
                }
                if let target = row.targetMinutes {
                    Text(verbatim: "\(row.progressMinutes / 60)h de \(target / 60)h")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.textSecondary)
                        .monospacedDigit()
                    ProgressBar(progress: row.progress, height: 6)
                }
                if let deadline = row.deadline {
                    Text(verbatim: deadline.formatted(date: .abbreviated, time: .omitted))
                        .font(DS.Typography.caption)
                        .foregroundStyle(row.overdue ? DS.Colors.stateDanger : DS.Colors.textSecondary)
                }
            }
        }
    }

    private func weekdayName(_ weekday: Int) -> String {
        let symbols = calendar.standaloneWeekdaySymbols
        let index = weekday - 1
        return symbols.indices.contains(index) ? symbols[index].capitalized : "\(weekday)"
    }
}

#Preview {
    StudyView(di: .preview())
}
