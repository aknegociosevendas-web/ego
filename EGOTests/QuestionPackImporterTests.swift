import Foundation
import Testing
@testable import EGO

@MainActor
struct QuestionPackImporterTests {
    func packJSON(
        version: Int = 1,
        externalId: String = "t-001",
        year: Int = 2024,
        difficulty: Int = 2,
        options: [String] = ["A", "B", "C"],
        correctIndex: Int = 1,
        statement: String = "Enunciado de teste?",
        duplicate: Bool = false
    ) -> Data {
        let optionsJSON = "[" + options.map { "\"\($0)\"" }.joined(separator: ", ") + "]"
        let item = """
        {"externalId": "\(externalId)", "exam": "ENEM", "year": \(year),
         "subject": "Matemática", "topic": "Funções", "difficulty": \(difficulty),
         "statement": "\(statement)", "options": \(optionsJSON),
         "correctIndex": \(correctIndex), "explanation": "Porque sim.",
         "source": "Teste", "licenseNote": "Original"}
        """
        let questions = duplicate ? "[\(item), \(item)]" : "[\(item)]"
        return Data("""
        {"version": \(version), "pack": "teste", "questions": \(questions)}
        """.utf8)
    }

    func problems(_ data: Data) throws -> [String] {
        QuestionPackImporter.validate(try QuestionPackImporter.decode(data), currentYear: 2026)
    }

    @Test func validPackHasNoProblems() throws {
        #expect(try problems(packJSON()).isEmpty)
    }

    @Test func validationCatchesEachRule() throws {
        #expect(try !problems(packJSON(version: 2)).isEmpty)
        #expect(try !problems(packJSON(externalId: " ")).isEmpty)
        #expect(try !problems(packJSON(duplicate: true)).isEmpty)
        #expect(try !problems(packJSON(options: ["A"])).isEmpty)
        #expect(try !problems(packJSON(correctIndex: 3)).isEmpty)
        #expect(try !problems(packJSON(difficulty: 4)).isEmpty)
        #expect(try !problems(packJSON(year: 1990)).isEmpty)
        #expect(try !problems(packJSON(year: 2030)).isEmpty)
        #expect(try !problems(packJSON(statement: " ")).isEmpty)
    }

    @Test func problemsIncludeQuestionIndex() throws {
        let issues = try problems(packJSON(correctIndex: 7))
        #expect(issues.contains { $0.contains("question[0]") && $0.contains("t-001") })
    }

    @Test func upsertDedupesByExternalId() throws {
        let container = try PersistenceController.makeInMemoryContainer()
        let di = DIContainer(modelContainer: container)
        let pack = try QuestionPackImporter.decode(packJSON())

        let first = try di.questionRepository.upsert(pack.questions)
        let second = try di.questionRepository.upsert(pack.questions)

        #expect(first == 1)
        #expect(second == 0)
        #expect(try di.questionRepository.fetchAll().count == 1)
        let question = try di.questionRepository.fetchAll()[0]
        #expect(question.options == ["A", "B", "C"])
        #expect(question.correctIndex == 1)
    }

    @Test func bundledSeedPackIsValid() throws {
        // The shipping seed must always pass its own validation.
        let url = try #require(Bundle.main.url(forResource: "questions-seed", withExtension: "json"))
        let pack = try QuestionPackImporter.decode(Data(contentsOf: url))
        #expect(QuestionPackImporter.validate(pack, currentYear: 2026).isEmpty)
        #expect(pack.questions.count >= 10)
        // Sourcing decision: originals only, no third-party reproductions.
        #expect(pack.questions.allSatisfy { $0.source == "Item original EGO" })
    }
}
