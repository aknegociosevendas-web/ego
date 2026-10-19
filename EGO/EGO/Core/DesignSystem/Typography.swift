import SwiftUI

extension DS {
    /// Brand type scale (Nunito, rounded geometric — the immersive redesign).
    /// `Font.custom(_:size:relativeTo:)` keeps full Dynamic Type scaling.
    /// Requires `DS.Fonts.registerIfNeeded()` at launch.
    enum Typography {
        /// 34 / bold
        static let display = Font.custom(Fonts.bold, size: 34, relativeTo: .largeTitle)
        /// 28 / bold
        static let title = Font.custom(Fonts.bold, size: 28, relativeTo: .title)
        /// 20 / semibold
        static let headline = Font.custom(Fonts.semibold, size: 20, relativeTo: .title3)
        /// 17 / regular
        static let body = Font.custom(Fonts.regular, size: 17, relativeTo: .body)
        /// 15 / regular
        static let callout = Font.custom(Fonts.regular, size: 15, relativeTo: .callout)
        /// 13 / regular
        static let caption = Font.custom(Fonts.regular, size: 13, relativeTo: .footnote)
    }
}
