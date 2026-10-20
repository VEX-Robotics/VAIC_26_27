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
# Dockerfile.pi COPYs paths (JetsonWebDashboard/, JetsonExample/, JetsonImages/)
# that live at the repo root, so the build context must be the repo root.
REPO_ROOT="$(cd "$JETSON_DIR/.." && pwd)"
cd "$JETSON_DIR"

# ── Configuration ──────────────────────────────────────────────────────────────
RASPIOS_URL="https://downloads.raspberrypi.com/raspios_lite_arm64_latest"
RASPIOS_XZ="raspios-lite-arm64.img.xz"
RASPIOS_IMG="raspios-lite-arm64.img"
PI_FIRMWARE_DIR="./build/pi-firmware"
BASE_DOCKER_TAG="raspios-base:latest"

IMG_FILE="./out/vexai-pi5-$(date +%Y%m%d-%H%M%S).img"
BOOT_SIZE_MB=512

DOCKER_TAG="vexai-pi:dev"

# ── Cleanup state ──────────────────────────────────────────────────────────────
LOOP_OUT=""
MNT_BOOT=""
MNT_ROOT=""
CONTAINER_ID=""

cleanup() {
    set +e
    echo "Cleaning up..."
    [ -n "$CONTAINER_ID" ] && docker rm "$CONTAINER_ID" 2>/dev/null
    [ -n "$MNT_BOOT" ] && mountpoint -q "$MNT_BOOT" 2>/dev/null && umount "$MNT_BOOT"
    [ -n "$MNT_ROOT" ] && mountpoint -q "$MNT_ROOT" 2>/dev/null && umount "$MNT_ROOT"
    [ -n "$LOOP_OUT" ] && losetup -d "$LOOP_OUT" 2>/dev/null
    [ -n "$MNT_BOOT" ] && rmdir "$MNT_BOOT" 2>/dev/null || true
    [ -n "$MNT_ROOT" ] && rmdir "$MNT_ROOT" 2>/dev/null || true
}
trap cleanup EXIT

download_base_image() {
    if [ ! -f "$RASPIOS_IMG" ]; then
        if [ ! -f "$RASPIOS_XZ" ]; then
            echo "Downloading Raspberry Pi OS Lite arm64..."
            curl -L --progress-bar -o "$RASPIOS_XZ" "$RASPIOS_URL"
        fi
        echo "Decompressing Pi OS image..."
        xz -dk "$RASPIOS_XZ"
        LOOP_BASE=$(losetup --find --show --partscan "$RASPIOS_IMG")
        MNT_BASE=$(mktemp -d)
        mount -o ro "${LOOP_BASE}p1" "$MNT_BASE"
        echo "Copying Pi OS boot firmware to $PI_FIRMWARE_DIR..."
        mkdir -p "$PI_FIRMWARE_DIR"
        rsync -a --info=progress2 "$MNT_BASE/" "$PI_FIRMWARE_DIR/"
        umount "$MNT_BASE"
        rmdir "$MNT_BASE"
        losetup -d "$LOOP_BASE" 
    fi
}

mkdir -p out

# ── Install build dependencies ─────────────────────────────────────────────────
echo "Installing build dependencies..."
apt-get install -y --no-install-recommends parted dosfstools e2fsprogs rsync git curl xz-utils

# ── Pi OS image: download once, used for both Docker base and boot partition ───
if [ ! -d "$PI_FIRMWARE_DIR" ]; then
    download_base_image
    LOOP_BASE=$(losetup --find --show --partscan "$RASPIOS_IMG")
    MNT_BASE=$(mktemp -d)
    mount -o ro "${LOOP_BASE}p1" "$MNT_BASE"
    echo "Copying Pi OS boot firmware to $PI_FIRMWARE_DIR..."
    rsync -a --info=progress2 "$MNT_BASE/" "$PI_FIRMWARE_DIR/"
    umount "$MNT_BASE"
    rmdir "$MNT_BASE"
    losetup -d "$LOOP_BASE" 
fi

if ! docker image inspect "$BASE_DOCKER_TAG" &>/dev/null; then
    download_base_image
    LOOP_BASE=$(losetup --find --show --partscan "$RASPIOS_IMG")
    MNT_BASE=$(mktemp -d)
    mount -o ro "${LOOP_BASE}p2" "$MNT_BASE"
    echo "Importing Pi OS rootfs as $BASE_DOCKER_TAG..."
    tar -C "$MNT_BASE" --one-file-system -c . | docker import \
        --change 'ENV DEBIAN_FRONTEND=noninteractive' \
        - "$BASE_DOCKER_TAG"
    umount "$MNT_BASE"
    rmdir "$MNT_BASE"
    losetup -d "$LOOP_BASE"
fi

if [ -f "$RASPIOS_IMG" ]; then
    rm -f "$RASPIOS_IMG"
    rm -f "$RASPIOS_XZ"
fi

# ── Build Docker Pi rootfs ─────────────────────────────────────────────────────
echo "Building Pi rootfs Docker image..."
docker build --platform linux/arm64 -t "$DOCKER_TAG" -f Dockerfile.pi "$REPO_ROOT"

# ── Calculate image size from rootfs + 2 GiB headroom ─────────────────────────
ROOTFS_BYTES=$(docker image inspect "$DOCKER_TAG" --format='{{.Size}}')
HEADROOM_BYTES=$(( 2 * 1024 * 1024 * 1024 ))
BOOT_BYTES=$(( (BOOT_SIZE_MB + 4) * 1024 * 1024 ))

