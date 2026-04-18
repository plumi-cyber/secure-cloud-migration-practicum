# Data Integrity Report

## I/O Errors Discovered

During Phase 1 inventory (April 17, 2026), filesystem commands generated hundreds of "Input/output error" messages indicating bad sectors or corrupted areas.

## Affected Areas

| Path | Content Description | Status |
|------|-------------------|--------|
| Recovered drive - Voice Verifications | Date-stamped folders of recordings from 2013-2014 | Unreadable — folder structures recovered but file contents inaccessible |
| Credential stores - Browser backups | Browser profile data (multiple users) | Unreadable |
| Credential stores - Email client profiles | Email client data (multiple users) | Unreadable |
| Credential stores - OS credential vaults | Operating system credential data | Unreadable |
| Credential stores - Password files | Historical password and financial documents | Unreadable |

## Root Cause

Data on this drive was recovered using forensic data recovery tools (Level 2). The recovery process retrieved folder structures and metadata, but actual file contents on damaged sectors could not be recovered.

## Impact on Project

- Files appearing in directory listings may not be readable or movable
- File count and size inventories may be inaccurate for affected directories
- Hash verification (sha256sum) will fail on unreadable files — logged and skipped
- Error suppression (`2>/dev/null`) used in subsequent commands, with errors captured separately (`2>error_log.txt`) for documentation

## NTFS Filesystem Corruption

During a session on April 17, the drive disconnected from the VM mid-operation. On remount, the NTFS Master File Table mirror was inconsistent. Resolved using `ntfsfix` which corrected the MFT mirror mismatch. Prevention measures implemented: disabled USB selective suspend in Windows power settings, laptop sleep set to "Never" during operations.
