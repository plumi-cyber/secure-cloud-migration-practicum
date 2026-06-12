# Data Integrity Report

## I/O Errors Discovered

During Phase 1 inventory (April 17, 2026), filesystem commands generated hundreds of "Input/output error" messages indicating bad sectors or corrupted areas.

## Affected Areas

| Path                                      | Content Description                               | Status                                                                  |
| ----------------------------------------- | ------------------------------------------------- | ----------------------------------------------------------------------- |
| Recovered drive - Voice Verifications     | Date-stamped folders of recordings from 2013-2014 | Unreadable — folder structures recovered but file contents inaccessible |
| Credential stores - Browser backups       | Browser profile data (multiple users)             | Unreadable                                                              |
| Credential stores - Email client profiles | Email client data (multiple users)                | Unreadable                                                              |
| Credential stores - OS credential vaults  | Operating system credential data                  | Unreadable                                                              |
| Credential stores - Password files        | Historical password and financial documents       | Unreadable                                                              |

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

```
sudo find [mountpoint]/RAW/ -type f 2>~/io_errors.txt 1>/dev/null
```

The redirect strategy was deliberate:

- `2>~/io_errors.txt` — captured stderr (any I/O errors) to a writable home-directory file. Earlier attempts to write the error log to the drive itself had failed with permission-denied due to the NTFS mount going read-only after the MFT repair.
- `1>/dev/null` — discarded stdout (the filename list), since only error output was relevant.

Verification followed:

```
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

---

## SMART Drive Health Assessment (May 2026)

Formal SMART diagnostics were run using `smartmontools` after I/O errors were observed during file operations in mid-May. Four attributes were monitored across sessions:

| SMART Attribute          | Value at Assessment | Interpretation                                         |
| ------------------------ | ------------------- | ------------------------------------------------------ |
| Reallocated_Sector_Ct    | 0                   | No permanently remapped sectors                        |
| Current_Pending_Sector   | 55                  | 55 unstable sectors flagged for reallocation on read   |
| Offline_Uncorrectable    | 54                  | Sectors that failed offline self-test                  |
| UDMA_CRC_Error_Count     | 0                   | No cable or USB signal integrity errors                |

**Overall SMART status: PASSED** throughout all monitoring sessions.

The `UDMA_CRC_Error_Count` of 0 ruled out the USB cable and passthrough connection as contributing factors. The non-zero `Current_Pending_Sector` and `Offline_Uncorrectable` values, combined with the drive's low power-on hours (~1,677 hours at time of assessment), indicated multi-region physical damage consistent with past impact rather than age-related wear.

A short self-test triggered a failure at **10% completion** at LBA 874795072 (~417 GB mark), confirming that at least one damage region falls within the working data area of the drive.

### Monitoring Approach

`Current_Pending_Sector` was tracked across sessions to distinguish bounded damage from progressive failure. The count remained fixed (non-growing) across all subsequent checks, confirming that the damage is stable and not actively spreading.

Operations were scoped to avoid unnecessary reads on high-risk subtrees. The drive was not imaged with `ddrescue` at this stage; the supervisor was notified and indicated a full read-only image would be taken at project completion.

---

## Localized Damage Region — Financial Archive Subtree

During Phase 1 financial sorting (May 2026), a QuickBooks archive subtree returned **91 read errors** on direct access attempts. This was the highest concentration of read failures observed in any single directory during the project.

Two additional damaged subtrees were identified in the same entity folder during subsequent passes.

### Response

- All three subtrees added to the `find` prune list for all future operations
- Supervisor ruling received: recover directory metadata, CSV files, and business listings from affected paths; accept binary file contents as lost
- No bulk reads attempted against these subtrees after identification

### find Prune Idiom

Damaged paths must appear as the **leftmost** expression in the `find` predicate chain, grouped with `\( ... \)`:

```
find <root> \
    \( -path "*[damaged-entity-1]*" -o -path "*[damaged-entity-2]*" \) -prune -o \
    -type f -name "<target>" -print
