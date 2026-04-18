## Drive Assessment

## Drive Identification and Access

The practicum involved two physical drives:

- **Drive 1 (2.73TB)**: Initially provided by the supervisor. Investigation revealed only a 16MB Microsoft Reserved Partition with no data partition. Forensic checks (blkid, xxd) showed no LUKS or BitLocker encryption signatures. TestDisk scan found no recoverable partitions. Supervisor confirmed this was not the intended drive.
- **Drive 2 (LUKS-encrypted)**: Provided as a replacement. Ubuntu VM auto-detected the LUKS encryption and prompted for the passphrase. Confirmed via sudo blkid /dev/sdb returning TYPE="crypto_LUKS". The decrypted volume was auto-mounted by the operating system.
## Drive Contents Overview
The decrypted drive contains three top-level items:

- A previously organized directory (353GB) — a prior attempt at sorting the data. Partially complete.
- A RAW directory (3.2TB) — the original unorganized data dump containing six subdirectories from multiple source devices.
- A transfer log file (176MB) — rsync log documenting how data was copied onto this drive.

**Total** : ~3.55TB. Project scope mentions ~8TB total, so this drive is approximately half.

## Data Origin Analysis
The rsync transfer log (dated March 2026) reveals:

- Data was copied from a portable drive using rsync
- Data origin: forensic data recovery (Level 2) — not exported from an organized system
- Data categories include: phone system recordings, system backups, recovered user files, web hosting data, and loose files

## Security Observations

- **Exposed credentials were identified** in a credentials directory. Flagged to the supervisor immediately. No further browsing performed.
- **PII identified** in phone recordings (phone numbers, extension numbers, timestamps) and personal phone data.
- **Plaintext credentials in project documentation** — flagged to supervisor as a security concern.
- Proposed three-tier data sensitivity classification (Critical, High, Standard) for the migration plan.

## Data Integrity Issues
During inventory, find commands generated hundreds of "Input/output error" messages. Errors concentrated in recovered voice verification directories and credential stores.
- **Root cause**: Forensic data recovery retrieved folder structures but could not recover file contents from damaged sectors.
- **Impact**: Some files in the directory listings cannot be read or moved. Hash verification will fail on unreadable files — these are logged and skipped.
