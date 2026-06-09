# Design-lite

## Summary

- Risk: low.
- Change type: README attribution wording cleanup.
- Design approval mode: delayed approval through final PR review/merge.

## Decision

- Replace the README attribution link that exposes the old `nvim-sops` literal with plain attribution to Ben Sherman's original SOPS Neovim plugin lineage.
- Do not rewrite unrelated README sections.
- Do not edit historical Legion evidence from prior tasks just because it records previous old-name scope.

## Verification

- Run a README-scoped grep to ensure `README.md` no longer contains `nvim-sops`.
- Review the README attribution sentence for clarity.
