## Summary

- Add automatic edit recognition for `.sops.env`, `.sops.json`, and `.sops.yaml`.
- Map the new `.sops.*` suffixes to existing SOPS `dotenv`, `json`, and `yaml` handling.
- Document the additional automatic read/write suffixes in README.

## Verification

- `nvim --headless -u NONE --cmd "set rtp+=." ...` checked new `.sops.*` mappings, existing `.enc*` mappings, and BufRead/BufWrite autocmd registration.
- `git diff --check`

## Notes

- `:wsops` creation behavior is unchanged and continues to create `.enc` / `.enc.*` targets.
- `.sops.yml` and plain `.sops` are out of scope.
