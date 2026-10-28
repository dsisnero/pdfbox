# Changelog

The running, newest-first record of landed features (the "what did we just do"
log for `plans/parity.md`). Every entry states the feature, the
accessors/behaviour added, the spec file, the example-count delta
(e.g. `2,784→2,796 examples, 0 failures`), and any documented divergence.

**Rules**

- Newest first. Add a new entry at the top of the newest part file.
- One entry per landed feature, written as part of the feature commit.
- Keep `plans/parity.md` small: it links here instead of inlining the log.

## Parts

| Part | Covers | Entries |
|---|---|---|
| [`2026-10a.md`](changelog/2026-10a.md) | 2026-10-28 → 2026-10-15 | 43 |
| [`2026-10b.md`](changelog/2026-10b.md) | 2026-10-14 → 2026-10-13 | 61 |
| [`2026-10c.md`](changelog/2026-10c.md) | 2026-10-13 → 2026-10-07 | 92 |
| [`2026-08-and-earlier.md`](changelog/2026-08-and-earlier.md) | 2026-08-18 and the earlier phase summaries | 14 |

When the newest part grows past ~60 KB, start a new part for the current month
(e.g. `changelog/2026-11.md`) and link it here instead of appending to an old
file.
