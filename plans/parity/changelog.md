# Changelog

The running, newest-first record of landed features (the "what did we just do"
log for `plans/parity.md`). Every entry states the feature, the
accessors/behaviour added, the spec file, the example-count delta
(e.g. `2,784→2,796 examples, 0 failures`), and any documented divergence.

## Where new entries go

**Always the top of [`current.md`](changelog/current.md).** There is exactly one
`current.md`, so "newest" never depends on guessing a suffix.

## Archiving

When `current.md` passes ~60 KB, freeze it and start a new one:

1. `git mv current.md archive-<newest entry date>-to-<oldest entry date>.md`
   — for example `archive-2026-10-14-to-2026-10-13.md` (the file keeps its
   newest-first order, so the first entry is the newest date and the last entry
   the oldest).
2. Rewrite its title/quote to the archive header (see the existing archives) so
   it says "frozen, do not append" and links `current.md`.
3. Create a fresh `current.md` with the standard current header.
4. Add the new archive to the table below and update `plans/parity.md`.

Archives are append-only history: never add new entries to them.

## Parts (newest first)

| Part | Covers | Entries |
|---|---|---|
| [`current.md`](changelog/current.md) | 2026-10-28 → 2026-10-15 (open) | 43 |
| [`archive-2026-10-14-to-2026-10-13.md`](changelog/archive-2026-10-14-to-2026-10-13.md) | 2026-10-14 → 2026-10-13 | 61 |
| [`archive-2026-10-13-to-2026-10-07.md`](changelog/archive-2026-10-13-to-2026-10-07.md) | 2026-10-13 → 2026-10-07 | 92 |
| [`archive-2026-08-18-and-earlier.md`](changelog/archive-2026-08-18-and-earlier.md) | 2026-08-18 and the earlier phase summaries | 14 |
