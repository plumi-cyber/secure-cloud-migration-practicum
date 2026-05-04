# Sorting Decisions Log

This document records the audit log methodology used during the project's file reorganization phase. The actual log file (`SORTING_FLAGS.txt`) is located at the drive root and is not committed to this repository because it contains entity-specific paths and references to supervisor correspondence.

## Purpose

Capture every sorting decision that requires:
- Supervisor escalation
- Future review or cleanup
- Authorization before inspection
- Documented justification for filing destination

## Format
[YYYY-MM-DD] [LOCATION] | description | action taken | status
## Status values

| Status | Meaning |
|--------|---------|
| `OPEN` | Issue identified, decision pending |
| `OPEN — BLOCKER` | Issue prevents further work in that area; awaiting supervisor input |
| `RESOLVED [date]` | Conditions on the drive have been corrected; flag retained for traceability |

## When to log

- File or folder contents include PII for individuals not associated with known data owners
- Folder labels reference litigation, legal proceedings, or other privileged material
- Two or more folders exist that may be duplicates (case differences, naming variants)
- A sorting decision requires a judgment call beyond explicit supervisor instructions
- A folder is moved without contents being inspected (record what was decided based on labels alone)

## When to close a flag

A flag closes when the **condition on the drive** is corrected, not when the decision is made about it. Examples:

- Empty duplicate folder identified → flag stays OPEN until the duplicate is actually deleted.
- File flagged for supervisor review → flag stays OPEN until supervisor confirms or reassigns.
- Litigation material filed per supervisor direction → flag closes RESOLVED once the move is verified.
