import Foundation

/// Shared XP granting: bumps the profile, recomputes level and fires the
/// mascot on level-up. Used by the question/essay services (the session
/// path keeps its own inline flow).
@MainActor
final class XPService {
    private let userProfileRepository: UserProfileRepository
    private let mascotEvents: MascotEventCenter

    init(userProfileRepository: UserProfileRepository, mascotEvents: MascotEventCenter) {
        self.userProfileRepository = userProfileRepository
        self.mascotEvents = mascotEvents
    }

    /// Returns whether the grant caused a level-up.
    @discardableResult
    func grant(_ xp: Int, at date: Date = .now) throws -> Bool {
        guard xp > 0 else { return false }
        let profile = try userProfileRepository.fetchOrCreate()
        profile.xp += xp
        let newLevel = GamificationLogic.level(forXP: profile.xp)
        let didLevelUp = newLevel > profile.level
        profile.level = newLevel
        profile.updatedAt = date
        try userProfileRepository.save()
        if didLevelUp {
            mascotEvents.leveledUp()
        }
        return didLevelUp
    }
}
