# Test Report: Support `.sops` Infix Patterns

## Summary

- Result: PASS
- Scope: `.sops.env`, `.sops.json`, and `.sops.yaml` file-type resolution, automatic autocmd pattern registration, existing `.enc*` regression coverage, and diff hygiene.
- Worktree: `.worktrees/support-sops-infix-patterns/`

## Commands

```sh
nvim --headless -u NONE --cmd "set rtp+=." -c "lua local s=require('nvim_sops.sops'); local cases={['secret.sops.env']='dotenv',['secret.sops.json']='json',['secret.sops.yaml']='yaml',['secret.enc.env']='dotenv',['secret.enc.json']='json',['secret.enc.yaml']='yaml',['secret.enc']='binary'}; for path, expected in pairs(cases) do local actual=s.file_type_for_path(path); if actual ~= expected then error(path .. ' expected ' .. expected .. ' got ' .. tostring(actual)) end end; local required={['*.sops.env']=false,['*.sops.json']=false,['*.sops.yaml']=false,['*.enc.env']=false,['*.enc.json']=false,['*.enc.yaml']=false,['*.enc']=false}; for _, pattern in ipairs(s.supported_patterns) do if required[pattern] ~= nil then required[pattern]=true end end; for pattern, seen in pairs(required) do if not seen then error('missing supported pattern ' .. pattern) end end; require('nvim_sops').setup({}); for _, event in ipairs({'BufReadCmd','BufWriteCmd'}) do local autocmds=vim.api.nvim_get_autocmds({ group='nvim_sops', event=event }); local seen={}; for _, autocmd in ipairs(autocmds) do seen[autocmd.pattern]=true end; for pattern, _ in pairs(required) do if not seen[pattern] then error(event .. ' missing pattern ' .. pattern) end end end" -c "qa!"
```

- Exit code: 0
- Evidence: New `.sops.*` paths resolve to the expected SOPS types, existing `.enc*` paths still resolve to their prior types, and both `BufReadCmd` and `BufWriteCmd` register every required pattern.

```sh
git diff --check
```

- Exit code: 0
- Evidence: No whitespace errors in the diff.

## Selection Rationale

- A targeted headless Neovim check is the strongest low-cost validation because the change is a Lua suffix table update used directly by the plugin's runtime autocmd setup.
- Full SOPS encryption/decryption integration was not run because this task does not change SOPS command construction, FIFO handling, metadata parsing, or key reuse behavior.

## Notes

- An initial verification command incorrectly assumed Neovim would return one autocmd with multiple patterns. Neovim returns one autocmd per pattern, so the assertion was corrected and rerun successfully.
