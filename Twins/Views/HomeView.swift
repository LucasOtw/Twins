import SwiftUI

/// Accueil : la première impression. Des cartes qui flottent en fond, un titre
/// qui claque, deux modes lisibles d'un coup d'œil. On choisit (ou pas), on
/// appuie sur « Commencer », on joue.
struct HomeView: View {
    @Environment(StoreManager.self) private var store

    @State private var mode: GameMode = .progressive
    @State private var isPlaying = false
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            Theme.ambiance(for: .soft).ignoresSafeArea()
            FloatingCardsBackdrop()

            VStack(spacing: Theme.Spacing.md) {
                Spacer(minLength: Theme.Spacing.lg)
                header
                Spacer(minLength: Theme.Spacing.lg)
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
                .font(.system(size: 68, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Theme.accent(for: .soft),
                            Theme.accent(for: .pimente),
                            Theme.accent(for: .chaud)
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .shadow(color: Theme.accent(for: .pimente).opacity(0.5), radius: 24, y: 6)
            Text("Le jeu de cartes qui rapproche.\nUn téléphone, deux complices, une soirée qui monte.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .shadow(color: .black.opacity(0.5), radius: 8)
        }
    }

    private var modePicker: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(GameMode.allCases) { option in
                let locked = option.requiresUnlock && !store.isUnlocked
                ModeRow(mode: option, isSelected: option == mode, isLocked: locked) {
                    if locked {
                        showPaywall = true
                    } else {
                        withAnimation(.smooth(duration: 0.2)) { mode = option }
                    }
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

// MARK: - Mode

/// Ligne de sélection de mode avec un visuel parlant : pastille « chaude »
/// (dégradé des 3 paliers) pour la montée, pastille calme pour les questions.
private struct ModeRow: View {
    let mode: GameMode
    let isSelected: Bool
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                icon
                    .opacity(isLocked ? 0.85 : 1)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: Theme.Spacing.xs) {
                        Text(mode.title)
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(.white)
                        if isLocked { premiumPill }
                    }
                    Text(mode.subtitle)
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                trailing
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(isLocked ? 0.65 : 1)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                    .stroke(isSelected && !isLocked ? Theme.accent(for: .pimente).opacity(0.7) : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(mode.title)\(isLocked ? ", verrouillé, premium" : "")")
        .accessibilityAddTraits(isSelected && !isLocked ? [.isButton, .isSelected] : .isButton)
    }

    @ViewBuilder
    private var trailing: some View {
        if isLocked {
            Image(systemName: "lock.fill")
                .font(.headline)
                .foregroundStyle(Theme.accent(for: .chaud))
        } else {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isSelected ? Theme.accent(for: .pimente) : .white.opacity(0.4))
        }
    }

    private var premiumPill: some View {
        Text("PREMIUM")
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .tracking(1)
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(Theme.accent(for: .chaud), in: Capsule())
    }

    private var icon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(iconBackground)
                .frame(width: 50, height: 50)
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(.white.opacity(0.2), lineWidth: 1))
                .shadow(color: shadowColor, radius: 10, y: 4)
            Text(mode.emoji)
                .font(.system(size: 24))
        }
    }

    private var iconBackground: AnyShapeStyle {
        switch mode {
        case .progressive:
            return AnyShapeStyle(LinearGradient(
                colors: [Theme.accent(for: .soft), Theme.accent(for: .pimente), Theme.accent(for: .chaud)],
                startPoint: .topLeading, endPoint: .bottomTrailing))
        case .spicyHot:
            return AnyShapeStyle(LinearGradient(
                colors: [Theme.accent(for: .pimente), Theme.accent(for: .chaud)],
                startPoint: .topLeading, endPoint: .bottomTrailing))
        case .questionsOnly:
            return AnyShapeStyle(Color.white.opacity(0.12))
        }
    }

    private var shadowColor: Color {
        switch mode {
        case .progressive: return Theme.accent(for: .pimente).opacity(0.6)
        case .spicyHot:    return Theme.accent(for: .chaud).opacity(0.6)
        case .questionsOnly: return .clear
        }
    }
}

// MARK: - Fond de cartes flottantes

/// Quelques mini-cartes colorées qui flottent doucement en fond, pour donner
/// du relief et de l'envie dès le premier écran. Purement décoratif.
private struct FloatingCardsBackdrop: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false

    private struct Floater {
        let level: Level
        let symbol: String
        let size: CGSize
        let rotation: Double
        let x: CGFloat   // fraction de largeur
        let y: CGFloat   // fraction de hauteur
        let float: CGFloat
        let duration: Double
    }

    private let floaters: [Floater] = [
        .init(level: .soft,    symbol: "bubble.left.and.bubble.right.fill", size: .init(width: 84, height: 112), rotation: -14, x: 0.17, y: 0.20, float: 16, duration: 3.6),
        .init(level: .pimente, symbol: "flame.fill",                        size: .init(width: 96, height: 126), rotation:  13, x: 0.84, y: 0.17, float: 20, duration: 4.3),
        .init(level: .chaud,   symbol: "heart.fill",                        size: .init(width: 72, height: 96),  rotation:  10, x: 0.86, y: 0.45, float: 13, duration: 3.2),
        .init(level: .pimente, symbol: "hand.raised.fill",                  size: .init(width: 66, height: 88),  rotation: -11, x: 0.14, y: 0.46, float: 17, duration: 4.7),
        .init(level: .soft,    symbol: "sparkles",                          size: .init(width: 60, height: 80),  rotation:   6, x: 0.50, y: 0.07, float: 11, duration: 3.0),
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(floaters.indices, id: \.self) { i in
                    let f = floaters[i]
                    card(f)
                        .position(x: geo.size.width * f.x, y: geo.size.height * f.y)
                        .offset(y: reduceMotion ? 0 : (animate ? f.float : -f.float))
                        .animation(
                            reduceMotion ? nil :
                                .easeInOut(duration: f.duration).repeatForever(autoreverses: true),
                            value: animate)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear { animate = true }
        .accessibilityHidden(true)
    }

    private func card(_ f: Floater) -> some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Theme.cardGradient(for: f.level))
            .frame(width: f.size.width, height: f.size.height)
            .overlay(
                Image(systemName: f.symbol)
                    .font(.system(size: f.size.width * 0.32, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.white.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: Theme.accent(for: f.level).opacity(0.5), radius: 18, y: 8)
            .rotationEffect(.degrees(f.rotation))
            .opacity(0.9)
    }
}
