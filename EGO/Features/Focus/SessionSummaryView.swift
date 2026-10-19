import SwiftUI
import os

private let focusFlowLog = Logger(subsystem: "com.ego.EGO", category: "FocusFlow") // LOG(slice6)

/// What the summary step shows: a fully rewarded completion (F-14 feedback,
/// docs/07 §1) or an early finish via hold-to-conclude (existing abandon
/// semantics — no rewards, only the minutes actually focused).
enum FocusSummaryPayload: Equatable {
    case completed(CompletedSessionSummary)
    case endedEarly(minutes: Int)

    var minutes: Int {
        switch self {
        case .completed(let summary): summary.minutes
        case .endedEarly(let minutes): minutes
        }
    }
}

/// Step 3 of the focus flow, journal style (slice 5): static scenery frame as
/// backdrop, up to three underlined journal lines with colored highlights,
/// share + continue on the right, and a reward card in the footer when the
/// session unlocked something new.
struct SessionSummaryView: View {
    let payload: FocusSummaryPayload
    var scenery: FocusScenery = .night
    /// Free-text label from setup (falls back to the subject when empty).
    var focusLabel: String? = nil
    var subject: String? = nil
    var onContinue: () -> Void = {}
    /// Shown after a completed focus: jump back to the timer for the break.
    var onTakeBreak: (() -> Void)? = nil

    @State private var shareImage: Image?

    var body: some View {
        ZStack(alignment: .top) {
            // The scenery keeps living behind the journal (slice 6); Reduce
            // Motion falls back to the static frame inside the component.
            AnimatedSceneView(scenery: scenery)
                .ignoresSafeArea()

            // Top-down scrim so the journal lines stay legible over the
            // animated scene (stronger on top, gone by mid-screen).
            LinearGradient(
                colors: [
                    DS.Colors.bgCanvas.opacity(0.6),
                    DS.Colors.bgCanvas.opacity(0.25),
                    .clear
                ],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 380)
            .frame(maxHeight: .infinity, alignment: .top)
            .ignoresSafeArea(edges: .top)

            VStack(spacing: DS.Spacing.md) {
                HStack(alignment: .top, spacing: DS.Spacing.md) {
                    journalBlock
                    Spacer(minLength: DS.Spacing.sm)
                    actionColumn
                }

                Spacer()

                footer
            }
            .padding(.horizontal, DS.Spacing.screenPadding)
            .padding(.vertical, DS.Spacing.lg)
        }
        .task {
            renderShareCard()
        }
        .onAppear {
            focusFlowLog.debug("6/6 SessionSummaryView appeared, minutes=\(payload.minutes)") // LOG(slice6)
        }
    }

    // MARK: - Journal block

