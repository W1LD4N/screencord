# ScreenCord 🎬

Lightweight macOS screen recorder that produces efficient, compressed video files.

## Why ScreenCord?

macOS built-in screen recording creates **bloated files** - a 30-second recording can easily be 118MB or larger. ScreenCord uses ffmpeg with optimized H.264 encoding to create **much smaller files** with the same quality, perfect for sharing and storage.

## File Size Comparison

| Recording Method | Duration | File Size |
|-----------------|----------|-----------|
| macOS built-in | 1 minute | ~118MB |
| **ScreenCord** | **5 minutes** | **~35MB** |


## Quick Install

```bash
curl -o screencord.sh https://raw.githubusercontent.com/quamejnr/screencord/main/screencord.sh && chmod +x screencord.sh
```

## Requirements

- macOS
- ffmpeg: `brew install ffmpeg`

## Usage

```bash
./screencord.sh [OPTIONS]
```

The script will:
1. Show available video devices (cameras, screens)
2. Show available audio devices (microphones)
3. Let you select which devices to use
4. Start recording with native notifications
5. Save timestamped MP4 files to `~/Documents/`

### Options

| Option | Description |
|---|---|
| `-h` | Show help message |
| `-v` | Show version information |
| `-f` | Output format (default: `mp4`) |
| `-c` | Enable camera overlay |

### Custom Format

By default, the recording is saved as an `mp4` file. You can use the `-f` flag to specify a different format.

For example, to save as a `mov` file:

```sh
./screencord.sh -f mov
```

### Camera Overlay

Enable the camera overlay to record your screen and camera simultaneously.

```sh
./screencord.sh -c
```

The script will prompt you to select a camera device to use for the overlay.

## Features

- ✅ **Efficient compression** - Much smaller files than macOS native recording
- ✅ **Automatic quality detection** - Chooses the best resolution and framerate for your screen
- ✅ Interactive device selection
- ✅ Camera overlay
- ✅ High-quality H.264/AAC output
- ✅ macOS notifications

## Output

Files are saved as: `~/Documents/screencord_YYYY-MM-DD@HH.MM.SS.mp4`

## Stop Recording

Press `Ctrl+C` in the terminal to stop recording.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
