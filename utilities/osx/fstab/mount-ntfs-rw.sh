#!/bin/bash
# Mount "Extra Bulk Storage" NTFS volume in read-write mode.
# Uses macOS native (experimental) NTFS write support via /etc/fstab.
# Must be run as root: sudo bash mount-ntfs-rw.sh

set -e

VOL_UUID="858B0F34-CEFA-4D8C-A388-59486C7C2716"
VOL_NAME="Extra Bulk Storage"
DEVICE="/dev/disk6s2"

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: must run as root (sudo)" >&2
    exit 1
fi

# Add fstab entry if not already present
if ! grep -q "$VOL_UUID" /etc/fstab 2>/dev/null; then
    echo "UUID=$VOL_UUID none ntfs rw,auto,nobrowse" >> /etc/fstab
    echo "Added rw entry to /etc/fstab"
else
    echo "fstab entry already exists"
fi

# Unmount and remount
echo "Unmounting $VOL_NAME..."
diskutil unmount force "$DEVICE" || true
sleep 1
echo "Remounting $VOL_NAME..."
diskutil mount "$DEVICE"

# Verify
mount_info=$(mount | grep "$DEVICE" || true)
if echo "$mount_info" | grep -q "read-only"; then
    echo "FAIL: still read-only"
    echo "$mount_info"
    exit 1
else
    echo "SUCCESS: $VOL_NAME mounted read-write"
    echo "$mount_info"
fi
