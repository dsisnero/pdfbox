# Port Plan: Shading model + PDPageContentStream#shading_fill

**Goal:** `PDShading.create` (types 1-7) and `PDResources#add(PDShading)`/
`#shading`, and wire `shading_fill` to add the shading resource and write its
name + `sh` (Java `shadingFill`).

## Source of truth

- `vendor/pdfbox/.../pdmodel/graphics/shading/PDShading.java#create`
- `vendor/pdfbox/.../pdmodel/PDResources.java#add(PDShading)` / `getShading`
- `vendor/pdfbox/.../pdmodel/PDPageContentStream.java#shadingFill`

## Problem

`PDPageContentStream#shading_fill` wrote a bare `sh` with no operand and never
added the shading to the page resources, producing invalid content. There was
no `PDShading` base or `create`.

## Steps (red-green)

1. [x] Write `spec/pdfbox/pdmodel/graphics/shading_spec.cr` first (red):
   `shading_fill` stores `sh1` and writes `/sh1 sh`; `PDShading.create` maps
   types 1-7 and rejects unknown.
2. [x] `PDShading` base + `PDShadingType1..7` + `create`.
3. [x] `PDResources#add(PDShading)` (prefix "sh") / `#shading(name)`.
4. [x] `shading_fill` uses `ensure_resource_subdictionary("Shading")` and writes
   the name operand.
5. [x] Gates; parity.md + inventory.