```

Placing `-prune` after `-type` or `-name` predicates causes `find` to evaluate the type/name filter first, descend into matching directories including damaged ones, and only then apply the prune — by which point the read has already been attempted. This was the root cause of the transport cascade documented below.

---

## USB Transport Cascade (May 28, 2026)

A `find` command with a malformed prune predicate triggered a transport-layer cascade when it descended into a known damaged subtree.

### Cause

The `-prune` predicates were placed **after** `-type d -name "00002"` in the predicate chain. Because `find` applies predicates left-to-right with implicit AND, the prune condition only fired on items that were simultaneously a directory named "00002" **and** located under the damaged path — a condition nothing on the drive satisfied. The prune never engaged; `find` descended into the damaged subtree as though no prune had been written.

### Drive Response

| Event                              | Count | Detail                                             |
| ---------------------------------- | ----- | -------------------------------------------------- |
| USB SuperSpeed device resets       | 6     | `usb 2-1: reset SuperSpeed USB device`             |
| Hung read command                  | 1     | `cmd_age=215s`, ended in `DID_ABORT`               |
| Buffer I/O errors (LUKS layer)     | 8     | Logical blocks 7428486–7428495, device `dm-0`      |

The drive recovered without intervention. `ls` returned responsive within a few minutes of the final reset. SMART confirmed no new reallocated sectors following the event.

### Severity Assessment

This cascade was categorically more severe than a prior bounded 2-error event where the bus held and the drive fast-failed. Six resets plus a 215-second hung command represent sustained physical read retries against damaged sectors — the kernel retrying a failing read for over three minutes before aborting. The distinction matters for risk assessment: the earlier event was a fast-fail; this one was a sustained failure that visibly stressed the USB bus.

### Recovery Procedure

Standard recovery sequence executed after the event:

```
cd ~
sudo umount [mount_point]
sudo ntfsfix /dev/mapper/[luks-name]
sudo mount -t ntfs-3g /dev/mapper/[luks-name] [mount_point]
sudo dmesg | grep -iE "usb.*reset|cmd_age|buffer i/o|end_request"
```

Drive returned to clean state. Corrected `find` prune idiom documented and applied to all subsequent operations.

---

## Additional Damage Events (May–June 2026)

Isolated sector damage events were recorded across multiple working sessions during Phase 1 sorting. Each event followed the same pattern: `dmesg` reporting Buffer I/O errors on the LUKS device (`dm-0`) at specific LBA addresses, followed by ntfsfix and remount.

| Session Date | Trigger                       | Affected Sectors (LBA)          |
| ------------ | ----------------------------- | ------------------------------- |
| May 27, 2026 | File inventory walk (hv620s)  | 500519520                       |
| June 2, 2026 | File read during triage       | 564625760 (logical block 70574124) |
| June 8, 2026 | Directory walk (`du` sweep)   | 13469200, 13471256, 13488984, 13491040 |

The June 8 event was triggered by a `du` sweep of directory metadata — establishing that directory-level walks carry a risk of damage on this drive, not only file-content reads. The sweep was terminated after the first error. Four distinct sectors were affected before the kill signal reached the process.

All events were recovered using the standard ntfsfix sequence. SMART `Current_Pending_Sector` count remained stable across all events, confirming the damage pool is bounded and not growing.

### Operational Rule Established

Based on the cumulative damage event pattern, the following distinction was formalized:

- **`mv` operations on already-characterized files:** empirically safe — eleven consecutive moves completed with zero new `dmesg` events during a session with active kernel retries on a nearby damaged sector.
- **Inspection-heavy operations (`cat`, `strings`, `find` walks, `du` sweeps, document viewers):** carry damage-region risk. Scope narrowly and monitor `dmesg` after each operation.

---

## Cumulative Integrity Status

| Finding                           | Status     | Notes                                                   |
| --------------------------------- | ---------- | ------------------------------------------------------- |
| Phase 1 I/O errors (April)        | Documented | Affected areas mapped; file contents accepted as lost   |
| NTFS MFT mismatch (April 17)      | Resolved   | ntfsfix repair verified across 1,668,912 files          |
| SMART pending sectors (55)        | Monitoring | Fixed pool; no growth observed across sessions          |
| Financial subtree — 91 read errors | Quarantined | Pruned from all operations; supervisor ruling applied   |
| Transport cascade (May 28)        | Resolved   | Drive recovered; corrected find idiom documented        |
| Isolated sector events (May–June) | Resolved   | Each recovered via standard ntfsfix sequence            |
| New I/O errors — user data dirs   | Documented | Specific files in two large directories unreadable      |

**Overall drive health: SMART PASSED throughout the project. Damage is physical and bounded — not progressive filesystem failure.**data accessibility**, not **data integrity**. The OS can locate every file. Whether file contents are intact or have been corrupted will only be confirmed during data movement and hashing operations (sha256sum). Any silent data corruption would surface there, not here.
