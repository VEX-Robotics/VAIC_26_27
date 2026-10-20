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
# Dockerfile.jetsonnano-legacy COPYs paths (JetsonWebDashboard/, JetsonExample/)
# that live at the repo root, so the build context must be the repo root.
REPO_ROOT="$(cd "$JETSON_DIR/.." && pwd)"
cd "$JETSON_DIR"

L4T_DIR="./build/Linux_for_Tegra-r32"
L4T_CHECKSUM="7b6f4a698278226ae1d92661270c5441e16d01eafffb4bfb086de80b6964ae6f"
IMG_FILE="$JETSON_DIR/out/vexai-jetson-nano-legacy-$(date +%Y%m%d-%H%M%S).img"


if [ ! -d "$L4T_DIR" ]; then
    echo "Linux_for_Tegra directory not found. Downloading..."
    wget https://developer.nvidia.com/embedded/l4t/r32_release_v7.1/t210/jetson-210_linux_r32.7.1_aarch64.tbz2

    echo "Verifying checksum..."
    DOWNLOADED_CHECKSUM=$(sha256sum jetson-210_linux_r32.7.1_aarch64.tbz2 | awk '{print $1}')
    if [ "$DOWNLOADED_CHECKSUM" != "$L4T_CHECKSUM" ]; then
        echo "Checksum verification failed."
        echo "Expected: $L4T_CHECKSUM"
        echo "Got:      $DOWNLOADED_CHECKSUM"
        rm -f jetson-210_linux_r32.7.1_aarch64.tbz2
        exit 1
    fi
    echo "Checksum verified."

    echo "Extracting L4T..."
    tar xf jetson-210_linux_r32.7.1_aarch64.tbz2 
    if [ -d "Linux_for_Tegra" ] && [ "Linux_for_Tegra" != "$L4T_DIR" ]; then
        mkdir -p "$L4T_DIR"
        mv Linux_for_Tegra/* "$L4T_DIR"
        rm -rf Linux_for_Tegra
    fi
    
    rm jetson-210_linux_r32.7.1_aarch64.tbz2 


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
docker build -t vexai:nano -f Dockerfile.jetsonnano-legacy --output type=tar "$REPO_ROOT" | tar xf - -C "$L4T_DIR/rootfs"

echo "Rootfs built and extracted to L4T."
echo "Applying Nvidia binaries..."

cd $L4T_DIR

# `yes` commonly exits with SIGPIPE once apply_binaries.sh stops reading input.
# With `set -euo pipefail`, that would abort the script, so disable pipefail
# just for this pipeline.
set +o pipefail
yes n | ./apply_binaries.sh
set -o pipefail

# Final step is to generate the final image

mkdir -p $JETSON_DIR/out

# jetson-disk-image-creator.sh formats the rootfs partition on the build
# host via plain `mkfs -t ext4`, which uses the host's /etc/mke2fs.conf
# defaults. Modern e2fsprogs defaults enable orphan_file/metadata_csum_seed,
# which the Nano's Ubuntu 18.04 e2fsprogs (1.44.1) doesn't recognize, so
# resize2fs on first boot fails with "Filesystem has unsupported feature(s)".
# Override with a config that matches what e2fsprogs 1.44.1 supports.
MKE2FS_CONFIG_OVERRIDE="$JETSON_DIR/build/mke2fs-nano-legacy.conf"
cat > "$MKE2FS_CONFIG_OVERRIDE" << 'EOF'
[defaults]
	base_features = sparse_super,large_file,filetype,resize_inode,dir_index,ext_attr
	default_mntopts = acl,user_xattr
	enable_periodic_fsck = 0
	blocksize = 4096
	inode_size = 256
	inode_ratio = 16384

[fs_types]
	ext3 = {
		features = has_journal
	}
	ext4 = {
		features = has_journal,extent,huge_file,flex_bg,metadata_csum,64bit,dir_nlink,extra_isize
	}
EOF
export MKE2FS_CONFIG="$MKE2FS_CONFIG_OVERRIDE"

./tools/jetson-disk-image-creator.sh -o "$IMG_FILE" -b jetson-nano-2gb-devkit

echo "Compressing image..."
cd ..
pigz "$IMG_FILE"

echo "Generating SHA256 checksum..."
sha256sum "$IMG_FILE.gz" > "$IMG_FILE.gz.sha256"

echo Final image created: $IMG_FILE.gz

