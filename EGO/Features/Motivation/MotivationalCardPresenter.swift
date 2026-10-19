import Foundation
import Observation

/// Single queue behind `MotivationalCardView` (slice 7): notification taps
/// (deep link) and in-app milestone celebrations both land here; cards show
/// sequentially over whatever tab is active. Owned by the DIContainer and
/// observed by `AppRouter`.
@MainActor
@Observable
final class MotivationalCardPresenter {
    struct Card: Identifiable, Equatable {
        let id = UUID()
        let text: String
        let category: NotificationCategory
    }

    /// What the single root cover shows. One presentation at a time —
    /// stacking two `.fullScreenCover`s on the same view is a SwiftUI
    /// anti-pattern that made the underlying sheet presentation racy.
    enum Route: Identifiable, Equatable {
        case card(Card)
        case focusFlow

        var id: String {
            switch self {
            case .card(let card): card.id.uuidString
            case .focusFlow: "focusFlow"
            }
        }
    }

    private(set) var route: Route?
    private var queue: [Card] = []

    private let templateRepository: NotificationTemplateRepository
    private let phraseSelector: MotivationalPhraseSelectorProtocol

    init(
        templateRepository: NotificationTemplateRepository,
        phraseSelector: MotivationalPhraseSelectorProtocol
    ) {
        self.templateRepository = templateRepository
        self.phraseSelector = phraseSelector
    }

    // MARK: - Producers

    /// Notification tap: resolve the exact phrase by id; unknown ids fall
    /// back to a fresh pick from the category.
    func presentDeepLink(phraseId: String?, categoryRaw: String) {
        let category = NotificationCategory(rawValue: categoryRaw) ?? .generic
        var text: String?
        if let phraseId,
           let template = try? templateRepository.template(key: phraseId) {
            text = template.phrase
        }
        if text == nil {
            text = selectedPhrase(for: category)
        }
        guard let text, !text.isEmpty else { return }
        queue.append(Card(text: text, category: category))
        advanceIfIdle()
    }

    /// Fresh unlocks of a completed session (level up → streak milestone →
    /// goal), one card each, queued behind the summary's dismissal. Activation
    /// is deferred one beat so the focus cover finishes dismissing before the
    /// card cover presents.
    func enqueueMilestones(from result: SessionCompletionService.Result) {
        var count = 0
        if result.didLevelUp { count += 1 }
        if result.freezesEarned > 0 { count += 1 }
        if result.goalsCompleted > 0 { count += 1 }
        guard count > 0 else { return }
        for _ in 0..<count {
            guard let text = selectedPhrase(for: .milestone), !text.isEmpty else { continue }
            queue.append(Card(text: text, category: .milestone))
        }
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(700))
            self?.advanceIfIdle()
        }
    }

    // MARK: - Flow

    /// Card "Depois": move on to the next queued card, or close.
    func dismissCard() {
        route = queue.isEmpty ? nil : .card(queue.removeFirst())
    }

    /// The root cover reported a system-driven dismissal (the focus flow
    /// called its own `dismiss()`): show the next queued card, if any.
    func coverWasDismissed() {
        route = queue.isEmpty ? nil : .card(queue.removeFirst())
    }

    /// "Focar agora": drop the queue, dismiss the card, then raise the focus
    /// flow one beat later so the single cover fully swaps content.
    func requestFocusFlow() {
        queue.removeAll()
        route = nil
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(600))
            self?.route = .focusFlow
        }
    }

    private func advanceIfIdle() {
        guard route == nil, !queue.isEmpty else { return }
        route = .card(queue.removeFirst())
    }

    private func selectedPhrase(for category: NotificationCategory) -> String? {
        (try? phraseSelector.select(for: category))?.phrase
    }
}
