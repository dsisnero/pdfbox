# PR Workflow

- Keep commits focused and describe the behavior change in imperative form.
- Before pushing, run format, lint, and spec gates locally.
- Push completed work instead of leaving parity changes stranded locally.
- Call out remaining parity gaps explicitly in commit messages or handoff notes.

Recommended end-of-session flow:

```bash
git pull --rebase
git push
git status
```

Use `bd` to track follow-up work that is intentionally left pending.
