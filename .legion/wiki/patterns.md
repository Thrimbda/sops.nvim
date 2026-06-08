# Patterns

## SOPS Save Path

- Keep plaintext in memory/FIFO only; do not introduce plaintext temporary files for save-time re-encryption.
- Treat SOPS metadata key identifiers as non-secret command arguments only after confirming they are already present in the encrypted file metadata.
- Prefer explicit failure over partial support when a metadata shape cannot be faithfully represented by the SOPS CLI.
