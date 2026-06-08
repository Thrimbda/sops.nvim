# Add Wsops Command

## Summary

- Added a practical `:wsops` creation workflow for plaintext `.env`, `.json`, and `.yaml` buffers.
- Output filenames insert `.enc` before the supported suffix and can be created either next to the source file or inside a provided existing directory.
- New encrypted file creation relies on SOPS creation rules or equivalent SOPS-supported key configuration for the target `.enc.*` filename.

## Evidence

- Contract: `.legion/tasks/add-wsops-command/plan.md`
- Verification: `.legion/tasks/add-wsops-command/docs/test-report.md`
- Review: `.legion/tasks/add-wsops-command/docs/review-change.md`
- Walkthrough: `.legion/tasks/add-wsops-command/docs/report-walkthrough.md`

## Current Truth

- Native Neovim user commands cannot be lowercase, so the implementation uses canonical `:Wsops` plus a guarded command-line abbreviation for practical `:wsops` input.
- The command refuses unsupported plaintext suffixes, non-directory arguments, and existing encrypted targets.
- The creation path keeps plaintext in the existing stdin/FIFO flow and writes only encrypted SOPS output to the new target.
