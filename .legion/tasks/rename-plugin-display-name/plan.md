# Rename Plugin Display Name

## Contract

- `taskId`: `rename-plugin-display-name`
- `name`: Rename Lua-visible plugin label from `nvim-sops` to `sops.nvim`
- `goal`: Make user-visible Lua strings refer to the plugin as `sops.nvim` instead of `nvim-sops`.
- `problem`: The plugin repository and package name are `sops.nvim`, but Lua diagnostics, job labels, and temporary file names still embed the older `nvim-sops` text, which creates inconsistent user-facing naming.

## Acceptance

- `./lua/**/*.lua` contains no `nvim-sops` string occurrences.
- Existing `nvim-sops` string occurrences in the main Lua source are replaced with `sops.nvim`.
- Lua module paths, directory names, and internal identifiers such as `nvim_sops` are not renamed.
- The Lua modules still load in headless Neovim after the replacement.

## Scope

- Update string literals and command/job/temp-name text under `./lua/**/*.lua` in the main workspace.
- Update Legion task-local evidence for this work.

## Non-Goals

- Do not rename the `lua/nvim_sops/` module directory or `require('nvim_sops.*')` imports.
- Do not change plugin behavior beyond the literal label/name replacement.
- Do not modify existing nested worktree copies under `.worktrees/**` as part of this main-workspace task.
- Do not update non-Lua documentation unless verification finds an inaccurate generated artifact for this task.

## Assumptions

- The requested replacement targets literal `nvim-sops` text, not underscore-based module identifiers.
- Temporary filename prefixes and shell job labels may use `sops.nvim` safely because they are opaque labels/paths and not API contracts.
- Existing `.worktrees/**` entries belong to separate branch/worktree state and should not be mutated from the main workspace task.

## Constraints

- Keep the change minimal and localized to Lua source plus Legion evidence files.
- Preserve current behavior, supported file patterns, and SOPS command construction.
- Use a grep-based verification scoped to main Lua source.

## Risks

- A broad rename could accidentally break `require('nvim_sops.*')` module loading; this task intentionally avoids underscore identifiers.
- Hidden nested worktree files may still contain `nvim-sops`; verification must clearly distinguish main source from worktree copies.
- Dot-containing temporary file labels are valid but should be syntax-checked through module loading.

## Design Summary

- Treat this as a low-risk literal replacement in main Lua source only.
- Replace hyphenated `nvim-sops` strings with `sops.nvim` while leaving underscore module names unchanged.
- Verify with targeted grep and headless Neovim module loading.

## Phases

- Brainstorm: create a stable contract and task checklist.
- Engineer: perform the bounded Lua string replacement.
- Verify: confirm no scoped occurrences remain and Lua modules load.
- Review: inspect for accidental module rename or behavior change.
- Report: produce reviewer-facing delivery notes.
- Wiki: write only task summary unless reusable cross-task knowledge emerges.
