# Task Checklist

## Current Phase

- `brainstorm`: complete
- `engineer`: complete
- `verify-change`: complete
- `review-change`: complete
- `report-walkthrough`: complete
- `legion-wiki`: complete

## Checklist

- [x] Confirm `.enc` maps to SOPS `binary` and scope includes README updates.
- [x] Add `.enc` to automatic read/write support without changing `.enc.*` type classification.
- [x] Extend `:wsops` target derivation so ordinary plaintext filenames can create `<name>.enc`.
- [x] Keep already encrypted source names rejected.
- [x] Update README features and workflow text for `.enc` binary support.
- [x] Verify the change with available Lua/Neovim tooling.
- [x] Review the change for suffix-order and plaintext-handling regressions.
- [x] Record delivery summary.
- [x] Record reusable knowledge.
