# Review Change: Support `.sops` Infix Patterns

## Decision

- Result: PASS
- Scope compliance: PASS
- Verification evidence: PASS
- Security lens: Applied because the plugin handles encrypted secret files and SOPS workflows.

## Blocking Findings

- None.

## Review Notes

- `lua/nvim_sops/sops.lua` adds only exact `.sops.env`, `.sops.json`, and `.sops.yaml` structured suffix matches.
- Existing `.enc.env`, `.enc.json`, `.enc.yaml`, and `.enc` mappings remain present, with the plain `.enc` binary mapping still last.
- `README.md` documents the additional automatic edit suffixes without changing or implying new `:wsops` creation behavior.
- `docs/test-report.md` records a targeted headless Neovim check for type resolution, autocmd pattern registration, existing `.enc*` regression coverage, and diff whitespace hygiene.

## Security Notes

- The change expands which filenames enter the already-existing automatic decrypt/encrypt workflow, but it does not add a new command execution path.
- No key-management behavior, SOPS metadata parsing, FIFO plaintext handling, or encrypted-file write semantics changed.
- No new plaintext temporary files or broader secret exposure paths were introduced.

## Residual Risk

- The task intentionally does not add `.sops.yml` or plain `.sops` support. That matches the confirmed scope but remains a possible future compatibility request.
