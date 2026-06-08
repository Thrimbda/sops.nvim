# Test Report

## Summary

- Result: PASS
- Date: 2026-06-08
- Scope: metadata-based re-encryption for existing `.enc.json`, `.enc.yaml`, and `.enc.env` files.

## Commands

- `nvim --headless -u NONE --cmd "set rtp+=." -c "lua require('nvim_sops.sops')" -c "qa!"`
- `nix-shell --run 'if printf "%s\n" "{\"foo\":\"baz\"}" | SOPS_AGE_KEY_FILE=.legion/tasks/fix-sops-metadata-encryption/scratch/age-key.txt sops --encrypt --input-type json --output-type json --filename-override .legion/tasks/fix-sops-metadata-encryption/scratch/api_key.enc.json /dev/stdin >/dev/null 2>&1; then exit 1; fi'`
- `nix-shell --run 'SOPS_AGE_KEY_FILE=.legion/tasks/fix-sops-metadata-encryption/scratch/age-key.txt nvim --headless -u NONE --cmd "set rtp+=." -c "lua vim.g.nvim_sops_bin_path = \"sops\"; local sops = require(\"nvim_sops.sops\"); local result = sops.encrypt_text(\".legion/tasks/fix-sops-metadata-encryption/scratch/api_key.enc.json\", \"{\\\"foo\\\":\\\"verify-json\\\"}\\n\"); if not result.ok then error(result.output) end; vim.fn.writefile(vim.split(result.output, \"\\n\", { plain = true }), \".legion/tasks/fix-sops-metadata-encryption/scratch/verify-json.enc.json\", \"b\")" -c "qa!" && SOPS_AGE_KEY_FILE=.legion/tasks/fix-sops-metadata-encryption/scratch/age-key.txt sops --decrypt --input-type json --output-type json .legion/tasks/fix-sops-metadata-encryption/scratch/verify-json.enc.json'`
- `nix-shell --run 'SOPS_AGE_KEY_FILE=.legion/tasks/fix-sops-metadata-encryption/scratch/age-key.txt nvim --headless -u NONE --cmd "set rtp+=." -c "lua vim.g.nvim_sops_bin_path = \"sops\"; local sops = require(\"nvim_sops.sops\"); local result = sops.encrypt_text(\".legion/tasks/fix-sops-metadata-encryption/scratch/test.enc.yaml\", \"foo: verify-yaml\\n\"); if not result.ok then error(result.output) end; vim.fn.writefile(vim.split(result.output, \"\\n\", { plain = true }), \".legion/tasks/fix-sops-metadata-encryption/scratch/verify-yaml.enc.yaml\", \"b\")" -c "qa!" && SOPS_AGE_KEY_FILE=.legion/tasks/fix-sops-metadata-encryption/scratch/age-key.txt sops --decrypt --input-type yaml --output-type yaml .legion/tasks/fix-sops-metadata-encryption/scratch/verify-yaml.enc.yaml'`
- `nix-shell --run 'SOPS_AGE_KEY_FILE=.legion/tasks/fix-sops-metadata-encryption/scratch/age-key.txt nvim --headless -u NONE --cmd "set rtp+=." -c "lua vim.g.nvim_sops_bin_path = \"sops\"; local sops = require(\"nvim_sops.sops\"); local result = sops.encrypt_text(\".legion/tasks/fix-sops-metadata-encryption/scratch/test.enc.env\", \"FOO=verify-env\\n\"); if not result.ok then error(result.output) end; vim.fn.writefile(vim.split(result.output, \"\\n\", { plain = true }), \".legion/tasks/fix-sops-metadata-encryption/scratch/verify-env.enc.env\", \"b\")" -c "qa!" && SOPS_AGE_KEY_FILE=.legion/tasks/fix-sops-metadata-encryption/scratch/age-key.txt sops --decrypt --input-type dotenv --output-type dotenv .legion/tasks/fix-sops-metadata-encryption/scratch/verify-env.enc.env'`

## Evidence

- Lua module loaded in headless Neovim without syntax/runtime errors.
- The old stdin encryption shape still fails without creation rules, proving the original failure mode remains reproducible.
- JSON re-encryption decrypted to `{ "foo": "verify-json" }` after the plugin extracted the age recipient from existing metadata.
- YAML re-encryption decrypted to `foo: verify-yaml` after the plugin extracted the age recipient from existing metadata.
- Dotenv re-encryption decrypted to `FOO=verify-env` after the plugin extracted the age recipient from existing metadata.

## Rationale

- These targeted checks directly exercise the changed `encrypt_text` path through Neovim and SOPS, including the same FIFO mechanism used by plugin writes.
- Full integration through `BufReadCmd` and `BufWriteCmd` was not required because the changed behavior is isolated to SOPS command construction and encryption execution.

## Skipped

- No KMS/GCP/Azure/Vault live-key tests were run because this environment only has local age credentials. Those providers are covered by metadata parsing and command construction logic, but not by live provider calls.
