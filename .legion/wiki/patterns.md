# Patterns

## SOPS Save Path

- Keep plaintext in memory/FIFO only; do not introduce plaintext temporary files for save-time re-encryption.
- Treat SOPS metadata key identifiers as non-secret command arguments only after confirming they are already present in the encrypted file metadata.
- Prefer explicit failure over partial support when a metadata shape cannot be faithfully represented by the SOPS CLI.

## SOPS Creation Path

- Derive first-time encrypted targets by inserting `.enc` before supported plaintext suffixes: `.env`, `.json`, and `.yaml`.
- Use the target encrypted filename as the SOPS filename override so creation rules match the file that will be written.
- Refuse to overwrite existing targets and write encrypted output through exclusive file creation.
- For lowercase command UX in Neovim, use a guarded command-line abbreviation around an uppercase canonical user command because native user commands cannot be lowercase.
