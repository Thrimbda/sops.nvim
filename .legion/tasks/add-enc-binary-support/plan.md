# Add Enc Binary Support

## Contract

- `taskId`: `add-enc-binary-support`
- `name`: Add `.enc` suffix support for SOPS binary files
- `goal`: Treat files ending in `.enc` as SOPS `binary` files for automatic edit workflows and document the supported suffix.
- `problem`: The plugin currently supports structured encrypted suffixes (`.enc.env`, `.enc.json`, and `.enc.yaml`) but does not expose the SOPS binary type through a plain `.enc` suffix. Users with non-structured or binary SOPS files cannot use the automatic read/write path or first-time creation workflow consistently.

## Acceptance

- Files ending in `.enc` are included in the automatic `BufReadCmd` and `BufWriteCmd` support list.
- SOPS operations for `.enc` files use `--input-type binary` and `--output-type binary`.
- Existing support for `.enc.env`, `.enc.json`, and `.enc.yaml` continues to select `dotenv`, `json`, and `yaml` respectively.
- `:wsops` can create a sibling `<name>.enc` target from a plaintext buffer whose filename is not already one of the structured supported plaintext suffixes.
- `:wsops` continues to reject already encrypted source names and refuses to overwrite existing targets.
- README mentions `.enc` binary support in features, automatic workflow, and creation workflow.

## Scope

- Update the supported suffix/type mapping in the SOPS wrapper.
- Update first-time encrypted target-name derivation for the binary `.enc` suffix.
- Update README user-facing descriptions of supported suffixes and creation behavior.
- Keep verification focused on Lua syntax and deterministic helper behavior that can be exercised without real key material.

## Non-Goals

- Do not add new key-management options, recipient flags, or SOPS configuration behavior.
- Do not alter existing `.enc.env`, `.enc.json`, or `.enc.yaml` semantics.
- Do not introduce plaintext temporary files or change the current FIFO/stdin posture.
- Do not add format-specific handling for arbitrary binary payload editing beyond SOPS `binary` type support.
- Do not broaden structured type support to additional suffixes such as `.yml` unless requested separately.

## Assumptions

- SOPS `binary` type is the intended mapping for a plain `.enc` suffix.
- Neovim buffers may still expose decrypted bytes as buffer content; this task only wires the SOPS file type and documented suffix behavior.
- For first-time creation, a source already ending in `.enc` should be considered encrypted and rejected rather than producing `.enc.enc`.

## Constraints

- Keep the change localized to `lua/nvim_sops/sops.lua`, `lua/nvim_sops/commands.lua`, README, and Legion task artifacts unless verification exposes a required adjacent change.
- Preserve explicit error behavior for unsupported or already encrypted source names.
- Preserve existing command registration and autocmd setup behavior.

## Risks

- Pattern ordering must ensure `.enc.env`, `.enc.json`, and `.enc.yaml` do not get classified as plain `.enc` binary files.
- Binary SOPS output may contain bytes that are awkward to edit as normal text in Neovim; README should avoid promising more than suffix/type support.
- Adding fallback `:wsops` naming must not accidentally accept already encrypted names or change existing structured naming.

## Design Summary

- Add `*.enc` to the supported autocmd patterns and map only filenames ending exactly in `.enc` to SOPS `binary`.
- Keep structured suffix checks before the plain `.enc` check so existing `.enc.*` formats retain their current SOPS types.
- Extend `:wsops` target-name derivation with a fallback that appends `.enc` to unsupported plaintext names while rejecting source names that already look encrypted.
- Update README examples and feature text to distinguish structured `.enc.*` files from plain `.enc` binary files.

## Phases

- Brainstorm: create this stable task contract and checklist.
- Engineer: implement the suffix/type and README changes within the bounded scope.
- Verify: run Lua/Neovim checks that exercise type resolution and target naming where available.
- Review: inspect for suffix ordering, creation naming, plaintext handling, and README accuracy.
- Report: produce reviewer-facing delivery notes.
- Wiki: record durable suffix/type and creation-flow knowledge if reusable.
