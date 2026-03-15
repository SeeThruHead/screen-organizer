# Screen Organizer

A simple macOS app that sits in your menu bar and automatically:
- **Compresses and moves** `.mov` files (screen recordings) from `~/Screenshots/` to `~/ScreenRecordings/`
- **Compresses** `.png` files (screenshots) in `~/Screenshots/` to reduce file size
- **Shows visual feedback** in the menu bar when processing files

## Features

🎬 **Video Compression**: Reduces `.mov` files by ~66% using FFmpeg  
🖼️ **Image Compression**: Optimizes `.png` files using ImageMagick  
👁️ **Visual Feedback**: Menu bar icon changes to gear when processing  
🚀 **Auto-start**: Can be set to start automatically at login  
📁 **Quick Access**: Right-click menu to open Screenshots/ScreenRecordings folders  
📅 **Date Organization**: Organize existing files into date-based folders (YYYY-MM-DD)  

## Setup

1. **Install dependencies**:
   ```bash
   cd ~/Projects/ScreenOrganizer
   chmod +x setup.sh
   ./setup.sh
   ```

2. **Build the app**:
   ```bash
   chmod +x build.sh
   ./build.sh
   ```

3. **Install the app**:
   ```bash
   cp -R "build/Screen Organizer.app" /Applications/
   ```

4. **Run the app**:
   ```bash
   open "/Applications/Screen Organizer.app"
   ```

5. **Auto-start at login** (optional):
   - Go to System Preferences → Users & Groups → Login Items
   - Click "+" and add "Screen Organizer.app"

## How It Works

- The app watches `~/Screenshots/` folder for new files
- When a `.mov` file appears, it compresses it with FFmpeg and moves to `~/ScreenRecordings/`
- When a `.png` file appears, it compresses it in place with ImageMagick
- The menu bar icon shows a camera normally, and a spinning gear when processing

## Menu Bar Options

Right-click the menu bar icon to:
- See current status
- Open Screenshots folder
- Open ScreenRecordings folder
- **Organize by Date** - Move all existing files into date-based subfolders (YYYY-MM-DD)
- Quit the app

That's it! Simple and automatic.