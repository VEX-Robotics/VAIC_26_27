#!/bin/bash

option=$1

# Run from this script's own directory so relative script paths resolve
# regardless of the caller's current working directory.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

build_scripts=(
    "scripts/build-img-jetson-orin.sh"
    "scripts/build-img-jetson-legacy.sh"
    "scripts/build-img-pi.sh"
)

if [ -z "$option" ]; then
    echo "--------------------------------"
    echo "      VAIC Image Builder"
    echo "--------------------------------"
    echo "1) Jetson Orin Nano"
    echo "2) Jetson Nano Legacy"
    echo "3) Raspberry Pi 5"
    echo "4) All Images"
    read -p "Select an image to build (1-4): " option
fi

case "${option,,}" in
    1|orin)
        script_index=0
        selection="orin"
        ;;
    2|nano)
        script_index=1
        selection="nano"
        ;;
    3|pi)
        script_index=2
        selection="pi"
        ;;
    4|all)
        selection="all"
        ;;
    *)
        echo "Invalid option: $option"
        echo "Use one of: orin, nano, pi, all"
        exit 1
        ;;
esac

if [ "$selection" != "all" ]; then
    build_script="${build_scripts[$script_index]}"
    sudo ./"$build_script"
    if [ $? -ne 0 ]; then
        echo "Error: $build_script failed."
        exit 1
    fi
else
    for script in "${build_scripts[@]}"; do
        sudo ./"$script"
        if [ $? -ne 0 ]; then
            echo "Error: $script failed."
        fi
    done
fi
