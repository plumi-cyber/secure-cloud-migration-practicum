#!/usr/bin/env bash
# =============================================================================
# dedup_scan.sh — Size-first, MD5-confirmed duplicate detection
# =============================================================================
# Project: Secure Cloud Migration Practicum
#
# Background:
#   Used to resolve a deduplication question across four live copies of
#   QuickBooks company files spanning multiple source locations. The approach
#   was driven by a constraint: the drive had multi-region platter damage, so
#   minimizing unnecessary reads was a safety requirement, not just efficiency.
#
# Algorithm:
#   1. Index all files by byte size (metadata read only — no data I/O)
#   2. Identify sizes shared by 2+ files (collision candidates)
#   3. MD5-hash only the collision candidates
#   4. Report files sharing an identical MD5 hash
#
# Key asymmetry:
#   Size MISMATCH = guaranteed not identical (free proof, no hashing needed)
#   Size MATCH    = possible duplicate — requires MD5 to confirm
#
#   This matters for QuickBooks files: identical file sizes occur routinely
#   across unrelated QBB backups. Size alone is not a reliable signal.
#
# Safety:
#   This script reports only. It never deletes, moves, or modifies any file.
#   Review output and obtain supervisor approval before any removal.
#
# Usage:
#   bash dedup_scan.sh <search_path> [min_size_bytes]
#   Example: bash dedup_scan.sh /mnt/drive/FINANCIAL 1048576
#
# Flags reference (Linux+):
#   find -printf '%s\t%p\n' — print size in bytes, tab, then full path
#   sort -k1,1n             — sort numerically on first field (size)
#   awk '{print $1}'        — extract size column
#   uniq -d                 — print only lines that appear more than once
#   md5sum                  — compute MD5 hash of file contents
# =============================================================================

set -euo pipefail

SEARCH_PATH="${1:?Usage: $0 <search_path> [min_size_bytes]}"
MIN_SIZE="${2:-0}"    # Default: include all file sizes

if [[ ! -d "${SEARCH_PATH}" ]]; then
    echo "[ERROR] Directory not found: ${SEARCH_PATH}" >&2
    exit 1
fi

WORK_DIR=$(mktemp -d)
trap 'rm -rf "${WORK_DIR}"' EXIT

SIZE_INDEX="${WORK_DIR}/sizes.txt"
COLLISION_SIZES="${WORK_DIR}/collisions.txt"
HASH_RESULTS="${WORK_DIR}/hashes.txt"

echo "=== Deduplication Scan ==="
echo "Path:     ${SEARCH_PATH}"
echo "Min size: ${MIN_SIZE} bytes"
echo "Start:    $(date -Iseconds)"
echo ""

# --- Phase 1: Build size index (metadata only) ---
echo "[Phase 1/4] Indexing file sizes..."
# find -printf avoids stat() calls per file — single-pass metadata read.
# +Xc means "greater than X bytes" in find's -size syntax (c = bytes).
find "${SEARCH_PATH}" -type f -size "+${MIN_SIZE}c" \
    -printf '%s\t%p\n' > "${SIZE_INDEX}" 2>/dev/null || true

FILE_COUNT=$(wc -l < "${SIZE_INDEX}")
echo "  Files indexed: ${FILE_COUNT}"

if [[ "${FILE_COUNT}" -eq 0 ]]; then
    echo "[OK] No files found matching criteria."
    exit 0
fi

# --- Phase 2: Find size collisions ---
echo "[Phase 2/4] Identifying size collisions..."
awk '{print $1}' "${SIZE_INDEX}" | sort -n | uniq -d > "${COLLISION_SIZES}"
COLLISION_COUNT=$(wc -l < "${COLLISION_SIZES}")
echo "  Distinct sizes with 2+ files: ${COLLISION_COUNT}"

if [[ "${COLLISION_COUNT}" -eq 0 ]]; then
    echo "[OK] No size collisions. No duplicates possible."
    exit 0
fi

# Count total candidate files
CANDIDATE_COUNT=0
while IFS= read -r size; do
    count=$(grep -c "^${size}	" "${SIZE_INDEX}" || true)
    CANDIDATE_COUNT=$((CANDIDATE_COUNT + count))
done < "${COLLISION_SIZES}"
echo "  Candidate files to hash: ${CANDIDATE_COUNT}"

# --- Phase 3: MD5 hash candidates only ---
echo "[Phase 3/4] Hashing collision candidates..."
while IFS= read -r size; do
    while IFS= read -r filepath; do
        if [[ -f "${filepath}" ]]; then
            md5sum "${filepath}" 2>/dev/null || echo "READ_ERROR  ${filepath}"
        fi
    done < <(grep "^${size}	" "${SIZE_INDEX}" | cut -f2-)
done < "${COLLISION_SIZES}" > "${HASH_RESULTS}"
echo "  Hashing complete."

# --- Phase 4: Report confirmed duplicates ---
echo "[Phase 4/4] Identifying byte-identical files..."
echo ""

DUPE_GROUPS=0
while IFS= read -r hash; do
    FILE_LIST=$(grep "^${hash}  " "${HASH_RESULTS}" | awk '{print $2}')
    FILE_COUNT_IN_GROUP=$(echo "${FILE_LIST}" | wc -l)
    if [[ "${FILE_COUNT_IN_GROUP}" -gt 1 ]]; then
        DUPE_GROUPS=$((DUPE_GROUPS + 1))
        echo "--- Duplicate group ${DUPE_GROUPS} (MD5: ${hash}) ---"
        echo "${FILE_LIST}" | while IFS= read -r f; do
            SIZE=$(stat -c '%s' "${f}" 2>/dev/null || echo "?")
            echo "  [${SIZE} bytes]  ${f}"
        done
        echo ""
    fi
done < <(awk '{print $1}' "${HASH_RESULTS}" | grep -v "READ_ERROR" | sort | uniq -d)

if [[ "${DUPE_GROUPS}" -eq 0 ]]; then
    echo "[OK] No byte-identical files found despite size collisions."
    echo "     (Size matches alone do not confirm duplication — MD5 is required.)"
else
    echo "=== SUMMARY: ${DUPE_GROUPS} duplicate group(s) found. ==="
    echo "    Review with supervisor before deleting any files."
    echo "    For QuickBooks: always keep the largest (most recent) version as canonical."
    echo "    Move archived copies to a dated subfolder — do not delete until confirmed."
fi

echo ""
echo "=== Scan complete. No files were modified. ==="
echo "Ended: $(date -Iseconds)"
