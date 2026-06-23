import SwiftUI

/// Accueil : on lance l'app, on choisit (ou pas) un mode, on appuie sur
/// « Commencer », on joue. Aucun réglage obligatoire.
struct HomeView: View {
    @Environment(StoreManager.self) private var store

    @State private var mode: GameMode = .progressive
    @State private var isPlaying = false
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            Theme.ambiance(for: .soft).ignoresSafeArea()

            VStack(spacing: Theme.Spacing.xl) {
                Spacer()
                header
                Spacer()
                modePicker
                startButton
                footer
            }
            .padding(Theme.Spacing.lg)
        }
        .fullScreenCover(isPresented: $isPlaying) {
            GameView(viewModel: GameViewModel(mode: mode, unlocked: store.isUnlocked))
                .environment(store)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(onClose: { showPaywall = false },
                        onUnlocked: { showPaywall = false })
                .environment(store)
                .presentationBackground(Theme.surface)
        }
    }

    private var header: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text(AppInfo.name)
                .font(.system(size: 64, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Text("Le jeu de cartes qui rapproche.\nUn téléphone, deux complices, une soirée qui monte.")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
    }

    private var modePicker: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(GameMode.allCases) { option in
                ModeRow(mode: option, isSelected: option == mode) {
                    withAnimation(.smooth(duration: 0.2)) { mode = option }
                }
            }
        }
    }

    private var startButton: some View {
        Button { isPlaying = true } label: {
            Text("Commencer")
                .font(Theme.Font.button)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.capsule)
        .controlSize(.large)
        .tint(Theme.accent(for: .pimente))
        .sensoryFeedback(.impact(weight: .medium, intensity: 1.0), trigger: isPlaying)
    }

    private var footer: some View {
        VStack(spacing: Theme.Spacing.xs) {
            if !store.isUnlocked {
                Button("Tout débloquer") { showPaywall = true }
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white)
            }
            Text("Aucune donnée collectée · 18+")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
    }
}

/// Ligne de sélection de mode (carte tappable, repli accessibilité via glass).
private struct ModeRow: View {
    let mode: GameMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.sm) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.title)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.white)
                    Text(mode.subtitle)
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Theme.accent(for: .pimente) : .white.opacity(0.4))
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                    .stroke(isSelected ? Theme.accent(for: .pimente).opacity(0.6) : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
