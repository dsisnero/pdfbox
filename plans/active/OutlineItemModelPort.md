# Port Plan: PDOutlineItem destination/action/structure/text-color

**Goal:** complete the canonical `PDOutlineItem` model surface and
`findDestinationPage`, matching Apache PDFBox.

## Source of truth

- `vendor/pdfbox/.../documentnavigation/outline/PDOutlineItem.java`
  (`getDestination`/`setDestination`, `getAction`/`setAction`,
  `getStructureElement`/`setStructureElement`, `getTextColor`/`setTextColor`,
  `findDestinationPage`)
- `vendor/pdfbox/.../PDDocumentCatalog.java#findNamedDestinationPage`

## Steps (red-green)

1. [x] Write `spec/pdfbox/pdmodel/interactive/outline_item_model_spec.cr`
   first (red): default nil/black, destination/action/structure/text-color
   round-trips, and `find_destination_page` for page destinations, GoTo
   actions, page-number destinations and named destinations.
2. [x] Implement the five surfaces on
   `Outline::PDOutlineItem` (with action/destination/structure types and
   `PDColor` text colour).
3. [x] Add `DocumentCatalog#find_named_destination_page` walking `/Names /Dests`
   names/kids trees, falling back to the catalog `/Dests` dictionary.
4. [x] Gates; parity.md + inventory.

## Notes

- This is the newer `documentnavigation/outline/PDOutlineItem` (the one used by
  `PDOutlineItemTest`/`PDOutlineNodeTest`). The legacy `Pdfbox::Pdmodel::OutlineItem`
  in `pdmodel.cr` is a separate, older implementation.
- The generic `Common::PDNameTreeNode` could not polymorphically dispatch its
  abstract `convert_cos_to_pd` through `Kids`, so named-destination lookup is a
  small direct tree walk instead.
