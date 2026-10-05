#!/usr/bin/env bash
# Builds a universal Clipq.app into npm/dist/.
# Usage: scripts/build-app.sh [--native]   (--native: host arch only, for fast local runs)
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION=$(node -p "require('./npm/package.json').version")
APP=npm/dist/Clipq.app

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

if [[ "${1:-}" == "--native" ]]; then
  swift build -c release
  BIN_DIR=$(swift build -c release --show-bin-path)
  cp "$BIN_DIR/Clipq" "$APP/Contents/MacOS/Clipq"
else
  # One build per arch, merged with lipo: Xcode 16's combined multi-arch build compiles
  # Clipq before the KeyboardShortcuts module exists ("no such module").
  for arch in arm64 x86_64; do swift build -c release --arch "$arch"; done
  BIN_DIR=$(swift build -c release --arch arm64 --show-bin-path)
  lipo -create "$BIN_DIR/Clipq" "$(swift build -c release --arch x86_64 --show-bin-path)/Clipq" \
    -output "$APP/Contents/MacOS/Clipq"
fi
# Ad-hoc signatures default to a per-build hash, so macOS drops the Accessibility grant
# on every update. An identifier-only requirement keeps it. Signed before the bundle
# exists around it, because codesign refuses the bundle (see below).
codesign --force --sign - --identifier com.clipq.Clipq \
  -r='designated => identifier "com.clipq.Clipq"' "$APP/Contents/MacOS/Clipq"
# App icon (Finder, Activity Monitor, permission prompts). Regenerate with scripts/make-icon.sh.
cp assets/icon/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
# SwiftPM's generated Bundle.module looks for resource bundles at the .app root.
cp -R "$BIN_DIR/KeyboardShortcuts_KeyboardShortcuts.bundle" "$APP/"

cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleIdentifier</key><string>com.clipq.Clipq</string>
  <key>CFBundleName</key><string>Clipq</string>
  <key>CFBundleExecutable</key><string>Clipq</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$VERSION</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
</dict>
</plist>
EOF

# No bundle codesign: the resource bundle at the root can't be sealed. The executable
# keeps its ad-hoc linker signature, which is enough to run without quarantine.
echo "Built $APP ($(lipo -archs "$APP/Contents/MacOS/Clipq"))"
