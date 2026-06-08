# Add Wsops Command

## Contract

- `taskId`: `add-wsops-command`
- `name`: Add a command for creating encrypted SOPS files from plaintext buffers
- `goal`: Provide a Neovim command users can run from `.env`, `.json`, or `.yaml` buffers to create a same-basename SOPS encrypted file with an `.enc` infix.
- `problem`: The plugin currently supports automatic editing of existing `.enc.env`, `.enc.json`, and `.enc.yaml` files, but it does not expose a convenient in-editor command for creating the first encrypted counterpart from a plaintext file.

## Acceptance

- Users can invoke the workflow as `:wsops` in practice from a plaintext `.env`, `.json`, or `.yaml` buffer.
- With no argument, the encrypted file is created in the same directory as the current buffer.
- With one directory argument, the encrypted file is created inside that directory.
- Output names insert `.enc` before the supported suffix: `.env` becomes `.enc.env`, `name.json` becomes `name.enc.json`, and `name.yaml` becomes `name.enc.yaml`.
- The command rejects unsupported current-buffer suffixes and rejects an argument that is not an existing directory.
- The command does not overwrite an existing target file.
- Plaintext is passed to SOPS through the existing stdin/FIFO flow and is not written to a plaintext temporary file.
- Documentation mentions the creation command and its SOPS creation-rule dependency.

## Scope

- Add command registration to the existing plugin setup path.
- Add the minimal SOPS wrapper needed to encrypt new plaintext content using SOPS creation rules for the target encrypted filename.
- Reuse existing buffer line joining, SOPS environment handling, and encrypted-output file writing patterns where practical.
- Update README workflow/feature documentation.

## Non-Goals

- Do not add key-management options or inline recipient flags for first-time file creation.
- Do not broaden supported source suffixes beyond `.env`, `.json`, and `.yaml`.
- Do not change existing automatic read/write behavior for `.enc.*` files.
- Do not introduce background encryption, realtime encryption, or automatic command execution on write.
- Do not overwrite existing encrypted targets.

## Assumptions

- First-time encryption should rely on the user's existing SOPS configuration, such as `.sops.yaml` creation rules or other SOPS-supported configuration.
- The command argument is a Neovim path that must resolve to an existing directory; the confirmed behavior is to create the encrypted file inside that directory.
- Neovim user-defined commands require an uppercase canonical name, so the implementation may expose a canonical uppercase command plus a lowercase command-line abbreviation to satisfy practical `:wsops` invocation.

## Constraints

- Keep the change localized to `lua/nvim_sops/commands.lua`, `lua/nvim_sops/sops.lua`, and README unless verification shows another entrypoint is required.
- Preserve the current plaintext handling posture: plaintext may exist in memory and stdin/FIFO, but not in target-path or temporary plaintext files.
- Keep failure behavior explicit and user-visible through existing notification style.

## Risks

- Lowercase `:wsops` cannot be a native Neovim user command, so the alias must avoid expanding unrelated command-line text.
- SOPS creation can fail if no creation rule or key configuration matches the target encrypted path; the plugin should surface that failure instead of inventing key behavior.
- Filename derivation around dotfiles, especially `.env`, must produce the expected `.enc.env` target.

## Design Summary

- Add a create command that derives the current buffer's source type and target encrypted path, validates the optional directory argument, refuses pre-existing targets, encrypts current buffer text for the target filename, and writes the encrypted output exclusively.
- Add a SOPS helper for new-file encryption that uses `--encrypt`, source/target type flags, and `--filename-override` for the target encrypted path without trying to reuse metadata from an existing encrypted file.
- Register an uppercase canonical command for Neovim compatibility and a guarded lowercase `wsops` command-line abbreviation so users can type the requested `:wsops` form.

## Phases

- Brainstorm: create this stable task contract and checklist.
- Engineer: implement the command and documentation within the bounded scope.
- Verify: run syntax/headless Neovim checks that exercise target derivation and command behavior with a SOPS stub.
- Review: inspect the change for command alias risk, overwrite behavior, and plaintext handling.
- Report: produce reviewer-facing delivery notes.
- Wiki: record durable command and creation-flow knowledge if reusable.
