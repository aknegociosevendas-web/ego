import SwiftUI

/// Selectable ambience for the focus flow (F-01 redesign, slice 5): two
/// illustrated frame sequences in the catalog (`SceneDayFocus00…31`,
/// `SceneNightFocus00…31`, 440×953, authored for an 8fps seamless loop —
/// see the asset README). The choice persists via
/// `@AppStorage(FocusScenery.storageKey)` — a device preference,
/// deliberately outside SwiftData.
enum FocusScenery: String, CaseIterable, Identifiable {
    case day
    case night

    static let storageKey = "focusScenery"
    /// Frames per sequence and their authored cadence (8 fps → 4s loop).
    static let frameCount = 32
    static let frameRate: Double = 8

    /// Storage migration: slice 4 stored `nightLake`/`forest`/`swamp`; any
    /// unknown value silently falls back to `.night`.
    static func from(storageValue: String) -> FocusScenery {
        FocusScenery(rawValue: storageValue) ?? .night
    }

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .day: "scenery.day"
        case .night: "scenery.night"
        }
    }

    private var framePrefix: String {
        switch self {
        case .day: "SceneDayFocus"
        case .night: "SceneNightFocus"
        }
    }

    func frameImageName(_ index: Int) -> String {
        framePrefix + String(format: "%02d", min(max(index, 0), Self.frameCount - 1))
    }

    /// Frame shown wherever the scene shouldn't animate (setup preview,
    /// summary background, Reduce Motion).
    var staticImageName: String { frameImageName(0) }
}

/// Sheet picker for the focus ambience: one static miniature per scenery.
struct ScenePickerView: View {
    @Binding var selection: FocusScenery
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Text("scenery.title")
                .font(DS.Typography.title)
                .foregroundStyle(DS.Colors.textPrimary)

            HStack(spacing: DS.Spacing.sm) {
                ForEach(FocusScenery.allCases) { scenery in
                    sceneryCard(scenery)
                }
            }

            Spacer()
        }
        .padding(DS.Spacing.screenPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DS.Colors.bgCanvas)
    }

    private func sceneryCard(_ scenery: FocusScenery) -> some View {
        let isSelected = scenery == selection
        return Button {
            selection = scenery
            dismiss()
        } label: {
            VStack(spacing: DS.Spacing.xs) {
                Image(scenery.staticImageName)
                    .resizable()
                    .interpolation(.none)
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 170)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.card)
                            .strokeBorder(
                                isSelected ? DS.Colors.brandGreen : DS.Colors.borderSubtle,
                                lineWidth: isSelected ? 2.5 : 1
                            )
                    )
                Text(scenery.titleKey)
                    .font(DS.Typography.caption)
                    .foregroundStyle(isSelected ? DS.Colors.textPrimary : DS.Colors.textSecondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(scenery.titleKey))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    ScenePickerView(selection: .constant(.night))
}
