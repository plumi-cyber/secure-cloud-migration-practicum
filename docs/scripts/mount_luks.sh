#!/usr/bin/env bash
# =============================================================================
# mount_luks.sh — LUKS + NTFS mount procedure for encrypted external drive
# =============================================================================
# Project: Secure Cloud Migration Practicum
#
# Background:
#   Drive is a LUKS-encrypted NTFS volume attached via VirtualBox USB 3.0
#   passthrough. USB passthrough drops cause unclean dismounts which set the
#   NTFS dirty flag. ntfsfix must run on the open LUKS mapper device (not the
#   raw block device) before mounting with ntfs-3g.
#
#   Two NTFS drivers exist on Ubuntu 24:
#     ntfs3  — kernel driver, fast, rejects dirty volumes by default
#     ntfs-3g — FUSE driver, slower, tolerates dirty flag after ntfsfix
#   This script uses ntfs-3g for write access.
#
# Usage:
#   sudo bash mount_luks.sh <device> <luks_name> <mount_point>
#
# Example:
#   sudo bash mount_luks.sh /dev/sdb luks-drive /media/user/DATA
#
# What each flag does (Linux+ exam reference):
#   lsblk       — list block devices and their mount state
#   mountpoint  — test if a path is currently a mount point (exit 0 = yes)
#   cryptsetup luksOpen  — decrypt LUKS header and create /dev/mapper/<name>
#   ntfsfix     — clear NTFS dirty flag; does NOT repair filesystem
#   mount -t ntfs-3g — mount using the FUSE ntfs-3g driver, not kernel ntfs3
# =============================================================================

set -euo pipefail

# --- Argument validation ---
if [[ $# -lt 3 ]]; then
    echo "Usage: sudo $0 <device> <luks_name> <mount_point>" >&2
    echo "  Example: sudo $0 /dev/sdb luks-drive /media/user/DATA" >&2
    exit 1
fi

DEVICE="$1"
LUKS_NAME="$2"
MOUNT_POINT="$3"
MAPPER="/dev/mapper/${LUKS_NAME}"

# Must run as root (cryptsetup and mount require it)
if [[ $EUID -ne 0 ]]; then
    echo "[ERROR] Run with sudo." >&2
    exit 1
fi

echo "=== LUKS Mount: ${DEVICE} -> ${MOUNT_POINT} ==="
echo "Timestamp: $(date -Iseconds)"
echo ""

# --- Step 1: Confirm device exists ---
if ! lsblk "${DEVICE}" &>/dev/null; then
    echo "[ERROR] Device ${DEVICE} not found." >&2
    echo "  Check: lsblk | grep sd" >&2
    echo "  VirtualBox: Devices -> USB -> confirm drive is passed through." >&2
    exit 1
fi
echo "[1/5] Device ${DEVICE} confirmed."

# --- Step 2: Check if already mounted ---
if mountpoint -q "${MOUNT_POINT}"; then
    echo "[INFO] ${MOUNT_POINT} is already mounted. Nothing to do."
    lsblk "${DEVICE}"
    exit 0
fi

# --- Step 3: Open LUKS layer ---
# Creates /dev/mapper/<luks_name> — the decrypted block device.
# All subsequent operations (ntfsfix, mount) target this mapper, not /dev/sdb.
if [[ ! -e "${MAPPER}" ]]; then
    echo "[2/5] Opening LUKS layer: ${DEVICE} -> ${MAPPER}"
    cryptsetup luksOpen "${DEVICE}" "${LUKS_NAME}"
else
    echo "[2/5] LUKS mapper ${MAPPER} already open. Skipping luksOpen."
fi

# --- Step 4: ntfsfix to clear dirty flag ---
# ntfs-3g will refuse a volume with the dirty flag set.
# ntfsfix operates on the decrypted mapper, not the raw encrypted device.
# It clears the flag but does NOT repair structural corruption —
# for that, use Windows chkdsk or a full ntfsck.
echo "[3/5] Running ntfsfix on ${MAPPER}..."
ntfsfix "${MAPPER}"

# --- Step 5: Mount with ntfs-3g ---
echo "[4/5] Mounting ${MAPPER} at ${MOUNT_POINT}..."
mount -t ntfs-3g "${MAPPER}" "${MOUNT_POINT}"

# --- Step 6: Verify and report ---
echo "[5/5] Verifying mount..."
lsblk "${DEVICE}"
df -h "${MOUNT_POINT}"
echo ""
echo "[OK] Drive mounted at ${MOUNT_POINT}."
echo "     Run: sudo dmesg | tail -5 to confirm USB bus is clean."
echo "     On dismount: umount ${MOUNT_POINT} && cryptsetup close ${LUKS_NAME}"
