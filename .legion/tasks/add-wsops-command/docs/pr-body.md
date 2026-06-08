## Summary

- Add `:wsops` practical invocation for creating `.enc.env`, `.enc.json`, and `.enc.yaml` files from plaintext buffers.
- Reuse the existing SOPS stdin/FIFO path for new-file encryption and refuse existing targets.
- Document same-directory creation, directory argument behavior, and SOPS creation-rule requirements.

## Verification

- `nvim --headless -u NONE -c "set rtp+=." -c "lua ... headless command behavior verification ..."`
- `nvim --headless -u NONE -c "set rtp+=." -c "lua ... rejection path verification ..."`

## Notes

- Native Neovim user commands cannot be lowercase, so the implementation registers `:Wsops` and provides a guarded lowercase `wsops` command-line abbreviation for interactive `:wsops` usage.
