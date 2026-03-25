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
crystal spec -Dpreview_mt -Dexecution_context
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
- Port tests first and match Java behavior exactly; do not simplify behavior for convenience.
- Prefer Crystal idioms only when they preserve the Java logic and observable semantics.
- Keep the repo shippable: run format, ameba, and specs before committing.
- Use `./temp` for temporary artifacts and keep repository-local tooling state out of version control.

## Commit Convention

Use focused, imperative commit messages that describe the behavior change, for example:

```text
Port COSDocumentCompressionTest#testAlteredDoc with Flate stream parity
```

## Project Conventions

- Use `bd` for issue tracking; do not keep markdown TODO lists.
- Run `ameba --fix src spec` before the final lint/spec pass when code changes.
- Prefer vendor fixtures and Java tests over synthetic replacements when porting parity behavior.
- Keep temporary scripts and downloaded fixtures under `./temp`.
