import Foundation
import SwiftData

/// Builds the app-wide `ModelContainer` (docs/02 §5).
enum PersistenceController {
    /// Must match the container in Signing & Capabilities / the developer portal.
    static let cloudKitContainerID = "iCloud.com.ego.EGO"

    /// Single schema for every configuration so stores stay compatible.
    static var schema: Schema {
        Schema([
            UserProfile.self,
            UserStats.self,
            SubjectStat.self,
            FocusSession.self,
            Streak.self,
            Wallet.self,
            CoinTransaction.self,
            Reminder.self,
            NotificationTemplate.self,
            Routine.self,
            RoutineBlock.self,
            RoutineLog.self,
            TopicGoal.self,
            Question.self,
            QuestionAttempt.self,
            ReviewItem.self,
            EssayTemplate.self,
            EssayDraft.self,
            EssayFlashcard.self,
        ])
    }

    /// CloudKit-backed (private DB) container for the running app.
    /// In DEBUG, falls back to a local-only store when CloudKit is unavailable
    /// (simulator without an iCloud account, entitlement not yet provisioned)
    /// so development isn't blocked on portal setup.
    static func makeAppContainer() -> ModelContainer {
        do {
            let configuration = ModelConfiguration(
                schema: schema,
                cloudKitDatabase: .private(cloudKitContainerID)
            )
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            #if DEBUG
            return makeLocalContainer()
            #else
            fatalError("Could not create CloudKit ModelContainer: \(error)")
            #endif
        }
    }

    /// In-memory container for unit tests and previews. Named per instance:
    /// unnamed in-memory configurations share the /dev/null store identity,
    /// so parallel test suites hammering the same entity trap inside
    /// SwiftData (EXC_BREAKPOINT on fetch/save).
    static func makeInMemoryContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(
            UUID().uuidString,
            schema: schema,
            isStoredInMemoryOnly: true,
            allowsSave: true,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private static func makeLocalContainer() -> ModelContainer {
        do {
            let configuration = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            #if DEBUG
            // Last-resort dev fallback (e.g. a store poisoned by an earlier
            // schema mistake) — never kill the app/test host over dev data.
            print("⚠️ Local store failed (\(error)); falling back to in-memory")
            guard let container = try? makeInMemoryContainer() else {
                fatalError("Could not create any ModelContainer: \(error)")
            }
            return container
            #else
            fatalError("Could not create local ModelContainer: \(error)")
            #endif
        }
    }
}
