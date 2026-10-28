# PDFBox Crystal

> **How to resume:** read [`plans/parity.md`](plans/parity.md) first and use its
> **Where we are** block (current focus + "Next up"), then run `make format`,
> `make lint` and `make test`. Details: [docs/resuming.md](docs/resuming.md).
> Do not re-derive state from git history.

Crystal port of Apache PDFBox for creating, reading, and modifying PDF
documents, ported from [apache/pdfbox](https://github.com/apache/pdfbox) and
vendored at `vendor/pdfbox/` (`4.0.0-SNAPSHOT`; see `.gitmodules`).

## Commands

```bash
make install          # shards install
make update           # shards update
make submodule-init   # check out the vendored Apache PDFBox source
make submodule-update # move the vendored tree to its pinned upstream commit
make format           # crystal tool format --check src spec (gate, writes nothing)
make lint             # ameba src spec (gate, writes nothing)
make test             # crystal spec
make quality          # format + lint + test
make clean            # remove ./temp contents
```

`make format` and `make lint` are **checks**. To rewrite files instead, use the
explicit fix targets: `make format-fix`, `make lint-fix`.

> **Tooling:** `.ameba.yml` targets ameba `1.7.x`, the version pinned in
> `shard.lock`. Run the linter through `make lint` (or `ameba` from `PATH`);
> a stale `./bin/ameba` build (1.6.x) reports ~90 false failures. All three
> gates are green on a clean checkout — treat any new offense as a regression.

## Documentation

| Doc | Purpose |
| --- | --- |
| [docs/architecture.md](docs/architecture.md) | High-level structure and source-of-truth boundaries |
| [docs/development.md](docs/development.md) | Local workflow, setup, and temporary-file conventions |
| [docs/coding-guidelines.md](docs/coding-guidelines.md) | Porting rules and Crystal-specific coding expectations |
| [docs/testing.md](docs/testing.md) | Test-first parity workflow and quality gates |
| [docs/pr-workflow.md](docs/pr-workflow.md) | Commit, push, and review expectations |
| [docs/resuming.md](docs/resuming.md) | How a new session resumes work |

## Core Principles

- Treat Apache PDFBox Java source under `vendor/pdfbox/` as the source of truth.
- Before making changes to code, verify the intended vendor logic by asking questions via DeepWiki (`apache/pdfbox`), then confirm against the actual Java source under `vendor/pdfbox/`.
- Port tests first and match Java behavior exactly; do not simplify behavior for convenience.
- Prefer Crystal idioms only when they preserve the Java logic and observable semantics.
- Keep the repo shippable: run format, ameba, and specs before committing.
- Spec-dependent fixtures belong under `spec/` — see [docs/testing.md](docs/testing.md) for the layout rules.
- Use `./temp` only for ad-hoc scripts and throwaway artifacts; it is cleaned periodically, so never put spec dependencies there.
- Keep parity tracking current: `plans/parity.md` and `plans/inventory/`.
- Port upstream tests as first-class work; never weaken assertions or fixtures.

## Workflow

- Pick one **feature** at a time (one Java class or a small cluster), complete it, commit it.
- Before committing, run the quality gates: `make format`, `make lint`, `make test`
  (equivalently `crystal tool format --check src spec`, `ameba src spec`, `crystal spec`).
- Update `plans/parity.md` and the inventory ledgers, then commit with a detailed description of what was implemented.

## Tracking Work

Work is tracked in the tree (no external tracker), in five places:

| Where | What it records |
| --- | --- |
| [`plans/parity.md`](plans/parity.md) | Entry point: **Where we are**, the Overview table, and the work-file index (split parts with their status). |
| [`plans/parity/changelog.md`](plans/parity/changelog.md) (+ `plans/parity/changelog/`) | **The running feature changelog**, newest-first: one `current.md` plus frozen `archive-<newest date>-to-<oldest date>.md` parts. |
| [`plans/parity/phases.md`](plans/parity/phases.md), [`plans/parity/upcoming-chunks.md`](plans/parity/upcoming-chunks.md), [`plans/parity/naming.md`](plans/parity/naming.md) | Historical roadmap (Phases 1–13), the Work Chunk A–AW plans, and the Java → Crystal naming notes. |
| [`plans/inventory/java_source_parity.tsv`](plans/inventory/java_source_parity.tsv) | Per **Java source symbol** ledger. Columns: `source_api_id`, `status`, `crystal_refs`, `notes`. |
| [`plans/inventory/java_port_inventory.tsv`](plans/inventory/java_port_inventory.tsv) | Per **ported symbol** ledger. Columns: `source_id`, `kind`, `status`, `crystal_refs`, `notes`. |
| [`plans/inventory/java_test_parity.tsv`](plans/inventory/java_test_parity.tsv) | Per **Java test** ledger. Columns: `source_test_id`, `status`, `crystal_refs`, `notes`. |
| [`plans/active/*.md`](plans/active/) | One plan per branch-sized feature cluster (the older, coarse-grained workflow). |

**The changelog** is the source of truth for "what did we just do". It lives in
[`plans/parity/changelog.md`](plans/parity/changelog.md), which indexes the
newest-first part files under `plans/parity/changelog/`:

- add a new entry at the **top of [`plans/parity/changelog/current.md`](plans/parity/changelog/current.md)**
  (there is exactly one `current.md`, so "newest" is never ambiguous);
- when `current.md` grows past ~60 KB, freeze it as
  `changelog/archive-<newest date>-to-<oldest date>.md`, start a fresh
  `current.md`, and list the archive in `plans/parity/changelog.md`;
- `plans/parity.md` only links to the changelog (the `| Fixed since last
  update |` cell is a pointer, not a copy).

Each bullet states the feature, the accessors/behaviour added, the spec file, and the example-count delta (e.g. `2,572→2,573 examples, 0 failures`).

**Ledger rows.** Ids look like `<java/path>::method::<Class>.<method>`, `::class::`, `::const::`, or `::interface::`. `status` is `ported`, `partial`, or `missing`. When a feature lands, flip its rows to `ported`, set `crystal_refs` to the Crystal file(s), and set `notes` to a short marker (e.g. `ported: <feature>`).

> **The `missing` status is noisy.** The classifier only looks for `def`; it misses `property`, `getter`, `setter`, and members with a different owner. Before treating a row as a real gap, confirm the Crystal source truly lacks the behaviour. Likewise, prefer a trailing `# ameba:disable <Rule>` comment over renaming a Java-compatible method.

## Session continuity (read this first)

`plans/parity.md` is the single source of truth for where we are. At the start
of every session:

1. Read `plans/parity.md` and use its **Where we are** block to find the
   current focus and the next phase. Do not re-derive state from git history.
2. Skim `git log --oneline -10` and `git status` to confirm the working tree.
3. Run the gates (`make format`, `make lint`, `make test`) before making
   changes to confirm a clean baseline.

### Keeping parity.md resumable

- `plans/parity.md` starts with a **Where we are** block: `Current focus`,
  `Next up`, and the **work files** table with each split file's status plus
  the file we are currently working in. Keep it accurate after every feature.
- Work chunks are feature-sized (roughly one branch/commit). The per-symbol
  state lives in `plans/inventory/java_port_inventory.tsv`, not in this plan.
- **`plans/parity.md` is an entry point, not a dumping ground.** It was split
  (2026-10-28) into `plans/parity/changelog.md` (+ `changelog/current.md` and
  `changelog/archive-*.md`), `phases.md`, `upcoming-chunks.md` and `naming.md`. When it grows too large,
  split the offending section into another `plans/parity/<module>.md`, link it
  from `plans/parity.md`, and in `plans/parity.md` mark each split file as
  complete/in-progress and name the file we are currently working in plus the
  next file/phase to start.

### Definition of done for every feature (required)

A feature is complete only when all of the following are true, and all of it
must be committed as **one** atomic commit before starting the next feature:

1. the API surface is implemented;
2. upstream tests (or equivalent characterization specs) exist and pass;
3. gates pass: `make format`, `make lint`, `make test`;
4. parity inventory rows for the feature are updated
   (`plans/inventory/java_port_inventory.tsv` and
   `plans/inventory/java_source_parity.tsv`);
5. `plans/parity.md` status is updated and the **Where we are** block refreshed
   (current focus + next up);
6. any intentional divergence is documented (in `plans/parity.md` and/or the
   commit message).

### Commit message

Start with a one-line imperatively-worded subject (e.g. `Add …`, `Complete …`,
`Fix …`; the older bulk-port commits use a `port:` prefix). Then bullets for
what changed, then the upstream revision (`apache/pdfbox 4.0.0-SNAPSHOT`, see
`vendor/pdfbox/`). Include new/changed files, divergences, and the gate results
so a new session can resume from the commit alone.
