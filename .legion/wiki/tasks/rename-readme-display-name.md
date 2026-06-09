# Rename README Display Name

## Metadata

- `task-id`: `rename-readme-display-name`
- `status`: `completed`
- `risk`: `low`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- README attribution no longer contains the old `nvim-sops` literal.
- Attribution now credits Ben Sherman's original SOPS plugin for Neovim without exposing the stale repository name in README.
- This is a follow-up to `rename-plugin-display-name`, which was intentionally scoped to Lua source only.
- Historical Legion raw evidence from prior tasks may still mention the old string as previous scope or command evidence.

## Reusable Decisions

- No cross-task rule was promoted from this task; the result is a task-local README cleanup.

## Related Raw Sources

- `plan`: `.legion/tasks/rename-readme-display-name/plan.md`
- `log`: `.legion/tasks/rename-readme-display-name/log.md`
- `tasks`: `.legion/tasks/rename-readme-display-name/tasks.md`
- `design-lite`: `.legion/tasks/rename-readme-display-name/docs/rfc.md`
- `verification`: `.legion/tasks/rename-readme-display-name/docs/test-report.md`
- `review`: `.legion/tasks/rename-readme-display-name/docs/review-change.md`
- `report`: `.legion/tasks/rename-readme-display-name/docs/report-walkthrough.md`

## Notes

- Use raw task docs for command output and review details.
