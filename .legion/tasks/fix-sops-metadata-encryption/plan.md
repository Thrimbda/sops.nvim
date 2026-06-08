# Fix SOPS Metadata Encryption

## Contract

- `taskId`: `fix-sops-metadata-encryption`
- `name`: Fix SOPS metadata reuse when saving existing encrypted files
- `goal`: Ensure `:w` on an already-decrypted SOPS file can re-encrypt using the file's existing SOPS metadata, even when no `.sops.yaml` creation rule is available.
- `problem`: The current write path encrypts buffer plaintext as a fresh encryption operation. SOPS then tries to resolve creation rules from config or command-line keys and fails for existing encrypted files that only carry usable key metadata in the file itself.

## Acceptance

- Saving an existing supported SOPS file uses the original encrypted file as the metadata source for re-encryption.
- The plugin still avoids writing plaintext to the target path or to a plaintext temporary file.
- Unsupported file types still fail with the existing unsupported-type error path.
- New encrypted file creation remains out of scope and may still require SOPS creation rules or explicit keys.
- Verification covers the SOPS command construction or an equivalent functional path for the existing-file save case.

## Scope

- Update the automatic write path for `.enc.env`, `.enc.json`, and `.enc.yaml` files that were successfully decrypted by the plugin.
- Preserve current same-directory FIFO plaintext handling and atomic encrypted-file replacement behavior.
- Update documentation if the requirements or workflow text becomes inaccurate.

## Non-Goals

- Do not add automatic creation of new SOPS files.
- Do not add new key configuration options.
- Do not change supported filename patterns or file formats.
- Do not introduce plaintext temporary files.

## Assumptions

- SOPS CLI does not provide a safe stdin mode that directly reuses an existing file's metadata, so the plugin must extract reusable key and rule information from the existing metadata and pass it as explicit encryption flags.
- The buffer state already tracks the decrypted source path and can safely enforce that writes only occur for files decrypted by the plugin.
- Users expect metadata reuse only for existing encrypted files, not for first-time file creation.

## Constraints

- Keep the change minimal and localized to the SOPS command wrapper and write path.
- Preserve Neovim compatibility with the current `vim.system` and FIFO fallback behavior.
- Avoid broad behavioral compatibility layers without a concrete need.

## Risks

- SOPS CLI behavior differs by version for stdin plus metadata reuse, so verification must check the actual command behavior available in this repository's environment when possible.
- Passing the wrong file context could silently rotate recipients or fail to preserve metadata.
- A fix that writes plaintext through an on-disk file would violate the plugin's security model.

## Design Summary

- Use a metadata-aware re-encryption path that reads the existing encrypted file metadata, converts supported key and encryption-rule fields into explicit SOPS flags, and still feeds edited plaintext through stdin/FIFO.
- Keep the decrypted-buffer guard in place so re-encryption is only attempted after a successful read.
- For metadata structures that cannot be represented safely as flat SOPS CLI flags, fail explicitly instead of silently changing encryption semantics or adding an unsafe plaintext workaround.

## Phases

- Brainstorm: create this stable contract and task checklist.
- Engineer: implement the metadata-aware save path within the bounded scope.
- Verify: run the strongest available command-level or functional checks for existing-file save behavior.
- Review: inspect the change for behavioral regressions and security risks.
- Report: produce reviewer-facing delivery notes.
- Wiki: write durable knowledge if the task yields reusable SOPS behavior guidance.
