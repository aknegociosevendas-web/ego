import CoreText
import Foundation

extension DS {
    /// Bundled brand font (Nunito, OFL). Registered programmatically at launch
    /// because the app's Info.plist is generated (no static `UIAppFonts`).
    /// Both the app and the widget extension register in their own process.
    enum Fonts {
        static let regular = "Nunito-Regular"
        static let semibold = "Nunito-SemiBold"
        static let bold = "Nunito-Bold"

        private static var didRegister = false

        /// Idempotent; safe to call from every process entry point.
        static func registerIfNeeded(in bundle: Bundle = .main) {
            guard !didRegister else { return }
            didRegister = true
            for name in [regular, semibold, bold] {
                guard let url = bundle.url(forResource: name, withExtension: "ttf") else { continue }
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }
}
