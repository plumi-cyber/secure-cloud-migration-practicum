# Secure Cloud Data Migration — Cybersecurity Practicum

## Project Overview
Planned and executed a secure migration of ~8TB of data from a retiring cloud system 
to a secure replacement for Autism Today Foundation. Designed a structured directory 
hierarchy with role-based access controls, implemented encryption, and verified file 
integrity across the full migration.

**Organization:** Autism Today Foundation  
**Role:** Cybersecurity Practicum Student  
**Duration:** April – [End Month] 2026  
**Supervised by:** Jonathan, Head of Cybersecurity Department

## Skills Demonstrated
- Linux file management and administration (rsync, find, chmod, chown, ACLs)
- Disk encryption with LUKS (cryptsetup)
- File integrity verification using SHA-256 hash manifests
- Cloud storage security and IAM access controls
- Directory hierarchy design with role-based permissions
- Bash scripting for automation
- Risk assessment and migration planning
- Technical documentation and reporting

## Tools & Technologies
- Ubuntu (WSL2)
- cryptsetup / LUKS
- rsync
- GnuPG (gpg)
- SHA-256 (sha256sum)
- Cloud platform: [TBD — update after first meeting]

## Project Phases
1. **Assessment & Discovery** — Evaluated current data organization, identified stakeholders and access requirements
2. **Planning** — Designed directory schema, permission matrix, and phased migration plan
3. **Security Controls** — Implemented encryption, access controls, and logging
4. **Migration Execution** — Transferred data in batches with integrity verification per batch
5. **Verification & Testing** — Compared hash manifests, tested access controls, and confirmed zero data loss

## Repository Structure
├── README.md              # Project overview (you are here)
├── docs/
│   ├── directory_schema.md    # Proposed directory structure
│   ├── permission_matrix.md   # Access control mapping
│   └── migration_plan.md      # Phased migration plan
├── scripts/
│   ├── set_permissions.sh     # Permission automation script
│   ├── migrate.sh             # rsync migration script
│   └── verify_integrity.sh    # Hash verification script
├── screenshots/               # Evidence of setup and verification
└── logs/
└── activity_log.md        # Daily work log with hours

## Key Outcomes
- [Update after project completion]
- [Example: Migrated X TB across Y files with zero data loss]
- [Example: Implemented role-based access for Z user groups]
- [Example: Verified integrity of all files via SHA-256 comparison]

## Certifications Aligned
This project directly applies skills from:
- CompTIA Security+ (SY0-701) — Domains 1, 3, 4, 5
- CompTIA Linux+ — File management, permissions, scripting
- TCM Security PSAA — Documentation and incident methodology
- ISC2 CC — Access controls, security operations

## Contact
**Oluwapelumi Kolawole**  
[LinkedIn](https://linkedin.com/in/oluwapelumi-kolawole) | pelumi.kola@gmail.com
