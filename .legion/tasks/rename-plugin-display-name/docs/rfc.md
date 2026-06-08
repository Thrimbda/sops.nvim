# Design-lite

## Summary

- Risk: low.
- Change type: literal string replacement in main Lua source.
- Design approval mode: delayed approval through final review of the Legion evidence/change.

## Decision

- Replace only hyphenated `nvim-sops` string literals under `./lua/**/*.lua` with `sops.nvim`.
- Preserve underscore identifiers and module paths such as `nvim_sops`.
- Do not touch `.worktrees/**` copies from this main-workspace task.

## Verification

- Run a scoped grep to ensure `./lua/**/*.lua` has no `nvim-sops` occurrences.
- Run headless Neovim module loading for the affected Lua modules.
