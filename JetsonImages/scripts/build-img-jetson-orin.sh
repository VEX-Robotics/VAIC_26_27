#!/bin/bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (sudo)"
    exit 1
fi

# Run from the JetsonImages directory (this script's parent) so relative
# paths (Dockerfile, build/, out/) resolve regardless of invocation cwd.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JETSON_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# Dockerfile.jetsonorin COPYs paths (JetsonWebDashboard/, JetsonExample/)
# that live at the repo root, so the build context must be the repo root.
REPO_ROOT="$(cd "$JETSON_DIR/.." && pwd)"
cd "$JETSON_DIR"

L4T_DIR="./build/Linux_for_Tegra-r39"
L4T_CHECKSUM="1626626cd827de0e350b8802033b9da653c69b2290accedb9e5d01f49607e099"
IMG_FILE="$JETSON_DIR/out/vexai-jetson-orin-nano-$(date +%Y%m%d-%H%M%S).img"


if [ ! -d "$L4T_DIR" ]; then
    echo "Linux_for_Tegra directory not found. Downloading..."
    wget https://developer.nvidia.com/downloads/embedded/L4T/r39_Release_v2.0/release/Jetson_Linux_R39.2.0_aarch64.tbz2

    echo "Verifying checksum..."
    DOWNLOADED_CHECKSUM=$(sha256sum Jetson_Linux_R39.2.0_aarch64.tbz2 | awk '{print $1}')
    if [ "$DOWNLOADED_CHECKSUM" != "$L4T_CHECKSUM" ]; then
        echo "Checksum verification failed."
        echo "Expected: $L4T_CHECKSUM"
        echo "Got:      $DOWNLOADED_CHECKSUM"
        rm -f Jetson_Linux_R39.2.0_aarch64.tbz2
        exit 1
    fi
    echo "Checksum verified."
    
    echo "Extracting L4T..."
    tar xf Jetson_Linux_R39.2.0_aarch64.tbz2
    if [ -d "Linux_for_Tegra" ] && [ "Linux_for_Tegra" != "$L4T_DIR" ]; then
        mkdir -p "$L4T_DIR"
        mv Linux_for_Tegra/* "$L4T_DIR"
        rm -rf Linux_for_Tegra
    fi
    rm Jetson_Linux_R39.2.0_aarch64.tbz2

    # Fixes issue with ssh-keygen
    sed -i 's/ssh-keygen -t dsa/ssh-keygen -t rsa/' \
        "$L4T_DIR/tools/ota_tools/version_upgrade/ota_make_recovery_img_dtb.sh"

    echo "Linux_for_Tegra downloaded successfully."

    # Needed by the build process
    apt-get install -y libxml2-utils qemu-user-static binfmt-support

    # L4T relies on x86 binaries, so have to emulate them
    # Enable automatic qemu translation via binfmt
    update-binfmts --enable qemu-x86_64 || true
    update-binfmts --enable qemu-i386 || true
    
fi

echo "Building rootfs and extracting to L4T..."
rm -rf $L4T_DIR/rootfs/*
docker build -t vexai:dev -f Dockerfile.jetsonorin --output type=tar "$REPO_ROOT" | tar xf - -C "$L4T_DIR/rootfs"

echo "Rootfs built and extracted to L4T."
echo "Applying Nvidia binaries..."

cd $L4T_DIR
./apply_binaries.sh

# Final step is to generate the final image

mkdir -p $JETSON_DIR/out

./tools/jetson-disk-image-creator.sh -o "$IMG_FILE" -b jetson-orin-nano-devkit -d SD

echo "Compressing image..."
cd ..
pigz "$IMG_FILE"

echo "Generating SHA256 checksum..."
sha256sum "$IMG_FILE.gz" > "$IMG_FILE.gz.sha256"

echo Final image created: $IMG_FILE.gz

