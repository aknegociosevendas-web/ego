import Foundation

/// Content-pack decoding + validation (docs/08 §1 pipeline:
/// JSON → validation → seed). Pure; persistence happens in the repository.
nonisolated enum QuestionPackImporter {
    static let supportedVersion = 1

    struct Pack: Decodable, Equatable {
        let version: Int
        let pack: String
        let questions: [Item]
    }

    struct Item: Decodable, Equatable {
        let externalId: String
        let exam: String
        let year: Int
        let subject: String
        let topic: String?
        let difficulty: Int
        let statement: String
        let options: [String]
        let correctIndex: Int
        let explanation: String?
        let source: String?
        let licenseNote: String?
    }

    static func decode(_ data: Data) throws -> Pack {
        try JSONDecoder().decode(Pack.self, from: data)
    }

    /// Human-readable validation problems, indexed per question; empty = valid.
    static func validate(_ pack: Pack, currentYear: Int) -> [String] {
        var problems: [String] = []
        if pack.version != supportedVersion {
            problems.append("unsupported version \(pack.version)")
        }

        var seenIDs = Set<String>()
        for (index, item) in pack.questions.enumerated() {
            func flag(_ reason: String) {
                problems.append("question[\(index)] (\(item.externalId)): \(reason)")
            }
            if item.externalId.trimmingCharacters(in: .whitespaces).isEmpty {
                flag("empty externalId")
            } else if !seenIDs.insert(item.externalId).inserted {
                flag("duplicate externalId")
            }
            if item.statement.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                flag("empty statement")
            }
            if item.exam.isEmpty { flag("empty exam") }
            if item.subject.isEmpty { flag("empty subject") }
            if !(2...5).contains(item.options.count) {
                flag("needs 2–5 options, got \(item.options.count)")
            }
            if !item.options.indices.contains(item.correctIndex) {
                flag("correctIndex \(item.correctIndex) out of range")
            }
            if !(1...3).contains(item.difficulty) {
                flag("difficulty must be 1–3")
            }
            if !(1998...currentYear).contains(item.year) {
                flag("implausible year \(item.year)")
            }
        }
        return problems
    }
}
