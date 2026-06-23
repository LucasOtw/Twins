import SwiftUI

/// Écran d'annonce de montée de palier (« Ça se réchauffe… 🔥 »). C'est un
/// moment de jeu, pas un changement silencieux.
struct LevelTransitionView: View {
    let level: Level

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private var accent: Color { Theme.accent(for: level) }

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            Spacer()

            Text(level.emoji)
                .font(.system(size: 88))
                .scaleEffect(appeared || reduceMotion ? 1 : 0.4)
                .opacity(appeared || reduceMotion ? 1 : 0)

            Text(level.teaser)
                .font(.system(.title, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("Niveau \(level.rawValue) · \(level.title)")
                .font(Theme.Font.badge)
                .foregroundStyle(accent)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.xs)
                .background(accent.opacity(0.18), in: Capsule())
                .overlay(Capsule().stroke(accent.opacity(0.5), lineWidth: 1))

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Theme.Spacing.lg)
        .opacity(appeared || reduceMotion ? 1 : 0)
        .onAppear {
            guard !reduceMotion else { appeared = true; return }
            withAnimation(.bouncy(duration: 0.6)) { appeared = true }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(level.teaser) Niveau \(level.rawValue), \(level.title)")
    }
}
