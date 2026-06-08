## Summary

- Re-encrypt existing SOPS files by deriving supported key and rule flags from existing file metadata instead of requiring creation rules on save.
- Preserve the existing FIFO plaintext flow and encrypted temporary replacement behavior.
- Update README requirements for existing-file saves versus new encrypted file creation.

## Verification

- `nvim --headless -u NONE --cmd "set rtp+=." -c "lua require('nvim_sops.sops')" -c "qa!"`
- `nix-shell --run ...` reproduced the old no-creation-rule failure.
- `nix-shell --run ...` verified JSON, YAML, and dotenv age-backed round-trips through `encrypt_text` without creation rules.

## Notes

- Unsupported metadata structures such as `key_groups` and KMS encryption contexts now fail explicitly rather than silently changing encryption semantics.
