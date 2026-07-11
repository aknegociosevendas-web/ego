import SwiftUI

/// Mascot states shipped in this slice (docs/05 §3). More states
/// (worried, sleeping, levelUp, guarding…) land with their features.
enum MascotState: Equatable {
    case idle
    case studying
    case happy
    case sad
    case worried
    case levelUp
    case guarding

    /// The mascot is decorative — a concise PT-BR label is enough.
    var accessibilityLabelKey: LocalizedStringKey {
        switch self {
        case .idle: "mascot.a11y.idle"
        case .studying: "mascot.a11y.studying"
        case .happy: "mascot.a11y.happy"
        case .sad: "mascot.a11y.sad"
        case .worried: "mascot.a11y.worried"
        case .levelUp: "mascot.a11y.levelUp"
        case .guarding: "mascot.a11y.guarding"
        }
    }
}
