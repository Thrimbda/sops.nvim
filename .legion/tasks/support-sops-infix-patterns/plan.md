# Support `.sops` Infix Patterns

## Contract

- `name`: Support `.sops` infix patterns
- `taskId`: `support-sops-infix-patterns`
- `goal`: Let the automatic SOPS edit workflow recognize common encrypted filenames that use `.sops` as the infix before a structured suffix.
- `problem`: The plugin currently recognizes `.enc.env`, `.enc.json`, `.enc.yaml`, and plain `.enc`. Many SOPS users name encrypted structured files as `name.sops.env`, `name.sops.json`, or `name.sops.yaml`; those files currently do not enter the plugin's automatic decrypt/encrypt handlers.

## Acceptance

- Files ending in `.sops.env` are included in automatic read/write handling and use SOPS `dotenv` type.
- Files ending in `.sops.json` are included in automatic read/write handling and use SOPS `json` type.
- Files ending in `.sops.yaml` are included in automatic read/write handling and use SOPS `yaml` type.
- Existing `.enc`, `.enc.env`, `.enc.json`, and `.enc.yaml` behavior remains unchanged.
- README documents the additional `.sops.*` supported filenames.

## Scope

- Update suffix pattern recognition for automatic `BufReadCmd` and `BufWriteCmd` handling.
- Update SOPS file-type resolution for the new `.sops.*` structured suffixes.
- Update documentation and task-local validation evidence.

## Non-Goals

- Do not change `:wsops` default target derivation; it should continue creating `.enc`, `.enc.env`, `.enc.json`, or `.enc.yaml` targets unless a future task changes that behavior.
- Do not add new SOPS data types beyond the existing `dotenv`, `json`, `yaml`, and `binary` mappings.
- Do not change metadata parsing, key reuse, FIFO handling, or encryption semantics.

## Assumptions

- `.sops.env`, `.sops.json`, and `.sops.yaml` are alternative encrypted filenames for the same SOPS data types already supported through `.enc.*`.
- Plain `.sops` is not in scope because the confirmed request is about `.sops` as an infix for structured filenames.
- `.sops.yml` is not in scope because the current plugin does not support `.yml` as a structured suffix.

## Constraints

- Keep structured suffix checks before broad suffix checks so `.enc.*` and `.sops.*` files are not misclassified as binary.
- Keep the change minimal and avoid altering the command creation workflow.
- Preserve existing documented `.enc` behavior.

## Risks

- Pattern ordering mistakes could reclassify structured encrypted files as binary or stop existing `.enc.*` support from matching.
- Documentation could imply `:wsops` creates `.sops.*` files if wording is not explicit.
- Without a dedicated test harness, verification should use targeted headless Neovim checks for file-type resolution and autocmd patterns.

## Design Summary

- Extend the supported autocmd pattern list with `*.sops.env`, `*.sops.json`, and `*.sops.yaml`.
- Extend file-type mapping with exact suffix matches for `.sops.env`, `.sops.json`, and `.sops.yaml` using the same types as their `.enc.*` counterparts.
- Leave `.enc` binary fallback and `:wsops` creation rules unchanged.

## Phases

- Contract: confirm task scope and materialize `plan.md` and `tasks.md`.
- Implementation: update suffix recognition and README with minimal code changes.
- Verification: run targeted headless Neovim checks and inspect diffs.
- Readiness: perform change review, walkthrough/report artifacts, and Legion wiki writeback.
