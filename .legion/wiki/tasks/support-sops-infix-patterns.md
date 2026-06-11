# Support Sops Infix Patterns

## Summary

- Added automatic read/write recognition for `.sops.env`, `.sops.json`, and `.sops.yaml` files.
- Reused the existing structured SOPS type mappings: `dotenv`, `json`, and `yaml`.
- Left first-time creation behavior unchanged; `:wsops` still creates `.enc` or `.enc.*` targets.

## Evidence

- Contract: `.legion/tasks/support-sops-infix-patterns/plan.md`
- Verification: `.legion/tasks/support-sops-infix-patterns/docs/test-report.md`
- Review: `.legion/tasks/support-sops-infix-patterns/docs/review-change.md`
- Walkthrough: `.legion/tasks/support-sops-infix-patterns/docs/report-walkthrough.md`

## Current Truth

- `.sops.env`, `.sops.json`, and `.sops.yaml` are supported automatic edit suffixes alongside `.enc.env`, `.enc.json`, and `.enc.yaml`.
- `.sops.*` support is recognition-only for existing encrypted files in this task; creation remains `.enc` / `.enc.*` based.
- Plain `.sops` and `.sops.yml` remain unsupported unless a future task expands the suffix set.
