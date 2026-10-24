# Development

## Setup

```bash
make submodule-init   # check out the vendored Apache PDFBox source
make install          # shards install
```

Dependencies are pinned in `shard.yml` / `shard.lock`; refresh them with
`make update`.

## Upstream reference

This repository ports Apache PDFBox (Java) to Crystal. The Java source of truth
lives in the git submodule at `vendor/pdfbox/` (release `4.0.0-SNAPSHOT`, URL in
`.gitmodules`). It is **checked out and read**, not edited:

- `make submodule-init` populates `vendor/pdfbox/`.
- `make submodule-update` moves it to the pinned upstream commit.

When the Crystal code and the Java code disagree, the Java code wins. See
[architecture.md](architecture.md) for the layer boundaries and
[coding-guidelines.md](coding-guidelines.md) for the porting rules.

## Local loop

```bash
make format   # crystal tool format --check src spec   (gate, writes nothing)
make lint     # ameba src spec                          (gate, writes nothing)
make test     # crystal spec
make quality  # all three
```

The gates are checks. When you actually want files rewritten, use the explicit
fix targets: `make format-fix` and `make lint-fix`.

`make lint` uses ameba `1.7.x` (the version pinned in `shard.lock` and named in
`.ameba.yml`). A stale `./bin/ameba` build (1.6.x) reports ~90 false failures —
run the gate as `make lint`, not through an old local binary. The gates are
green on a clean checkout, so any new offense is a regression.

## Temporary files

Ad hoc scripts, scratch outputs, and one-off PDFs belong in `./temp`, which is
git-ignored and cleared by `make clean`. Spec-dependent fixtures must **not**
live there — put them under `spec/` (`spec/fixtures`, or
`spec/resources/<module>/` mirroring the Java `src/test/resources` layout).

## Environment note (exFAT / network volume checkouts)

This checkout may live on an exFAT/extreme_ssd volume. macOS then writes
AppleDouble sidecars (`._*`), which the repo already ignores via `.gitignore`
and marks `binary linguist-generated=true` in `.gitattributes`. Two symptoms to
recognize:

- a `._foo_spec.cr` sidecar can break spec discovery;
- `git` can print `non-monotonic index .../._pack-*.idx`; delete the sidecars
  with `find .git -name '._*' -delete`.

The volume can also unmount briefly, which aborts a running `crystal spec` with
`Error getting current directory`. Re-run the suite; nothing is corrupted.
