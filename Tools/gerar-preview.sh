#!/bin/zsh
# Regenera Assets/preview.png (ilustração do README).
set -euo pipefail
cd "$(dirname "$0")/.."
T=$(mktemp -d)
swiftc -O -swift-version 5 Sources/Sprites.swift Tools/preview/main.swift -o "$T/preview"
"$T/preview" Assets/preview.png
rm -rf "$T"
