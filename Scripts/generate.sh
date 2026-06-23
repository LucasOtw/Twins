#!/bin/bash
# Régénère le projet Xcode depuis project.yml et réapplique les réglages que
# XcodeGen ne sait pas exprimer.
#
# Pourquoi : iPhone en iOS 27 + Xcode 26 → les bibliothèques de diagnostic
# injectées au lancement debug (Thread Performance Checker notamment) plantent
# (-[OS_dispatch_mach_msg _setContext:]: unrecognized selector). On les coupe.
#
# Utilise CE script au lieu de `xcodegen generate` directement.
set -e
cd "$(dirname "$0")/.."

xcodegen generate

SCHEME="Twins.xcodeproj/xcshareddata/xcschemes/Twins.xcscheme"
if ! grep -q "disablePerformanceAntipatternChecker" "$SCHEME"; then
  sed -i '' 's/<LaunchAction/<LaunchAction\n      disablePerformanceAntipatternChecker = "YES"/' "$SCHEME"
fi

echo "✓ Projet généré (checkers runtime désactivés pour compat iOS 27 / Xcode 26)"
