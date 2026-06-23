import Foundation

/// Le paquet de cartes bundlé dans l'app (JSON versionné, éditable sans
/// toucher à la logique de jeu).
struct Deck: Codable {
    let version: Int
    let cards: [Card]

    /// Charge `deck.json` depuis le bundle. En cas d'échec (ressource absente
    /// du bundle ou JSON invalide), on NE crashe PAS : on retombe sur un petit
    /// deck de secours embarqué dans le binaire, pour que l'app reste lançable
    /// et jouable en toutes circonstances.
    static func loadBundled(named name: String = "deck") -> Deck {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            print("⚠️ Twins: \(name).json introuvable dans le bundle — deck de secours utilisé.")
            return .fallback
        }
        do {
            let data = try Data(contentsOf: url)
            let deck = try JSONDecoder().decode(Deck.self, from: data)
            return deck.cards.isEmpty ? .fallback : deck
        } catch {
            print("⚠️ Twins: décodage de \(name).json impossible (\(error)) — deck de secours utilisé.")
            return .fallback
        }
    }

    func cards(at level: Level) -> [Card] {
        cards.filter { $0.level == level }
    }

    /// Deck minimal garanti, embarqué dans le code. Filet de sécurité si la
    /// ressource JSON manque — l'app reste jouable.
    static let fallback = Deck(version: 0, cards: [
        Card(id: "fs1", type: .question, level: .soft, text: "Quel est ton souvenir préféré de nous deux ?"),
        Card(id: "fs2", type: .verite, level: .soft, text: "Avoue un petit truc que tu adores chez moi."),
        Card(id: "fs3", type: .action, level: .soft, text: "Refais-moi le sourire de notre première rencontre."),
        Card(id: "fp1", type: .question, level: .pimente, text: "C'est quoi le compliment que tu n'as jamais osé me faire ?"),
        Card(id: "fp2", type: .action, level: .pimente, text: "Regarde-moi dans les yeux cinq secondes sans rire."),
        Card(id: "fc1", type: .verite, level: .chaud, text: "Décris-moi le moment où tu as eu le plus envie de moi."),
    ])
}
