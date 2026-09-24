# Screen Organizer

A simple macOS menu bar app that automatically:
- **Compresses and moves** `.mov` screen recordings from `~/screenshots/` to `~/screen-recordings/`
- **Compresses** `.png` screenshots in place
- **Organizes files by date** into `YYYY-MM-DD` subfolders (optional)
- **Shows visual feedback** — menu bar icon changes to a gear when processing
- **Copies each capture to the clipboard** as one item that pastes as the file in Slack or Finder, as the path in a terminal or Claude, and as an image in image fields (optional)

## Install

```bash
brew install seethruhead/tap/screenorganizer
```

## Launch

```bash
open "/Applications/Screen Organizer.app"
```

Enable **Open at Login** from the menu bar icon to start automatically.

## Configuration

Settings are managed from the menu bar icon, or by editing `~/.config/screenorganizer`:

```
screenshotsFolder=screenshots
screenRecordingsFolder=screen-recordings
videoQuality=medium
imageQuality=medium
organizeByDate=false
copyToClipboard=true
```

**Quality levels:** `low` (smallest files), `medium` (balanced), `high` (best quality)

## Menu Bar Options

- Open Screenshots / Recordings folder
- Organize by Date (toggle)
- Copy to Clipboard (toggle)
- Open at Login (toggle)
- Settings
- Quit

## Dependencies

Installed automatically by Homebrew:
- [ffmpeg](https://ffmpeg.org/) — video compression
- [imagemagick](https://imagemagick.org/) — image compression
