# Port Plan: Form Field Appearance Generation

**Goal:** Port AcroForm variable-text field appearance generation to match
Apache PDFBox, driven by `AppearanceGenerationTest.java` (PDFBOX-5763),
`PDDefaultAppearanceStringTest.java`, and `PDTextFieldTest.java`.

## Source of truth

- `vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/interactive/form/AppearanceGeneratorHelper.java` (1059 lines)
- `.../PDDefaultAppearanceString.java` (326 lines)
- `.../PDVariableText.java` (270 lines)
- `.../PDTextField.java` (constructAppearances)
- `.../PDTerminalField.java` (applyChange)
- Tests: `PDDefaultAppearanceStringTest.java`, `AppearanceGenerationTest.java#testTinyHorizontalFieldWith0FontSize`

## Steps (red-green)

1. [x] Port `PDDefaultAppearanceString` (DA string parse: `/F 12 Tf` font+size, `rg`/`g`/`k` color, missing-resource and wrong-arg errors) + `PDResources#add(font)` / `get_font` returning `PDFont` — green via `PDDefaultAppearanceStringTest`
2. [x] Port `PDVariableText` base (default appearance/DA inheritable, default style string, quadding Q, rich text value) + `PDAcroForm#default_resources=`, `#set_default_appearance`
3. [x] Port `AppearanceGeneratorHelper#setAppearanceValue` core (widget loop, appearance dict/stream prep, `initializeAppearanceContent` background/border, `insertGeneratedAppearance` text+clip, `calculateFontSize` with PDFBOX-5763 `-Infinity` guard)
4. [x] Wire `PDTextField#value=` → `applyChange` → `construct_appearances` → `AppearanceGeneratorHelper`
5. [x] Port `AppearanceGenerationTest#testTinyHorizontalFieldWith0FontSize` (no `-Infinity`, no exception)
6. [x] Run gates: `crystal tool format --check src spec`, `ameba`, `crystal spec`; update parity.md + inventory

## Notes

- `PDAppearanceContentStream` lacks: `clip()`, `set_font` with existing resource name, RGB 3-arg color setter. Extend it as needed.
- `PlainText`/`PlainTextFormatter`/`AppearanceStyle` already ported.
- `PDAppearanceStream` exists in `pdappearance_dictionary.cr`; needs `form_type=`/`set_form_type`.
- Keep comb/listbox paths minimal but faithful; primary target is text-field single-line + PDFBOX-5763.
