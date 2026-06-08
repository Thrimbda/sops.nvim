# Rename Plugin Display Name

## Metadata

- `task-id`: `rename-plugin-display-name`
- `status`: `completed`
- `risk`: `low`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- Main Lua source now uses `sops.nvim` for the plugin's visible label text instead of `nvim-sops`.
- The change covered notification prefixes, temporary encrypted output prefixes, FIFO prefixes, error text, and the writer job label.
- `nvim_sops` module identifiers were intentionally preserved.
- Existing nested `.worktrees/**` copies were out of scope and remain separate worktree state.

## Reusable Decisions

- No cross-task rule was promoted from this task; the result is a task-local naming cleanup.

## Related Raw Sources

- `plan`: `.legion/tasks/rename-plugin-display-name/plan.md`
- `log`: `.legion/tasks/rename-plugin-display-name/log.md`
- `tasks`: `.legion/tasks/rename-plugin-display-name/tasks.md`
- `design-lite`: `.legion/tasks/rename-plugin-display-name/docs/rfc.md`
- `verification`: `.legion/tasks/rename-plugin-display-name/docs/test-report.md`
- `review`: `.legion/tasks/rename-plugin-display-name/docs/review-change.md`
- `report`: `.legion/tasks/rename-plugin-display-name/docs/report-walkthrough.md`

## Notes

- Use raw task docs for command output and review details.
