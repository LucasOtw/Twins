import Foundation

/// Point unique de vérité pour l'identité de l'app.
/// Pour renommer l'app plus tard, changer `name` ici (et le `PRODUCT_NAME` /
/// `CFBundleDisplayName` dans `project.yml`) — aucune autre chaîne en dur ailleurs.
enum AppInfo {
    /// Nom affiché du jeu, réutilisé dans l'UI.
    static let name = "Twins"

    /// Identifiant du produit StoreKit (achat unique « à vie »).
    static let unlockProductID = "com.lucasotw.twins.unlockall"

    /// Clé `UserDefaults` de cache rapide de l'état débloqué (la source de
    /// vérité reste les transactions StoreKit, voir `StoreManager`).
    static let unlockedCacheKey = "twins.unlocked.cache"
}
