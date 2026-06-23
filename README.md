# Twins

Jeu de cartes pour jeunes couples, en présentiel, sur un seul téléphone qu'on se
passe. La soirée monte en intensité au fil des cartes — du tendre au taquin au
sensuel — en mêlant questions, vérités et petites actions. 100 % local, offline,
aucune donnée collectée.

- **Plateforme** : iOS 26+, SwiftUI pur, Xcode 26.
- **Langue** : français natif (pilier produit).
- **Monétisation** : un achat unique non-consommable (StoreKit 2) déverrouille
  les niveaux Pimenté et Chaud à vie. Le niveau Soft + un avant-goût du Pimenté
  sont gratuits.

## Générer le projet

Le `.xcodeproj` n'est pas commité — il est régénéré depuis `project.yml` via
[XcodeGen](https://github.com/yonaskolb/XcodeGen) :

```bash
brew install xcodegen   # une fois
xcodegen generate
open Twins.xcodeproj
```

Le schéma `Twins` est préconfiguré avec `Twins.storekit` pour tester les achats
en local, sans App Store Connect.

## Build en ligne de commande

```bash
xcodebuild -project Twins.xcodeproj \
  -scheme Twins \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -configuration Debug build CODE_SIGNING_ALLOWED=NO
```

## Architecture

MVVM léger, aucune dépendance externe.

| Dossier         | Rôle |
| --------------- | ---- |
| `App/`          | Entrée `@main`, constante `AppInfo` (nom de l'app centralisé). |
| `Models/`       | `Card`, `Deck`, `Level`, `CardType` — `Codable`. |
| `Resources/`    | `deck.json` (contenu versionné), assets. |
| `ViewModels/`   | `GameViewModel` — courbe de montée en intensité, mélange sans répétition. |
| `Views/`        | `HomeView`, `GameView`, `CardView`, `LevelTransitionView`, `PaywallView`. |
| `Store/`        | `StoreManager` — StoreKit 2. |
| `DesignSystem/` | `Theme` (tokens par palier), `GlassStyles` (Liquid Glass + repli accessibilité). |

### La mécanique (cœur du produit)

La courbe est pilotée par des constantes nommées dans `GameViewModel` :
`level2UnlocksAtCard`, `level3UnlocksAtCard`, `freePreviewLevel2Count`. Le niveau
autorisé croît avec la position, l'ordre est aléatoire sans répétition au sein
d'un palier, et chaque montée déclenche un écran de transition + une haptique
renforcée.

### Liquid Glass

Le verre est réservé à la couche fonctionnelle (contrôles, barres flottantes),
jamais sous le grand texte des cartes. Repli opaque automatique quand « Réduire
la transparence » est actif (`adaptiveGlass` dans `GlassStyles.swift`).
