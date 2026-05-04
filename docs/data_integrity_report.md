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

During a session on April 17, the drive disconnected from the VM mid-operation. On remount, the NTFS Master File Table mirror was inconsistent. Resolved using `ntfsfix`, which corrected the MFT mirror mismatch. Prevention measures implemented: disabled USB selective suspend in Windows power settings, laptop sleep set to "Never" during operations.

## Drive-Wide Verification After ntfsfix Repair (May 1, 2026)

Following the April 17 MFT repair via `ntfsfix`, the durability of the fix needed independent verification before any large-scale data movement could be committed.

### Method

Recursive `find` across the entire RAW directory:

```bash
sudo find [mountpoint]/RAW/ -type f 2>~/io_errors.txt 1>/dev/null
```

The redirect strategy was deliberate:

- `2>~/io_errors.txt` — captured stderr (any I/O errors) to a writable home-directory file. Earlier attempts to write the error log to the drive itself had failed with permission-denied due to the NTFS mount going read-only after the MFT repair.
- `1>/dev/null` — discarded stdout (the filename list), since only error output was relevant.

Verification followed:

```bash
wc -l ~/io_errors.txt
sudo find [mountpoint]/RAW/ -type f | wc -l
```

### Result

- Files walked: **1,668,912**
- I/O errors logged: **0**

The `io_errors.txt` file was zero bytes.

### Significance

The MFT repair was confirmed filesystem-wide. The earlier corruption affected metadata across the NTFS volume, and a localized fix would not have been sufficient evidence. The full-drive walk established that file access at the operating system level is reliable across the entire 3.6TB working copy.

This eliminated the need for a separate error log deliverable to the supervisor — there were no errors to report.

### Caveat

This verification confirms **metadata accessibility**, not **data integrity**. The OS can locate every file. Whether file contents are intact or have been corrupted will only be confirmed during data movement and hashing operations (sha256sum). Any silent data corruption would surface there, not here.
