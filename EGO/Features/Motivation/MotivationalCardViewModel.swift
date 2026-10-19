import Foundation
import Observation

/// State + actions for `MotivationalCardView` (slice 7). Dumb by design:
/// text/category come from the presented card; navigation intents are
/// injected closures (the presenter owns the queue). Share rendering lives in
/// the view (ImageRenderer is a UI concern, same pattern as the summary).
@MainActor
@Observable
final class MotivationalCardViewModel {
    let text: String
    let category: NotificationCategory

    private let onFocusNow: () -> Void
    private let onDismiss: () -> Void

    init(
        card: MotivationalCardPresenter.Card,
        onFocusNow: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.text = card.text
        self.category = card.category
        self.onFocusNow = onFocusNow
        self.onDismiss = onDismiss
    }

    /// Frog reaction per category (closest existing sprites — there's no
    /// dedicated celebrating/sleeping sheet yet).
    var mascotState: MascotState {
        switch category {
        case .milestone: .levelUp
        case .streakAtRisk: .worried
        case .morningBoost: .happy
        case .afternoonFocus: .studying
        case .comeback, .eveningWindDown, .sessionReminder, .generic: .idle
        }
    }

    func focusNow() {
        onFocusNow()
    }

    func dismiss() {
        onDismiss()
    }
}
