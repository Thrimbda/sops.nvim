# Decisions

## SOPS Existing-File Saves

- Status: current
- Source task: `fix-sops-metadata-encryption`
- Decision: For existing SOPS files, `sops encrypt` cannot safely re-encrypt stdin plaintext by directly reusing the encrypted file metadata. The plugin should derive supported key and encryption-rule flags from the existing file metadata, pass those flags explicitly to `sops encrypt`, and continue using FIFO plaintext input.
- Boundary: Metadata structures that cannot be represented safely as flat CLI flags, including `key_groups` and KMS encryption contexts, should fail explicitly instead of silently changing encryption semantics.

## SOPS New-File Creation

- Status: current
- Source task: `add-wsops-command`
- Decision: First-time encrypted file creation should rely on the user's SOPS creation rules or other SOPS-supported key configuration for the target `.enc.*` filename, not on new plugin key-management options.
- Boundary: The plugin should pass plaintext through stdin/FIFO, refuse unsupported source suffixes and existing targets, and surface SOPS failures when no matching creation rule or key configuration exists.
