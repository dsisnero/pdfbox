# PR Workflow

- Keep commits focused and describe the behavior change in imperative form.
- Before pushing, run the gates locally (`make quality`); see
  [testing.md](testing.md) for what each gate checks.
- Push completed work instead of leaving parity changes stranded locally.
- Call out remaining parity gaps explicitly in commit messages or handoff notes.

One feature per commit, and the commit is atomic: implementation, specs,
inventory rows, and the `plans/parity.md` status refresh land together (see the
**Definition of done** in `AGENTS.md`).

Recommended end-of-session flow:

```bash
git pull --rebase
make quality
git push
git status
```

Follow-up work that is intentionally left pending goes into `plans/parity.md`
(the **Next up** item) or a `plans/active/*.md` plan — not into an external
tracker.
