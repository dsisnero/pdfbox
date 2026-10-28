# Naming inconsistencies (Crystal class-name parity)

> Part of the parity tracking set; index at [`../parity.md`](../parity.md).
> **Status: reference** — how Java class/method names map to Crystal names and
> how the inventory matcher handles the renames. Not a work item.

## Naming Inconsistencies (Crystal class-name parity)

> **Status (2026-09-02):** the alias-aware matcher is implemented in
> `temp/reconcile_inventory.py` (`alias_tokens` + union method-set matching) and the
> inventory re-reconciled. Source counts moved from `ported 3,986 / partial 2,542 /
> missing 5,901` to **`ported 4,208 / partial 2,805 / missing 5,416`** (285
> `missing→partial`, 200 `missing→ported`, 22 `partial→ported`), with 100% recall of
> the 279 curated ground-truth positives. All three parity checks pass under
> tree-sitter. Example before/after: `COSArray.add` and `COSArray.removeObject` are
> now `ported` (previously only via ground truth / missing); `COSWriter.doWriteBody`
> stays `partial`. Two `getObject`-style rows where the Crystal name differs
> (`COSArray.get` vs Java `getObject`) remain `partial` — see `method_candidates`.

The inventory matcher (`temp/reconcile_inventory.py`) had a known weakness: Java
class names do not map 1:1 to Crystal class names. Java classes carry `PD`/`COS` prefixes
(`PDDocument`, `COSArray`, `PDAppearanceContentStream`), while the Crystal port strips
some prefixes (`PDDocument` → `Document`) but keeps others (`PDAppearanceContentStream`,
`PDFormContentStream`) or maps `COS*` into the `Cos::` namespace (`COSArray` → `Array`,
`COSDictionary` → `Dictionary`). Without alias handling the reconcile matcher
under-counted ported methods for `COS*` classes unless ground-truth rows were present.

The general-purpose codemod fixer uses [`fastmod`](https://github.com/facebookincubator/fastmod)
(cargo-installed; `fastmod 0.4.4` on `PATH`) to normalize names in one shot. It is a
regex-based, human-reviewable codemod tool:

```text
fastmod --help
# Usage:
fastmod [FLAGS] [OPTIONS] <REGEX> <subst> [--] [FILE OR DIR]...
# FLAGS:
#   --accept-all               auto-accept all changes (caution)
#   -F, --fixed-strings        treat REGEX as a literal string
#   -i, --ignore-case          case-insensitive search
#   -m, --multiline            dot matches newlines
# OPTIONS:
#   -d, --dir <DIR>...         directory to walk
#   -e, --extensions <EXT>...  comma-delimited extensions to process
#   -g, --glob <GLOB>...       only process matching globs
# ARGS:
#   <REGEX>                    regex to match (Rust regex crate: ${1} capture groups,
#                              no look-around, no backreferences)
#   <subst>                    replacement (use ${1}; single-quote in bash so $ is literal)
```

Key differences from `perl -pi`/`sed` codemods that matter here:

- Uses the **Rust `regex` crate** — no look-around, no backreferences; use `${1}`
  (not `\1`) for capture groups, and `$$` for a literal `$`.
- **Interactive by default** — shows a colored diff per match and prompts
  accept/reject/edit; combine with `--accept-all` only after eyeballing a dry run.
- `-F`/`--fixed-strings` avoids escaping regex metacharacters for pure rename sweeps.

Concrete fixes the matcher needs / fastmod can apply:

```bash
# Strip the COS prefix so Java COSArray matches Crystal Cos::Array
fastmod -d src -e cr --extensions cr 'COS(Array|Dictionary|Name|Number|String|Stream)' '${1}'

# Normalize PD-prefixed names that the port strips to a short form
fastmod -d src -e cr 'PDDocumentCatalog' 'DocumentCatalog'

# Interactive (recommended first pass): see each change before accepting
fastmod -d src -e cr 'COSArray' 'Array'
```

Workflow (all steps now done for the 2026-09-02 pass):

1. Build the Java→Crystal class-token alias map (`alias_tokens`: strip `COS`/`PD`,
   prefer exact token, keep ambiguous short+prefixed forms; union matching when a
   Java class resolves to multiple Crystal tokens).
2. Re-run `temp/reconcile_inventory.py` (`ported 4,208 / partial 2,805 /
   missing 5,416`, 100% ground-truth recall) and re-check status counts + spot checks.
3. Re-run `check_port_inventory.sh` (and source/test parity) under tree-sitter — all
   pass (12,429 API / 1,936 tests tracked).
4. Refresh the `Overview` metrics and any phase checkboxes above to match the
   alias-aware reconciled inventory (`src/` 642 `.cr` files, ~2,169 passing tests).
