# Rename README Display Name

## Contract

- `taskId`: `rename-readme-display-name`
- `name`: Remove old plugin name literal from README attribution
- `goal`: Ensure README no longer contains the old `nvim-sops` literal while preserving attribution to the original author.
- `problem`: The previous naming cleanup was intentionally scoped to Lua source, leaving README attribution text with the old upstream repository name. That makes repository-wide name checks still surface the old name in user-facing documentation.

## Acceptance

- `README.md` contains no `nvim-sops` literal.
- README attribution still credits Ben Sherman as the original creator/source of the derived plugin lineage.
- Existing installation and usage documentation remains unchanged except for the attribution sentence.
- Legion evidence records why this is a follow-up to the Lua-only rename task.

## Scope

- Update `README.md` attribution wording.
- Add task-local Legion evidence under `.legion/tasks/rename-readme-display-name/**`.
- Add a wiki task summary for this follow-up.

## Non-Goals

- Do not rewrite feature, workflow, installation, or configuration docs.
- Do not alter license files or attribution outside README unless verification finds the same old literal in README-adjacent generated evidence for this task.
- Do not mutate historical raw evidence from previous Legion tasks that intentionally mention the old string as prior scope or verification input.

## Assumptions

- The user's expected fix is README-facing text cleanup, not a rewrite of historical Legion evidence.
- Attribution can remain accurate by crediting the original author/source without naming the old repository literal.
- Repository-wide historical task docs may continue to mention `nvim-sops` as raw evidence; acceptance is scoped to README.

## Constraints

- Keep the documentation edit minimal and reader-facing.
- Preserve attribution clarity for README readers.
- Verify with a README-scoped grep.

## Risks

- Removing the explicit old repository link may reduce attribution specificity; the wording should keep the original creator clear.
- A repository-wide grep will still find old literals in historical Legion evidence; final reporting must distinguish raw evidence from current README content.

## Design Summary

- Treat this as a low-risk documentation follow-up.
- Replace the old linked upstream repository reference with a concise author/source attribution that does not contain the old literal.
- Verify README no longer contains `nvim-sops` and review that attribution remains understandable.

## Phases

- Brainstorm: create the follow-up contract and task checklist.
- Engineer: update the README attribution sentence.
- Verify: confirm README has no old literal.
- Review: check scope and attribution accuracy.
- Report: produce reviewer-facing delivery notes.
- Wiki: add a task summary and avoid promoting a cross-task rule.
