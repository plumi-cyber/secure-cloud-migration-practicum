#!/usr/bin/env bash
# =============================================================================
# risk_assessment.sh — Security risk triage for legacy data migration audits
# =============================================================================
# Project: Secure Cloud Migration Practicum
#
# Purpose:
#   Parse an audit flag log produced during manual data migration triage,
#   classify open findings by severity, and generate a structured risk report.
#   Mirrors the SOC L1 triage loop: ingest event source, classify, escalate,
#   document.
#
# Context — findings surfaced during this practicum (sanitized):
#   The following security events were discovered during triage of a 3.6TB
#   multi-entity legacy archive and escalated to the authorized supervisor:
#
#   [CRITICAL] Possible live payment processor credential found in an
#              unsorted user data directory (file: backup codes for a payment
#              API). Escalated immediately; supervisor confirmed live and
#              initiated credential rotation.
#
#   [HIGH]     Application control bypass URL and 7 unsigned executables
#              found in a Windows workstation backup directory. Executables
#              deleted post-supervisor approval. Bypass URL documented.
#
#   [HIGH]     19-subfolder PII archive (multi-machine salvage data) identified
#              requiring per-file review before routing. Blocked from bulk
#              operations pending disposition decisions.
#
#   [MEDIUM]   NTFS MFT mismatch (filesystem corruption) on the production
#              archive. Repaired with ntfsfix; full 1,668,912-file walk
#              confirmed zero residual I/O errors post-repair.
#
#   [MEDIUM]   55 pending sectors on the production drive (Current_Pending_Sector).
#              Monitored across sessions; pool remained fixed (non-growing),
#              indicating bounded damage rather than active failure.
#
#   [LOW]      VirtualBox USB passthrough causing unclean dismounts on session
#              end. Recurring NTFS dirty flag events documented; flagged to
#              supervisor as configuration concern.
#
# Audit log format (SORTING_FLAGS.txt):
#   [YYYY-MM-DD] LOCATION | description | action taken | STATUS: OPEN / RESOLVED
#
# Output:
#   Terminal summary + Markdown risk report
#
# Usage:
#   bash risk_assessment.sh <sorting_flags_file> [output_report.md]
#   Example: bash risk_assessment.sh SORTING_FLAGS.txt risk_report_$(date +%Y%m%d).md
#
# SOC L1 relevance:
#   Severity model maps to NIST SP 800-30 risk categories and MITRE ATT&CK:
#     CRITICAL — Credential / token exposure (T1552 — Unsecured Credentials)
#     HIGH     — Executable in unexpected location (T1204), bypass technique,
#                unprotected PII (data classification failure)
#     MEDIUM   — Data integrity event, access control gap (filesystem level)
#     LOW      — Infrastructure misconfiguration, operational hygiene
# =============================================================================

set -euo pipefail

FLAGS_FILE="${1:?Usage: $0 <sorting_flags_file> [output_report.md]}"
OUTPUT="${2:-risk_report_$(date +%Y%m%d_%H%M).md}"

if [[ ! -f "${FLAGS_FILE}" ]]; then
    echo "[ERROR] Audit flags file not found: ${FLAGS_FILE}" >&2
    exit 1
fi

TIMESTAMP=$(date -Iseconds)

# --- Severity classification ---
# Input: one line of text from SORTING_FLAGS.txt
# Output: CRITICAL / HIGH / MEDIUM / LOW / INFO
classify_severity() {
    local line="$1"

    # CRITICAL: credentials, auth tokens, payment data, secrets
    if echo "${line}" | grep -qiE \
        "credential|password|stripe|payment|token|api.?key|secret|backup.?code|auth|private.?key"; then
        echo "CRITICAL"

    # HIGH: executables, bypass techniques, PII, unvetted code
    elif echo "${line}" | grep -qiE \
        "\.exe|executable|applocker|bypass|pii|personal.*data|unvetted|unsigned.*exec|malware|suspicious.*file"; then
        echo "HIGH"

    # MEDIUM: data integrity, corruption, access control, damage
    elif echo "${line}" | grep -qiE \
        "corrupt|mft|mismatch|damaged|read.?error|access.*control|integrity|sector|ntfsfix|i\/o error|unclean"; then
        echo "MEDIUM"

    # LOW: infrastructure, configuration, operational issues
    elif echo "${line}" | grep -qiE \
        "usb|passthrough|config|vm|virtualbox|dirty.?flag|passthrough|dismount|infrastructure"; then
        echo "LOW"

    else
        echo "INFO"
    fi
}

# --- Parse flags file ---
declare -a CRITICAL_OPEN HIGH_OPEN MEDIUM_OPEN LOW_OPEN INFO_OPEN
declare -a CRITICAL_RES HIGH_RES MEDIUM_RES LOW_RES

TOTAL=0
OPEN=0
RESOLVED=0

while IFS= read -r line; do
    [[ -z "${line}" ]] && continue
    [[ "${line}" =~ ^# ]] && continue
    [[ "${line}" =~ ^\[.*\] ]] || continue   # Must start with a date bracket

    TOTAL=$((TOTAL + 1))
    SEVERITY=$(classify_severity "${line}")

    if echo "${line}" | grep -qiE "STATUS.*RESOLVED|RESOLVED\s*$|\|\s*RESOLVED"; then
        RESOLVED=$((RESOLVED + 1))
        case "${SEVERITY}" in
            CRITICAL) CRITICAL_RES+=("${line}") ;;
            HIGH)     HIGH_RES+=("${line}") ;;
            MEDIUM)   MEDIUM_RES+=("${line}") ;;
            LOW)      LOW_RES+=("${line}") ;;
        esac
    else
        # Treat as OPEN if STATUS says OPEN or if status is ambiguous
        OPEN=$((OPEN + 1))
        case "${SEVERITY}" in
            CRITICAL) CRITICAL_OPEN+=("${line}") ;;
            HIGH)     HIGH_OPEN+=("${line}") ;;
            MEDIUM)   MEDIUM_OPEN+=("${line}") ;;
            LOW)      LOW_OPEN+=("${line}") ;;
            *)        INFO_OPEN+=("${line}") ;;
        esac
    fi

