import SwiftUI

/// Tokens de design. Tout passe par ici — pas de littéraux dispersés dans les
/// vues. L'app vit en mode sombre (ambiance soirée), les couleurs sont pensées
/// pour ce contexte.
enum Theme {

    // MARK: Espacements

    enum Spacing {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 12
        static let md: CGFloat = 20
        static let lg: CGFloat = 32
        static let xl: CGFloat = 48
    }

    enum Radius {
        static let card: CGFloat = 36
        static let control: CGFloat = 22
    }

    // MARK: Typographie (police système, SF Pro Rounded pour la chaleur)

    enum Font {
        static func cardText(_ size: CGFloat = 30) -> SwiftUI.Font {
            .system(size: size, weight: .semibold, design: .rounded)
        }
        static let title = SwiftUI.Font.system(.largeTitle, design: .rounded).weight(.bold)
        static let badge = SwiftUI.Font.system(.subheadline, design: .rounded).weight(.semibold)
        static let button = SwiftUI.Font.system(.headline, design: .rounded).weight(.semibold)
    }

    // MARK: Couleurs par palier (codage visuel de la montée — §7)

    /// Accent d'un palier : doux/pastel → chaud → profond/intense.
    static func accent(for level: Level) -> Color {
        switch level {
        case .soft:    return Color(red: 0.96, green: 0.62, blue: 0.70) // rose tendre
        case .pimente: return Color(red: 0.98, green: 0.52, blue: 0.31) // orange chaud
        case .chaud:   return Color(red: 0.86, green: 0.16, blue: 0.36) // rouge profond
        }
    }

    /// Dégradé d'ambiance plein écran derrière le contenu, par palier.
    static func ambiance(for level: Level) -> LinearGradient {
        let base = accent(for: level)
        return LinearGradient(
            colors: [
                base.opacity(0.42),
                Color.black.opacity(0.92),
                Color.black
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Fond neutre des écrans hors carte (accueil, fin).
    static let surface = Color.black
}
