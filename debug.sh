#!/bin/bash
# Debug helper script

set -e

echo "🐛 Debug Mode for Screen Organizer"
echo ""

# Kill any existing instance
pkill -f "Screen Organizer" 2>/dev/null || true
echo "Killed existing app instances"

# Build fresh version
echo "Building fresh version..."
./build.sh

echo ""
echo "Starting app with debug monitoring..."
echo "Watch for output below and in menu bar:"
echo ""

# Start Console.app filter in background
osascript << 'EOF' 2>/dev/null &
tell application "Console"
    activate
end tell
EOF

# Run the app and capture output
open "build/Screen Organizer.app"

echo "✅ App started!"
echo ""
echo "Debug checklist:"
echo "□ Camera icon appears in menu bar"  
echo "□ Right-click menu works"
echo "□ Console.app shows 'Started watching Screenshots folder'"
echo "□ Settings dialog opens (right-click → Settings)"
echo "□ Config file created at ~/.config/screenorganizer"
echo ""
echo "To test file processing:"
echo "  chmod +x test.sh && ./test.sh"
echo ""
echo "To view logs:"
echo "  tail -f /var/log/system.log | grep ScreenOrganizer"