
# Activity Log

| Date | Task | Commands/Actions | Outcome | Hours |
|------|------|-----------------|---------|-------|
| Apr 3, 2026 | First meeting with Jonathan and project partner | Discussed project scope, deliverables, timeline | Defined project: migrate ~8TB data, design directory hierarchy, implement encryption, verify integrity. Received Seagate GoFlex Desk 2.73TB drive. Format: fully remote, self-paced, weekly/bi-weekly check-ins. 100+ hours required. | 1.5 |
| Apr 3, 2026 | Environment setup — WSL2 | `sudo apt update && sudo apt upgrade`, installed `cryptsetup`, `lvm2`, `rsync`, `tree`, `htop`, `openssh-server`, `gnupg`, `acl`, `parted`, `fdisk`, `util-linux`. Installed AnyDesk on Windows. | All packages installed and versions verified. AnyDesk ready for remote access. | 1.0 |
| Apr 3, 2026 | First drive access attempt | `cryptsetup open /dev/sdb enc`, `sudo blkid /dev/sdb1`, `sudo parted /dev/sdb print` | LUKS open failed ("not a valid LUKS device"). Drive shows GPT table, single 16.8MB Microsoft Reserved Partition, ~2,999GB unallocated. Decision: do NOT write/format/modify the drive. | 1.0 |
| Apr 4, 2026 | Discovered WSL2 dm-crypt limitation | `sudo modprobe dm-crypt` (failed in WSL2) | WSL2 kernel lacks dm-crypt module. LUKS operations impossible in WSL2. Documented as Challenge #1. | 0.5 |
| Apr 4, 2026 | VirtualBox setup for LUKS operations | `sudo modprobe dm-crypt`, `lsmod | grep dm_crypt` in VM. Installed VirtualBox Extension Pack. Enabled USB 3.0 (xHCI) controller. Passed drive through via Devices → USB. | dm-crypt works in VM. Drive detected as `/dev/sdb`. Key decision: WSL2 for daily work, VirtualBox only for LUKS (8GB RAM constraint). | 2.0 |
| Apr 4, 2026 | Noted LVM warning in WSL2 | `lvm` commands in WSL2 | "Failure to communicate with kernel device-mapper driver." Expected — WSL2 lacks full device-mapper. Documented as Challenge #2. | 0.25 |
| Apr 4, 2026 | Ordered test drive and prepared meeting questions | Ordered Seagate ST500LM021 500GB from Amazon. Drafted five questions for Jonathan. | Test drive for safe LUKS practice (not Jonathan's drive). Questions: cloud platform, directory structure, access roles, deadline, backup status. | 0.5 |
| Apr 7–9, 2026 | Communicated hardware delay to Jonathan | Emailed Jonathan about test drive shipping delay | Proactive communication rather than surprising at meeting. Documented as Challenge #4. | 0.25 |
| Apr 7–9, 2026 | Created portfolio template | Built 14-page Word doc with sections: Executive Summary through Appendices | Template ready for progressive documentation as project advances. | 2.0 |
| Apr 7–9, 2026 | Designed GitHub repository structure | Created `secure-cloud-migration-practicum` repo with `README.md`, `docs/`, `scripts/`, `screenshots/`, `logs/activity_log.md` | Placeholder files in place. Rule set: no real data, credentials, or org-sensitive info on GitHub. | 1.0 |
| Apr 9, 2026 | Received Jonathan's response on drive issue | WhatsApp messages from Jonathan | Jonathan says whole disk is encrypted, try `/dev/sdb` not `/dev/sdb1`. But initial `cryptsetup open /dev/sdb` had already failed. | 0.25 |
| Apr 11, 2026 | VirtualBox USB passthrough for drive investigation | Devices → USB menu. Identified two Seagate entries (drive + docking bridge). Passed through bridge device. | Initial attach failed — resolved by ejecting drive from Windows first to release handle. Drive detected as `/dev/sdb`. | 0.5 |
| Apr 11, 2026 | Forensic check for encryption | `sudo blkid /dev/sdb`, `sudo xxd /dev/sdb | head -5` | GPT partition table confirmed. No LUKS magic bytes, no BitLocker `-FVE-FS-` signature. Drive shows no evidence of encryption. | 0.5 |
| Apr 11, 2026 | TestDisk scan for lost partitions | `sudo apt install testdisk -y`, `sudo testdisk /dev/sdb` → No Log → EFI GPT → Analyse → Quick Search | Scan in progress. All operations read-only. Expected 30+ min due to 2.7TB over USB. | ongoing |
| | | | **Running Total:** | **~11.25** |