done < "${FLAGS_FILE}"

# --- Determine overall risk level ---
get_risk_level() {
    if [[ ${#CRITICAL_OPEN[@]} -gt 0 ]]; then
        echo "CRITICAL"
    elif [[ ${#HIGH_OPEN[@]} -gt 0 ]]; then
        echo "HIGH"
    elif [[ ${#MEDIUM_OPEN[@]} -gt 0 ]]; then
        echo "MEDIUM"
    elif [[ ${#LOW_OPEN[@]} -gt 0 ]]; then
        echo "LOW"
    else
        echo "CLEAR"
    fi
}

RISK_LEVEL=$(get_risk_level)

# --- Generate Markdown report ---
{
cat <<HEADER
# Risk Assessment Report
**Generated:** ${TIMESTAMP}
**Source file:** \`$(basename "${FLAGS_FILE}")\`
**Analyst:** Practicum lead (role-based)

---

## Executive Summary

| Metric | Value |
|--------|-------|
| Total audit flags | ${TOTAL} |
| Open findings | ${OPEN} |
| Resolved findings | ${RESOLVED} |
| Critical (open) | ${#CRITICAL_OPEN[@]} |
| High (open) | ${#HIGH_OPEN[@]} |
| Medium (open) | ${#MEDIUM_OPEN[@]} |
| Low (open) | ${#LOW_OPEN[@]} |

HEADER

case "${RISK_LEVEL}" in
    CRITICAL) echo "**Overall Risk Level: 🔴 CRITICAL — Immediate escalation required before any further operations.**" ;;
    HIGH)     echo "**Overall Risk Level: 🟠 HIGH — Escalate to supervisor and resolve before proceeding.**" ;;
    MEDIUM)   echo "**Overall Risk Level: 🟡 MEDIUM — Review and address before next session.**" ;;
    LOW)      echo "**Overall Risk Level: 🔵 LOW — Monitor; no immediate action required.**" ;;
    CLEAR)    echo "**Overall Risk Level: 🟢 CLEAR — All findings resolved.**" ;;
esac

echo ""
echo "---"
echo ""

# Helper function: print a section of flags
print_section() {
    local heading="$1"
    shift
    local -n _flags=$1
    if [[ ${#_flags[@]} -gt 0 ]]; then
        echo "## ${heading}"
        echo ""
        for entry in "${_flags[@]}"; do
            echo "- ${entry}"
        done
        echo ""
    fi
}

print_section "🔴 Critical — Open" CRITICAL_OPEN
print_section "🟠 High — Open" HIGH_OPEN
print_section "🟡 Medium — Open" MEDIUM_OPEN
print_section "🔵 Low — Open" LOW_OPEN
print_section "ℹ️ Info — Open" INFO_OPEN

echo "---"
echo ""
echo "## Resolved Findings (for reference)"
echo ""
print_section "✅ Critical — Resolved" CRITICAL_RES
print_section "✅ High — Resolved" HIGH_RES
print_section "✅ Medium — Resolved" MEDIUM_RES
print_section "✅ Low — Resolved" LOW_RES

cat <<METHODOLOGY

---

## Methodology

Flags parsed from a manual sorting audit log maintained throughout the migration.
Format: \`[YYYY-MM-DD] LOCATION | description | action taken | STATUS\`

Severity classification follows NIST SP 800-30 and maps to MITRE ATT&CK:

| Severity | Classification Criteria | ATT&CK Reference |
|----------|------------------------|-----------------|
| CRITICAL | Exposed credentials, auth tokens, payment data | T1552 (Unsecured Credentials) |
| HIGH | Executables in data directories, bypass techniques, unprotected PII | T1204 (User Execution), data classification failure |
| MEDIUM | Data integrity events, filesystem corruption, access control gaps | Impact: Data Manipulation |
| LOW | Infrastructure misconfig, operational hygiene gaps | Defense Evasion: T1562 (partial) |

All findings were escalated to the authorized disposition officer per project SOP.
No destructive operations were performed without explicit written approval.

METHODOLOGY

} > "${OUTPUT}"

# --- Terminal summary ---
echo ""
echo "=== Risk Assessment Complete ==="
echo "Flags total: ${TOTAL}  |  Open: ${OPEN}  |  Resolved: ${RESOLVED}"
echo ""

[[ ${#CRITICAL_OPEN[@]} -gt 0 ]] && echo "  🔴 CRITICAL (open): ${#CRITICAL_OPEN[@]}"
[[ ${#HIGH_OPEN[@]} -gt 0 ]]     && echo "  🟠 HIGH (open):     ${#HIGH_OPEN[@]}"
[[ ${#MEDIUM_OPEN[@]} -gt 0 ]]   && echo "  🟡 MEDIUM (open):   ${#MEDIUM_OPEN[@]}"
[[ ${#LOW_OPEN[@]} -gt 0 ]]      && echo "  🔵 LOW (open):      ${#LOW_OPEN[@]}"

echo ""
echo "Overall risk level: ${RISK_LEVEL}"
echo "Full report written: ${OUTPUT}"
