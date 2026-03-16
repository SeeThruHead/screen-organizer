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
videoQuality=medium
imageQuality=medium
organizeByDate=false
EOF
    echo "Created default config"
fi

# Create test directories
mkdir -p ~/screenshots ~/screen-recordings

# --- Images ---

# PNG (1x1 red pixel)
echo "Creating test PNG..."
echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==" | base64 -d > ~/screenshots/test-screenshot.png

if command -v magick >/dev/null; then
    echo "Creating test JPEG..."
    magick -size 100x100 xc:blue ~/screenshots/test-image.jpg

    echo "Creating test WebP..."
    magick -size 100x100 xc:green ~/screenshots/test-image.webp

    echo "Creating test HEIC..."
    magick -size 100x100 xc:yellow ~/screenshots/test-image.heic 2>/dev/null || echo "  ⚠ HEIC creation failed (codec may not be available)"
else
    echo "⚠ ImageMagick not found — skipping JPEG/WebP/HEIC test images"
fi

# --- Videos ---

if command -v ffmpeg >/dev/null; then
    echo "Creating test MOV..."
    ffmpeg -f lavfi -i color=black:size=320x240:duration=1 -y ~/screenshots/test-recording.mov 2>/dev/null

    echo "Creating test MP4..."
    ffmpeg -f lavfi -i color=red:size=320x240:duration=1 -y ~/screenshots/test-recording.mp4 2>/dev/null

    echo "Creating test MKV..."
    ffmpeg -f lavfi -i color=blue:size=320x240:duration=1 -y ~/screenshots/test-recording.mkv 2>/dev/null

    echo "Creating test AVI..."
    ffmpeg -f lavfi -i color=green:size=320x240:duration=1 -y ~/screenshots/test-recording.avi 2>/dev/null

    echo "Creating test WebM..."
    ffmpeg -f lavfi -i color=white:size=320x240:duration=1 -c:v libvpx -y ~/screenshots/test-recording.webm 2>/dev/null
else
    echo "⚠ FFmpeg not found — skipping video test files"
fi

echo ""
echo "✅ Test files created in ~/screenshots/"
ls -lh ~/screenshots/
echo ""
echo "Now:"
echo "1. Start the app:  open 'build/Screen Organizer.app'"
echo "2. Watch logs:     log stream --predicate 'process == \"ScreenOrganizer\"' --level debug"
echo "3. Check results:"
echo "   ls -lh ~/screenshots/    # images should become .jpg"
echo "   ls -lh ~/screen-recordings/  # videos should become .mp4"
