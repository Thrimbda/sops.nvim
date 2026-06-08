# Fix SOPS Metadata Encryption

## Summary

- Existing encrypted-file saves now derive supported SOPS key and encryption-rule CLI flags from the target file's metadata.
- The implementation keeps plaintext in the existing FIFO flow and writes only encrypted output to the replacement temp file.
- README now clarifies that automatic writes support existing encrypted files, while new file creation still requires external SOPS rules or keys.

## Evidence

- Contract: `.legion/tasks/fix-sops-metadata-encryption/plan.md`
- Verification: `.legion/tasks/fix-sops-metadata-encryption/docs/test-report.md`
- Review: `.legion/tasks/fix-sops-metadata-encryption/docs/review-change.md`
- Walkthrough: `.legion/tasks/fix-sops-metadata-encryption/docs/report-walkthrough.md`

## Current Truth

- `sops encrypt` with stdin and `--filename-override` still requires creation rules or explicit keys.
- The plugin works around this by extracting supported metadata key/rule fields and passing them explicitly.
- Unsupported metadata shapes should fail explicitly.
