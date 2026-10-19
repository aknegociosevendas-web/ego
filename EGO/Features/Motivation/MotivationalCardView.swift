import SwiftUI

/// Illustrated motivational card (slice 7): opened by a notification tap or
/// an in-app milestone. Home scene dimmed behind, category badge on top,
/// large reacting frog, the phrase in the mascot's voice, and three actions —
/// share (story-sized render), focus now, later. Entrance is fade + scale
/// 0.95→1 in 300ms; Reduce Motion drops the scale.
struct MotivationalCardView: View {
    let viewModel: MotivationalCardViewModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    @State private var shareImage: Image?

    var body: some View {
        ZStack {
            ForestSceneView()
                .ignoresSafeArea()
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: DS.Spacing.lg) {
                badge
                    .padding(.top, DS.Spacing.xl)

                MascotView(state: viewModel.mascotState)
                    .frame(width: 180, height: 180)

                Text(verbatim: viewModel.text)
                    .font(DS.Typography.title)
                    .foregroundStyle(DS.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)
                    .shadow(color: DS.Colors.bgCanvas.opacity(0.7), radius: 5)
                    .padding(.horizontal, DS.Spacing.xxl)

                Text("card.signature")
                    .font(DS.Typography.caption.italic())
                    .foregroundStyle(DS.Colors.textSecondary)

                Spacer()

                actions
                    .padding(.bottom, DS.Spacing.xxxl)
            }
            .padding(.horizontal, DS.Spacing.screenPadding)
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(reduceMotion ? 1 : (appeared ? 1 : 0.95))
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                appeared = true
            }
        }
        .task {
            renderShareCard()
        }
    }

    private var badge: some View {
        Text(badgeKey)
            .font(DS.Typography.caption)
            .fontWeight(.semibold)
            .foregroundStyle(DS.Colors.textSecondary)
            .padding(.horizontal, DS.Spacing.sm)
            .padding(.vertical, DS.Spacing.xs)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(DS.Colors.borderSubtle.opacity(0.6), lineWidth: 1))
    }

    private var badgeKey: LocalizedStringKey {
        switch viewModel.category {
        case .comeback: "card.badge.comeback"
        case .streakAtRisk: "card.badge.streakAtRisk"
        case .morningBoost: "card.badge.morningBoost"
        case .afternoonFocus: "card.badge.afternoonFocus"
        case .eveningWindDown: "card.badge.eveningWindDown"
        case .milestone: "card.badge.milestone"
        case .sessionReminder: "card.badge.sessionReminder"
        case .generic: "card.badge.generic"
        }
    }

    private var actions: some View {
        HStack(spacing: DS.Spacing.sm) {
            if let shareImage {
                ShareLink(
                    item: shareImage,
                    preview: SharePreview(Text("summary.share"), image: shareImage)
                ) {
                    Image(systemName: "square.and.arrow.up")
                        .font(DS.Typography.callout)
                        .foregroundStyle(DS.Colors.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(Circle().strokeBorder(DS.Colors.borderSubtle, lineWidth: 1))
                }
                .accessibilityLabel(Text("summary.share"))
            }

            Button {
                viewModel.focusNow()
            } label: {
                Text("card.focusNow")
                    .font(DS.Typography.callout)
                    .foregroundStyle(DS.Colors.textOnBrand)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(DS.Colors.brandGreen, in: Capsule())
            }

            Button {
                viewModel.dismiss()
            } label: {
                Text("card.later")
                    .font(DS.Typography.callout)
                    .foregroundStyle(DS.Colors.textSecondary)
                    .frame(height: 44)
                    .padding(.horizontal, DS.Spacing.xs)
            }
            .accessibilityLabel(Text("card.later"))
        }
    }

    // MARK: - Share render (1080×1920 story format: 360×640 @3x)

    private var shareCard: some View {
        ZStack {
            ForestSceneView()
            Color.black.opacity(0.3)
            VStack(spacing: DS.Spacing.lg) {
                Spacer()
                Image(MascotSprite.restingImageName)
                    .resizable()
                    .interpolation(.none)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 160, height: 160)
                Text(verbatim: viewModel.text)
                    .font(DS.Typography.title)
                    .foregroundStyle(DS.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .shadow(color: DS.Colors.bgCanvas.opacity(0.7), radius: 5)
                Text("card.signature")
                    .font(DS.Typography.caption.italic())
                    .foregroundStyle(DS.Colors.textSecondary)
                Spacer()
                Text(verbatim: "EGO")
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.textSecondary)
                    .padding(.bottom, DS.Spacing.lg)
            }
            .padding(DS.Spacing.xl)
        }
        .frame(width: 360, height: 640)
    }

    @MainActor
    private func renderShareCard() {
        let renderer = ImageRenderer(content: shareCard)
        renderer.scale = 3
        if let uiImage = renderer.uiImage {
            shareImage = Image(uiImage: uiImage)
        }
    }
}

#Preview {
    MotivationalCardView(viewModel: MotivationalCardViewModel(
        card: .init(text: "Constância vence talento cansado.", category: .milestone),
        onFocusNow: {},
        onDismiss: {}
    ))
}
