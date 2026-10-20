#!/bin/bash
set -e

ROOT_DEV=$(findmnt -n -o SOURCE /)
DISK=$(lsblk -no PKNAME "$ROOT_DEV")

# Jetson Nano's util-linux (2.31.1) predates the PARTN column (added in
# 2.34), so derive the partition number from the device name instead:
# strip the "/dev/$DISK" prefix (which may end in a "p" separator for
# devices like mmcblk0p1) and keep the trailing digits.
PARTNUM=$(echo "${ROOT_DEV#/dev/$DISK}" | tr -dc '0-9')

growpart /dev/$DISK $PARTNUM
resize2fs $ROOT_DEV
