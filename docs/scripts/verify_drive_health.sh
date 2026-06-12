#!/usr/bin/env bash
# =============================================================================
# verify_drive_health.sh — SMART and dmesg health check for external drives
# =============================================================================
# Project: Secure Cloud Migration Practicum
#
# Background:
#   Used at the start of each working session to assess drive state before
#   any read or write operations. Critical on a drive with known multi-region
#   platter damage (1,677 power-on hours, abnormal damage pattern consistent
#   with past physical impact).
#
#   Four SMART attributes were tracked throughout this project:
#
#     Reallocated_Sector_Ct   — sectors the drive has permanently marked bad
#                               and remapped to spare area. Non-zero = damage
#                               has occurred. Growing count = active failure.
#
#     Current_Pending_Sector  — unstable sectors flagged for reallocation on
#                               next successful read. Non-zero = damage present.
#                               A fixed (non-growing) count indicates bounded
#                               damage, not progressive failure.
#
#     Offline_Uncorrectable   — sectors that failed during offline self-tests.
#                               If non-zero, check which LBA regions are affected.
#
#     UDMA_CRC_Error_Count    — signal integrity errors on the cable/USB path.
#                               Non-zero = connection problem, not drive problem.
#                               Distinguish from platter damage before escalating.
#
#   dmesg patterns indicating a transport cascade (USB passthrough + VirtualBox):
#     "usb X-X: reset SuperSpeed USB device" — bus attempting recovery
#     "cmd_age=XXXs"                          — hung command (>60s = severe)
#     "Buffer I/O error on dev dm-0"          — I/O failure on LUKS layer
#     "end_request: I/O error"               — read failing at block layer
#
# Usage:
#   sudo bash verify_drive_health.sh <device>
#   Example: sudo bash verify_drive_health.sh /dev/sdb
#
# Requires: smartmontools (apt install smartmontools)
# =============================================================================

set -euo pipefail

DEVICE="${1:?Usage: sudo $0 <device>}"

if [[ $EUID -ne 0 ]]; then
    echo "[ERROR] Run with sudo (smartctl requires root)." >&2
    exit 1
fi

if ! command -v smartctl &>/dev/null; then
    echo "[ERROR] smartmontools not installed. Run: sudo apt install smartmontools" >&2
    exit 1
fi

echo "=== Drive Health Check: ${DEVICE} ==="
echo "Timestamp: $(date -Iseconds)"
echo ""

# --- Overall SMART verdict ---
echo "--- SMART Overall Status ---"
smartctl -H "${DEVICE}" | grep -i "overall-health\|result\|SMART overall"
echo ""

# --- Key attributes ---
echo "--- Key Attributes ---"
smartctl -A "${DEVICE}" | \
    awk 'NR==1{print} /Reallocated_Sector_Ct|Current_Pending_Sector|Offline_Uncorrectable|UDMA_CRC_Error_Count/{
        printf "  %-32s value=%-6s raw=%-10s\n", $2, $4, $10
    }'
echo ""

# --- Threshold alerts ---
PENDING=$(smartctl -A "${DEVICE}" | awk '/Current_Pending_Sector/{print $10}')
REALLOCATED=$(smartctl -A "${DEVICE}" | awk '/Reallocated_Sector_Ct/{print $10}')
UDMA=$(smartctl -A "${DEVICE}" | awk '/UDMA_CRC_Error_Count/{print $10}')

if [[ -n "${REALLOCATED}" && "${REALLOCATED}" -gt 0 ]]; then
    echo "[WARN] Reallocated sectors: ${REALLOCATED}"
    echo "       Drive has permanently remapped bad sectors."
    echo "       Track this number across sessions — a growing count signals active failure."
fi

if [[ -n "${PENDING}" && "${PENDING}" -gt 0 ]]; then
    echo "[WARN] Pending sectors: ${PENDING}"
    echo "       These sectors may fail on next read."
    echo "       If count is growing across sessions: image with ddrescue before continuing."
fi

if [[ -n "${UDMA}" && "${UDMA}" -gt 0 ]]; then
    echo "[WARN] UDMA CRC errors: ${UDMA}"
    echo "       This indicates a cable/USB connection problem, not platter damage."
    echo "       Check USB cable, port, and passthrough configuration."
fi

echo ""

# --- dmesg: USB transport and I/O events ---
# sudo required on Ubuntu 24+ (kernel restricts dmesg to root by default
# to prevent leaking kernel addresses that could aid privilege escalation).
echo "--- Recent dmesg: USB + Block I/O Events ---"
echo "(Filtering for: usb reset, cmd_age, Buffer I/O, end_request, dm-)"
echo ""
dmesg | grep -iE "usb.*reset|cmd_age|buffer i/o error|end_request|dm-[0-9]" | tail -20 || \
    echo "  (No matching events in dmesg)"
echo ""

# --- Cascade severity heuristic ---
USB_RESETS=$(dmesg | grep -c "usb.*reset" 2>/dev/null || echo 0)
HUNG_CMDS=$(dmesg | grep -c "cmd_age" 2>/dev/null || echo 0)

if [[ "${USB_RESETS}" -ge 4 ]] || [[ "${HUNG_CMDS}" -ge 1 ]]; then
    echo "[WARN] Transport stress indicators:"
    echo "       USB resets: ${USB_RESETS}  |  Hung commands: ${HUNG_CMDS}"
    echo "       If a session ended abruptly, run ntfsfix before mounting."
fi

echo ""
echo "=== Health check complete. Review warnings before any bulk read operations. ==="
