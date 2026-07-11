import Foundation

/// Bundled routine templates (docs/01 F-05). Content data in PT-BR (like
/// subjects); weekdays follow `Calendar` convention (1 = Sunday).
enum RoutineTemplateCatalog {
    struct BlockSpec {
        let weekday: Int
        let subject: String
        let minutes: Int
        let sessions: Int
    }

    struct Template: Identifiable {
        let key: String
        let name: String
        let blocks: [BlockSpec]
        var id: String { key }
    }

    static let templates: [Template] = [
        Template(key: "enem6m", name: "ENEM 6 meses", blocks: [
            BlockSpec(weekday: 2, subject: "Matemática", minutes: 100, sessions: 2),
            BlockSpec(weekday: 3, subject: "Português", minutes: 100, sessions: 2),
            BlockSpec(weekday: 4, subject: "Física", minutes: 50, sessions: 1),
            BlockSpec(weekday: 4, subject: "Química", minutes: 50, sessions: 1),
            BlockSpec(weekday: 5, subject: "História", minutes: 50, sessions: 1),
            BlockSpec(weekday: 5, subject: "Geografia", minutes: 50, sessions: 1),
            BlockSpec(weekday: 6, subject: "Redação", minutes: 100, sessions: 2),
            BlockSpec(weekday: 7, subject: "Biologia", minutes: 50, sessions: 1),
        ]),
        Template(key: "intensivo", name: "Intensivo", blocks: [
            BlockSpec(weekday: 2, subject: "Matemática", minutes: 150, sessions: 3),
            BlockSpec(weekday: 3, subject: "Português", minutes: 150, sessions: 3),
            BlockSpec(weekday: 4, subject: "Física", minutes: 100, sessions: 2),
            BlockSpec(weekday: 4, subject: "Química", minutes: 50, sessions: 1),
            BlockSpec(weekday: 5, subject: "Biologia", minutes: 100, sessions: 2),
            BlockSpec(weekday: 6, subject: "Redação", minutes: 100, sessions: 2),
            BlockSpec(weekday: 6, subject: "História", minutes: 50, sessions: 1),
            BlockSpec(weekday: 7, subject: "Geografia", minutes: 100, sessions: 2),
            BlockSpec(weekday: 1, subject: "Inglês", minutes: 50, sessions: 1),
        ]),
        Template(key: "revisao", name: "Revisão pré-prova", blocks: [
            BlockSpec(weekday: 2, subject: "Redação", minutes: 50, sessions: 1),
            BlockSpec(weekday: 3, subject: "Matemática", minutes: 50, sessions: 1),
            BlockSpec(weekday: 4, subject: "Redação", minutes: 50, sessions: 1),
            BlockSpec(weekday: 5, subject: "Matemática", minutes: 50, sessions: 1),
            BlockSpec(weekday: 6, subject: "Português", minutes: 50, sessions: 1),
        ]),
    ]

    static func template(forKey key: String) -> Template? {
        templates.first { $0.key == key }
    }
}
