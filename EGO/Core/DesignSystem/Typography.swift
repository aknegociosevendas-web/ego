import SwiftUI

extension DS {
    /// Type scale from docs/04 §3. SF Pro through Dynamic Type text styles so
    /// every size scales with the user's accessibility settings.
    /// Placeholder until a brand font is locked.
    enum Typography {
        /// 34 / bold
        static let display = Font.system(.largeTitle, weight: .bold)
        /// 28 / bold
        static let title = Font.system(.title, weight: .bold)
        /// 20 / semibold
        static let headline = Font.system(.title3, weight: .semibold)
        /// 17 / regular
        static let body = Font.system(.body)
        /// 15 / regular
        static let callout = Font.system(.callout)
        /// 13 / regular (SF Pro footnote is the 13pt style)
        static let caption = Font.system(.footnote)
    }
}
