## Summary

- Add `.enc` as the SOPS `binary` suffix for automatic read/write handling.
- Reuse JSON SOPS metadata for existing `.enc` binary saves and keep `.enc.env`, `.enc.json`, and `.enc.yaml` structured mappings unchanged.
- Let `:wsops` create `<name>.enc` from ordinary plaintext buffers and update README support docs.

## Verification

- `nvim --headless -u NONE -c 'set rtp^=.' -c 'lua require("nvim_sops.sops"); require("nvim_sops.commands")' -c 'qa'`
- `nvim -n --headless -u NONE -c 'set rtp^=.' -c '<targeted Lua assertions>' -c 'qa!'`
- `git diff --check`

## Notes

- `sops` is not installed in this environment, so validation used monkeypatched SOPS calls to assert plugin-side command construction without real key material.
- Security review found no new plaintext-at-rest path or credential-exposure issue.
