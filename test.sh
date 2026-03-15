#!/bin/bash
# Test script to create sample files for testing

set -e

echo "🧪 Creating test files..."

# Ensure config is set up first
mkdir -p ~/.config
if [[ ! -f ~/.config/screenorganizer ]]; then
    cat > ~/.config/screenorganizer << EOF
# Screen Organizer Configuration
screenshotsFolder=screenshots
screenRecordingsFolder=screen-recordings
videoCompression=medium
imageCompression=medium
EOF
    echo "Created default config"
fi

# Create test directories
mkdir -p ~/screenshots ~/screen-recordings

# Create a sample PNG (1x1 red pixel)
echo "Creating test screenshot..."
echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==" | base64 -d > ~/screenshots/test-screenshot.png

# Create a tiny sample MOV file (1 second black video)
if command -v ffmpeg >/dev/null; then
    echo "Creating test recording..."
    ffmpeg -f lavfi -i color=black:size=320x240:duration=1 -y ~/screenshots/test-recording.mov 2>/dev/null || echo "FFmpeg test failed"
else
    echo "FFmpeg not found - skipping MOV test"
fi

echo "✅ Test files created in ~/screenshots/"
echo ""
echo "Now:"
echo "1. Start the app: open 'build/Screen Organizer.app'"
echo "2. Watch Console.app (filter: ScreenOrganizer)"
echo "3. Check that files get processed and moved"
echo "4. Test the Settings menu"