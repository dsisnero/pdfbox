# Testing

This project follows a test-first parity workflow.

- Port the relevant Java test before implementing behavior.
- Use upstream fixtures from `vendor/pdfbox/` whenever they exist.
- Keep pending specs explicit when a broader subsystem is still missing.
- Never weaken an assertion or a fixture to make a port pass.

Run the quality gates after significant changes:

```bash
make format   # crystal tool format --check src spec
make lint     # ameba src spec
make test     # crystal spec
```

The gates only check; use `make format-fix` / `make lint-fix` when you mean to
rewrite files.

`make lint` uses ameba `1.7.x` (pinned in `shard.lock`). A stale `./bin/ameba`
build (1.6.x) reports ~90 false failures, so always run the gate as
`make lint`. The gates are green on a clean checkout; a new offense is a
regression.

Spec-dependent fixtures belong under `spec/`: `spec/fixtures` for standalone
fixtures, or `spec/resources/<module>/` mirroring the Java `src/test/resources`
layout for vendor-parity fixtures. Do not put spec dependencies in `./temp`,
which is cleaned periodically.

Record the example-count delta (e.g. `2,572→2,573 examples, 0 failures`) in the
`plans/parity/changelog/` part file when a feature lands (`plans/parity.md`
only links the changelog).
