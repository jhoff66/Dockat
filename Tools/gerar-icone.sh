#!/bin/zsh
# Regenera Assets/ (logo, ícone da barra de menus e Dockat.icns) a partir do pixel art em Sources/Sprites.swift.
set -euo pipefail
cd "$(dirname "$0")/.."
T=$(mktemp -d)
swiftc -O -swift-version 5 Sources/Sprites.swift Tools/icone/main.swift -o "$T/icone"
"$T/icone" Assets
iconutil -c icns Assets/Dockat.iconset -o Assets/Dockat.icns
rm -rf Assets/Dockat.iconset "$T"
