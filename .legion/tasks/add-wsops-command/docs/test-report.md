# Test Report

## Summary

- Result: PASS
- Scope verified: command registration, `:wsops` practical lowercase invocation, same-directory output, directory-argument output, `.env` dotfile naming, overwrite refusal, unsupported suffix refusal, and non-directory argument refusal.
- Environment note: `luac` is not installed in this environment, so Lua syntax/load coverage came from Neovim 0.11.5 headless execution.

## Commands

```sh
nvim --headless -u NONE -c "set rtp+=." -c "lua ... headless command behavior verification ..."
```

- PASS: loaded the plugin, confirmed `Wsops` command registration, created `config.enc.yaml` next to `config.yaml`, invoked interactive lowercase `:wsops` through command-line abbreviation, and created `.enc.env` inside the requested directory.
- PASS: verified an existing `config.enc.json` target was not overwritten.

```sh
nvim --headless -u NONE -c "set rtp+=." -c "lua ... rejection path verification ..."
```

- PASS: rejected `notes.txt` as an unsupported plaintext suffix without creating `notes.enc.txt`.
- PASS: rejected a file path argument as not being a directory without creating output.

```sh
luac -p "lua/nvim_sops/commands.lua" "lua/nvim_sops/sops.lua" "lua/nvim_sops/init.lua"
```

- SKIPPED: `luac` is not installed (`zsh:1: command not found: luac`).

## Why These Checks

- Headless Neovim is the most direct available validation surface because the feature depends on Neovim command registration, command-line abbreviation behavior, buffer filenames, and plugin runtime functions.
- A repository-local SOPS stub was used to prove the plugin command path, target derivation, FIFO stdin flow, and exclusive encrypted output write without requiring real SOPS keys in the test environment.
- No full SOPS live encryption was run because the task accepts relying on user SOPS creation rules, and this environment does not provide task-specific keys or creation-rule fixtures.

## Residual Risk

- Real SOPS provider/key behavior is not covered here; failures from missing or mismatched creation rules are expected to surface through the command's SOPS error notification.
