import SwiftUI

/// Overlay top bar for the immersive screens (redesign): hamburger → settings
/// on the left, streak badge + frog avatar → profile on the right. Sits over
/// the scene, so it carries no background of its own.
struct AppTopBar: View {
    let streak: Int
    let level: Int
    let onMenu: () -> Void
    let onAvatar: () -> Void
    /// Optional: tapping the streak badge (e.g. to open the freeze shop).
    var onStreak: (() -> Void)?

    var body: some View {
        HStack {
            Button(action: onMenu) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(DS.Colors.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().strokeBorder(DS.Colors.borderSubtle, lineWidth: 1))
            }
            .accessibilityLabel(Text("nav.menu"))
            .accessibilityIdentifier("home.menu")

            Spacer()

            HStack(spacing: DS.Spacing.xs) {
                if let onStreak {
                    Button(action: onStreak) { StreakBadge(count: streak) }
                        .buttonStyle(.plain)
                        .accessibilityHint(Text("freeze.badgeHint"))
                } else {
                    StreakBadge(count: streak)
                }
                Button(action: onAvatar) {
                    MascotAvatar(level: level)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("nav.profile"))
                .accessibilityIdentifier("home.avatar")
            }
        }
    }
}

#Preview {
    ZStack {
        DS.Colors.bgCanvas.ignoresSafeArea()
        VStack {
            AppTopBar(streak: 12, level: 7, onMenu: {}, onAvatar: {})
            Spacer()
        }
        .padding(DS.Spacing.screenPadding)
    }
}
