# Patterns

## SOPS Save Path

- Keep plaintext in memory/FIFO only; do not introduce plaintext temporary files for save-time re-encryption.
- Treat SOPS metadata key identifiers as non-secret command arguments only after confirming they are already present in the encrypted file metadata.
- Prefer explicit failure over partial support when a metadata shape cannot be faithfully represented by the SOPS CLI.
- For SOPS `binary` files, treat the encrypted file as JSON SOPS metadata for key reuse while using `binary` as the SOPS input and output type.

## SOPS Suffix Types

- Map `.enc.env`, `.enc.json`, and `.enc.yaml` to SOPS `dotenv`, `json`, and `yaml` respectively.
- Map a plain `.enc` suffix to SOPS `binary`.
- Keep structured suffix checks before the plain `.enc` check so existing `.enc.*` files do not get reclassified as binary.

## SOPS Creation Path

- Derive first-time structured encrypted targets by inserting `.enc` before supported plaintext suffixes: `.env`, `.json`, and `.yaml`.
- For other plaintext filenames, derive the encrypted target by appending `.enc` and using SOPS `binary` type.
- Use the target encrypted filename as the SOPS filename override so creation rules match the file that will be written.
- Refuse already encrypted source names, refuse to overwrite existing targets, and write encrypted output through exclusive file creation.
- For lowercase command UX in Neovim, use a guarded command-line abbreviation around an uppercase canonical user command because native user commands cannot be lowercase.
