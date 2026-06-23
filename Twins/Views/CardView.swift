import SwiftUI

/// Une carte = un écran. Le grand texte est la star : il vit sur un matériau
/// standard (jamais sur du verre — illisible), bien aéré, Dynamic Type respecté.
struct CardView: View {
    let card: Card

    private var accent: Color { Theme.accent(for: card.level) }

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            header

            Spacer(minLength: 0)

            Text(card.text)
                .font(Theme.Font.cardText())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Theme.Spacing.sm)
                .accessibilityAddTraits(.isStaticText)

            Spacer(minLength: 0)

            // Espace réservé pour que le texte respire au-dessus des contrôles.
            Color.clear.frame(height: Theme.Spacing.xl)
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                        .stroke(accent.opacity(0.45), lineWidth: 1)
                )
        }
        .padding(Theme.Spacing.md)
    }

    private var header: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: card.type.symbolName)
            Text(card.type.label.uppercased())
        }
        .font(Theme.Font.badge)
        .foregroundStyle(accent)
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background(accent.opacity(0.16), in: Capsule())
        .overlay(Capsule().stroke(accent.opacity(0.4), lineWidth: 1))
        .accessibilityLabel("Carte \(card.type.label), niveau \(card.level.title)")
    }
}
