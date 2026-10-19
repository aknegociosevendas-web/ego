import Foundation

extension DS {
    /// Spacing scale in points (docs/04 §4).
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 40
        /// Standard horizontal screen padding.
        static let screenPadding: CGFloat = 20
    }

    /// Corner radii (docs/04 §4).
    enum Radius {
        static let card: CGFloat = 16
        static let button: CGFloat = 12
        static let sheet: CGFloat = 24
        static let chip: CGFloat = 20
    }
}
