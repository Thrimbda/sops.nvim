# Decisions

## SOPS Existing-File Saves

- Status: current
- Source task: `fix-sops-metadata-encryption`
- Decision: For existing SOPS files, `sops encrypt` cannot safely re-encrypt stdin plaintext by directly reusing the encrypted file metadata. The plugin should derive supported key and encryption-rule flags from the existing file metadata, pass those flags explicitly to `sops encrypt`, and continue using FIFO plaintext input.
- Boundary: Metadata structures that cannot be represented safely as flat CLI flags, including `key_groups` and KMS encryption contexts, should fail explicitly instead of silently changing encryption semantics.
