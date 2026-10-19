import Foundation

/// Repertório content-pack decoding + validation (docs/08 §2 pipeline:
/// JSON → validation → seed). Pure; persistence happens in the repository.
nonisolated enum RepertorioPackImporter {
    static let supportedVersion = 1

    struct Pack: Decodable, Equatable {
        let version: Int
        let pack: String
        let flashcards: [Item]
    }

    struct Item: Decodable, Equatable {
        let externalId: String
        let theme: String
        let front: String
        let back: String
    }

    static func decode(_ data: Data) throws -> Pack {
        try JSONDecoder().decode(Pack.self, from: data)
    }

    /// Human-readable validation problems, indexed per card; empty = valid.
    static func validate(_ pack: Pack) -> [String] {
        var problems: [String] = []
        if pack.version != supportedVersion {
            problems.append("unsupported version \(pack.version)")
        }

        var seenIDs = Set<String>()
        for (index, item) in pack.flashcards.enumerated() {
            func flag(_ reason: String) {
                problems.append("flashcard[\(index)] (\(item.externalId)): \(reason)")
            }
            if item.externalId.trimmingCharacters(in: .whitespaces).isEmpty {
                flag("empty externalId")
            } else if !seenIDs.insert(item.externalId).inserted {
                flag("duplicate externalId")
            }
            if item.theme.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                flag("empty theme")
            }
            if item.front.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                flag("empty front")
            }
            if item.back.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                flag("empty back")
            }
        }
        return problems
    }
}
