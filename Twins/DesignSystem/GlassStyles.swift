import SwiftUI

/// Helpers Liquid Glass (iOS 26) + repli accessibilité.
///
/// Règles respectées (brief §7) :
/// - Le verre vit sur la couche fonctionnelle (contrôles flottants), jamais
///   sous le grand texte de la carte.
/// - On ne teinte que l'action primaire.
/// - On ne empile jamais verre sur verre → regrouper dans `GlassEffectContainer`.
/// - Repli propre quand « Réduire la transparence » est actif : un matériau
///   opaque prend le relais, l'app reste belle et lisible sans le verre.
extension View {

    /// Applique un effet de verre sur une surface fonctionnelle, avec repli
    /// opaque si la transparence est réduite.
    func adaptiveGlass(
        tint: Color? = nil,
        interactive: Bool = true,
        in shape: some Shape = Capsule()
    ) -> some View {
        modifier(AdaptiveGlass(tint: tint, interactive: interactive, shape: AnyShape(shape)))
    }
}

private struct AdaptiveGlass: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    let tint: Color?
    let interactive: Bool
    let shape: AnyShape

    func body(content: Content) -> some View {
        if reduceTransparency {
            // Repli structurel : surface opaque, lisible sans verre.
            content
                .background((tint ?? Color.white.opacity(0.14)).opacity(tint == nil ? 1 : 0.9), in: shape)
                .overlay(shape.stroke(Color.white.opacity(0.12), lineWidth: 1))
        } else {
            content
                .glassEffect(glass, in: shape)
        }
    }

    private var glass: Glass {
        var g: Glass = .regular
        if let tint { g = g.tint(tint) }
        if interactive { g = g.interactive() }
        return g
    }
}
