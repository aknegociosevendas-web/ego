import Foundation

/// Persistence boundary for the single local user profile.
@MainActor
protocol UserProfileRepository: AnyObject {
    /// Returns the profile, creating it on first access (single-user app).
    func fetchOrCreate() throws -> UserProfile
    func save() throws
}