    private var journalBlock: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            journalLine(dateLine)
            journalLine(focusLine)
            if case .completed(let summary) = payload {
                journalLine(rewardLine(for: summary))
                journalLine(phraseLine)
            }
        }
    }

    /// Rotating motivational note (completed sessions only), picked by day of
    /// year so it stays stable across re-renders and sessions within a day.
    /// Bundle lookup instead of `LocalizedStringKey(interpolated)` — the
    /// interpolation would be captured as a `%lld` format key and miss.
    private var phraseLine: Text {
        let dayIndex = (Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 0)
            % Self.phraseCount
        let phrase = Bundle.main.localizedString(
            forKey: "summary.phrase.\(dayIndex)", value: nil, table: nil
        )
        return Text(verbatim: phrase)
    }

    private static let phraseCount = 5

    /// One handwritten-journal row: text over a 1pt rule.
    private func journalLine(_ text: Text) -> some View {
        text
            .font(DS.Typography.body)
            .foregroundStyle(DS.Colors.textPrimary)
            .shadow(color: DS.Colors.bgCanvas.opacity(0.6), radius: 3)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, DS.Spacing.xxs)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(DS.Colors.textSecondary)
                    .frame(height: 1)
            }
    }

    private var dateLine: Text {
        Text("summary.journal.date \(Date.now.formatted(date: .numeric, time: .omitted))")
    }

    /// "Focou [N minutos] em [Matéria]" — or the early-finish variant.
    private var focusLine: Text {
        let prefix: Text = switch payload {
        case .completed: Text("summary.journal.focusedPrefix")
        case .endedEarly: Text("summary.journal.endedEarlyPrefix")
        }
        let minutes = Text("summary.journal.minutes \(payload.minutes)")
            .foregroundStyle(DS.Colors.accentStreak)
        guard let target = focusTarget else { return prefix + minutes }
        return prefix + minutes
            + Text("summary.journal.connector")
            + Text(verbatim: target).foregroundStyle(DS.Colors.brandGreen)
    }

    /// "Ganhou [X XP] e [Y moedas]" — completed sessions only.
    private func rewardLine(for summary: CompletedSessionSummary) -> Text {
        Text("summary.journal.earnedPrefix")
            + Text("summary.journal.xp \(summary.result.xpEarned)")
                .foregroundStyle(DS.Colors.brandGreen)
            + Text("summary.journal.and")
            + Text("summary.journal.coins \(summary.result.coinsEarned)")
                .foregroundStyle(DS.Colors.accentStreak)
    }

    private var focusTarget: String? {
        if let label = focusLabel?.trimmingCharacters(in: .whitespacesAndNewlines), !label.isEmpty {
            return label
        }
        return subject
    }

    // MARK: - Right-hand actions

    private var actionColumn: some View {
        VStack(spacing: DS.Spacing.sm) {
            if let shareImage {
                ShareLink(
                    item: shareImage,
                    preview: SharePreview(Text("summary.share"), image: shareImage)
                ) {
                    Image(systemName: "square.and.arrow.up")
                        .font(DS.Typography.callout)
                        .foregroundStyle(DS.Colors.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(Circle().strokeBorder(DS.Colors.borderSubtle, lineWidth: 1))
                }
                .accessibilityLabel(Text("summary.share"))
            }

            Button {
                onContinue()
            } label: {
                Text("summary.continue")
                    .font(DS.Typography.callout)
                    .foregroundStyle(DS.Colors.textOnBrand)
                    .padding(.horizontal, DS.Spacing.md)
                    .frame(height: 44)
                    .background(DS.Colors.brandGreen, in: Capsule())
            }
        }
    }

    // MARK: - Footer (reward card + break link)

    @ViewBuilder
    private var footer: some View {
        if case .completed(let summary) = payload {
            if let reward = SummaryReward.from(summary.result) {
                SummaryRewardCard(reward: reward, shareImage: shareImage)
            }

            if let onTakeBreak {
                Button {
                    onTakeBreak()
                } label: {
                    Text("summary.takeBreak")
                        .font(DS.Typography.callout)
                        .foregroundStyle(DS.Colors.textPrimary)
                        .shadow(color: DS.Colors.bgCanvas.opacity(0.6), radius: 3)
                        .underline()
                }
            }
        }
    }

    // MARK: - Share card (placeholder until F-12 story cards)

    /// Scenery frame + journal focus line, rendered off-screen for the share
    /// sheet.
    private var shareCard: some View {
        ZStack {
            Image(scenery.staticImageName)
                .resizable()
                .interpolation(.none)
                .aspectRatio(contentMode: .fill)
                .frame(width: 360, height: 450)
                .clipped()
            VStack(spacing: DS.Spacing.sm) {
                Spacer()
                focusLine
                    .font(DS.Typography.headline)
                    .foregroundStyle(DS.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .shadow(color: DS.Colors.bgCanvas.opacity(0.85), radius: 6)
                Text(verbatim: "EGO")
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.textSecondary)
                    .shadow(color: DS.Colors.bgCanvas.opacity(0.85), radius: 4)
            }
            .padding(DS.Spacing.lg)
        }
        .frame(width: 360, height: 450)
    }

    @MainActor
    private func renderShareCard() {
        let renderer = ImageRenderer(content: shareCard)
        renderer.scale = 3
        if let uiImage = renderer.uiImage {
            shareImage = Image(uiImage: uiImage)
        }
    }
}

#Preview("Concluída") {
    SessionSummaryView(
        payload: .completed(CompletedSessionSummary(
            minutes: 25,
            result: SessionCompletionService.Result(
                xpEarned: 35,
                coinsEarned: 5,
                didLevelUp: true,
                newLevel: 2,
                streakOutcome: .extended,
                streakCurrent: 4,
                freezesEarned: 1,
                goalsCompleted: 1
            )
        )),
        scenery: .day,
        focusLabel: "Revisão de matemática",
        onTakeBreak: {}
    )
}

#Preview("Encerrada antes") {
    SessionSummaryView(payload: .endedEarly(minutes: 12), subject: "Matemática")
}
