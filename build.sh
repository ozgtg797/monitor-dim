#!/bin/zsh
# Builds build/MonitorDim.app (menu bar app) and build/ddc-test (CLI).
set -euo pipefail
cd "${0:A:h}"

VERSION=0.1.0
FLAGS=(-O -target arm64-apple-macos14.0 -import-objc-header Sources/Bridge.h -framework IOKit -framework CoreFoundation)
APP=build/MonitorDim.app

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
swiftc "${FLAGS[@]}" Sources/*.swift Tools/main.swift -o build/ddc-test
swiftc "${FLAGS[@]}" -framework AppKit -framework ServiceManagement Sources/*.swift App/*.swift -o "$APP/Contents/MacOS/MonitorDim"
cp Resources/AppIcon.icns "$APP/Contents/Resources/"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key><string>io.github.ozgtg797.monitordim</string>
    <key>CFBundleName</key><string>MonitorDim</string>
    <key>CFBundleExecutable</key><string>MonitorDim</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundleVersion</key><string>$VERSION</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHumanReadableCopyright</key><string>MIT License</string>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP"
echo "built $APP"
