import StoreKit
import Observation

/// Gère l'achat unique non-consommable qui débloque les niveaux 2 et 3 à vie.
/// Source de vérité = `Transaction.currentEntitlements` (StoreKit 2) ; un cache
/// `UserDefaults` permet un boot instantané avant la vérification réelle.
@MainActor
@Observable
final class StoreManager {

    enum PurchasePhase: Equatable {
        case idle
        case purchasing
        case success
        case cancelled
        case failed(String)
    }

    private(set) var product: Product?
    private(set) var isUnlocked: Bool
    var phase: PurchasePhase = .idle

    private var updatesTask: Task<Void, Never>?

    /// Prix localisé affiché dans le paywall (repli si le produit n'a pas chargé).
    var displayPrice: String { product?.displayPrice ?? "—" }

    init() {
        isUnlocked = UserDefaults.standard.bool(forKey: AppInfo.unlockedCacheKey)
    }

    /// À appeler au lancement : écoute des transactions + chargement produit +
    /// vérification des droits.
    func start() async {
        updatesTask = listenForTransactions()
        await loadProduct()
        await refreshEntitlements()
    }

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [AppInfo.unlockProductID])
            product = products.first
        } catch {
            // Non bloquant : l'app reste pleinement jouable en gratuit.
        }
    }

    func purchase() async {
        guard let product else {
            phase = .failed("Produit indisponible. Réessaie plus tard.")
            return
        }
        phase = .purchasing
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshEntitlements()
                phase = .success
            case .userCancelled:
                phase = .cancelled
            case .pending:
                phase = .idle
            @unknown default:
                phase = .idle
            }
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func restore() async {
        phase = .purchasing
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            phase = isUnlocked ? .success : .failed("Aucun achat à restaurer.")
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func refreshEntitlements() async {
        var unlocked = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == AppInfo.unlockProductID,
               transaction.revocationDate == nil {
                unlocked = true
            }
        }
        setUnlocked(unlocked)
    }

    private func setUnlocked(_ value: Bool) {
        isUnlocked = value
        UserDefaults.standard.set(value, forKey: AppInfo.unlockedCacheKey)
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await update in Transaction.updates {
                guard let self else { continue }
                guard case .verified(let transaction) = update else { continue }
                await transaction.finish()
                await self.refreshEntitlements()
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error): throw error
        case .verified(let safe):       return safe
        }
    }
}
