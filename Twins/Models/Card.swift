import SwiftUI

/// Type de carte. Trois registres qui rythment la partie.
enum CardType: String, Codable, CaseIterable {
    case question   // une question à se poser
    case verite     // une vérité à avouer
    case action     // une petite action à faire

    /// Libellé court affiché sur la carte.
    var label: String {
        switch self {
        case .question: return "Question"
        case .verite:   return "Vérité"
        case .action:   return "Action"
        }
    }

    var symbolName: String {
        switch self {
        case .question: return "bubble.left.and.bubble.right.fill"
        case .verite:   return "hand.raised.fill"
        case .action:   return "flame.fill"
        }
    }
}

/// Palier d'intensité. Le cœur de la mécanique : la soirée se réchauffe.
enum Level: Int, Codable, CaseIterable, Comparable, Identifiable {
    case soft = 1      // tendre, tout public, vitrine gratuite
    case pimente = 2   // flirty, taquin, bon enfant
    case chaud = 3     // sensuel, suggestif (jamais explicite)

    var id: Int { rawValue }

    static func < (lhs: Level, rhs: Level) -> Bool { lhs.rawValue < rhs.rawValue }

    var title: String {
        switch self {
        case .soft:    return "Soft"
        case .pimente: return "Pimenté"
        case .chaud:   return "Chaud"
        }
    }

    /// Phrase d'annonce affichée sur l'écran de transition de palier.
    var teaser: String {
        switch self {
        case .soft:    return "On démarre en douceur…"
        case .pimente: return "Ça se réchauffe…"
        case .chaud:   return "Ça devient brûlant…"
        }
    }

    var emoji: String {
        switch self {
        case .soft:    return "🫶"
        case .pimente: return "😏"
        case .chaud:   return "🔥"
        }
    }
}

/// Une carte = un prompt en français, son type et son palier.
struct Card: Codable, Identifiable, Equatable {
    let id: String
    let type: CardType
    let level: Level
    let text: String

    private enum CodingKeys: String, CodingKey {
        case id, type, level, text
    }

    /// Décodage tolérant : `level` est stocké en `Int` dans le JSON.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        type = try c.decode(CardType.self, forKey: .type)
        let raw = try c.decode(Int.self, forKey: .level)
        guard let lvl = Level(rawValue: raw) else {
            throw DecodingError.dataCorruptedError(
                forKey: .level, in: c,
                debugDescription: "Palier inconnu: \(raw)")
        }
        level = lvl
        text = try c.decode(String.self, forKey: .text)
    }

    init(id: String, type: CardType, level: Level, text: String) {
        self.id = id
        self.type = type
        self.level = level
        self.text = text
    }
}
