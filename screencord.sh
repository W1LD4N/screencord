#!/usr/bin/env bash
#
# ScreenCord v0.1.0 - Simple macOS Screen Recorder
# https://github.com/quamejnr/screencord

VERSION="0.1.0"

show_help() {
    cat << EOF
ScreenCord v$VERSION - Efficient macOS Screen Recorder

USAGE:
    ./screencord.sh [OPTIONS] [FORMAT]

OPTIONS:
    -h, --help     Show this help message
    -v, --version  Show version information

ARGUMENTS:
    FORMAT         Output format (default: mp4)

DESCRIPTION:
    Interactive screen recorder that produces compressed videos.
    Creates much smaller files than macOS built-in recording.

WORKFLOW:
    1. Lists available video devices (cameras, screens)
    2. Select video device index
    3. Lists available audio devices (microphones)
    4. Select audio device index
    5. Records until Ctrl+C is pressed
    6. Saves to ~/Documents/ and opens folder

OUTPUT:
    ~/Documents/screencord_YYYY-MM-DD@HH.MM.SS.FORMAT

EXAMPLES:
    ./screencord.sh              # Record as MP4
    ./screencord.sh mov          # Record as MOV
    ./screencord.sh --help       # Show help

EOF
}

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    show_help
    exit 0
fi

if [[ "$1" == "--version" || "$1" == "-v" ]]; then
    echo "ScreenCord v$VERSION"
    exit 0
fi

FORMAT="${1:-mp4}"
fileName="$HOME/Documents/screencord_$(date '+%Y-%m-%d@%H.%M.%S').$FORMAT"

devices=$(ffmpeg -f avfoundation -list_devices true -i "" 2>&1)

validate_input() {
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        break
    else
        echo "Invalid input. Please enter a number."
    fi

}

get_video_devices() {
    echo "--- VIDEO DEVICES ---"
    echo "$devices" | sed -n '/AVFoundation video devices:/,/AVFoundation audio devices:/p' | grep "\[[0-9]\+\]"
    while true; do
        printf "\nEnter video device index (eg. 0):\n"
        read video_index
        validate_input $video_index
    done
}

get_audio_devices() {
    printf "\n--- AUDIO DEVICES ---\n"
    echo "$devices" | sed -n '/AVFoundation audio devices:/,$p' | grep "\[[0-9]\+\]"
    while true; do
        printf "\nEnter audio device index (eg. 0):\n"
        read audio_index
        validate_input $audio_index
    done
}

record_video() {
    ffmpeg -f avfoundation -i "$1:$2" \
      -c:v libx264 -preset medium -crf 23 \
      -c:a aac -b:a 128k \
      -movflags +faststart \
      -pix_fmt yuv420p "$fileName"
}

get_video_devices
get_audio_devices

echo "Recording with video:$video_index, audio:$audio_index"
echo "Output: $fileName"
echo "Press Ctrl+C to stop recording"

title="ScreenCord"
msg="Recording started..."
osascript -e "display notification \"$msg\" with title \"$title\""

record_video "$video_index" "$audio_index"

if [ -f "$fileName" ]; then
    msg="Video saved at $fileName"
    osascript -e "display notification \"$msg\" with title \"$title\""
    
    sleep 1
    open "$(dirname "$fileName")"
    
else
    msg="Recording failed"
    osascript -e "display notification \"$msg\" with title \"$title\""
fi
