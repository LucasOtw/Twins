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
        case .soft:    return Color(red: 0.97, green: 0.55, blue: 0.62) // rose chaud
        case .pimente: return Color(red: 1.0, green: 0.478, blue: 0.0) // orange pétant #FF7A00
        case .chaud:   return Color(red: 0.93, green: 0.16, blue: 0.16) // rouge sensuel #ED2929
        }
    }

    /// Dégradé d'ambiance plein écran derrière le contenu, par palier.
    /// La teinte du palier irrigue plus largement l'écran → ambiance chaude,
    /// lumière tamisée, plutôt qu'un fond noir froid.
    static func ambiance(for level: Level) -> LinearGradient {
        let base = accent(for: level)
        return LinearGradient(
            colors: [
                base.opacity(0.60),
                base.opacity(0.16),
                Color.black
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Dégradé riche et coloré de la carte elle-même, par palier. Saturé en
    /// haut, profond en bas → le texte blanc reste lisible (centré sur le
    /// mi-ton sombre) tout en donnant de la couleur et du relief.
    static func cardGradient(for level: Level) -> LinearGradient {
        let top: Color
        let mid: Color
        let bottom: Color
        switch level {
        case .soft:    // rose chaud
            top = Color(red: 0.86, green: 0.34, blue: 0.46)
            mid = Color(red: 0.40, green: 0.13, blue: 0.22)
            bottom = Color(red: 0.10, green: 0.04, blue: 0.07)
        case .pimente: // orange pétant
            top = Color(red: 1.0, green: 0.52, blue: 0.12)
            mid = Color(red: 0.64, green: 0.25, blue: 0.03)
            bottom = Color(red: 0.13, green: 0.05, blue: 0.01)
        case .chaud:   // rouge sensuel, chaud
            top = Color(red: 0.92, green: 0.16, blue: 0.16)
            mid = Color(red: 0.50, green: 0.06, blue: 0.08)
            bottom = Color(red: 0.14, green: 0.02, blue: 0.02)
        }
        return LinearGradient(
            colors: [top, mid, bottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Fond neutre des écrans hors carte (accueil, fin).
    static let surface = Color.black
}
