#!/usr/bin/env bash
# Rebuilds assets/icon/AppIcon.icns from assets/icon/clipq-1024.png (macOS: sips + iconutil).
# Edit clipq-app-icon.svg, export it to clipq-1024.png at 1024x1024, then run this.
set -euo pipefail
cd "$(dirname "$0")/../assets/icon"

SET=$(mktemp -d)/AppIcon.iconset
mkdir -p "$SET"
for size in 16 32 128 256 512; do
  sips -z $size $size clipq-1024.png --out "$SET/icon_${size}x${size}.png" >/dev/null
  double=$((size * 2))
  sips -z $double $double clipq-1024.png --out "$SET/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$SET" -o AppIcon.icns
echo "Wrote assets/icon/AppIcon.icns"
