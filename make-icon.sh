#!/bin/zsh
# Regenerates Resources/AppIcon.icns from Tools/make-icon.swift.
set -euo pipefail
cd "${0:A:h}"

SET=build/AppIcon.iconset
rm -rf "$SET" && mkdir -p "$SET" Resources
swift Tools/make-icon.swift build/icon_1024.png
for s in 16 32 128 256 512; do
    sips -z $s $s build/icon_1024.png --out "$SET/icon_${s}x${s}.png" >/dev/null
    sips -z $((s * 2)) $((s * 2)) build/icon_1024.png --out "$SET/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$SET" -o Resources/AppIcon.icns
echo "wrote Resources/AppIcon.icns"
