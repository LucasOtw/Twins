import SwiftUI

/// Écran d'achat. Argument produit : honnête, lisible, sans dark pattern.
/// Réutilisable comme étape de jeu (mur du gratuit) ou présenté en feuille.
struct PaywallView: View {
    @Environment(StoreManager.self) private var store
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    /// Appelé quand l'utilisateur ferme sans acheter.
    var onClose: () -> Void = {}
    /// Appelé quand l'achat (ou la restauration) débloque le contenu.
    var onUnlocked: () -> Void = {}

    private let accent = Theme.accent(for: .chaud)

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            Text("🔥")
                .font(.system(size: 64))

            VStack(spacing: Theme.Spacing.sm) {
                Text("Passez à la vitesse supérieure")
                    .font(Theme.Font.title)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)

                Text("Débloquez les niveaux **Pimenté** et **Chaud** en entier — toutes les cartes, à vie. Un seul achat, aucun abonnement.")
                    .font(.system(.body, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, Theme.Spacing.sm)
            }

            argumentsList

            Spacer()

            if case .failed(let message) = store.phase {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
            }

            actions
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: store.isUnlocked) { _, unlocked in
            if unlocked { onUnlocked() }
        }
    }

    private var argumentsList: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            argument("Tous les niveaux, sans limite", "infinity")
            argument("Achat unique, à vie", "checkmark.seal.fill")
            argument("Aucune donnée collectée, tout reste sur l'appareil", "lock.fill")
        }
        .padding(Theme.Spacing.md)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
    }

    private func argument(_ text: String, _ symbol: String) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: symbol)
                .foregroundStyle(accent)
                .frame(width: 24)
            Text(text)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
            Spacer(minLength: 0)
        }
    }

    private var actions: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Button {
                Task { await store.purchase() }
            } label: {
                Group {
                    if store.phase == .purchasing {
                        ProgressView().tint(.white)
                    } else {
                        Text("Tout débloquer · \(store.displayPrice)")
                            .font(Theme.Font.button)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .tint(accent)
            .disabled(store.phase == .purchasing)
            .sensoryFeedback(.success, trigger: store.isUnlocked)

            HStack(spacing: Theme.Spacing.md) {
                Button("Restaurer mes achats") { Task { await store.restore() } }
                Spacer()
                Button("Plus tard", action: onClose)
            }
            .font(.system(.subheadline, design: .rounded))
            .foregroundStyle(.white.opacity(0.7))
            .disabled(store.phase == .purchasing)
        }
    }
}
