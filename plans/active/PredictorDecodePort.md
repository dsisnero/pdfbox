# Port Plan: PNG/TIFF predictor decoding in Flate/LZW

**Goal:** apply `DecodeParms` predictors after Flate/LZW decode, matching Java
`Predictor.wrapPredictor` / `FlateFilter#decode`.

## Source of truth

- `vendor/pdfbox/.../filter/Predictor.java` (`decodePredictorRow`,
  `calculateRowLength`, `wrapPredictor` + `PredictorOutputStream`)
- `vendor/pdfbox/.../filter/FlateFilter.java#decode`
- `vendor/pdfbox/.../filter/LZWFilter.java#decode`

## Problem

`FlateFilter`/`LZWFilter` ignored `DecodeParms`, so PNG (10-15) and TIFF (2)
predictors were never applied. Any predicted stream (e.g. PNGConverter's
transparency mask, LosslessFactory images) decoded to still-predicted data.

## Steps (red-green)

1. [x] Write `spec/pdfbox/filter/predictor_decode_spec.cr` first (red): each
   predictor mode plus end-to-end Flate and `Cos::Stream` decode.
2. [x] `Predictor.decode_predictor_row` (TIFF SUB 1/8/16 bpc + generic, PNG
   NONE/SUB/UP/AVG/PAETH) and `Predictor.calculate_row_length`.
3. [x] `Predictor.decode_data` (row buffering, per-row predictor byte for >=10,
   zero-filled final partial row).
4. [x] `FlateFilter`/`LZWFilter` override params-aware `decode`.
5. [x] Gates; parity.md + inventory.

## Notes

- The predictor is applied on the already-inflated/decoded bytes; no behaviour
  change when `Predictor` is absent or <= 1.
