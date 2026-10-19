import Foundation
import Observation

/// F-07 browse state: filters over the local bank + today's review queue.
@MainActor
@Observable
final class QuestionBankViewModel {
    private let questionRepository: QuestionRepository
    private let reviewItemRepository: ReviewItemRepository

    var filters = QuestionFilters()
    var timedPractice = false
    private(set) var allQuestions: [Question] = []
    private(set) var dueQuestions: [Question] = []

    init(questionRepository: QuestionRepository, reviewItemRepository: ReviewItemRepository) {
        self.questionRepository = questionRepository
        self.reviewItemRepository = reviewItemRepository
    }

    var filtered: [Question] {
        allQuestions.filter { question in
            (filters.exam == nil || question.exam == filters.exam)
                && (filters.year == nil || question.year == filters.year)
                && (filters.subject == nil || question.subject == filters.subject)
                && (filters.topic == nil || question.topic == filters.topic)
                && (filters.difficulty == nil || question.difficulty == filters.difficulty)
        }
    }

    var exams: [String] { distinct(\.exam) }
    var subjects: [String] { distinct(\.subject) }
    var years: [Int] { Array(Set(allQuestions.compactMap(\.year))).sorted(by: >) }
    var difficulties: [Int] { Array(Set(allQuestions.compactMap(\.difficulty))).sorted() }

    /// Topics narrow to the selected subject when one is set.
    var topics: [String] {
        let pool = filters.subject == nil
            ? allQuestions
            : allQuestions.filter { $0.subject == filters.subject }
        return Array(Set(pool.compactMap(\.topic))).sorted()
    }

    func refresh(now: Date = .now) {
        allQuestions = (try? questionRepository.fetchAll()) ?? []
        dueQuestions = ((try? reviewItemRepository.dueItems(on: now)) ?? [])
            .compactMap(\.question)
        // Selected topic may no longer exist under a new subject filter.
        if let topic = filters.topic, !topics.contains(topic) {
            filters.topic = nil
        }
    }

    private func distinct(_ keyPath: KeyPath<Question, String?>) -> [String] {
        Array(Set(allQuestions.compactMap { $0[keyPath: keyPath] })).sorted()
    }
}
