import SwiftUI
import Charts

/// F-11 stats dashboard: tiles, XP bar, weekly trend chart, subject breakdown.
struct StatsView: View {
    @State private var viewModel: StatsViewModel

    init(di: DIContainer) {
        _viewModel = State(initialValue: di.makeStatsViewModel())
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                Text("stats.title")
                    .font(DS.Typography.display)
                    .foregroundStyle(DS.Colors.textPrimary)

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: DS.Spacing.sm),
                        GridItem(.flexible()),
                    ],
                    spacing: DS.Spacing.sm
                ) {
                    StatTile(value: viewModel.totalFocusText, labelKey: "stats.totalFocus")
                    StatTile(value: "\(viewModel.totalSessions)", labelKey: "stats.sessions")
                    StatTile(value: "\(viewModel.currentStreak)", labelKey: "stats.currentStreak")
                    StatTile(value: "\(viewModel.longestStreak)", labelKey: "stats.longestStreak")
                }

                levelCard
                weeklyCard
                subjectsCard
            }
            .padding(.horizontal, DS.Spacing.screenPadding)
            .padding(.vertical, DS.Spacing.lg)
        }
        .background(DS.Colors.bgCanvas)
        .onAppear {
            viewModel.refresh()
        }
    }

    private var levelCard: some View {
        Card {
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                HStack {
                    Text("stats.level")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.textSecondary)
                    Spacer()
                    Text(verbatim: "\(viewModel.xpInLevel)/\(viewModel.xpLevelSpan) XP")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.textSecondary)
                        .monospacedDigit()
                }
                HStack(spacing: DS.Spacing.sm) {
                    Text(verbatim: "\(viewModel.level)")
                        .font(DS.Typography.title)
                        .foregroundStyle(DS.Colors.textPrimary)
                    ProgressBar(progress: viewModel.levelProgress)
                }
                HStack(spacing: DS.Spacing.xxs) {
                    Image(systemName: "circlebadge.2.fill")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.accentStreak)
                    Text("stats.coins")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.textSecondary)
                    Spacer()
                    Text(verbatim: "\(viewModel.coins)")
                        .font(DS.Typography.callout)
                        .foregroundStyle(DS.Colors.textPrimary)
                        .monospacedDigit()
                }
                .padding(.top, DS.Spacing.xxs)
            }
        }
    }

    private var weeklyCard: some View {
        Card {
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                Text("stats.weekly")
                    .font(DS.Typography.headline)
                    .foregroundStyle(DS.Colors.textPrimary)
                Chart(viewModel.weekly) { item in
                    BarMark(
                        x: .value("stats.chart.day", item.day, unit: .day),
                        y: .value("stats.chart.minutes", item.minutes)
                    )
                    .foregroundStyle(DS.Colors.brandGreen)
                    .cornerRadius(3)
                }
                .chartYScale(domain: 0...viewModel.weeklyDomainMax)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated), centered: true)
                    }
                }
                .frame(height: 160)
            }
        }
    }

    private var subjectsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                Text("stats.bySubject")
                    .font(DS.Typography.headline)
                    .foregroundStyle(DS.Colors.textPrimary)
                if viewModel.subjects.isEmpty {
                    Text("stats.bySubject.empty")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.textSecondary)
                } else {
                    ForEach(viewModel.subjects) { item in
                        VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                            HStack {
                                Text(verbatim: item.subject)
                                    .font(DS.Typography.callout)
                                    .foregroundStyle(DS.Colors.textPrimary)
                                Spacer()
                                Text(verbatim: "\(item.minutes) min")
                                    .font(DS.Typography.caption)
                                    .foregroundStyle(DS.Colors.textSecondary)
                                    .monospacedDigit()
                            }
                            ProgressBar(progress: viewModel.subjectFraction(item), height: 6)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    StatsView(di: .preview())
}
