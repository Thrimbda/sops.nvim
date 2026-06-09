# Add Enc Binary Support

## Summary

- Added plain `.enc` suffix support for SOPS `binary` files.
- Automatic read/write now includes `.enc` alongside `.enc.env`, `.enc.json`, and `.enc.yaml`.
- First-time creation with `:wsops` now appends `.enc` for ordinary plaintext filenames while preserving structured `.enc.*` naming.

## Evidence

- Contract: `.legion/tasks/add-enc-binary-support/plan.md`
- Verification: `.legion/tasks/add-enc-binary-support/docs/test-report.md`
- Review: `.legion/tasks/add-enc-binary-support/docs/review-change.md`
- Walkthrough: `.legion/tasks/add-enc-binary-support/docs/report-walkthrough.md`

## Current Truth

- Plain `.enc` maps to SOPS `binary`; `.enc.env`, `.enc.json`, and `.enc.yaml` keep their structured SOPS types.
- Existing `.enc` saves reuse SOPS metadata by parsing the encrypted binary file as JSON metadata, then still pass `binary` input/output types to SOPS.
- `:wsops` appends `.enc` for ordinary plaintext filenames and rejects a source already ending in `.enc` rather than producing `.enc.enc`.
