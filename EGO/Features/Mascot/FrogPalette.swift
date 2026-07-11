import SwiftUI

/// Sprite art palette from assets/mascot/MASCOT-ANIMATION-REFERENCE.md.
/// These are pixel-art colors, not UI tokens — hex is allowed here by design
/// (the UI around the mascot still uses DS tokens; sparks reuse `accentStreak`).
enum FrogPalette {
    static let outline = Color(frogHex: 0x183619)
    static let green = Color(frogHex: 0x6B8F3C)
    static let greenLight = Color(frogHex: 0x88A94E)
    static let greenDark = Color(frogHex: 0x49661F)
    static let belly = Color(frogHex: 0xAEC473)
    static let bellyDark = Color(frogHex: 0x93AA5C)
    static let spots = Color(frogHex: 0x3C5320)
    static let eyeWhite = Color(frogHex: 0xF3F7E8)
    static let pupil = Color(frogHex: 0x152012)
    static let blush = Color(frogHex: 0xE58A86)
    static let hat = Color(frogHex: 0x7C4A26)
    static let hatDark = Color(frogHex: 0x573216)
    static let hatLight = Color(frogHex: 0x9C6538)
    static let book = Color(frogHex: 0xB8463A)
    static let bookPage = Color(frogHex: 0xF2EAD2)
    static let tear = Color(frogHex: 0x8FB0C9)
    /// Amber celebration sparks map to the locked streak accent token.
    static let spark = DS.Colors.accentStreak
}

private extension Color {
    init(frogHex hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
