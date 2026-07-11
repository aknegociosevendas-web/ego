import Foundation

/// Preset subjects for session attribution. These are content data stored in
/// `FocusSession.subject` (like `examTarget`), not UI chrome — hence PT-BR
/// literals instead of xcstrings keys.
enum SubjectCatalog {
    static let presets = [
        "Matemática",
        "Português",
        "Redação",
        "Física",
        "Química",
        "Biologia",
        "História",
        "Geografia",
        "Filosofia/Sociologia",
        "Inglês",
    ]
}
