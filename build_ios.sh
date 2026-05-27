#!/bin/bash
set -e

# Auto-increment build number in pubspec.yaml
PUBSPEC="pubspec.yaml"
CURRENT=$(grep "^version:" $PUBSPEC | sed 's/version: //' | tr -d ' ')
VERSION=$(echo $CURRENT | cut -d'+' -f1)
BUILD=$(echo $CURRENT | cut -d'+' -f2)
NEW_BUILD=$((BUILD + 1))
NEW_VERSION="${VERSION}+${NEW_BUILD}"

sed -i '' "s/^version: .*/version: $NEW_VERSION/" $PUBSPEC
echo "📦 Version bumped: $CURRENT → $NEW_VERSION"

# Update Xcode build number
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEW_BUILD" ios/Runner/Info.plist
echo "🔢 Xcode build number set to $NEW_BUILD"

# Update pods if needed
echo "📦 Updating CocoaPods specs..."
cd ios && pod repo update && pod install && cd ..

# Flutter build
echo "🏗️  Building Flutter iOS release..."
flutter build ios --release --build-number=$NEW_BUILD

# Patch objective_c.framework
echo "🔧 Patching objective_c.framework MinimumOSVersion..."
PLIST="build/native_assets/ios/objective_c.framework/Info.plist"

if [ -f "$PLIST" ]; then
  /usr/libexec/PlistBuddy -c "Set :MinimumOSVersion 16.0" "$PLIST"
  echo "✅ Patched: MinimumOSVersion set to 16.0"
else
  echo "⚠️  Plist not found at $PLIST — skipping patch"
fi

echo "✅ Build $NEW_BUILD ready. Open Xcode → Archive → Distribute."
