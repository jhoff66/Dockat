#!/bin/zsh
# Compila o Dockat e monta o Dockat.app nesta pasta.
set -euo pipefail
cd "$(dirname "$0")"

mkdir -p build

# Binário universal: roda em Apple Silicon e em Intel.
for arch in arm64 x86_64; do
  swiftc -O -swift-version 5 -target $arch-apple-macos14.0 Sources/*.swift -o build/Dockat-$arch
done
lipo -create build/Dockat-arm64 build/Dockat-x86_64 -output build/Dockat
APP="Dockat.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp Assets/Dockat.icns "$APP/Contents/Resources/Dockat.icns"
cp build/Dockat "$APP/Contents/MacOS/Dockat"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Dockat</string>
  <key>CFBundleDisplayName</key><string>Dockat</string>
  <key>CFBundleIdentifier</key><string>app.dockat</string>
  <key>CFBundleIconFile</key><string>Dockat</string>
  <key>CFBundleExecutable</key><string>Dockat</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST
codesign --force --sign - "$APP"
echo "Pronto: $PWD/$APP"

# `./build.sh install` também atualiza a cópia em /Applications e reabre o app.
if [[ "${1:-}" == "install" ]]; then
  pkill -x Dockat || true
  rm -rf /Applications/Dockat.app
  cp -R "$APP" /Applications/Dockat.app
  open /Applications/Dockat.app
  echo "Instalado em /Applications/Dockat.app"
fi
