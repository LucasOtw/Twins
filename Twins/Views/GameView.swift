import SwiftUI

/// Écran de jeu. Affiche l'étape courante du `GameViewModel` et offre une
/// navigation à une main (swipe + grands boutons au pouce). Le verre est
/// réservé aux contrôles ; le contenu vit sur matériau standard.
struct GameView: View {
    @Environment(StoreManager.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State var viewModel: GameViewModel
    @State private var dragOffset: CGFloat = 0

    private var level: Level {
        switch viewModel.currentStep {
        case .card(let card):     return card.level
        case .transition(let l):  return l
        case .paywall:            return .chaud
        case .finished:           return .soft
        }
    }

    var body: some View {
        ZStack {
            Theme.ambiance(for: level)
                .ignoresSafeArea()
                .animation(.smooth(duration: 0.5), value: level)

            content
                .id(viewModel.index)
                .transition(stepTransition)
                .offset(x: dragOffset)
                .rotationEffect(.degrees(Double(dragOffset) / 40))
                .gesture(swipe)

            VStack {
                topBar
                Spacer()
                bottomControls
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.md)
        }
        // Haptique bien présente à chaque carte, renforcée au passage de palier.
        .sensoryFeedback(trigger: viewModel.index) { _, _ in
            viewModel.lastAdvanceWasMilestone
                ? .impact(weight: .heavy, intensity: 1.0)
                : .impact(weight: .medium, intensity: 0.95)
        }
    }

    // MARK: Contenu par étape

    @ViewBuilder
    private var content: some View {
        switch viewModel.currentStep {
        case .card(let card):
            CardView(card: card)
        case .transition(let level):
            LevelTransitionView(level: level)
        case .paywall:
            PaywallView(
                onClose: { dismiss() },
                onUnlocked: { restartUnlocked() }
            )
        case .finished:
            EndView(onReplay: { restart(unlocked: store.isUnlocked) },
                    onHome: { dismiss() })
        }
    }

    // MARK: Barre haute

    private var topBar: some View {
        HStack {
            if showsProgress {
                let p = viewModel.cardProgress
                Text("\(p.current) / \(p.total)")
                    .font(Theme.Font.badge)
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, Theme.Spacing.xs)
                    .adaptiveGlass(interactive: false)
                    .accessibilityLabel("Carte \(p.current) sur \(p.total)")
            }

            Spacer()

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.headline)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .controlSize(.large)
            .accessibilityLabel("Quitter la partie")
        }
    }

    private var showsProgress: Bool {
        switch viewModel.currentStep {
        case .card, .transition: return true
        default:                 return false
        }
    }

    // MARK: Contrôles bas (Liquid Glass groupé)

    @ViewBuilder
    private var bottomControls: some View {
        switch viewModel.currentStep {
        case .card:
            GlassEffectContainer(spacing: Theme.Spacing.sm) {
                HStack(spacing: Theme.Spacing.sm) {
                    if viewModel.canGoBack {
                        backButton
                    }
                    advanceButton(title: "Carte suivante")
                }
            }
        case .transition:
            GlassEffectContainer(spacing: Theme.Spacing.sm) {
                HStack(spacing: Theme.Spacing.sm) {
                    if viewModel.canGoBack { backButton }
                    advanceButton(title: "C'est parti")
                }
            }
        case .paywall, .finished:
            EmptyView()
        }
    }

    private var backButton: some View {
        Button { go { viewModel.goBack() } } label: {
            Image(systemName: "arrow.uturn.backward")
                .font(Theme.Font.button)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .controlSize(.large)
        .accessibilityLabel("Carte précédente")
    }

    private func advanceButton(title: String) -> some View {
        Button { go { viewModel.advance() } } label: {
            Text(title)
                .font(Theme.Font.button)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.capsule)
        .controlSize(.large)
        .tint(Theme.accent(for: level))
    }

    // MARK: Gestes & animations

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                guard canSwipe else { return }
                dragOffset = value.translation.width
            }
            .onEnded { value in
                guard canSwipe else { return }
                let threshold: CGFloat = 80
                if value.translation.width < -threshold {
                    go { viewModel.advance() }
                } else if value.translation.width > threshold, viewModel.canGoBack {
                    go { viewModel.goBack() }
                }
                withAnimation(.smooth(duration: 0.25)) { dragOffset = 0 }
            }
    }

    /// On ne laisse pas glisser sur le paywall (achat = action explicite) ni
    /// sur l'écran de fin.
    private var canSwipe: Bool {
        switch viewModel.currentStep {
        case .card, .transition: return true
        default:                 return false
        }
    }

    private var stepTransition: AnyTransition {
        reduceMotion
            ? .opacity
            : .opacity.combined(with: .scale(scale: 0.96))
    }

    private func go(_ action: () -> Void) {
        dragOffset = 0
        if reduceMotion {
            action()
        } else {
            withAnimation(.smooth(duration: 0.32)) { action() }
        }
    }

    private func restart(unlocked: Bool) {
        viewModel = GameViewModel(mode: viewModel.mode, unlocked: unlocked)
    }

    private func restartUnlocked() {
        restart(unlocked: true)
    }
}

/// Écran de fin de partie — sobre et chaleureux.
private struct EndView: View {
    var onReplay: () -> Void
    var onHome: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            Spacer()
            Text("💞")
                .font(.system(size: 72))
            Text("Fin de partie")
                .font(Theme.Font.title)
                .foregroundStyle(.white)
            Text("Vous vous êtes peut-être (re)découverts ce soir.\nOn remet ça ?")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            Spacer()
            VStack(spacing: Theme.Spacing.sm) {
                Button { onReplay() } label: {
                    Text("Rejouer")
                        .font(Theme.Font.button)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                .tint(Theme.accent(for: .pimente))

                Button("Retour à l'accueil", action: onHome)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
