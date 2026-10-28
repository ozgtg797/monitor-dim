#!/bin/zsh
# Builds the app and packages it as build/MonitorDim.dmg (drag-to-Applications).
set -euo pipefail
cd "${0:A:h}"

./build.sh

STAGE=build/dmg
rm -rf "$STAGE" build/MonitorDim.dmg
mkdir -p "$STAGE"
cp -R build/MonitorDim.app "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname MonitorDim -srcfolder "$STAGE" -ov -format UDZO build/MonitorDim.dmg >/dev/null
echo "built build/MonitorDim.dmg"
