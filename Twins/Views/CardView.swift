import SwiftUI

/// Une carte = un écran. La carte est un objet désirable : dégradé coloré par
/// palier, filigrane décoratif, halo d'accent qui la fait flotter au-dessus de
/// l'ambiance, et un grand texte lisible qui respire.
struct CardView: View {
    let card: Card

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false
    private var accent: Color { Theme.accent(for: card.level) }

    var body: some View {
        ZStack {
            glow
            cardSurface

            VStack(spacing: Theme.Spacing.lg) {
                header
                Spacer(minLength: Theme.Spacing.md)
                Text(card.text)
                    .font(Theme.Font.cardText())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(7)
                    .minimumScaleFactor(0.6)
                    .shadow(color: .black.opacity(0.35), radius: 12, y: 4)
                    .accessibilityAddTraits(.isStaticText)
                Spacer(minLength: Theme.Spacing.md)
                footer
            }
            .padding(Theme.Spacing.lg)
        }
        // Marges qui détachent la carte de l'ambiance et la dégagent des
        // contrôles flottants (barre haute + boutons bas).
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, 60)
        .padding(.bottom, 96)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    // MARK: Halo animé

    /// Lueur d'accent diffuse derrière la carte, qui respire lentement.
    private var glow: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
            .fill(accent)
            .blur(radius: 55)
            .opacity(reduceMotion ? 0.30 : (pulse ? 0.55 : 0.28))
            .scaleEffect(reduceMotion ? 0.95 : (pulse ? 1.0 : 0.9))
            .accessibilityHidden(true)
    }

    // MARK: Surface

    private var cardSurface: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
        return shape
            .fill(Theme.cardGradient(for: card.level))
            .overlay(alignment: .bottomTrailing) { watermark }
            .clipShape(shape)
            .overlay {
                // Liseré lumineux : un dégradé d'accent plutôt qu'un trait plat.
                shape.strokeBorder(
                    LinearGradient(
                        colors: [accent.opacity(0.9), accent.opacity(0.25)],
                        startPoint: .top, endPoint: .bottom),
                    lineWidth: 1.5)
            }
            // Halo coloré qui soulève la carte du fond (désactivé si la
            // transparence est réduite, pour rester sobre et net).
            .shadow(color: reduceTransparency ? .clear : accent.opacity(0.45),
                    radius: 34, y: 14)
            .shadow(color: .black.opacity(0.5), radius: 18, y: 10)
    }

    /// Grand symbole du type, très estompé, pour habiller le fond.
    private var watermark: some View {
        Image(systemName: card.type.symbolName)
            .font(.system(size: 230, weight: .bold))
            .foregroundStyle(.white.opacity(0.07))
            .rotationEffect(.degrees(-12))
            .offset(x: 60, y: 50)
    }

    // MARK: En-tête / pied

    private var header: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: card.type.symbolName)
            Text(card.type.label.uppercased())
        }
        .font(Theme.Font.badge)
        .foregroundStyle(.white)
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.xs)
        .background(.white.opacity(0.18), in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.25), lineWidth: 1))
        .accessibilityLabel("Carte \(card.type.label), niveau \(card.level.title)")
    }

    private var footer: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Circle()
                .fill(accent)
                .frame(width: 7, height: 7)
            Text(card.level.title.uppercased())
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.7))
        }
        .accessibilityHidden(true)
    }
}
