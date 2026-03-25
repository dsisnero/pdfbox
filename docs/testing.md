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
crystal spec -Dpreview_mt -Dexecution_context
```

If a spec depends on an external fixture that is not committed, place temporary
downloads in `./temp` and avoid relying on system temp directories.
