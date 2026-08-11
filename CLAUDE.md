# PDFBox Crystal

Crystal port of Apache PDFBox for creating, reading, and modifying PDF documents.

## Verified Commands

```bash
make install
make update
make format
make lint
make test
make clean

crystal tool format --check src spec
ameba src spec
crystal spec
shards install
shards update
```

## Documentation

| Doc | Purpose |
| --- | --- |
| [docs/architecture.md](docs/architecture.md) | High-level structure and source-of-truth boundaries |
| [docs/development.md](docs/development.md) | Local workflow, setup, and temporary-file conventions |
| [docs/coding-guidelines.md](docs/coding-guidelines.md) | Porting rules and Crystal-specific coding expectations |
| [docs/testing.md](docs/testing.md) | Test-first parity workflow and quality gates |
| [docs/pr-workflow.md](docs/pr-workflow.md) | Commit, push, and review expectations |

## Core Principles

- Treat Apache PDFBox Java source under `vendor/pdfbox/` as the source of truth.
- Before making changes to code, verify the intended vendor logic by asking questions via DeepWiki (`apache/pdfbox`), then confirm against the actual Java source under `vendor/pdfbox/`.
- Port tests first and match Java behavior exactly; do not simplify behavior for convenience.
- Prefer Crystal idioms only when they preserve the Java logic and observable semantics.
- Keep the repo shippable: run format, ameba, and specs before committing.
- Spec-dependent fixtures belong under `spec/` — `spec/fixtures` for standalone fixtures, or `spec/resources/<module>/` mirroring the Java `src/test/resources` layout for vendor-parity fixtures.
- Use `./temp` only for ad-hoc scripts and throwaway artifacts; it is cleaned periodically, so never put spec dependencies there.

## Workflow

- Follow `plans/parity.md` to pick what to work on next.
- Work on one phase to completion before stopping: close every unchecked item in that phase.
- Before committing, clean the quality gates: `crystal tool format --check src spec`, `ameba src spec`, and `crystal spec`.
- Update `plans/parity.md` (check off completed items) and the inventory, then commit with a detailed description of what was implemented.

## Commit Convention

Use focused, imperative commit messages that describe the behavior change, for example:

```text
Port COSDocumentCompressionTest#testAlteredDoc with Flate stream parity
```

## Project Conventions

- Run `ameba --fix src spec` before the final lint/spec pass when code changes.
- Prefer vendor fixtures and Java tests over synthetic replacements when porting parity behavior.
- Keep temporary scripts under `./temp`; never rely on them as spec dependencies since the directory is cleaned periodically.
