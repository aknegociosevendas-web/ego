import Foundation

/// Bundled seed phrases in the mascot's voice (docs/05 §6: caring, upbeat,
/// never mocking). Content data stored in `NotificationTemplate` rows —
/// PT-BR literals by design, like subjects.
enum NotificationPhraseCatalog {
    struct Entry {
        let key: String
        let phrase: String
        let category: String
    }

    static let seeds: [Entry] = [
        // Daily session reminder
        Entry(key: "reminder.1", phrase: "Bora focar? Já peguei o livro pra gente. 📚", category: NotificationTemplate.Category.reminder),
        Entry(key: "reminder.2", phrase: "Hora de estudar! Eu acompanho você. 🐸", category: NotificationTemplate.Category.reminder),
        Entry(key: "reminder.3", phrase: "Uma sessão de foco agora e o dia está ganho!", category: NotificationTemplate.Category.reminder),
        Entry(key: "reminder.4", phrase: "Partiu revisar? Prometo não piscar.", category: NotificationTemplate.Category.reminder),
        // Streak at risk
        Entry(key: "streak.1", phrase: "Sua sequência está em risco! Uma sessão salva o dia. 🔥", category: NotificationTemplate.Category.streak),
        Entry(key: "streak.2", phrase: "Não deixa a chama apagar — ainda dá tempo!", category: NotificationTemplate.Category.streak),
        Entry(key: "streak.3", phrase: "Eu seguro o livro, você segura a sequência?", category: NotificationTemplate.Category.streak),
        // Comeback
        Entry(key: "comeback.1", phrase: "Senti sua falta… bora voltar aos estudos? 🐸", category: NotificationTemplate.Category.comeback),
        Entry(key: "comeback.2", phrase: "Alguns dias sem focar — que tal recomeçar agora?", category: NotificationTemplate.Category.comeback),
        Entry(key: "comeback.3", phrase: "Continuo aqui, esperando. Uma sessãozinha?", category: NotificationTemplate.Category.comeback),
        // Soft-focus (left the app mid-session)
        Entry(key: "softFocus.1", phrase: "Ei! A sessão ainda está rodando 👀", category: NotificationTemplate.Category.softFocus),
        Entry(key: "softFocus.2", phrase: "Volta! Estou segurando o foco sozinho aqui…", category: NotificationTemplate.Category.softFocus),
        Entry(key: "softFocus.3", phrase: "Sua sessão está em risco — respira e volta!", category: NotificationTemplate.Category.softFocus),
    ]
}
