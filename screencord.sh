#!/usr/bin/env bash
#
# ScreenCord - Simple macOS Screen Recorder
# https://github.com/quamejnr/screencord

VERSION="0.2.0"
FORMAT="mp4"

show_help() {
    cat << EOF
ScreenCord v$VERSION - Efficient macOS Screen Recorder

USAGE:
    ./screencord.sh [OPTIONS] [FORMAT]

OPTIONS:
    -h    Show this help message
    -v    Show version information
    -f    Output format (default: mp4)
    -c    Enable camera overlay

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
    ./screencord.sh -h           # Show help
    ./screencord.sh -f mov       # Record as MOV
    ./screencord.sh -c           # Record with camera overlay

EOF
}


declare -a input_opts
declare -a video_opts
declare -a audio_opts
declare -a output_opts
declare -a camera_opts
declare -a filter_opts
camera_overlay=false
camera_index=""


while getopts "hvf:c" opt; do
    case $opt in
        h) show_help; exit 0;;
        v) echo "ScreenCord v$VERSION"; exit 0;;
        f) FORMAT="$OPTARG" ;;
        c) camera_overlay=true ;;
    esac
done

fileName="$HOME/Documents/screencord_$(date '+%Y-%m-%d@%H.%M.%S').$FORMAT"

devices=$(ffmpeg -f avfoundation -list_devices true -i "" 2>&1)

is_valid_input() {
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        return 0
    else
        return 1
    fi
}


get_video_devices() {
    echo "--- VIDEO DEVICES ---"
    echo "$devices" | sed -n '/AVFoundation video devices:/,/AVFoundation audio devices:/p' | grep "\[[0-9]\+\]"
    while true; do
        printf "\nEnter video device index (eg. 0):\n"
        read video_index
        if is_valid_input "$video_index"; then
            break
        else
            echo "Invalid input. Please enter a number."
        fi
    done
}

get_audio_devices() {
    printf "\n--- AUDIO DEVICES ---\n"
    echo "$devices" | sed -n '/AVFoundation audio devices:/,$p' | grep "\[[0-9]\+\]"
    while true; do
        printf "\nEnter audio device index (eg. 0):\n"
        read audio_index
        if is_valid_input "$audio_index"; then
            break
        else
            echo "Invalid input. Please enter a number."
        fi
    done
}

get_camera_devices() {
    if [[ "$camera_overlay" == "true" ]]; then
        echo "--- CAMERA DEVICES ---"
        echo "$devices" | sed -n '/AVFoundation video devices:/,/AVFoundation audio devices:/p' | grep "\[[0-9]\+\]"
        while true; do
            printf "\nEnter camera device index (eg. 0):\n"
            read camera_index
            if is_valid_input "$camera_index"; then
                break
            else
                echo "Invalid input. Please enter a number."
            fi
        done
    fi
}

get_best_framerate_quality() {
    resolutions=("3840x2160" "2560x1440" "1920x1080" "1280x720" "640x480")
    framerates=(60 30 24)

    best_frame=""
    best_res=""

    for res in "${resolutions[@]}"; do
        for fps in "${framerates[@]}"; do
            if ffmpeg -f avfoundation -framerate "$fps" -video_size "$res" -i "$1" -t 0.1 -f null - &>/dev/null; then
                echo "$fps $res"
                return 0
            fi
        done
    done
    return 1
}

build_ffmpeg_options() {
    local video_device="$1"
    local audio_device="$2"
    local camera_device="$3"

    if ! best_framerate_quality=$(get_best_framerate_quality "$video_device"); then
        echo "Supported format not found!"
        return 1
    fi
    read -r best_frame best_res <<< "$best_framerate_quality"

    screen_opts=(-f avfoundation -framerate "$best_frame" -video_size "$best_res" -i "$video_device:$audio_device")
    video_opts=(-c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p)
    audio_opts=(-c:a aac -b:a 128k)
    output_opts=(-movflags +faststart "$fileName")

    if [[ "$camera_overlay" == "true" ]]; then
        if ! best_framerate_quality=$(get_best_framerate_quality "$camera_device"); then
            echo "Supported format not found!"
            return 1
        fi
        read -r best_cam_frame best_cam_res <<< "$best_framerate_quality"
        camera_opts=(-f avfoundation -framerate "$best_cam_frame" -video_size "$best_cam_res" -i "$camera_device")
        filter_opts=(-filter_complex "[0:v]scale=480:270[cam];[1:v][cam]overlay=W-w-10:10")
    fi
}


record_video() {
    if ! build_ffmpeg_options "$1" "$2" "$3" ; then
        return 1
    fi
    ffmpeg "${camera_opts[@]}" "${screen_opts[@]}" "${video_opts[@]}" "${filter_opts[@]}" "${audio_opts[@]}" "${output_opts[@]}"
}

get_video_devices
get_audio_devices
get_camera_devices

echo "\nRecording with video:$video_index, audio:$audio_index"
if [[ "$camera_overlay" == "true" ]]; then
    echo "Camera overlay: $camera_index"
fi
echo "Output: $fileName"
echo "Press Ctrl+C to stop recording\n"

title="ScreenCord"
msg="Recording started..."
osascript -e "display notification \"$msg\" with title \"$title\""

record_video "$video_index" "$audio_index" "$camera_index"

if [ -f "$fileName" ]; then
    msg="Video saved at $fileName"
    osascript -e "display notification \"$msg\" with title \"$title\""
    
    sleep 1
    open "$(dirname "$fileName")"
    
else
    msg="Recording failed"
    osascript -e "display notification \"$msg\" with title \"$title\""
fi

