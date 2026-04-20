# Secure Cloud Migration Practicum

A cybersecurity practicum project focused on organizing and securely migrating ~8TB of poorly structured data from legacy storage to a secure replacement system. Completed as part of a cybersecurity diploma at Alberta Education Center.

## Project Overview

A nonprofit organization needs to consolidate data from multiple legacy drives into a structured, secure storage system. The data originated from forensic recovery operations and included files from multiple source devices, business entities, and personal backups — all in an unorganized state.

**Scope:** Assess source data, design a directory taxonomy, organize ~3.55TB across multiple business entities, verify file integrity, and prepare for migration to the destination storage platform.

## Skills & Tools

- **Linux administration:** Ubuntu (WSL2 + VirtualBox VM), bash scripting, mount operations, user permissions
- **Encryption:** LUKS (cryptsetup), dm-crypt kernel module, encrypted volume management
- **Data assessment:** disk forensics (blkid, xxd, TestDisk), file type analysis (find, sed, sort, uniq), disk usage analysis (du)
- **File operations:** rsync, mv, find, tree, directory structure design
- **Integrity verification:** sha256sum hash manifests, diff comparison
- **Filesystem repair:** ntfsfix (NTFS MFT recovery)
- **Virtualization:** VirtualBox USB passthrough, VM resource management on constrained hardware (8GB RAM)
- **Security practices:** PII identification, credential exposure detection, data sensitivity classification, read-only mounting
- **Documentation:** activity logging, challenge tracking, inventory reporting

## Repository Structure

```
secure-cloud-migration-practicum/
├── README.md
├── docs/
│   ├── directory_schema.md        — Finalized folder hierarchy
│   ├── drive_assessment.md        — Drive identification and access findings
│   ├── data_inventory.md          — Full inventory results with file type analysis
│   ├── data_integrity_report.md   — I/O errors and filesystem corruption findings
│   ├── source_target_mapping.md   — Source-to-target sorting plan
│   ├── migration_plan.md          — Organization workflow and methodology
│   └── permission_matrix.md       — Access controls (TBD)
├── scripts/
│   ├── set_permissions.sh         — Permission automation (TBD)
│   ├── migrate.sh                 — Migration automation (TBD)
│   └── verify_integrity.sh        — Hash verification automation (TBD)
├── screenshots/
└── logs/
    └── activity_log.md            — Detailed activity log with commands and outcomes
```

## Methodology

1. **Environment Setup** — Configured dual Linux environments (WSL2 for daily work, VirtualBox VM for encryption operations) to work within 8GB RAM constraints.
2. **Assessment & Discovery** — Identified encryption type, accessed source drive, mapped contents, and flagged security concerns (exposed credentials, PII in call recordings).
3. **Directory Design** — Analyzed source data, proposed a taxonomy based on business entities, and iterated with the supervisor to finalize the structure.
4. **Inventory** — Ran automated inventory scripts to catalog folder sizes, file types per directory, and data integrity issues across ~3.55TB.
5. **Organization** — Sorting data into the finalized structure, deduplicating overlapping datasets, and verifying integrity with hash manifests. *(In progress)*
6. **Verification** — File count and hash comparison to confirm no data loss. *(Upcoming)*

## Key Challenges Solved

- WSL2 kernel lacks dm-crypt — pivoted to VirtualBox for encryption operations
- USB passthrough failures — resolved via Windows Device Manager device release
- NTFS filesystem corruption after USB disconnect — repaired with ntfsfix
- Exposed credentials in source data — escalated immediately, proposed sensitivity classification
- I/O errors from forensic recovery — documented affected directories, implemented error suppression and logging

## Current Status

- [x] Environment setup (WSL2 + VirtualBox)
- [x] Drive access and encryption identification
- [x] Full data inventory completed
- [x] Directory structure finalized and created on drive
- [x] Source-to-target mapping defined
- [ ] Deduplication of overlapping datasets
- [ ] File organization and sorting
- [ ] Integrity verification
- [ ] Migration to destination storage

## Note

All data, credentials, file paths, and personally identifiable information have been sanitized in this repository. No real organizational data is stored here — this repo contains documentation and scripts only.
