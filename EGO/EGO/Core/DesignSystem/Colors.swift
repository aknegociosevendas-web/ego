import SwiftUI

/// Namespace for design-system tokens (docs/04-DESIGN-SYSTEM.md).
enum DS {}

extension DS {
    /// Semantic color tokens. Each maps to a color set in `Assets.xcassets`
    /// carrying the LOCKED green palette (light + dark variants, docs/04 §2).
    /// Views use these tokens only — never raw hex or `Color` literals.
    enum Colors {
        static let brandGreen = Color("BrandGreen")
        static let brandGreenDeep = Color("BrandGreenDeep")
        static let brandGreenSoft = Color("BrandGreenSoft")
        static let accentStreak = Color("AccentStreak")
        static let accentFocus = Color("AccentFocus")
        static let stateSuccess = Color("StateSuccess")
        static let stateDanger = Color("StateDanger")
        static let bgCanvas = Color("BgCanvas")
        static let bgSurface = Color("BgSurface")
        static let bgSurfaceAlt = Color("BgSurfaceAlt")
        static let borderSubtle = Color("BorderSubtle")
        static let textPrimary = Color("TextPrimary")
        static let textSecondary = Color("TextSecondary")
        /// Foreground for content sitting on `brandGreen` (not in docs/04 §2;
        /// added so components never hard-code white).
        static let textOnBrand = Color("TextOnBrand")
    }
}
