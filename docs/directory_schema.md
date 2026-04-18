# Directory Schema

[DRIVE_LABEL]/
├── Autism_Today/
│   ├── Conferences/
│   ├── Resources_and_IP/
│   ├── Business_development/
│   ├── Documents/
│   └── Media/
│       ├── Web_assets/
│       ├── Video/
│       └── Other/
├── Mediation/
│   ├── Business_development/
│   ├── Financial/
│   ├── Legal/
│   └── Clients/
├── VOCROM/
│   ├── Financial/
│   ├── Legal/
│   ├── Email_archive/
│   ├── Phone_Records/
│   └── Media/
│       ├── Art_assets/
│       ├── Video/
│       └── Other/
├── Newslink/
│   ├── Financial/
│   ├── Legal/
│   ├── Email_archive/
│   ├── Phone_Records/
│   └── Media/
│       ├── Art_assets/
│       ├── Video/
│       └── Other/
├── Personal_DOCS/
├── System_backups/
│   └── BURNINGSTATION/
└── Unsorted/

#Design Decisions
Each business entity has its own Media, Financial, and Legal subfolders to avoid ambiguity when sorting files.
Mediation is a separate, different operational domain from the call center businesses.
Personal DOCS remains its own category per supervisor instruction.
System backups are retained temporarily — will be deleted after confirming no data is missing from the main archive.
Unsorted folder for files that don't clearly fit any category — to be reviewed by stakeholders.
No top-level Financial or Legal — finances are intertwined with specific business entities, so financial/legal docs go under their respective entities.
