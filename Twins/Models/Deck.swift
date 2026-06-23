import Foundation

/// Le paquet de cartes bundlé dans l'app (JSON versionné, éditable sans
/// toucher à la logique de jeu).
struct Deck: Codable {
    let version: Int
    let cards: [Card]

    /// Charge `deck.json` depuis le bundle. En cas d'échec (fichier absent /
    /// JSON invalide), on `fatalError` volontairement : c'est une erreur de
    /// build, pas un cas runtime à gérer silencieusement.
    static func loadBundled(named name: String = "deck") -> Deck {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            fatalError("Ressource \(name).json introuvable dans le bundle.")
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(Deck.self, from: data)
        } catch {
            fatalError("Décodage de \(name).json impossible: \(error)")
        }
    }

    func cards(at level: Level) -> [Card] {
        cards.filter { $0.level == level }
    }
}
