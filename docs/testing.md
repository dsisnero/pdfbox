# Testing

This project follows a test-first parity workflow.

- Port the relevant Java test before implementing behavior.
- Use upstream fixtures from `vendor/pdfbox/` whenever they exist.
- Keep pending specs explicit when a broader subsystem is still missing.

Run the quality gates after significant changes:

```bash
crystal tool format --check src spec
ameba --fix src spec
ameba src spec
crystal spec
```

Spec-dependent fixtures belong under `spec/`: `spec/fixtures` for standalone
fixtures, or `spec/resources/<module>/` mirroring the Java `src/test/resources`
layout for vendor-parity fixtures. Do not put spec dependencies in `./temp`,
which is cleaned periodically.
