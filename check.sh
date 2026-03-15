#!/bin/bash
# Quick status check

echo "📋 Screen Organizer Status Check"
echo "================================"
echo ""

# Check if app is running
if pgrep -f "Screen Organizer" >/dev/null; then
    echo "✅ App is running (PID: $(pgrep -f 'Screen Organizer'))"
else
    echo "❌ App is not running"
fi

# Check config file
CONFIG_FILE=~/.config/screenorganizer
if [[ -f "$CONFIG_FILE" ]]; then
    echo "✅ Config file exists"
    echo "📁 Current settings:"
    cat "$CONFIG_FILE" | grep -E "^[^#]" | sed 's/^/   /'
else
    echo "❌ Config file missing"
fi

echo ""

# Check folders
SCREENSHOTS_FOLDER=$(grep "screenshotsFolder=" "$CONFIG_FILE" 2>/dev/null | cut -d= -f2 || echo "screenshots")
RECORDINGS_FOLDER=$(grep "screenRecordingsFolder=" "$CONFIG_FILE" 2>/dev/null | cut -d= -f2 || echo "screen-recordings")

SCREENSHOTS_PATH="$HOME/$SCREENSHOTS_FOLDER"
RECORDINGS_PATH="$HOME/$RECORDINGS_FOLDER"

echo "📂 Folders:"
if [[ -d "$SCREENSHOTS_PATH" ]]; then
    FILES_COUNT=$(ls -1 "$SCREENSHOTS_PATH" | wc -l)
    echo "   ✅ $SCREENSHOTS_PATH ($FILES_COUNT files)"
else
    echo "   ❌ $SCREENSHOTS_PATH (missing)"
fi

if [[ -d "$RECORDINGS_PATH" ]]; then
    FILES_COUNT=$(ls -1 "$RECORDINGS_PATH" | wc -l)
    echo "   ✅ $RECORDINGS_PATH ($FILES_COUNT files)"
else
    echo "   ❌ $RECORDINGS_PATH (missing)"
fi

echo ""

# Check dependencies
echo "🔧 Dependencies:"
if command -v ffmpeg >/dev/null; then
    echo "   ✅ ffmpeg $(ffmpeg -version 2>&1 | head -1 | cut -d' ' -f3)"
else
    echo "   ❌ ffmpeg (missing)"
fi

if command -v magick >/dev/null; then
    echo "   ✅ imagemagick $(magick -version | head -1 | cut -d' ' -f3)"
else
    echo "   ❌ imagemagick (missing)"
fi

echo ""
echo "🎯 Quick actions:"
echo "   Start app: open 'build/Screen Organizer.app'"
echo "   Kill app:  pkill -f 'Screen Organizer'"
echo "   Test:      ./test.sh"
echo "   Debug:     ./debug.sh"