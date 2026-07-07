#!/usr/bin/env bash
# Compile the native macOS menu plugin into a universal Unity bundle.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
PROJ="$(cd "$HERE/../.." && pwd)"
BUNDLE="$PROJ/Assets/Plugins/macOS/RobotDraftMenu.bundle"

rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS"

clang++ -bundle -arch arm64 -arch x86_64 -mmacosx-version-min=11.0 \
  -framework Cocoa -framework AppKit -fobjc-arc \
  -o "$BUNDLE/Contents/MacOS/RobotDraftMenu" "$HERE/NativeMenu.mm"

cat > "$BUNDLE/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleExecutable</key><string>RobotDraftMenu</string>
  <key>CFBundleIdentifier</key><string>com.noizu.robotdraft.menu</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleName</key><string>RobotDraftMenu</string>
  <key>CFBundlePackageType</key><string>BNDL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
</dict>
</plist>
PLIST

echo "built: $BUNDLE"
lipo -info "$BUNDLE/Contents/MacOS/RobotDraftMenu"
