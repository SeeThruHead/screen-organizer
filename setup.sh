#!/bin/bash
set -e

echo "🔧 Setting up Screen Organizer dependencies..."

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew not found. Please install Homebrew first:"
    echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

echo "✅ Homebrew found"

# Install ffmpeg if not present
if ! command -v /opt/homebrew/bin/ffmpeg &> /dev/null; then
    echo "📦 Installing ffmpeg..."
    brew install ffmpeg
else
    echo "✅ ffmpeg found"
fi

# Install imagemagick if not present
if ! command -v /opt/homebrew/bin/magick &> /dev/null; then
    echo "📦 Installing imagemagick..."
    brew install imagemagick
else
    echo "✅ imagemagick found"
fi

echo ""
echo "🎉 Dependencies ready!"
echo ""
echo "Next steps:"
echo "1. Run ./build.sh to compile the app"
echo "2. Copy the app to /Applications/"
echo "3. Add it to Login Items in System Preferences"