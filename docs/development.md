# Development

Install dependencies with `make install` or `shards install`.

Use the normal local loop:

```bash
crystal tool format --check src spec
ameba --fix src spec
ameba src spec
crystal spec -Dpreview_mt -Dexecution_context
```

Temporary files, ad hoc scripts, and downloaded fixtures belong in `./temp`.
`make clean` removes temporary artifacts from that directory.

Use `bd` for task tracking and keep work in focused commits that can be pushed
independently.
