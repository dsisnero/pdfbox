# Resuming Work

How to pick up this repo in a fresh session.

## Source of truth

`plans/parity.md` is the single source of truth for where we are. It starts with
a **`## Where we are`** block (`Current focus`, `Next up`) and keeps a
newest-first changelog of recent features in two places:

- the top bullet under `### Current Active Work` (near the bottom), and
- the start of the `| Fixed since last update |` cell in the Overview table.

Per-symbol state lives in the inventory ledgers under `plans/inventory/` (see
`AGENTS.md` → *Tracking Work*): `java_source_parity.tsv`, `java_port_inventory.tsv`,
`java_test_parity.tsv`.

## Steps

1. `git status` — the working tree may contain uncommitted work; do not discard it.
2. Read the **`## Where we are`** block and the **first bullet under
   `### Current Active Work`** in `plans/parity.md`. That is the most recently
   completed feature; continue from there.
3. `git log --oneline -10` to confirm the commit history.
4. Run the gates to confirm a clean baseline:
   `crystal tool format --check src spec`, `ameba src spec`, `crystal spec`.
5. Pick the next feature (see below), then run the per-feature loop in
   `AGENTS.md`.

## Picking the next feature

Find a **genuine gap**: a Java symbol under `vendor/pdfbox/` whose inventory row
is `missing` **and** which has no matching Crystal `def`/`property`/`getter`.
The `missing` status is noisy (the classifier only looks for `def`), so always
confirm against the Crystal source before treating a row as a gap.
