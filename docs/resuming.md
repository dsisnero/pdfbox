# Resuming Work

How to pick up this repo in a fresh session. This points at the state; it does
not restate it.

## Source of truth

`plans/parity.md` is the single source of truth for where we are. It starts with
a **`## Where we are`** block (`Current focus`, `Next up`, working-in file) and
indexes the split parts; the running feature changelog lives in
`plans/parity/changelog.md` (newest entry at the top of
`plans/parity/changelog/current.md`; older parts are frozen `archive-*.md`
files).

Per-symbol state lives in the inventory ledgers under `plans/inventory/` (see
`AGENTS.md` → *Tracking Work*): `java_source_parity.tsv`, `java_port_inventory.tsv`,
`java_test_parity.tsv`.

## Steps

1. `git status` — the working tree may hold uncommitted work; do not discard
   it.
2. Read the **`## Where we are`** block in `plans/parity.md` (current focus, next
   up, and the work file we are in) and the **top entry of
   `plans/parity/changelog/current.md`**. That is the most recently completed
   feature; continue from there.
3. `git log --oneline -10` to confirm the commit history.
4. Run the gates to confirm the baseline:

   ```bash
   make format
   make lint
   make test
   ```

   All three gates are green on a clean checkout, and they strip the
   AppleDouble `._*` sidecars that exFAT checkouts leave behind (a
   `._foo_spec.cr` breaks spec discovery). [testing.md](testing.md) owns the gate
   details, including the stale-`./bin/ameba` trap.
5. Pick the next feature (see below), then run the per-feature loop in
   `AGENTS.md`.

## Picking the next feature

Find a **genuine gap**: a Java symbol under `vendor/pdfbox/` whose inventory row
is `missing` **and** which has no matching Crystal `def`/`property`/`getter`.
The `missing` status is noisy (the classifier only looks for `def`), so always
confirm against the Crystal source before treating a row as a gap.

To see what is left inside the current chunk:

```bash
tail -n +2 plans/inventory/java_port_inventory.tsv | cut -f3 | sort | uniq -c
```

## Environment notes

If the checkout sits on an exFAT/extreme_ssd volume, see the *Environment note*
section of [development.md](development.md) for the `._*` sidecar and transient
unmount quirks.
