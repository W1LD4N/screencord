#!/usr/bin/env bash
#
# ScreenCord v0.1.0 - Simple macOS Screen Recorder
# https://github.com/quamejnr/screencord

VERSION="0.1.0"

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
