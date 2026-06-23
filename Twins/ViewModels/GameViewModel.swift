import SwiftUI
import Observation

/// Mode de partie choisi sur l'accueil. Le progressif est la star (§6) ;
/// le filtre par type reste une option simple.
enum GameMode: String, CaseIterable, Identifiable {
    case progressive   // montée en intensité — le défaut
    case questionsOnly // uniquement des questions, montée conservée
    case spicyHot      // direct dans le vif (pimenté → chaud) — réservé premium

    var id: String { rawValue }

    var title: String {
        switch self {
        case .progressive:   return "Montée progressive"
        case .questionsOnly: return "Questions only"
        case .spicyHot:      return "Spicy hot"
        }
    }

    var subtitle: String {
        switch self {
        case .progressive:   return "Du tendre au brûlant, au fil de la soirée."
        case .questionsOnly: return "Que des questions, toujours plus complices."
        case .spicyHot:      return "Direct dans le vif — pimenté puis brûlant."
        }
    }

    var emoji: String {
        switch self {
        case .progressive:   return "🔥"
        case .questionsOnly: return "💬"
        case .spicyHot:      return "🌶️"
        }
    }

    /// Mode réservé à l'achat débloqué (grisé tant qu'on n'a pas payé).
    var requiresUnlock: Bool {
        switch self {
        case .spicyHot:                 return true
        case .progressive, .questionsOnly: return false
        }
    }
}

/// Une étape de la partie. La vue de jeu se contente d'afficher l'étape
/// courante — toute la logique de courbe vit dans le ViewModel.
enum GameStep: Equatable {
    case card(Card)
    case transition(Level) // écran d'annonce de montée de palier
    case paywall           // l'utilisateur gratuit bute sur du contenu verrouillé
    case finished          // fin de partie
}

@MainActor
@Observable
final class GameViewModel {

    // MARK: Réglages de la courbe (constantes nommées — pas de nombres magiques)

    /// Le niveau 2 s'invite à partir de cette carte (intention de design sur
    /// un deck complet ; mis à l'échelle si le paquet jouable est plus petit).
    static let level2UnlocksAtCard = 8
    /// Le niveau 3 s'invite à partir de cette carte.
    static let level3UnlocksAtCard = 16
    /// Avant-goût du niveau 2 offert aux joueurs non débloqués (§8).
    static let freePreviewLevel2Count = 3

    // MARK: État exposé à la vue

    private(set) var steps: [GameStep] = []
    private(set) var index: Int = 0
    /// Vrai quand la dernière transition franchie est une montée de palier
    /// (sert à renforcer l'haptique).
    private(set) var lastAdvanceWasMilestone = false

    let mode: GameMode

    private let deck: Deck

    init(deck: Deck = Deck.loadBundled(), mode: GameMode = .progressive, unlocked: Bool) {
        self.deck = deck
        self.mode = mode
        self.steps = Self.buildSteps(deck: deck, mode: mode, unlocked: unlocked)
    }

    // MARK: Navigation

    var currentStep: GameStep { steps.indices.contains(index) ? steps[index] : .finished }
    var canGoBack: Bool { index > 0 }
    var isFinished: Bool { currentStep == .finished }

    /// Numéro de la carte courante / total de cartes (indicateur discret).
    var cardProgress: (current: Int, total: Int) {
        let total = steps.reduce(0) { $0 + (isCard($1) ? 1 : 0) }
        let current = steps[..<min(index + 1, steps.count)].reduce(0) { $0 + (isCard($1) ? 1 : 0) }
        return (current, total)
    }

    func advance() {
        guard index < steps.count - 1 else { return }
        let next = steps[index + 1]
        lastAdvanceWasMilestone = { if case .transition = next { return true } else { return false } }()
        index += 1
    }

    func goBack() {
        guard index > 0 else { return }
        lastAdvanceWasMilestone = false
        index -= 1
    }

    private func isCard(_ step: GameStep) -> Bool {
        if case .card = step { return true } else { return false }
    }

    // MARK: Construction de la séquence

    private static func buildSteps(deck: Deck, mode: GameMode, unlocked: Bool) -> [GameStep] {
        let pool: [Card]
        switch mode {
        case .progressive:   pool = deck.cards
        case .questionsOnly: pool = deck.cards.filter { $0.type == .question }
        case .spicyHot:      pool = deck.cards.filter { $0.level != .soft }
        }
        return unlocked ? unlockedOrder(pool: pool) : freeOrder(pool: pool)
    }

    /// Courbe complète : niveau autorisé croissant selon la position, ordre
    /// aléatoire sans répétition au sein du palier, transitions insérées aux
    /// changements de palier.
    private static func unlockedOrder(pool: [Card]) -> [GameStep] {
        let count = pool.count
        // Seuils : intention de design sur deck complet, mis à l'échelle sinon.
        let t2 = min(level2UnlocksAtCard, max(1, count / 3))
        let t3 = min(level3UnlocksAtCard, max(t2 + 1, (count * 2) / 3))

        func levelCap(at position: Int) -> Int {
            if position >= t3 { return 3 }
            if position >= t2 { return 2 }
            return 1
        }

        var seen = Set<String>()
        var order: [Card] = []
        while true {
            let cap = levelCap(at: order.count)
            let unseen = pool.filter { !seen.contains($0.id) }
            if unseen.isEmpty { break }
            let eligible = unseen.filter { $0.level.rawValue <= cap }
            // Repli : si rien n'est éligible sous le plafond mais qu'il reste
            // des cartes, on prend la plus douce restante (jamais de perte).
            let pick = eligible.randomElement()
                ?? unseen.min(by: { $0.level < $1.level })!
            seen.insert(pick.id)
            order.append(pick)
        }

        // Une transition s'affiche la première fois qu'un palier supérieur au
        // palier de base du paquet apparaît (les seuils t2/t3 contrôlent
        // *quand* ces paliers entrent via levelCap). Ainsi « Spicy hot », qui
        // démarre déjà en pimenté, n'annonce que le passage au chaud.
        let baseLevel = order.map(\.level).min() ?? .soft
        var announced = Set<Level>()
        var steps: [GameStep] = []
        for card in order {
            if card.level > baseLevel, !announced.contains(card.level) {
                announced.insert(card.level)
                steps.append(.transition(card.level))
            }
            steps.append(.card(card))
        }
        steps.append(.finished)
        return steps
    }

    /// Version gratuite : tout le niveau 1, puis un avant-goût du niveau 2,
    /// puis le paywall quand on veut aller plus loin (§8).
    private static func freeOrder(pool: [Card]) -> [GameStep] {
        let level1 = pool.filter { $0.level == .soft }.shuffled()
        let preview = Array(pool.filter { $0.level == .pimente }.shuffled().prefix(freePreviewLevel2Count))

        var steps: [GameStep] = level1.map { .card($0) }
        if !preview.isEmpty {
            steps.append(.transition(.pimente))
            steps.append(contentsOf: preview.map { .card($0) })
        }
        steps.append(.paywall)
        return steps
    }
}
