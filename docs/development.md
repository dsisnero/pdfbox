# Development

Install dependencies with `make install` or `shards install`.

Use the normal local loop:

```bash
crystal tool format --check src spec
ameba --fix src spec
ameba src spec
crystal spec
```

Temporary files and ad hoc scripts belong in `./temp`; `make clean` removes
them from that directory. Spec-dependent fixtures must not live there — place
them under `spec/` (`spec/fixtures` or `spec/resources/<module>/`).

Use `bd` for task tracking and keep work in focused commits that can be pushed
independently.
