# Report Walkthrough: Support `.sops` Infix Patterns

## Mode

- `implementation`

## Summary

- Added automatic SOPS edit support for `.sops.env`, `.sops.json`, and `.sops.yaml` filenames.
- Mapped the new suffixes to the same SOPS structured types as existing `.enc.*` support: `dotenv`, `json`, and `yaml`.
- Updated README automatic edit documentation to list the new supported filenames.
- Left `:wsops` creation behavior unchanged; it still creates `.enc` / `.enc.*` targets.

## Files Changed

- `lua/nvim_sops/sops.lua`: extends `supported_patterns` and `supported_types` with exact `.sops.*` structured suffixes.
- `README.md`: documents the expanded automatic read/write filename support.
- `.legion/tasks/support-sops-infix-patterns/**`: records contract, verification, review, and delivery evidence.

## Verification

- `docs/test-report.md` records PASS for targeted headless Neovim validation of type resolution, autocmd pattern registration, existing `.enc*` regression coverage, and `git diff --check`.

## Review

- `docs/review-change.md` records PASS.
- Security lens was applied because the plugin handles encrypted secret files; no new key handling, metadata parsing, FIFO behavior, or plaintext temporary file path was introduced.

## Reviewer Notes

- The plain `.enc` binary mapping remains last, preserving existing structured suffix behavior.
- `.sops.yml` and plain `.sops` are intentionally out of scope for this task.
