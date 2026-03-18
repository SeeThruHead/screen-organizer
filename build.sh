#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "Building Screen Organizer..."

# Create build directory
mkdir -p build

# Compile Swift files
swiftc -o build/ScreenOrganizer \
    ScreenOrganizer/main.swift \
    ScreenOrganizer/AppDelegate.swift \
    ScreenOrganizer/StatusBarController.swift \
    ScreenOrganizer/FileWatcher.swift \
    ScreenOrganizer/FileProcessor.swift \
    ScreenOrganizer/DateOrganizer.swift \
    ScreenOrganizer/Config.swift \
    ScreenOrganizer/SupportedFormats.swift \
    -framework Cocoa \
    -target x86_64-apple-macos11.0

# Create app bundle
mkdir -p "build/Screen Organizer.app/Contents/MacOS"
mkdir -p "build/Screen Organizer.app/Contents/Resources"

# Copy executable
cp build/ScreenOrganizer "build/Screen Organizer.app/Contents/MacOS/"

# Copy Info.plist
cp ScreenOrganizer/Info.plist "build/Screen Organizer.app/Contents/"

# Set bundle identifier and version in Info.plist
sed -i '' 's/$(PRODUCT_BUNDLE_IDENTIFIER)/io.github.seethruhead.screenorganizer/g' "build/Screen Organizer.app/Contents/Info.plist"
sed -i '' 's/$(EXECUTABLE_NAME)/ScreenOrganizer/g' "build/Screen Organizer.app/Contents/Info.plist"
sed -i '' 's/$(PRODUCT_NAME)/Screen Organizer/g' "build/Screen Organizer.app/Contents/Info.plist"
sed -i '' 's/$(PRODUCT_BUNDLE_PACKAGE_TYPE)/APPL/g' "build/Screen Organizer.app/Contents/Info.plist"
sed -i '' 's/$(MARKETING_VERSION)/1.0/g' "build/Screen Organizer.app/Contents/Info.plist"
sed -i '' 's/$(CURRENT_PROJECT_VERSION)/1/g' "build/Screen Organizer.app/Contents/Info.plist"
sed -i '' 's/$(MACOSX_DEPLOYMENT_TARGET)/11.0/g' "build/Screen Organizer.app/Contents/Info.plist"
sed -i '' 's/$(DEVELOPMENT_LANGUAGE)/en/g' "build/Screen Organizer.app/Contents/Info.plist"

# Ad-hoc code sign
codesign -s - --force "build/Screen Organizer.app"

echo "✅ Built Screen Organizer.app"
echo ""
echo "To install:"
echo "  cp -R \"build/Screen Organizer.app\" /Applications/"
echo ""
echo "To run:"
echo "  open \"build/Screen Organizer.app\""
echo ""
echo "To auto-start at login:"
echo "  System Preferences → Users & Groups → Login Items → Add the app"