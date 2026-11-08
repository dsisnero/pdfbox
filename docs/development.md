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

Run the gates after every change:

```bash
make quality  # format + lint + test
```

[testing.md](testing.md) owns the gate details: what each target checks,
the `make format-fix` / `make lint-fix` rewrite variants, and the ameba-version
trap that makes a stale `./bin/ameba` report false failures. The gates are green
on a clean checkout, so any new offense is a regression.

One repository-specific prerequisite is wired into the Makefile: macOS writes
AppleDouble `._*` sidecars on exFAT volumes, a `._foo_spec.cr` sidecar breaks
spec discovery, so `format`/`lint`/`test` depend on the `sidecars` target, which
deletes them from `src/` and `spec/` first (`make sidecars` runs it alone).

## Temporary files

Ad hoc scripts, scratch outputs, and one-off PDFs belong in `./temp`, which is
git-ignored and cleared by `make clean`. Spec-dependent fixtures must **not**
live there — see [testing.md](testing.md) for where they belong.

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
