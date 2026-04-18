# Data Inventory Report

Completed April 17, 2026. Commands used: `du -sh` for sizes and `find` piped through `sed`, `sort`, `uniq -c`, `sort -rn` for file type counts.

## RAW Folder Inventory

| Folder | Size | Top File Types | Assessment |
|--------|------|---------------|------------|
| Web hosting data | 34G | txt (9210), mp3 (8315), php (7228), jpg (5430), png (4592), svg (2720), js (2389), pdf (1508), css (1380), html (1119) | Web assets — php, html, css, js. Target: entity-specific Media/Web_assets/ |
| Recovered drive A | 1.1TB | wmf (129055), cdr (105098), jpg (69005), pdf (56523), mp3 (28841), eps (23991), doc (23098), gif (21530), html (20688), TTF (16817) | Design files (CorelDRAW), documents, fonts, audio. Contains I/O errors in voice verification directories. |
| Recovered drive B | 1.5TB | wmf (128857), cdr (124437), jpg (123928), pdf (107171), txt (68553), mp3 (41789), eps (29087), doc (24855), TTF (16771), html (12760) | Nearly identical profile to Drive A — likely overlapping data. Needs deduplication assessment. |
| Phone backup | 278M | MOV (37), JPG (36), AAE (1) | 74 files total. Personal photos and videos. Target: Personal_DOCS/ |
| Creative workstation | 614G | jpg (345), par (34), DS_Store (27), M2V (23), ppt (21), fcp (21), mov (18), psd (16), aiff (16), mpg (15) | macOS origin. Final Cut Pro, Photoshop, video production. Target: needs entity clarification. |
| Credential stores | 4.1G | final (550), sqlite (247), png (241), js (240), json (149), svg (116), dll (77), txt (68), qm (67), metadata-v2 (67) | Browser data and credentials. Most contents unreadable due to I/O errors. Awaiting supervisor guidance. |

## Previously Organized Folder Inventory

| Folder | Size | Top File Types | Assessment |
|--------|------|---------------|------------|
| Autism | 2.9G | msg (1236), doc (402), ppt (98), jpg (71), pdf (69), xls (51), JPG (16), tif (11), docx (11), htm (7) | Outlook emails dominant. Target: Autism_Today/ |
| Financial | 194G | pdf (13213), doc (8936), bmp (994), tif (744), log (688), cfx (448), cdr (425), jpg (391), cfs (326), qbc (312) | Largest folder. Contains QuickBooks databases (cfx, cfs, qbc). Must keep database groups intact. |
| Legal | 1.5G | pdf (1188), doc (1037), docx (649), jpg (88), xlsx (61), db (23), lnk (9), PDF (7), xls (6), LNK (6) | Standard legal documents. Target: distribute to entity-specific Legal/ folders. |
| Media | 68G | pdf (18200), doc (7742), cdr (6553), jpg (4990), docx (3465), JPG (2708), lwp (2652), txt (2161), eps (1855), xls (1828) | Mixed documents and design files. Contains legacy Lotus Word Pro (lwp) files. |
| Mediation | 0 | (empty) | Never populated in first pass. |
| Personal Documents | 80G | JPG (4664), jpg (1965), pdf (524), docx (393), MOV (343), download (224), mov (126), css (81), zip (80), html (75) | Photos and videos. Target: Personal_DOCS/ |
| Call Center Business | 6.6G | jpg (1605), pdf (735), doc (640), JPG (583), xls (257), png (204), docx (64), MDI (45), dll (44), xlsx (41) | Business documents and scanned files (MDI). Target: entity-specific subfolders. |

## Key Observations

1. Two recovered drives (1.1TB + 1.5TB) have nearly identical file profiles — likely duplicate data. Deduplication could save significant space.
2. Creative workstation (614G) needs entity attribution before sorting.
3. Financial folder contains accounting databases — must be kept intact.
4. Media folder contains legacy file formats requiring flagging.
5. Phone backup is trivial (74 files) — can be moved immediately.
6. Mediation folder was never populated — data may be scattered elsewhere.