# 15% overhead for ext4 block alignment and filesystem metadata
TOTAL_BYTES=$(( ROOTFS_BYTES * 115 / 100 + HEADROOM_BYTES + BOOT_BYTES ))
IMG_SIZE_MB=$(( (TOTAL_BYTES + 1024 * 1024 - 1) / (1024 * 1024) ))

echo "Rootfs: $(( ROOTFS_BYTES / 1024 / 1024 )) MiB  Image: ${IMG_SIZE_MB} MiB"

# ── Create and partition output image ─────────────────────────────────────────
echo "Creating ${IMG_SIZE_MB} MiB image: $IMG_FILE"
dd if=/dev/zero of="$IMG_FILE" bs=1M count="$IMG_SIZE_MB" status=progress

BOOT_END_MIB=$((BOOT_SIZE_MB + 4))
parted -s "$IMG_FILE" \
    mklabel msdos \
    mkpart primary fat32 4MiB "${BOOT_END_MIB}MiB" \
    mkpart primary ext4 "${BOOT_END_MIB}MiB" 100% \
    set 1 boot on

LOOP_OUT=$(losetup --find --show --partscan "$IMG_FILE")
echo "Loop device: $LOOP_OUT"

# Allow kernel time to register partition devices.
partprobe "$LOOP_OUT" 2>/dev/null || true
sleep 1

# ── Format partitions ─────────────────────────────────────────────────────────
echo "Formatting partitions..."
mkdosfs -F 32 -n bootfs "${LOOP_OUT}p1"
mkfs.ext4 -L rootfs "${LOOP_OUT}p2"

# ── Determine PARTUUIDs ────────────────────────────────────────────────────────
PARTUUID_BOOT=$(blkid -s PARTUUID -o value "${LOOP_OUT}p1")
PARTUUID_ROOT=$(blkid -s PARTUUID -o value "${LOOP_OUT}p2")
echo "boot=$PARTUUID_BOOT  root=$PARTUUID_ROOT"

# ── Populate root partition from Docker image ──────────────────────────────────
echo "Extracting Docker rootfs into image..."
MNT_ROOT=$(mktemp -d)
mount "${LOOP_OUT}p2" "$MNT_ROOT"

CONTAINER_ID=$(docker create --platform linux/arm64 "$DOCKER_TAG" /bin/sh)
docker export "$CONTAINER_ID" | tar xf - -C "$MNT_ROOT"
docker rm "$CONTAINER_ID"; CONTAINER_ID=""

APT_KVER=$(ls "$MNT_ROOT/lib/modules/" | head -1)
echo "Apt kernel version: $APT_KVER"

# ── Populate boot partition ────────────────────────────────────────────────────
echo "Populating boot partition..."
MNT_BOOT=$(mktemp -d)
mount "${LOOP_OUT}p1" "$MNT_BOOT"

# Use the Pi OS image boot partition directly — kernel and firmware are already
# version-matched (both come from the same downloaded image).

rsync -a --info=progress2 "$PI_FIRMWARE_DIR/" "$MNT_BOOT/"

cat > "$MNT_BOOT/config.txt" << 'EOF'
arm_64bit=1
enable_uart=1
# Coral M.2 PCIe Accelerator (gasket driver requires kernel8.img for PCIe support)
kernel=kernel8.img
dtparam=pciex1
dtparam=pciex1_gen=3
dtparam=uart0
dtparam=uart0_console
dtoverlay=pineboards-hat-ai
EOF

printf 'console=serial0,115200 console=tty1 root=PARTUUID=%s rootfstype=ext4 fsck.repair=yes rootwait\n' \
    "$PARTUUID_ROOT" > "$MNT_BOOT/cmdline.txt"

umount "$MNT_BOOT"
rmdir "$MNT_BOOT"; MNT_BOOT=""

# Remove apt kernel files from rootfs — they now live on the FAT32 partition.
rm -rf "$MNT_ROOT/boot/firmware/"*
mkdir -p "$MNT_ROOT/boot/firmware"

# ── Write /etc/fstab ──────────────────────────────────────────────────────────
cat > "$MNT_ROOT/etc/fstab" << EOF
proc            /proc           proc    defaults                    0       0
PARTUUID=${PARTUUID_BOOT}   /boot/firmware  vfat    defaults,nofail,x-systemd.device-timeout=5  0  2
PARTUUID=${PARTUUID_ROOT}   /   ext4    defaults,noatime            0       1
EOF

# ── Write /etc/hosts ──────────────────────────────────────────────────────────
# Can't be set at Docker build time (/etc/hosts is a read-only build mount that
# Docker discards). Written here so the hostname resolves (avoids sudo warnings).
cat > "$MNT_ROOT/etc/hosts" << EOF
127.0.0.1   localhost
127.0.1.1   vexai
::1         localhost ip6-localhost ip6-loopback
ff02::1     ip6-allnodes
ff02::2     ip6-allrouters
EOF

echo "vexai" > "$MNT_ROOT/etc/hostname"

# ── Finalize ──────────────────────────────────────────────────────────────────
umount "$MNT_ROOT"
rmdir "$MNT_ROOT"; MNT_ROOT=""
losetup -d "$LOOP_OUT"; LOOP_OUT=""

echo "Compressing image..."
pigz "$IMG_FILE"

echo "Generating SHA256 checksum..."
sha256sum "$IMG_FILE.gz" > "$IMG_FILE.gz.sha256"

echo ""
echo "Pi image created: $IMG_FILE.gz"
echo "Flash with:"
echo "  gunzip -c $IMG_FILE.gz | sudo dd of=/dev/sdX bs=4M status=progress conv=fsync"
echo "  or use Raspberry Pi Imager → 'Use custom'"