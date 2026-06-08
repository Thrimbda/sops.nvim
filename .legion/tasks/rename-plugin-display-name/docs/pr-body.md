## Summary

- Rename Lua-visible `nvim-sops` string literals to `sops.nvim`.
- Preserve `nvim_sops` module identifiers and behavior.
- Add Legion evidence for contract, design-lite, verification, review, and walkthrough.

## Verification

- `if rg "nvim-sops" "lua" --glob "*.lua"; then exit 1; fi`
- `nvim --headless -u NONE --cmd "set rtp+=." -c "lua require('nvim_sops.sops'); require('nvim_sops.commands')" -c "qa!"`

## Legion Evidence

- Plan: `.legion/tasks/rename-plugin-display-name/plan.md`
- Test report: `.legion/tasks/rename-plugin-display-name/docs/test-report.md`
- Review: `.legion/tasks/rename-plugin-display-name/docs/review-change.md`
- Walkthrough: `.legion/tasks/rename-plugin-display-name/docs/report-walkthrough.md`
